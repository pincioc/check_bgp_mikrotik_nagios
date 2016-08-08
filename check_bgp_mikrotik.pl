#!/usr/bin/perl -w 
# nagios:-epn

#########################################
#  check_bgp_mikrotik - nagios plugin 	#
#					#
#       Mauro - blog.openskills.it	#
#########################################

use lib qw( /usr/lib/nagios/plugins );
use lib qw( /opt/librenms/plugins );
use utils qw(%ERRORS $TIMEOUT &print_revision &support &usage);
use Switch;
use Mikrotik;
use Nagios::Plugin::Getopt;
$ng = Nagios::Plugin::Getopt->new(
	usage => 'Usage: %s -H mtik_host -a apiport -u mtik_user -p mtik_passwd -b BGP_peer_ip -c Min_prefix_count',
	version => '0.3 [http://blog.openskills.it]',
);
$ng->arg(spec => 'host|H=s', help => "Mikrotik Host", required => 1);
$ng->arg(spec => 'apiport|a=s', help => "API Port", required => 0);
$ng->arg(spec => 'user|u=s', help => "API username", required => 1);
$ng->arg(spec => 'pass|p=s', help => "API password", required => 1);
$ng->arg(spec => 'bgppeer|b=s', help => "BGP Peer IP", required => 1);
$ng->arg(spec => 'count|c=s', help => "Min prefix-count", required => 0);
$ng->getopts;
$Mtik::debug = 0;
if (!length $ng->get('apiport'))
{
	$apiport=8728
}else{
	$apiport=$ng->get('apiport')
}		
if (Mtik::login($ng->get('host'),$ng->get('user'),$ng->get('pass'),$apiport))
	{
	my @cmd = ("/routing/bgp/peer/print","=status=","?remote-address=". $ng->get('bgppeer'));
	my($retval,@results) = Mtik::raw_talk(\@cmd);
	if (@results==1){
		print "UNKNOWN - Peer remote address not found \n"; 
		exit (1);
	}
	foreach my $result (@results) {
		#printf "$result\n";
		my @values = split('=', $result);
		$nums= @values;
		if ($nums == 3){ 
    			$chiave=$values[1];	
			$valore=$values[2];
			switch ($chiave){
				case "state"	{  $status=$valore }
				case "uptime"	{  $upfrom=$valore }
				case "disabled" {  $disabled=$valore }
				case "prefix-count" {  $prefix=$valore }
			}
  		}	
	}
	Mtik::logout;
	if (length $ng->get('count')  && $prefix < $ng->get('count')){
	 	print "WARNING - Prefix count $prefix lower then ".$ng->get('count')."\n";
                exit (1);
	}
	if ($disabled eq "true"){
		print "UNKNOWN - Peer disable \n"; 
		exit (3);
	}
	if ($status eq "established"){
		print "OK - Peer BGP $status from $upfrom with $prefix prefix count\n"; 
		exit (0);
		
	}else{
		print "CRITICAL - State $status\n"; 
		exit (2); 
	}
}else{
		print "UNKNOWN - I can't log in to ".$ng->get('host')."\n"; 
		exit (3); 
}

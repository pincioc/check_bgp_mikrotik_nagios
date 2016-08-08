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
	usage => 'Usage: %s -H mtik_host -a apiport -u mtik_user -p mtik_passwd -b BGP_peer_ip',
	version => '0.2 [http://blog.openskills.it]',
);
$ng->arg(spec => 'host|H=s', help => "Mikrotik Host", required => 1);
$ng->arg(spec => 'apiport|a=s', help => "API Port", required => 0);
$ng->arg(spec => 'user|u=s', help => "API username", required => 1);
$ng->arg(spec => 'pass|p=s', help => "API password", required => 1);
$ng->arg(spec => 'bgppeer|b=s', help => "BGP Peer IP", required => 1);
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
	$loo=0;
	$find=0;
	foreach my $result (@results) {
		#printf "$result\n";
		my @values = split('=', $result);
		$nums= @values;
		if ($nums == 3){ 
    			$chiave=$values[1];	
			$valore=$values[2];
			if ($chiave eq "remote-address"){
				if ($valore eq $ng->get('bgppeer')){
					$loo = 1;
					$find = 1;
				}else {
					$loo = 0;	
				}
			}
			if ($loo == 1){
				switch ($chiave){
					case "state"	{  $status=$valore }
					case "uptime"	{  $upfrom=$valore }
					case "disabled" {  $disabled=$valore }
					case "prefix-count" {  $prefix=$valore }
				}
			}
  		}	
	}
	Mtik::logout;
	if ($find == 0){
		print "UNKNOWN - Peer remote address not found \n"; 
		exit (1);
	}
	if ($disabled eq "true"){
		print "UNKNOWN - Peer disable \n"; 
		exit (1);
	}
	if ($status eq "established"){
		print "OK - Peer BGP $status from $upfrom with $prefix prefix count\n"; 
		exit (0);
		
	}else{
		print "CRITICAL - State $status\n"; 
		exit (2); 
	}
}else{
		print "UNKNOWN - I can't log in to $ng->get('host')\n"; 
		exit (1); 
}

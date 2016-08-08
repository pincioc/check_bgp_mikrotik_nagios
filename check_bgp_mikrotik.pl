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
use MikroTik;
use Nagios::Plugin::Getopt;
$ng = Nagios::Plugin::Getopt->new(
	usage => 'Usage: %s -H mtik_host -a apiport -u mtik_user -p mtik_passwd -b BGP_peer_ip -T [min:MAX]',
	version => '0.4 [http://blog.openskills.it]',
);
$ng->arg(spec => 'host|H=s', help => "Mikrotik Host", required => 1);
$ng->arg(spec => 'apiport|a=n', help => "API Port", required => 0);
$ng->arg(spec => 'user|u=s', help => "API username", required => 1);
$ng->arg(spec => 'pass|p=s', help => "API password", required => 1);
$ng->arg(spec => 'bgppeer|b=s', help => "BGP Peer IP", required => 1);
$ng->arg(spec => 'threshold|T=s', help => "Prefix count threshold in format min:MAX", required => 0);
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
	my @cmd = ("/routing/bgp/peer/print","=status=","?remote-address=".$ng->get('bgppeer'),"=.proplist=prefix-count,disabled,state,uptime");
	my($retval,@results) = Mtik::raw_talk(\@cmd);
	if (@results == 1){
		print "UNKNOWN - Peer remote address not found \n";
		exit (1);
	}
	my @values;
	foreach my $result (@results) {
		#printf "$result\n";
		my @cv = split('=', $result);
		if (@cv == 3){ 
			if ($cv[1] eq "disabled" && $cv[2] eq "true"){
       				print "UNKNOWN - Peer disable \n";
                		exit (3);
	        	}
			push @values, $cv[2];
  		}
	}
	Mtik::logout;
	if ($values[1] eq "true"){
		print "UNKNOWN - Peer disable \n";
		exit (3);
	}
	if (length $ng->get('threshold')){
		my @ts = split(':', $ng->get('threshold'));
		$tmin = $ts[0];
		$tmax = $ts[1];
	 	if ($values[0] lt $tmin){	
	 		print "WARNING - Prefix count $values[0] lower than min threshold $tmin\n";
                	exit (1);
		}
		if ($values[0] gt $tmax){
                        print "WARNING - Prefix count $values[0] bigger than MAX threshold $tmax\n";
                        exit (1);
                }
	}
	if ($values[2] eq "established"){
		print "OK - Peer BGP established from $values[3] with $values[0] prefix\n";
		exit (0);
	}else{
		print "CRITICAL - State $values[2]\n";
		exit (2);
	}
}else{
		print "UNKNOWN - I can't log in to ".$ng->get('host')."\n";
		exit (3);
}

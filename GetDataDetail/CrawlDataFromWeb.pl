#!/usr/bin/perl

use strict;
use JSON;
use Data::Dumper;
use script::CrawlSubs;

open(IN,$ARGV[0])||die("The file can't find!\n");
my $jsonparser = new JSON;

while(my $row = <IN>)
{
	chomp($row);
	my $json = $jsonparser->decode($row);
	my $url = $json->{url};	
	dowork($url,$json);
}

sub dowork
{
	my $url = shift;
	my $json = shift;

	my $ua = LWP::UserAgent->new;
	$ua->agent('Mozilla/5.0 '.$ua->_agent);
	my $response = $ua->get($url);

	if($response->is_success)
	{
		#my $res = crawl::parserVoaSpecialHTML($response);
		#my $res = crawl::parserVoaNormalHTML($response);
		my $res = crawl::parser51enHTML($response);
		$json->{info} = crawl::formater($res->{info});
		print $jsonparser->encode($json)."\n";
		#die;
	}
	else
	{
		dowork($url,$json);	
	}
}
1;


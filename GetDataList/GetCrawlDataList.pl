#!/usr/bin/perl

use strict;
use DBI;
use POSIX;
use threads;
use Encode;
use JSON;
use Try::Tiny;
use Data::Dumper;
use LWP::UserAgent;
use HTML::TreeBuilder;

open(OUT,">$ARGV[0]")||die("The file can't find!\n");

my $ref = {
	'news' => {
		'news/cnn/list_4_' => 30,
		'news/npr/list_5_' => 139,
		'news/cri/list_10_' => 43,
		'news/ap/list_2_' => 26,
		'news/sci/list_9_' => 25,
		'news/economist/list_19_' => 41
	},
	'nce' => {
		'nce/rp/list_24_' => 6,
		'nce/ga/list_29_' => 6
	},
	'ted' => {
		'talks/quick-list?page=' => 95
	}
};

my $ted = $ref->{ted};
my $prefix = 'https://www.ted.com';

&scan($ted);

sub scan
{
	my $ref = shift;
	my $flag = shift;

	foreach my $key (%$ref)
	{
		my $values = $ref->{$key};
		for(my $i = 1; $i <= $values; $i++)
		{
			my $url = $prefix.'/'.$key.$i;
			print $url."\n";
			getTedData($url);
		}
	}
}

sub getTedData 
{
	my $url = shift;
	my $try = 5;
	my $res;
	
	my $ua = LWP::UserAgent->new;
	$ua->agent('Mozilla/5.0 '.$ua->_agent);
	$ua->proxy('https', 'http://192.168.1.20:3128'); 
	my $response = $ua->get($url);

	if($response->is_success)
	{
		my $root = HTML::TreeBuilder->new_from_content($response->decoded_content);
		my $info_node = $root->look_down(_tag => 'div', class => 'row quick-list__container');

		my @url_node = $info_node->look_down(_tag => 'span', 'class' => 'l3');
		my @mp4_node = $info_node->look_down(_tag => 'ul', 'class' => 'quick-list__download');
		
		foreach my $url_node (@url_node)
		{
			my $url = $url_node->look_down(_tag => 'a');
			#print $prefix.$url->{href}."\n";
			push @{$res->{url}},$prefix.$url->{href};
		}
		
		foreach my $mp4_node (@mp4_node)
		{
			my @mp4;
			my @a_nodes = $mp4_node->look_down(_tag => 'a');
			foreach my $mp4 (@a_nodes)
			{
				#print $mp4->{href}."\n";
				push @mp4,$mp4->{href};
			}

			push @{$res->{mp4}},@mp4;
		}
		
		my $jsonparser = new JSON;
		print $jsonparser->encode($res)."\n";
	
		die;
	}
	else
	{
		if($try--)
		{
			return;
		}
		
		sleep(2);
		print "Outer : Get data fail, Try again...$url\n";
		getData($url);
	}
}

1;


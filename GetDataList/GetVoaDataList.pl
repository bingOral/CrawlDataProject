#!/usr/bin/perl

use strict;
use DBI;
use POSIX;
use threads;
use Encode;
use Try::Tiny;
use LWP::UserAgent;
use HTML::TreeBuilder;

open(OUT,">$ARGV[0]")||die("The file can't find!\n");

my $ref = {
	'news' => {
		'cnn/list_4_' => 30,
		'npr/list_5_' => 139,
		'cri/list_10_' => 43,
		'ap/list_2_' => 26,
		'sci/list_9_' => 25,
		'economist/list_19_' => 41
	},
	'nce' => {
		'rp/list_24_' => 6,
		'ga/list_29_' => 6
	}
};

my $news = $ref->{news};
my $nce = $ref->{nce};
my $prefix = 'http://www.51en.com';

&scan($news,'news');
&scan($nce,'nce');

sub scan
{
	my $ref = shift;
	my $flag = shift;

	foreach my $key (%$ref)
	{
		my $values = $ref->{$key};
		for(my $i = 1; $i <= $values; $i++)
		{
			my $url = $prefix.'/'.$flag.'/'.$key.$i.'.html';
			print $url."\n";
			getData($url);
		}
	}
}

sub getData 
{
	my $url = shift;
	my $try = 5;
	
	my $ua = LWP::UserAgent->new;
	$ua->agent('Mozilla/5.0 '.$ua->_agent);
	my $response = $ua->get($url);

	if($response->is_success)
	{
		my $root = HTML::TreeBuilder->new_from_content($response->decoded_content);
		my $info_node = $root->look_down(_tag => 'div', class => 'listl list3');
		if($info_node)
		{
			my @Links = $info_node->find_by_tag_name('a');
			foreach my $link (@Links) 
			{
                my $href = $link->{'href'};
                my $flag = $link->{'target'};
                if($flag)
                {
                	print OUT $prefix.$href."\n";
                }
			}
		}
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


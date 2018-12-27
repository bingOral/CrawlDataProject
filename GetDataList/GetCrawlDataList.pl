#!/usr/bin/perl

use strict;
use Encode;
use JSON;
use Try::Tiny;
use Data::Dumper;
use LWP::UserAgent;
use HTML::TreeBuilder;
use script::HtmlSubs;

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
			HtmlTools::ParserTedData($url);
		}
	}
}

1;


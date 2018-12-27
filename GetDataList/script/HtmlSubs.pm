#!/usr/bin/perl

use strict;
package HtmlTools;
use JSON;
use Try::Tiny;
use Data::Dumper;
use LWP::UserAgent;
use HTML::TreeBuilder;

sub ParserTedData 
{
	my $url = shift;

	my $try = 5;
	my $res;
	
	my $jsonparser = new JSON;
	my $ua = LWP::UserAgent->new;
	$ua->agent('Mozilla/5.0 '.$ua->_agent);
	$ua->proxy('https', 'http://192.168.1.20:3128'); 
	my $response = $ua->get($url);

	if($response->is_success)
	{
		my $root = HTML::TreeBuilder->new_from_content($response->decoded_content);
		my @info_nodes = $root->look_down(_tag => 'div', class => 'col xs-12 quick-list__container-row');

		foreach my $info_node (@info_nodes)
		{
			my $url_node = $info_node->look_down(_tag => 'span', 'class' => 'l3')->look_down(_tag => 'a');
			my @mp4_nodes = $info_node->look_down(_tag => 'li')->look_down(_tag => 'a');

			foreach my $mp4_node (@mp4_nodes)
			{
				my $url = $prefix.$url_node->{href};
				push @{$res->{$url}},$mp4_node->{href};
			}
		}

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

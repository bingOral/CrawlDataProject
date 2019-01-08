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
	my $prefix = shift;

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
			my $url_node = $info_node->look_down(_tag => 'span', 'class' => 'l3');
			my $a_url_node = $url_node->look_down(_tag => 'a');

			my @mp4_nodes = $info_node->look_down(_tag => 'li');

			foreach my $mp4_node (@mp4_nodes)
			{
				my $url = $prefix.$a_url_node->{href};
				my $a_mp4_node = $mp4_node->look_down(_tag => 'a');
				push @{$res->{$url}},$a_mp4_node->{href};
			}
		}

		print $jsonparser->encode($res)."\n";
	}
	else
	{
		if($try--)
		{
			return;
		}
		
		sleep(2);
		print "Outer : Get data fail, Try again...$url\n";
		ParserTedData($url,$prefix);
	}
}

sub Parser51enData 
{
	my $url = shift;
	my $prefix = shift;

	my $try = 5;
	
	my $jsonparser = new JSON;
	my $ua = LWP::UserAgent->new;
	$ua->agent('Mozilla/5.0 '.$ua->_agent);
	$ua->proxy('https', 'http://192.168.1.20:3128'); 
	my $response = $ua->get($url);

	if($response->is_success)
	{
		my $root = HTML::TreeBuilder->new_from_content($response->decoded_content);
		my $info_node = $root->look_down(_tag => 'div', class => 'listl list3');
		my @url_nodes = $info_node->look_down(_tag => 'a', target => '_blank');

		foreach my $url_node (@url_nodes)
		{
			print $prefix.$url_node->{href}."\n";	
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
		ParserTedData($url,$prefix);
	}
}

sub ParserVoaNormalData 
{
	my $url = shift;
	my $prefix = shift;

	my $try = 5;
	
	my $jsonparser = new JSON;
	my $ua = LWP::UserAgent->new;
	$ua->agent('Mozilla/5.0 '.$ua->_agent);
	$ua->proxy('https', 'http://192.168.1.20:3128'); 
	my $response = $ua->get($url);

	if($response->is_success)
	{
		my $root = HTML::TreeBuilder->new_from_content($response->decoded_content);
		my $info_node = $root->look_down(_tag => 'div', id => 'list');
		my @url_nodes = $info_node->look_down(_tag => 'a', target => '_blank');

		foreach my $url_node (@url_nodes)
		{
			print $prefix.$url_node->{href}."\n";	
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
		ParserTedData($url,$prefix);
	}
}

sub ParserVoaSpecialData 
{
	my $url = shift;
	my $prefix = shift;

	my $try = 5;
	
	my $jsonparser = new JSON;
	my $ua = LWP::UserAgent->new;
	$ua->agent('Mozilla/5.0 '.$ua->_agent);
	$ua->proxy('https', 'http://192.168.1.20:3128'); 
	my $response = $ua->get($url);

	if($response->is_success)
	{
		my $root = HTML::TreeBuilder->new_from_content($response->decoded_content);
		my $info_node = $root->look_down(_tag => 'span', id => 'list');
		my @url_nodes = $info_node->look_down(_tag => 'a', target => '_blank');

		foreach my $url_node (@url_nodes)
		{
			print $prefix.$url_node->{href}."\n";	
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
		ParserTedData($url,$prefix);
	}
}

1;

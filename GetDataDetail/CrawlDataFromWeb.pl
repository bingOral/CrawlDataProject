#!/usr/bin/perl

use LWP::Simple;
use strict;
use POSIX;
use JSON;
use threads;
use Encode;
use Config::Tiny;
use Try::Tiny;
use LWP::UserAgent;
use HTML::TreeBuilder;
binmode STDOUT, ":utf8";

my $config = Config::Tiny->new;
$config = Config::Tiny->read('config/config.ini', 'utf8');

if(scalar(@ARGV) != 3)
{
	print "Usage : perl $0 list output.res threadnum\n";
	exit;
}

my $mp3_dest = "/data/voa/normal/mp3/";
my $wav_dest = "/data/voa/normal/wav/";

open(IN,$ARGV[0])||die("The file can't find!\n");
open(OUT,">$ARGV[1]")||die("The file can't find!\n");

while(my $row = <IN>)
{
	chomp($row);
	print $row."\n";
	getData($row);
	#die;
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

		my $mp3_node = $root->look_down(_tag => 'a', id => 'mp3');
		my $filename;
		if($mp3_node)
		{
			$filename = download($mp3_node->{'href'});
		}
		else
		{
			return;
		}
		
		my $content_node = $root->look_down(_tag => 'div', id => 'content');
		if($content_node)
		{
			my @contents = $content_node->find_by_tag_name('p');
			my $buffer;
			foreach my $content (@contents) 
			{
				my $text = $content->as_trimmed_text();
				if($text =~ /_________________________________/)
				{
					last;
				}
				$buffer .= $text." ";
			}
			
			save($url,$filename,$buffer);
			$buffer = "";
		}
	}
	else
	{
		if($try--)
		{
			return;
		}
		
		sleep(2);
		print "Get data fail, Try again...$url\n";
		getData($url);
	}
}

sub download
{
	my $url = shift;

	my $mp3_filename;
	my $wav_filename;
	if($url =~ /.*\/(.*)\.mp3/)
	{
		my $filename = $1;
		$filename =~ s/\s+//g;
		$mp3_filename = $mp3_dest.$filename.'.mp3';
		$wav_filename = $wav_dest.$filename.'.wav';
	}

	getstore($url, $mp3_filename);

	#convert
	my $c_str = "ffmpeg -v quiet -y -i $mp3_filename -f wav -ar 16000 -ac 1 $wav_filename";
	print $c_str."\n"; 
	system($c_str);
	
	return $wav_filename;
}

sub save
{
	my $jsonparser = new JSON;
	my $res;

	my $url = shift;
	my $filename = shift;
	my $info = shift;
	my $time = strftime("%Y.%m.%d %H:%M:%S",localtime());

	$res->{'url'} = $url;
	$res->{'filename'} = $filename;
	$res->{'info'} = $info;
	$res->{'time'} = $time;
	print OUT $jsonparser->encode($res)."\n";
}

1;


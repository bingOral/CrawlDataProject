#!/usr/bin/perl

use strict;
use Encode;
use LWP::Simple;
package crawl;

sub parserVoaNormalHTML
{
	my $url = shift;
	my $response = shift;
	my $filehandle = shift;

	my $res;

	my $root = HTML::TreeBuilder->new_from_content($response->decoded_content);
	my $mp3_node = $root->look_down(_tag => 'a', id => 'mp3');
	my $filename;

	if($mp3_node)
	{
		print $mp3_node->{href}."\n";
		$res->{mp3} = $mp3_node->{href};
	}
	else
	{
		return;
	}
	
	my $content_node = $root->look_down(_tag => 'div', id => 'content');
	if($content_node)
	{
		my @contents = $content_node->find_by_tag_name('p');
		my $info;
		
		foreach my $content (@contents) 
		{
			my $text = $content->as_trimmed_text();
			if($text =~ /_________________________________/)
			{
				last;
			}
			$info .= $text." ";
		}
		$res->{info} = $info;
		$info = "";
	}
	else
	{
		return;
	}

	return $res;
}

sub formater
{
	my $info = shift;

	unless(Encode::is_utf8($info))
	{
		$info = Encode::decode('iso-8859-1',$info);
	}
	return $info;
}

sub getFilenameFromUrl
{
	my $url = shift;

	my $res;
	my $mp3_filename;
	my $wav_filename;
	if($url =~ /.*\/(.*)\.mp3/)
	{
		my $filename = $1;
		$filename =~ s/\s+|\\|\/|\"|\'//g;
		$mp3_filename = $filename.'.mp3';
		$wav_filename = $filename.'.wav';

		$res->{mp3_filename} = $mp3_filename;
		$res->{wav_filename} = $wav_filename;
	}
	return $res;
}

sub download
{
	my $url = shift;
	my $mp3_dest = shift;

	my $res = getFilenameFromUrl($url);
	my $mp3_filename = $mp3_dest.$res->{mp3_filename};

	getstore($url, $mp3_filename);
	return $mp3_filename;
}

sub convert
{
	my $url = shift;
	my $mp3_filename = shift;
	my $wav_dest = shift;

	my $res = getFilenameFromUrl($url);
	my $wav_filename = $wav_dest.$res->{wav_filename};

	#convert
	my $c_str = "ffmpeg -v quiet -y -i $mp3_filename -f wav -ar 16000 -ac 1 $wav_filename";
	print $c_str."\n"; 
	system($c_str);

	return $wav_filename;
}

sub save
{
	my $url = shift;
	my $filename = shift;
	my $info = shift;
	my $filehandle = shift;

	my $jsonparser = new JSON;
	my $res;
	my $time = strftime("%Y.%m.%d %H:%M:%S",localtime());

	$res->{'url'} = $url;
	$res->{'filename'} = $filename;
	$res->{'info'} = $info;
	$res->{'time'} = $time;

	print $filehandle $jsonparser->encode($res)."\n";
}

1;

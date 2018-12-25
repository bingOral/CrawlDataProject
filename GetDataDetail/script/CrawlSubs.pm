#!/usr/bin/perl

package crawl;
use strict;
use Encode;
use POSIX;
use Data::Dumper;
use LWP::Simple;
use HTML::TreeBuilder;

sub parserVoaNormalHTML
{
	my $response = shift;

	my $res;
	my $root = HTML::TreeBuilder->new_from_content($response->decoded_content);
	my $mp3_node = $root->look_down(_tag => 'a', id => 'mp3');

	if($mp3_node)
	{
		$res->{mp3} = $mp3_node->{href};
	}
	
	my $content_node = $root->look_down(_tag => 'div', id => 'content');
	if($content_node)
	{
		my $info;
		my @contents = $content_node->find_by_tag_name('p');
		if(scalar(@contents) > 0)
		{
			foreach my $content (@contents) 
			{
				my $text = $content->as_trimmed_text();
				if($text =~ /________________________/)
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
			$res->{info} = $content_node->as_trimmed_text();		
		}
	}

	return $res;
}

sub parser51enHTML
{
	my $response = shift;

	my $res;
	my $root = HTML::TreeBuilder->new_from_content($response->decoded_content);
	my $mp3_node = $root->look_down(_tag => 'a', id => 'menu_mp3');

	if($mp3_node)
	{
		$res->{mp3} = $mp3_node->{href};
	}
	
	my $content_node = $root->look_down(_tag => 'BODY', scroll => 'auto');
	if($content_node)
	{
		my $info;
		my @contents = $content_node->find_by_tag_name('P');
		if(scalar(@contents) > 0)
		{
			foreach my $content (@contents) 
			{
				my $text = $content->as_trimmed_text();
				$info .= $text." ";
			}
			$res->{info} = $info;
			$info = "";
		}
	}
	else
	{
		$content_node = $root->look_down(_tag => 'div', class => 'article-content');	
		{
			$res->{info} = $content_node->as_trimmed_text();		
		}
	}

	return $res;
}

sub parserVoaSpecialHTML
{
	my $response = shift;
	
	my $res;
	my $root = HTML::TreeBuilder->new_from_content($response->decoded_content);

	my $mp3_node = $root->look_down(_tag => 'script', language => 'javascript');
	if($mp3_node->{_content}->[0] =~ /Player\(\"(.*.mp3)\"\);/)
	{
		$res->{mp3} = 'http://downdb.51voa.com'.$1;
	}
	
	my $content_node = $root->look_down(_tag => 'div', id => 'content');
	if($content_node)
	{
		my $info;
		my @contents = $content_node->find_by_tag_name('p');
		if(scalar(@contents) > 0)
		{
			foreach my $content (@contents) 
			{
				my $text = $content->as_trimmed_text();
				$info .= $text." ";
			}
			$res->{info} = $info;
			$info = "";
		}
		else
		{
			$res->{info} = $content_node->as_trimmed_text();		
		}
	}

	return $res;
}


sub formater
{
	my $info = shift;

	unless(Encode::is_utf8($info))
	{
		$info = Encode::decode('utf-8',$info);
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
		$filename =~ s/\s+|\\|\/|\"|\'|%//g;
		$mp3_filename = $filename.'.mp3';
		$wav_filename = $filename.'.wav';

		$res->{mp3_filename} = $mp3_filename;
		$res->{wav_filename} = $wav_filename;
	}
	return $res;
}

sub download
{
	my $mp3_url = shift;
	my $mp3_dest = shift;

	my $res = getFilenameFromUrl($mp3_url);
	my $mp3_filename = $mp3_dest.$res->{mp3_filename};

	getstore($mp3_url, $mp3_filename);
	return $mp3_filename;
}

sub convert
{
	my $mp3_url = shift;
	my $mp3_filename = shift;
	my $wav_dest = shift;

	my $res = getFilenameFromUrl($mp3_url);
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

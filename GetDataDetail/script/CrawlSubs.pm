#!/usr/bin/perl

package crawl;
use strict;
use Encode;
use POSIX;
use Data::Dumper;
use LWP::Simple;
use HTML::TreeBuilder;

sub parserTedHTML
{
	my $response = shift;
	my $origin = shift;

	my $res;
	my $root = HTML::TreeBuilder->new_from_content($response->decoded_content);
	my @info_nodes = $root->look_down(_tag => 'div', class => 'Grid Grid--with-gutter d:f@md p-b:4');

	my $info = "";
	foreach my $info_node (@info_nodes)
	{
		my $text_node = $info_node->look_down(_tag => 'div', class => 'Grid__cell flx-s:1 p-r:4');
		my $text = $text_node->as_trimmed_text();
		$info .= $text." ";
	}
	
	$res->{info} = $info;
	$res->{origin} = $origin;

	return $res;
}

sub parserVoaNormalHTML
{
	my $response = shift;

	my $res;
	my $root = HTML::TreeBuilder->new_from_content($response->decoded_content);
	my $mp3_node = $root->look_down(_tag => 'a', id => 'mp3');

	if($mp3_node)
	{
		$res->{origin} = $mp3_node->{href};
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
		$res->{origin} = $mp3_node->{href};
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
		$res->{origin} = 'http://downdb.51voa.com'.$1;
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

sub getFilenameFromTedUrl
{
	my $url = shift;

	my $res;
	my $mp4_filename;
	my $wav_filename;

	#https://download.ted.com/talks/ColinRobertson_2012.mp4?apikey=TEDDOWNLOAD
	if($url =~ /.*\/(.*)\.mp4\?apikey=TEDDOWNLOAD/)
	{
		my $filename = $1;
		$filename =~ s/\s+|\\|\/|\"|\'|%//g;
		$mp4_filename = $filename.'.mp4';
		$wav_filename = $filename.'.wav';

		$res->{mp4_filename} = $mp4_filename;
		$res->{wav_filename} = $wav_filename;
	}
	return $res;
}

sub download
{
	my $url = shift;
	my $origin_dir = shift;

	my $res = getFilenameFromTedUrl($url);
	my $local_filename = $origin_dir.$res->{mp4_filename};
	
	print "Downloading file : ".$url." now!\n";
	getstore($url, $local_filename);
	return $local_filename;
}

sub OriginToWav
{
	my $url = shift;
	my $local_filename = shift;
	my $wav_dest = shift;

	my $res = getFilenameFromTedUrl($url);
	my $wav_filename = $wav_dest.$res->{wav_filename};

	#convert
	my $c_str = "ffmpeg -v quiet -y -i $local_filename -f wav -ar 16000 -ac 1 $wav_filename";
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

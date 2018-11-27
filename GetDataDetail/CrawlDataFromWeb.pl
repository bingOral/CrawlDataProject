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

if(scalar(@ARGV) != 2)
{
	print "Usage : perl $0 input.list threadnum\n";
	exit;
}

&Main();
sub Main
{
	my $ref = init();

	open(IN,$ARGV[0])||die("The file can't find!\n");
	my $threadnum = $ARGV[1];
	my @tasks = <IN>;
	my $group = div(\@tasks,$threadnum);

	my @threads;
	foreach my $key (keys %$group)
	{
		my $random = qx(uuidgen);
		$random =~ s/[\r\n]//g;
		open(OUT,">res/res-$random.txt")||die("The file can't find!\n");

		my $thread = threads->create(\&dowork,$group->{$key},\*OUT,$ref->{mp3_dest},$ref->{wav_dest},$ref->{proxy_flag});
		push @threads,$thread;
	}

	foreach(@threads)
	{
		$_->join();
	}
}

sub div
{
	my $ref = shift;
	my $threadnum = shift;

	my $res;
    	for(my $i = 0; $i < scalar(@$ref); $i++)
   	{
   		my $flag = $i%$threadnum;
   		push @{$res->{$flag}},$ref->[$i];
    	}

    	return $res;
}

sub dowork
{
	my $param = shift;
	my $filehandle = shift;
	my $mp3_dest = shift;
	my $wav_dest = shift;
	my $proxy_flag = shift;

	foreach my $row (@$param)
	{
		chomp($row);
		print $row."\n";
		getData($row,$filehandle,$mp3_dest,$wav_dest,$proxy_flag);
	}
}

sub init
{
	my $res;
	my $config = Config::Tiny->new;
	$config = Config::Tiny->read('config/config.ini', 'utf8');

	my $mp3_dest = $config->{config}->{mp3_dir};
	my $wav_dest = $config->{config}->{wav_dir};
	my $res_dest = $config->{config}->{res_dir};
	createdir($mp3_dest);
	createdir($wav_dest);
	createdir($res_dest);

	$res->{mp3_dest} = $mp3_dest;
	$res->{wav_dest} = $wav_dest;
	$res->{proxy_flag} = $config->{config}->{proxy_flag};
	return $res;
}

sub createdir
{
	my $dir = shift;
	unless (-e $dir) 
	{
		mkdir($dir);
	}
}

sub getProxyIP
{
	my $ua = LWP::UserAgent->new;
	my $response = $ua->get('http://123.207.35.36:5010/get');
	if($response->is_success)
	{
		return 'http://'.$response->decoded_content;
	}
	else
	{
		sleep(2);
		print "Get proxy ip fail, Try again...\n";
		getProxyIP();
	}
	
}

sub getData 
{
	my $url = shift;
	my $filehandle = shift;
	my $mp3_dest = shift;
	my $wav_dest = shift;
	my $proxy_flag = shift;

	my $try = 5;
	
	my $ua = LWP::UserAgent->new;

	if($proxy_flag == 1)
	{
		$ua->proxy('http', getProxyIP());
	}

	$ua->agent('Mozilla/5.0 '.$ua->_agent);
	my $response = $ua->get($url);

	if($response->is_success)
	{
		my $root = HTML::TreeBuilder->new_from_content($response->decoded_content);

		my $mp3_node = $root->look_down(_tag => 'a', id => 'mp3');
		my $filename;
		if($mp3_node)
		{
			$filename = download($mp3_node->{'href'},$mp3_dest,$wav_dest);
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
			
			save($url,$filename,$buffer,$filehandle);
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
		#getData($url);
		getData($url,$filehandle,$mp3_dest,$wav_dest,$proxy_flag);
	}
}

sub download
{
	my $url = shift;
	my $mp3_dest = shift;
	my $wav_dest = shift;
	
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
	my $filehandle = shift;

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

	print $filehandle $jsonparser->encode($res)."\n";
}

1;


#!/usr/bin/perl

use strict;
use JSON;
use threads;
use Encode;
use Config::Tiny;
use Try::Tiny;
use LWP::UserAgent;
use HTML::TreeBuilder;
use script::CrawlSubs;
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
	
	my $mp3_dest = $config->{crawl_data_config}->{mp3_dir};
	my $wav_dest = $config->{crawl_data_config}->{wav_dir};
	my $res_dest = $config->{crawl_data_config}->{res_dir};
	createdir($mp3_dest);
	createdir($wav_dest);
	
	qx(rm -rf $res_dest);
	createdir($res_dest);

	$res->{mp3_dest} = $mp3_dest;
	$res->{wav_dest} = $wav_dest;
	$res->{proxy_flag} = $config->{crawl_data_config}->{proxy_flag};
	return $res;
}

sub createdir
{
	my $dir = shift;
	unless(-e $dir) 
	{
		qx(mkdir -p $dir);
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
	$ua->proxy('http', getProxyIP()) if($proxy_flag == 1);
	$ua->agent('Mozilla/5.0 '.$ua->_agent);
	my $response = $ua->get($url);

	if($response->is_success)
	{
		my $res = crawl::parserVoaNormalHTML($url,$response,$filehandle);
		if($res)
		{
			my $mp3_filename = crawl::download($res->{mp3},$mp3_dest);
			my $wav_filename = crawl::convert($res->{mp3},$mp3_filename,$wav_dest);
			crawl::save($url,$wav_filename,$res->{info},$filehandle);
		}
	}
	else
	{
		return if($try--);

		sleep(2);
		print "Get data fail, Try again...$url\n";
		getData($url,$filehandle,$mp3_dest,$wav_dest,$proxy_flag);
	}
}

1;


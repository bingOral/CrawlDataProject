#!/usr/bin/perl

use strict;
use JSON;
use threads;
use Encode;
use Try::Tiny;
use Data::Dumper;
use Config::Tiny;
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

		my $thread = threads->create(\&dowork,$group->{$key},\*OUT,$ref->{origin_dir},$ref->{wav_dest},$ref->{proxy_flag});
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

sub init
{
	my $res;
	my $config = Config::Tiny->new;
	$config = Config::Tiny->read('config/config.ini', 'utf8');
	
	my $origin_dir = $config->{crawl_data_config}->{origin_dir};
	my $wav_dest = $config->{crawl_data_config}->{wav_dir};
	my $res_dest = $config->{crawl_data_config}->{res_dir};
	createdir($origin_dir);
	createdir($wav_dest);
	
	qx(rm -rf $res_dest);
	createdir($res_dest);

	$res->{origin_dir} = $origin_dir;
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

sub dowork
{
	my $param = shift;
	my $filehandle = shift;
	my $origin_dir = shift;
	my $wav_dest = shift;
	my $proxy_flag = shift;
	
	my $jsonparser = new JSON;
	foreach my $row (@$param)
	{
		#modify
		chomp($row);
		my $json = $jsonparser->decode($row);
		foreach my $url (keys %$json)
		{	
			print $url.'/transcript'."\n";
			my $origin = $json->{$url}->[1];
			getData($url.'/transcript',$filehandle,$origin_dir,$wav_dest,$proxy_flag,$origin);
			die;
		}
	}
}

sub getData 
{
	my $url = shift;
	my $filehandle = shift;
	my $origin_dir = shift;
	my $wav_dest = shift;
	my $proxy_flag = shift;
	my $origin = shift;

	my $try = 5;

	my $ua = LWP::UserAgent->new;
	$ua->proxy('https', 'http://192.168.1.20:3128') if($proxy_flag == 1);
	$ua->agent('Mozilla/5.0 '.$ua->_agent);
	my $response = $ua->get($url);

	if($response->is_success)
	{
		my $res = crawl::parserTedHTML($response,$origin);
		my $local_filename = crawl::download($res->{origin},$origin_dir);
		my $wav_filename = crawl::OriginToWav($res->{origin},$local_filename,$wav_dest);
		crawl::save($url,$wav_filename,$res->{info},$filehandle);
	}
	else
	{
		return if($try--);
		sleep(2);
		print "Get data fail, Try again...$url\n";
		getData($url,$filehandle,$origin_dir,$wav_dest,$proxy_flag,$origin);
	}
}

1;


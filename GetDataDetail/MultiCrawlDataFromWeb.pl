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
	$res->{proxy_pool} = $config->{crawl_data_config}->{proxy_pool};
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
	foreach my $url (@$param)
	{
		chomp($url);
		getData($url,$filehandle,$origin_dir,$wav_dest,$proxy_flag);
		#die;
=pod
		#ted-data
		my $json = $jsonparser->decode($row);
		foreach my $url (keys %$json)
		{	
			print $url.'/transcript'."\n";
			my $origin = $json->{$url}->[1];
			#https://download.ted.com/talks/DavidGallo_DeepOcean_2012E-600k.mp4
			getData($url.'/transcript',$filehandle,$origin_dir,$wav_dest,$proxy_flag,$origin);
			#die;
		}
=cut 	
		
	}
}

sub getData 
{
	my $url = shift;
	my $filehandle = shift;
	my $origin_dir = shift;
	my $wav_dest = shift;
	my $proxy_flag = shift;
	
	#ted
	#my $origin = shift;

	my $try = 5;

	my $ua = LWP::UserAgent->new;
	$ua->proxy('https', 'http://192.168.1.20:3128') if($proxy_flag == 1);
	$ua->agent('Mozilla/5.0 '.$ua->_agent);
	my $response = $ua->get($url);

	if($response->is_success)
	{
		#ted
		#my $res = crawl::parserTedHTML($response,$origin);
		#my $local_filename = crawl::downloadFormTed($res->{origin},$origin_dir);
		#my $wav_filename = crawl::OriginToWav($res->{origin},$local_filename,$wav_dest);
		#crawl::save($url,$wav_filename,$res->{info},$filehandle);
	
		#51en
		#my $res = crawl::parser51enHTML($response);
		#my $local_filename = crawl::download($res->{origin},$origin_dir);
		#my $wav_filename = crawl::OriginToWav($res->{origin},$local_filename,$wav_dest);
		#crawl::save($url,$wav_filename,$res->{info},$filehandle);
		
		#voa-special
		#my $res = crawl::parserVoaSpecialHTML($response);
		#my $local_filename = crawl::download($res->{origin},$origin_dir);
		#my $wav_filename = crawl::OriginToWav($res->{origin},$local_filename,$wav_dest);
		#crawl::save($url,$wav_filename,$res->{info},$filehandle);

		#voa-normal
		my $res = crawl::parserVoaNormalHTML($response);
		my $local_filename = crawl::download($res->{origin},$origin_dir);
		my $wav_filename = crawl::OriginToWav($res->{origin},$local_filename,$wav_dest);
		crawl::save($url,$wav_filename,$res->{info},$filehandle);

	}
	else
	{
		return if($try--);
		sleep(2);
		print "Get data fail, Try again...$url\n";
		getData($url,$filehandle,$origin_dir,$wav_dest,$proxy_flag);
	}
}

1;


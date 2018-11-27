#!/usr/bin/perl

use strict;
use JSON;
use threads;
use Encode;

my $jsonparser = new JSON;
open(IN,$ARGV[0])||die("The file can't find!\n");

&Main();

sub Main
{
	my $threadnum = $ARGV[1];
	my @tasks = <IN>;
	my $group = div(\@tasks,$threadnum);

	my @threads;
	foreach my $key (keys %$group)
	{
		my $thread = threads->create(\&dowork,$group->{$key});
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
	
	foreach my $row (@$param)
	{
		chomp($row);
		my $wav_filename = $row;
		$wav_filename =~ s/mp3$/wav/;
		$wav_filename =~ s/normal\/mp3/normal\/wav/;
			
		my $c_str = "ffmpeg -v quiet -y -i $row -f wav -ar 16000 -ac 1 $wav_filename";
		print $c_str."\n"; 
		system($c_str);
	}
}

1;


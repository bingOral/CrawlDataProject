#!/usr/bin/perl

use strict;
use Encode;
use JSON;
use Try::Tiny;
use Data::Dumper;
use LWP::UserAgent;
use HTML::TreeBuilder;
use script::HtmlSubs;

my $ref = {
	'news' => {
		'/news/list_1_' => 313,
		'/news/cnn/list_4_' => 31,
		'/news/npr/list_5_' => 144,
		'/news/cri/list_10_' => 43,
		'/news/ap/list_2_' => 27,
		'/news/economist/list_19_' => 43
	},
	'nce' => {
		'/nce/rp/list_24_' => 6,
		'/nce/ga/list_29_' => 6
	},
	'ielts' => {
		'/cambridge/list_48_' => 1,
		'/cambridge/list_47_' => 1,
		'/cambridge/list_46_' => 1,
		'/cambridge/list_45_' => 1,
		'/cambridge/list_44_' => 1,
		'/cambridge/list_43_' => 1,
		'/cambridge/list_42_' => 1,
		'/cambridge/list_41_' => 1
	},
	'tour' => {
		'/profession/tourism/list_13_' => 8,
		'/profession/tourism/list_15_' => 2,
		'/profession/tourism/list_18_' => 1,
		'/profession/tourism/list_49_' => 2,
		'/profession/tourism/list_11_' => 12
	},
	'51voa' => {
		'/VOA_Standard_' => 36,
		'/Technology_Report_' => 21,
		'/This_is_America_' => 18,
		'/Science_in_the_News_' => '17',
		'/Health_Report_' => 19,
		'/Education_Report_' => 21,
		'/Economics_Report_' => 16,
		'/American_Mosaic_' => 19,
		'/In_the_News_' => 20,
		'/American_Stories_' => 8,
		'/Words_And_Their_Stories_' => 14,
		'/Trending_Today_' => 11,
		'/as_it_is_' => 91,
		'/Everyday_Grammar_' => 4,
		'/ask_a_teacher_' => 1,
		'/The_Making_of_a_Nation_' => 12,
		'/National_Parks_' => 1,
		'/Americas_Presidents_' => 1,
		'/Agriculture_Report_' => 12,
		'/Explorations_' => 10,
		'/The_Making_of_a_Nation_' => 12,
		'/People_in_America_' => 10,
		'/Learn_A_Word_' => 65,
		'/Words_And_Idioms_' => 18,
		'/English_in_a_Minute_' => 1,
		'/How_American_English_' => 2,
		'/Business_Etiquette_' => 6,
		'/Words_And_Idioms_' => 18,
		'/American_English_Mosaic_' => 3,
		'/Popular_American_' => 8,
		'/Sports_English_' => 2,
		'/Go_English_' => 2,
		'/Word_Master_' => 12,
		'/American_Cafe_' => 2,
		'/Intermediate_American_English_' => 2,
		'/Americas_Presidents_' => 1
	},
	'51voa_archiver' => {
		'/VOA_Standard_' => 602
	},
	'21voa' => {
		'/Technology_Report_' => 14,
		'/This_is_America_' => 11,
		'/Science_in_the_News_' => 10,
		'/Health_Report_' => 12,
		'/Education_Report_' => 13,
		'/Economics_Report_' => 8,
		'/American_Mosaic_' => 12,
		'/In_the_News_' => 12,
		'/American_Stories_' => 5,
		'/Words_And_Their_Stories_' => 9,
		'/as_it_is_' => 77,
		'/Trending_Today_' => 9,
		'/Everyday_Grammar_' => 3,
		'/National_Parks_' => 1,
		'/Americas_Presidents_' => 1,
		'/The_Making_of_a_Nation_' => 6,
		'/People_in_America_' => 4,
		'/Agriculture_Report_' => 7,
		'/Explorations_' => 5	
	},
	'21voa_archiver' => {
		'/VOA_Special_English_2008/' => {
			'index_Development_Report_' => 1,
			'index_This_is_America_' => 1,
			'index_Agriculture_Report_' => 1,
			'index_Science_in_the_News_' => 1,
			'index_Health_Report_' => 1,
			'index_Explorations_' => 1,
			'index_Education_Report_' => 1,
			'index_The_Making_of_a_Nation_' => 1,
			'index_Economics_Report_' => 1,
			'index_American_Mosaic_' => 1,
			'index_In_the_News_' => 1,
			'index_American_Stories_' => 1,
			'index_Words_And_Their_Stories_' => 1,
			'index_People_in_America_' => 1
		},
		'/VOA_Special_English_2007/' => {
			'index_Development_Report_' => 1,
			'index_This_is_America_' => 1,
			'index_Agriculture_Report_' => 1,
			'index_Science_in_the_News_' => 1,
			'index_Health_Report_' => 1,
			'index_Explorations_' => 1,
			'index_Education_Report_' => 1,
			'index_The_Making_of_a_Nation_' => 1,
			'index_Economics_Report_' => 1,
			'index_American_Mosaic_' => 1,
			'index_In_the_News_' => 1,
			'index_American_Stories_' => 1,
			'index_Words_And_Their_Stories_' => 1,
			'index_People_in_America_' => 1
		},
		'/VOA_Special_English_2006/' => {
			'index_Development_Report_' => 1,
			'index_This_is_America_' => 1,
			'index_Agriculture_Report_' => 1,
			'index_Science_in_the_News_' => 1,
			'index_Health_Report_' => 1,
			'index_Explorations_' => 1,
			'index_Education_Report_' => 1,
			'index_The_Making_of_a_Nation_' => 1,
			'index_Economics_Report_' => 1,
			'index_American_Mosaic_' => 1,
			'index_In_the_News_' => 1,
			'index_American_Stories_' => 1,
			'index_Words_And_Their_Stories_' => 1,
			'index_People_in_America_' => 1
		},
		'/VOA_Special_English_2005/' => {
			'index_Development_Report_' => 1,
			'index_This_is_America_' => 1,
			'index_Agriculture_Report_' => 1,
			'index_Science_in_the_News_' => 1,
			'index_Health_Report_' => 1,
			'index_Explorations_' => 1,
			'index_Education_Report_' => 1,
			'index_The_Making_of_a_Nation_' => 1,
			'index_Economics_Report_' => 1,
			'index_American_Mosaic_' => 1,
			'index_In_the_News_' => 1,
			'index_American_Stories_' => 1,
			'index_Words_And_Their_Stories_' => 1,
			'index_People_in_America_' => 1
		},	
		'/VOA_Special_English_2004/' => {
			'index_Development_Report_' => 1,
			'index_This_is_America_' => 1,
			'index_Agriculture_Report_' => 1,
			'index_Science_in_the_News_' => 1,
			'index_Health_Report_' => 1,
			'index_Explorations_' => 1,
			'index_Education_Report_' => 1,
			'index_The_Making_of_a_Nation_' => 1,
			'index_Economics_Report_' => 1,
			'index_American_Mosaic_' => 1,
			'index_In_the_News_' => 1,
			'index_American_Stories_' => 1,
			'index_Words_And_Their_Stories_' => 1,
			'index_People_in_America_' => 1
		},
		'/VOA_Special_English_2003/' => {
			'index_Development_Report_' => 1,
			'index_This_is_America_' => 1,
			'index_Agriculture_Report_' => 1,
			'index_Science_in_the_News_' => 1,
			'index_Health_Report_' => 1,
			'index_Explorations_' => 1,
			'index_Education_Report_' => 1,
			'index_The_Making_of_a_Nation_' => 1,
			'index_Economics_Report_' => 1,
			'index_American_Mosaic_' => 1,
			'index_In_the_News_' => 1,
			'index_American_Stories_' => 1,
			'index_Words_And_Their_Stories_' => 1,
			'index_People_in_America_' => 1
		},
		'/VOA_Special_English_2002/' => {
			'index_Development_Report_' => 1,
			'index_This_is_America_' => 1,
			'index_Agriculture_Report_' => 1,
			'index_Science_in_the_News_' => 1,
			'index_Health_Report_' => 1,
			'index_Explorations_' => 1,
			'index_Education_Report_' => 1,
			'index_Science_Report_' => 1,
			'index_The_Making_of_a_Nation_' => 1,
			'index_Environment_Report_' => 1,
			'index_American_Mosaic_' => 1,
			'index_In_the_News_' => 1,
			'index_American_Stories_' => 1,
			'index_Words_And_Their_Stories_' => 1,
			'index_People_in_America_' => 1
		},
		'/VOA_Special_English_2001/' => {
			'index_Development_Report_' => 1,
			'index_This_is_America_' => 1,
			'index_Agriculture_Report_' => 1,
			'index_Science_in_the_News_' => 1,
			'index_Explorations_' => 1,
			'index_Science_Report_' => 1,
			'index_The_Making_of_a_Nation_' => 1,
			'index_Environment_Report_' => 1,
			'index_American_Mosaic_' => 1,
			'index_In_the_News_' => 1,
			'index_American_Stories_' => 1,
			'index_Words_And_Their_Stories_' => 1,
			'index_People_in_America_' => 1
		}
	},
	'ted' => {
		'/talks/quick-list?page=' => 95
	}
};

my $prefix = 'http://www.21voa.com';

#&scan($ref->{news});
#&scan($ref->{nce});
#&scan($ref->{ielts});
#&scan($ref->{tour});
#&scan($ref->{'51voa'});
#&scan($ref->{'21voa'});
#&scan($ref->{'51voa_archiver'});
&scan($ref->{'21voa_archiver'});

sub scan
{
	my $res = shift;

=pod
	foreach my $key (%$res)
	{
		my $value = $res->{$key};
		for(my $i = 1; $i <= $value; $i++)
		{
			my $url = $prefix.$key.$i.'.html';
			print $url."\n";
			#HtmlTools::ParserVoaSpecialData($url,$prefix);
		}
	}
=cut 
	
	foreach my $key (keys %$res)
	{
		my $archiver = $res->{$key};
		foreach my $item (keys %$archiver)
		{
			my $num = $archiver->{$item};
			for(my $i = 1; $i <= $num; $i++)
			{
				my $url = $prefix.$key.$item.$i.'.html';
				#print $url."\n";
				HtmlTools::ParserVoaSpecialData($url,$prefix.$key);
				#die;
			}
		}
	}		
}

1;


#!/usr/bin/perl -w
#
# imdbdataget.pl version 0.4.3
#
# (C)  2008-2011  tux99-imdbdataget (at) URIDIUM (dot) ORG
#
#  This program is free software: you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  version 2 as published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Modified for use with Roksbox by RojSpencer (@) github (dot) com

# program to use for html fetching, either wget or curl
# default is wget, to use curl comment out the wget line
# and uncomment the curl line
$get='/usr/bin/wget -q --tries=5 --wait=1 --retry-connrefused -U "Mozilla/5.0 (compatible;)" -O -';
#$get='/usr/bin/curl -s --retry 5 --retry-delay 1 -A "Mozilla/5.0 (compatible;)"';

$imagedir = '/var/www/html/media/video/images';

$baseurl="http://www.imdb.com/title";

if (! $ARGV[0])
  { print STDERR "ERROR - Missing IMDBid\nUsage: imdbdataget.pl [IMDBid] [xml]\n"; exit 1; }

$IMDBid=$ARGV[0];

if (! ($IMDBid=~/^tt[\d]{1,7}$/))
  { print STDERR "ERROR - IMDBid format incorrect\nIMDBid format needs to be: ttn - ttnnnnnnn ('tt' followed by 1 to 7 digits)\n"; exit 1; }

$file = "";
if ($ARGV[1]) {
	$file = $ARGV[1];
}

# Retrieve raw html data

$IMDBhtml = `$get $baseurl/$IMDBid/combined`;
$IMDBlplot = `$get $baseurl/$IMDBid/plotsummary`;

# Initialize data variables as empty strings

$lplot="";
$title="";
$year="";
$rating="";
$top250="";
$runtime="";
$plot="";
$mpaa="";
$company="";
$countries="";
$directors="";
$genres="";
$actors="";
$season="";
$episode="";
$series="";
$image="";
$imageurl="";

# Extract data from html

if ($IMDBlplot=~/<p class="plotpar">\n(.*?)\n.*?<\/p>/s)
  { $lplot=$1; html2utf8($lplot); }

if ($IMDBhtml=~/<div id="tn15crumbs">\n<a href="\/">IMDb<\/a> &gt;\n<b>([^<]+) \((\d\d\d\d)[\/]?[IVX]*\)[^<]*<\/b>/s)
  { $title=$1; $year=$2; html2utf8($title); }

if ($IMDBhtml=~/<div class="starbar-meta">.*?<b>([1]?[0-9]\.[0-9])/s)
  { $rating=$1; }

if ($IMDBhtml=~/<div class="starbar-special">.*?<a href="\/chart\/top\?tt[\d]+">Top 250: #([\d]+)<\/a>/s)
  { $top250=$1; }

if ($IMDBhtml=~/<h5>Runtime:<\/h5>.*?([0-9]+)( )*min/s)
  { $runtime=$1; }

if ($IMDBhtml=~/<h5>Plot:<\/h5>\n<div class="info-content">\n(.*?)( )*(\|)*( )*</s)
  { $plot=$1; $plot=~s/\n/ /g; html2utf8($plot); }

if ($plot && !($lplot))
  { $lplot=$plot; }

if ($IMDBhtml=~/MPAA<\/a>:<\/h5><div class="info-content">Rated ([\S]+)/s)
  { $mpaa=$1; }
elsif ($IMDBhtml=~/<a href="\/search\/title\?certificates=us:.*?">USA:([^<]+)<\/a>/s)
  { $mpaa=$1; }

if ($IMDBhtml=~/<h5>Company:<\/h5><div class="info-content"><a href="\/company\/co[\d]+\/">([^>]*)<\/a>/s)
  { $company=$1; html2utf8($company); }

if ($IMDBhtml=~/<img border="0" id="primary-poster" alt=".*" src="(.*\.jpg)" \/>/s) 
  { $image=$1 }

$countries=join(' / ',$IMDBhtml=~/<a href="\/country\/[\w]+">([^>]*)<\/a>/g);
html2utf8($countries);

$directors=join(', ',$IMDBhtml=~/directorlist\/position-[\d]+\/images\/b\.gif\?link=name\/nm[\d]+\/';">([^>]*)<.*$/mg);
html2utf8($directors);

$genres=join(', ',$IMDBhtml=~/<a href="\/Sections\/Genres\/[\w-]+\/">([^>]*)<\/a>/g);
html2utf8($genres);

$actors=join(', ',$IMDBhtml=~/\/castlist\/position-[\d]+\/images\/b\.gif\?link=\/name\/nm[\d]+\/';">([^>]*)</g);
html2utf8($actors);
# only need the 1st 4 actors, drop the rest
$actors =~ s/(.*?,.*?,.*?,.*?),.*/$1/;

# Season & Episode info

if ($IMDBhtml=~/\(Season (\d+), Episode (\d+)\)/s)
{ 
	$season=sprintf("%02d",$1);
	$episode=sprintf("%02d",$2);
}

# if season info, grab the series name from the title inbetween the quotes
if ( $season ne "") {
	if ($title=~/\"(.*)\"/s) {
		$series = $1;
	}
}

if ( $series ne "") {
	$genres = "[TV/$series/$season]";
	$title=~s/^(".*")/$1 S${season}E${episode}/
}

if ( $image ne "" ) {
	$imagefile = "${imagedir}/" . `basename "$file"`;
	$imagefile =~ s/\n/.jpg/;
	`/usr/bin/wget -q --tries=5 --wait=1 --retry-connrefused -U "Mozilla/5.0 (compatible;)" -O "$imagefile" "$image"`;
	$imageurl = $imagefile;
	$imageurl =~ s/.*(images\/.*)/$1/;
}

# Output data to STDOUT as xml or text in UTF-8

binmode (STDOUT, ':encoding(utf8)');

#print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<movie>\n";
print "<movie>\n";
print "\t<origtitle>$title</origtitle>\n";
print "\t<year>$year</year>\n";
print "\t<director>$directors</director>\n";
print "\t<mpaa>$mpaa</mpaa>\n";
print "\t<genre>$genres</genre>\n";
print "\t<actors>$actors</actors>\n";
print "\t<description>$plot</description>\n";
print "\t<length>$runtime</length>\n";
print "\t<videocodec>mp4</videocodec>\n";
print "\t<path>$file</path>\n";
print "\t<poster>$imageurl</poster>\n";
print "</movie>\n";

# subroutine that converts from numerical HTML encoded utf-8 character (&#xNNN;)
# to plain utf-8 character, except for '<' to '&lt;' and '&' to '&amp;'

sub html2utf8 {
  return $_[0]=~s/&#x([0-9A-Fa-f]+);/if($1 eq '3C'){'&lt;'} elsif($1 eq '26'){'&amp;'} else{chr(hex $1)}/ge;
}


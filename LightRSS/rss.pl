#!/usr/bin/perl

use strict;
use utf8;
use XML::RSS;
use CGI;
use DBD::mysql;

my $url="http://web.local/cgi-bin/rss.pl";
my $cgi=new CGI;
my $id = $cgi->param("id");

#Подотовка вывода
my $rss = XML::RSS->new( version => '1.0' );

chomp( my $channel_title = "Новостная лента организации" );
chomp( my $channel_link  = "web.localhost" );

$rss->channel(
	title        => $channel_title,
	link         => $channel_link,
    );

# Доступ к базе данных
my $dsn = 'dbi:mysql:rss:localhost:3306';
my $user = 'rss';
my $pass = 'ssr';
 
# Соединение с базой данных
my $dbh = DBI->connect($dsn, $user, $pass)
 or die "Can’t connect to the DB: $DBI::errstr\n";

#Генерация RSS
if ( $id=="" )
{
    my $sth = $dbh->prepare("SELECT id,Title,Description FROM feeds ORDER BY id DESC");
    $sth->execute;

    while(my ($id, $Title,$Description) = $sth->fetchrow_array()) {
        utf8::decode($Description);
	utf8::decode($Title);
	my $idt:=$id+10800;
	my $date=gmtime("$idt");
	$rss->add_item(
		title       => "$date $Title",
		link        => "$url\?id=$id",
		description => "$Description",
	my => {
    	    rating    => "A+",
	    category  => "X11/IRC",
	     },
    );
    }
    print CGI->header('text/xml; charset=UTF-8');
    print $rss->as_string;
}
else
{
#Генерация страницы с полным текстом новости
    my $sth = $dbh->prepare("SELECT id,Title,Body FROM feeds WHERE id=$id LIMIT 1");
    $sth->execute;
    my ($id, $Title,$Body) = $sth->fetchrow_array();
    print CGI->header('text/html; charset=UTF-8');
    print "<font size=+3>$Title<br></font>";
    print "<PRE>$Body</PRE>";
    print $cgi->end_html . "\n";
}


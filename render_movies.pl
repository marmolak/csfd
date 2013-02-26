#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;
use Encode;

use DBI;

sub render_movie {
	my ($movie, $d, $is_new) = @_;

	return unless defined $movie;

	my $movie_rating = "00";
	$movie_rating = $movie->{rating_average} if defined $movie->{rating_average};
	my $movie_name = Encode::encode ("utf8", $movie->{name}) if defined $movie->{name};

	my $movie_genre = $movie->{genre};

	my $movie_id = $movie->{id} if defined $movie->{id};

	print "<h3>NEW!</h3>\n" if $is_new;
	print "<p><strong>$movie_name - $movie_rating\% - ($d)</strong><br>\n";
	print "$movie_genre<br>\n";
	print "<a href=\"http://www.csfd.cz/film/$movie_id\">$movie_name</a></p>\n";
}

sub main {
	my $db_conn = DBI->connect(
		"dbi:SQLite:dbname=movies.db",
		"",
		"",
		{ RaiseError => 1 },
	) or die $DBI::errstr;

	my $query = "SELECT id, bname, dname, name, rating_average, genre, new FROM movies";
	my $prepared = $db_conn->prepare ($query);
	$prepared->execute ();

	print "<!DOCTYPE HTML>\n<html>\n<head><meta charset=\"utf-8\" /><title>Movies</title></head>\n<body>\n";
	while ( my @row =  $prepared->fetchrow_array () ) {
		my %movie;
		my $d = "";
		my $dir = "";
		my $is_new = 0;
		($movie{id}, $d, $dir, $movie{name}, $movie{rating_average}, $movie{genre}, $is_new) = @row;

		render_movie (\%movie, $d, $is_new);
	}
	print "</body>\n</html>\n";
}


exit (main ());

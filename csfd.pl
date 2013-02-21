#!/usr/bin/perl

use strict;
use warnings;
use Encode;
use Data::Dumper;

use CSFDAApi qw/get_search/;

sub g_search_csfd {
	my ($search_string, $out) = @_;

	$search_string = uri_escape ($search_string);

	my $cx = '';
	my $api_key = '';

	my $url = "https://www.googleapis.com/customsearch/v1?" .
		"key=$api_key&" .
		"cx=$cx&" .
		"q=$search_string";

	my $ua = LWP::UserAgent->new ();
	$ua->default_header ("HTTP_REFERER" => "lala.net");

	$SIG{ALRM} = sub { die "ALARM" };
	my $body = "";
	eval {
		local $@;
		alarm (2);
		$body = $ua->get ($url);
		alarm (0)
	} or do {
		return 0 if ( $@ =~ /ALARM/ );
		die $@;
	};

	my $json = from_json ($body->decoded_content);

	die "google error: $json->{error}->{message}" if ( defined $json->{error} );

	return 0 if ( not defined $json->{items} );

	my $items = \@{$json->{items}};


	my $link = $items->[0]->{link};
	my $snippet = $items->[0]->{snippet};
	my $title = $items->[0]->{title};

	@$out = ($title, $link, $snippet);

	return 1;
}


sub timeout_wrap {
	my ($f, $timeout) = @_;

	$timeout = 20 unless defined $timeout;

	my $ret = undef;
	eval {
		local $SIG{ALRM} = sub { die "alarm\n" };

		eval {
			alarm ($timeout);
			$ret = &$f();
			alarm (0);
			return $ret; # for eval
		} or do {
			alarm (0);
			my $err = $@;
			return unless $err;
			die $err;
		};
		alarm (0);
		return 1; # for eval
	} or do {
		alarm (0);
		my $err = $@;
		return unless $err;

		if ( $err =~ /^alarm/ ) {
			die "alarm\n";
		} else {
			die $err;
		}
	};

	return $ret;
}

sub better_name {
	my ($d) = @_;

	# get rid of mess from directory name
	#$d =~ s/\s-\s/ /ig;
	$d =~ s/1080p//ig;
	$d =~ s/\(720p\)//ig;
	$d =~ s/720p//ig;
	$d =~ s/BRrip//ig;
	$d =~ s/x264//ig;
	$d =~ s/[^a-zA-Z]CZ//ig;
	$d =~ s/[^a-zA-Z]EN//ig;
	$d =~ s/subtCZ//g;
	$d =~ s/sub//ig;
	$d =~ s/5.1//g;
	$d =~ s/\s+/ /g;
	$d =~ s/\s$//g;

	(my $year = $d) =~ s/.*\((\d{4})\)$/$1/;
	$d = Encode::encode ("utf8", $d);

	return ($d, $year);
}

sub cruise_dir {
	my ($dh) = @_;

	my %movie = ();

	while ( readdir ($dh) ) {
		my $td = $_;
		next if ( ($td eq '.') or ($td eq '..') );

		my ($d, $year) = better_name ($td);
	
		# skip
		next if ( defined $movie{$d} );
		$movie{$d} = 1;

		my @result = ();
		
		# closure for timeout wrapper
		my $get_search = sub {
			return get_search ($d);
		};
		my $ret = undef;
		eval {
			$ret = timeout_wrap ($get_search, 10);
			return 1; # for eval
		} or do {
			my $err = $@;
			return unless $err;
			undef $ret;
		};
		next if ( not defined $ret );

		my $movie = $ret->{films}[0];
		next if ( not defined $movie );

		my $movie_rating = "00";
		$movie_rating = $movie->{rating_average} if defined $movie->{rating_average};
		my $movie_name = Encode::encode ("utf8", $movie->{name});

		my $movie_genre = "";
		if (defined $movie->{genre}) {
			$movie_genre = join (' ', @{$movie->{genre}});

			$movie_genre = Encode::encode ("utf8", $movie_genre);
		}
		my $movie_id = $movie->{id};

		print "<p><strong>$movie_name - $movie_rating\% - ($d)</strong><br>\n";
		print "$movie_genre<br>\n";
		print "<a href=\"http://www.csfd.cz/film/$movie_id\">$movie_name</a></p>\n";
	}
}

sub main {
	print "<!DOCTYPE HTML>\n<html>\n<head><meta charset=\"utf-8\" /></head>\n<body>\n";

	my $dh = undef;

	my @dirs = qw(/data/public/MKV/ /data/public/DVD/);
	foreach my $dir (@dirs) {
		print "<h1>$dir</h1>\n";
		my $opendir = sub {
			opendir (my $dh, $dir) or die "opendir ($!)\n";
			return $dh;
		};

		#my $dh = 0;
		eval {
			$dh = timeout_wrap ($opendir, 2);
			cruise_dir ($dh);
			closedir ($dh);
			return 1; # for eval
		} or do {
			my $err = $@;
			return unless $err;

			if ( $err =~ m/^opendir/ ) {
				print "i can't open $dir directory ($err)\n";
			} else {
				print "$err\n";
			}
		};
	}
	print "</body>\n</html>\n";
}

eval {
	local $@;
	my $ret = main ();
	exit ($ret);
} or do {
	my $err = $@;
	return unless $err;

	die $err;
}

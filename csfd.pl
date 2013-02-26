#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Encode;
use Data::Dumper;

use Linux::Inotify2;
use AnyEvent;
use File::Basename;
use DBI;

use CSFDAApi;

my $poller = undef;
my %W;

sub better_name {
	my ($d) = @_;

	chomp $d;
	# get rid of mess from directory name
	
	$d =~ s/\[(\d{4})\]/ ($1)/g; # sometimes, year is in [] ... csfd preffer year in ().
	$d =~ s/\[(:?^\d{4})\]//g; # remove all [Xvid] atd.
	$d =~ s/\[.*\]//g; # sometimes, year is in []
	$d =~ s/(?:FULL)?CAM//g;
	$d =~ s/\(?(?:1080|720)p\)?//ig;
	$d =~ s/(?:BRrip|DVD(?:rip|scr)|HDTV|XviD|2HD|AAC|AC3)//ig;
	$d =~ s/(?:x|h)264//ig;
	$d =~ s/[^a-zA-Z](?:CZ|EN)//ig;
	$d =~ s/sub(:?tCZ)?//g;
	$d =~ s/5\.1//g;
	$d =~ s/\-.*$//g; # -aXXo etc...

	$d =~ s/(?:\.|\-)/ /g;
	$d =~ s/\s+/ /g;

	$d = Encode::encode ("utf8", $d);

	return $d;
}

sub is_new_movie {
	my ($ctime) = @_;

	my $now = time ();

	my $day = 3600 * 24;
	my $week = $day * 7;

	return (($now - $ctime) < $week);
}

sub get_search {
	my ($d) = @_;

	# closure for timeout wrapper
	my $get_search = sub {
		return CSFDAApi::get_search ($d);
	};

	my $ret = undef;
	eval {
		$ret = Wraps::timeout ($get_search, 10);
		return 1; # for eval
	} or do {
		my $err = $@;
		return unless $err;
		$ret = undef;
	};

	return $ret;
}

sub prepare_add_query {
	my ($db_conn) = @_;

	my $query = "INSERT INTO movies (id, bname, dname, name, rating_average, genre, new) VALUES (?, ?, ?, ?, ?, ?, ?)";
	my $prepared = $db_conn->prepare ($query);

	return $prepared;
}

sub add_movie {
	my ($prepared, $dir, $d, $movie, $is_new) = @_;

	my $movie_rating = "00";
	$movie_rating = $movie->{rating_average} if defined $movie->{rating_average};
	my $movie_name = "";
	$movie_name = Encode::encode ("utf8", $movie->{name}) if defined $movie->{name};

	my $movie_genre = "";
	if (defined $movie->{genre}) {
		$movie_genre = join (' ', @{$movie->{genre}});
		$movie_genre = Encode::encode ("utf8", $movie_genre);
	}
	my $movie_id = 00;
	$movie_id = $movie->{id} if defined $movie->{id};

	$prepared->execute ($movie_id, $d, $dir, $movie_name, $movie_rating, $movie_genre, $is_new) or die "i can't add movie";
	$prepared->finish ();
}

sub cruise_dir {
	my ($db_conn, $dh) = @_;

	my %movie = ();

	chdir ($dh);

	my @dirs = sort { $a cmp $b } grep { !/^\./ && -d $_ } readdir ($dh);

	my $prepared = prepare_add_query ($db_conn);

	foreach my $dir (@dirs) {

		my $d = better_name ($dir);

		# skip
		next if ( defined $movie{$d} );
		$movie{$d} = 1;

		my $ret = get_search ($d);
		next unless defined $ret;
		my $movie = $ret->{films}[0];
		next unless defined $movie;

		my $ctime = (stat ($dir))[10];
		my $is_new = is_new_movie ($ctime);

		add_movie ($prepared, $dir, $d, $movie, $is_new);
	}
}

sub flush_movies_table ($) {
	my ($db_conn) = @_;
	my $query = "DELETE FROM movies";
	my $prepared = $db_conn->prepare ($query);
	$prepared->execute () or die "i can't delete table!";
}

sub pool {
	my ($db_conn) = @_;


	my @dirs = qw(/data/public/MKV/ /data/public/DVD/);
	foreach my $dir (@dirs) {
		# skip if $dir is not directory
		my $opendir = sub {
			opendir (my $dh, $dir) or die "opendir: $!\n";
			return $dh;
		};

		eval {
			my $dh = Wraps::timeout ($opendir, 2);
			cruise_dir ($db_conn, $dh);
			closedir ($dh);
			return 1; # for eval
		} or do {
			my $err = $@;
			return unless $err;

			if ( $err =~ m/^opendir/ ) {
				chomp $err;
				print STDERR "i can't open $dir directory ($err)\n";
			} else {
				print STDERR "$err\n";
			}
		};
	}
}


sub main_impl {
	my ($db_conn) = @_;
	flush_movies_table ($db_conn);

	pool ($db_conn);

	my $inotify = Linux::Inotify2->new () or die "Inotify initalization failed!";

	my @dirs = qw(/data/public/MKV/ /data/public/DVD/);
	my $prepared = prepare_add_query ($db_conn);

	my $query = "DELETE FROM movies WHERE dname = ?";
	my $del_prepared = $db_conn->prepare ($query);

	foreach my $dir (@dirs) {
		my $watcher = $inotify->watch ($dir, IN_CREATE | IN_DELETE | IN_ONLYDIR, sub {
				my ($e) = @_;
				my $name = $e->fullname;

				return unless (($e->IN_CREATE) || ($e->IN_DELETE));

				my $filename = (fileparse ($name))[0];

				if ( $e->IN_CREATE ) {

					my $d = better_name ($filename);

					my $ret = get_search ($d);
					return unless defined $ret;

					my $movie = $ret->{films}[0];
					return unless defined $movie;

					#render_movie ($movie, $d, 1);
					add_movie ($prepared, $filename, $d, $movie, 1);
					return;
				}

				if ( $e->IN_DELETE ) {
					$del_prepared->execute ($filename) or die "can't delete!";
					$del_prepared->finish ();
					return;
				}
			}
		) or do { print STDERR "cant watch $dir: ($!)\n"; next; };
		$W{$dir} = $watcher;
	}

	die "Nothing to watch!" unless %W;

	$poller = AnyEvent->io (
		fh   => $inotify->fileno,
		poll => 'r',
		cb   => sub { $inotify->poll () }
	);

}

sub cleanup_before_next_loop {
	# clean up
	undef $poller;
	foreach my $dir (keys %W) {
		$W{$dir}->cancel ();
	}
	undef %W;
}

sub main {

	my $db_conn = DBI->connect(          
		"dbi:SQLite:dbname=movies.db",
		"",
		"",
		{ RaiseError => 1 },
	) or die $DBI::errstr;

	my $cv = AnyEvent->condvar ();
	my $w = AnyEvent->timer (after => 0, interval => 3600, cb => sub {
			cleanup_before_next_loop ();

			eval {
				return main_impl ($db_conn);
			} or do {
				my $err = $@;
				return unless $err;
				chomp $err;
				print STDERR $err;
			};
		});
	
	$cv->recv;
}

eval {
	my $ret = main ();
	exit ($ret);
} or do {
	my $err = $@;
	return unless $err;

	chomp $err;
	print STDERR "$err\n";
};

package Wraps;

sub timeout {
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

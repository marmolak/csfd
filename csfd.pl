#!/usr/bin/perl

use strict;
use warnings;
use Encode;
use Data::Dumper;

use Linux::Inotify2;
use AnyEvent;
use File::Basename;

use CSFDAApi qw/get_search/;

my $poller = undef;
my %W;


sub better_name {
	my ($d) = @_;

	chomp $d;
	# get rid of mess from directory name
	$d =~ s/\[.*\]//ig;
	$d =~ s/(?:FULL)?CAM//g;
	$d =~ s/\(?(?:1080|720)p\)?//ig;
	$d =~ s/(?:BRrip|DVD(?:rip|scr)|HDTV|XviD|2HD|AAC|AC3)//ig;
	$d =~ s/(?:x|h)264//ig;
	$d =~ s/[^a-zA-Z](CZ|EN)//ig;
	$d =~ s/sub(:?tCZ)?//g;
	$d =~ s/5\.1//g;
	$d =~ s/\-.*$//g; # -aXXo etc...

	$d =~ s/(?:\.|\-)/ /g;
	$d =~ s/\s+/ /g;

	$d = Encode::encode ("utf8", $d);

	return $d;
}

sub render_movie {
	my ($movie, $d) = @_;

	return unless defined $movie;

	my $movie_rating = "00";
	$movie_rating = $movie->{rating_average} if defined $movie->{rating_average};
	my $movie_name = Encode::encode ("utf8", $movie->{name}) if defined $movie->{name};

	my $movie_genre = "";
	if (defined $movie->{genre}) {
		$movie_genre = join (' ', @{$movie->{genre}});

		$movie_genre = Encode::encode ("utf8", $movie_genre);
	}
	my $movie_id = $movie->{id} if defined $movie->{id};

	print "<p><strong>$movie_name - $movie_rating\% - ($d)</strong><br>\n";
	print "$movie_genre<br>\n";
	print "<a href=\"http://www.csfd.cz/film/$movie_id\">$movie_name</a></p>\n";
}

sub is_new_movie {
	my ($ctime) = @_;

	my $now = time ();

	my $day = 3600 * 24;
	my $week = $day * 7;

	return (($now - $ctime) < $week);
}

sub csfd_get_search {
	my ($d) = @_;

	# closure for timeout wrapper
	my $get_search = sub {
		return get_search ($d);
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

sub cruise_dir {
	my ($dh) = @_;

	my %movie = ();

	while ( readdir ($dh) ) {
		my $d = $_;
		next if ( ($d eq '.') or ($d eq '..') );

		$d = better_name ($d);
	
		# skip
		next if ( defined $movie{$d} );
		$movie{$d} = 1;

		my $ret = csfd_get_search ($d);
		next unless defined $ret;

		my $movie = $ret->{films}[0];

		render_movie ($movie, $d);
	}
}

sub pool {
	my $dh = undef;

	my @dirs = qw(/data/public/MKV/ /data/public/DVD/);
	foreach my $dir (@dirs) {
		# skip if $dir is not directory
		my $opendir = sub {
			opendir (my $dh, $dir) or die "opendir: $!\n";
			return $dh;
		};

		eval {
			$dh = Wraps::timeout ($opendir, 2);
			print "<h1>$dir</h1>\n";
			cruise_dir ($dh);
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
	print "<!DOCTYPE HTML>\n<html>\n<head><meta charset=\"utf-8\" /></head>\n<body>\n";

	#pool ();

	my $inotify = Linux::Inotify2->new () or die "Inotify initalization failed!";

	my @dirs = qw(/data/public/MKV/ /data/public/DVD/);

	foreach my $dir (@dirs) {
		my $watcher = $inotify->watch ($dir, IN_CREATE, sub {
				my ($e) = @_;
				my $name = $e->fullname;

				return unless ($e->IN_CREATE && -d $name);
	
				my($filename, $directories, $suffix) = fileparse ($name);
				my $bname = better_name ($filename);

				my $ret = csfd_get_search ($bname);
				return unless defined $ret;

				my $movie = $ret->{films}[0];
				return unless defined $movie;
				my $movie_name = Encode::encode ("utf8", $movie->{name});

				my $ctime = (stat ($name))[10];
				
				my $what = is_new_movie ($ctime) ? ' - new!' : '';
				print $movie_name . $what . "\n";

			}
		) or do { print "cant watch $dir: ($!)\n"; next; };
		$W{$dir} = $watcher;
	}

	die "Nothing to watch!" unless %W;

	$poller = AnyEvent->io (
		fh   => $inotify->fileno,
		poll => 'r',
		cb   => sub { $inotify->poll () }
	);

	print "</body>\n</html>\n";
}

$|++;

sub cleanup_before_next_loop {
	# clean up
	undef $poller;
	foreach my $dir (keys %W) {
		$W{$dir}->cancel ();
	}
	undef %W;
}
sub main {

	my $cv = AnyEvent->condvar ();
	my $w = AnyEvent->timer (after => 0, interval => 60, cb => sub {
			cleanup_before_next_loop ();
			eval {
				return main_impl ();
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

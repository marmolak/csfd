package CSFDAApi;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT_OK = qw/get_search/;

use Digest::HMAC_SHA1 qw/hmac_sha1 hmac_sha1_hex/;
use LWP::UserAgent;
use LWP::Simple;
use JSON;
use URI::Escape;
use Data::Dumper;

my $api_key = "061025241049";
my $api_secret = "88af9526ee967179";

sub mac($) {
        my $url = shift;
        my $z = $url =~ m/[?]/ ? '&'  : '?';
        my $r = "${url}${z}api_consumer_key=$api_key";
        my $mac = hmac_sha1_hex ($r, $api_secret);
        $r = "$r&api_signature=$mac";
        return $r;
}

sub get_search($) {
        my $q = uri_escape(shift);
        #print "escaped: $q\n";
        my $page = get (mac ("https://android-api.csfd.cz/search?q=$q") );
        my $json = decode_json ($page);
}

1;

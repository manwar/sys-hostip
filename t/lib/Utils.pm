package t::lib::Utils;
# ABSTRACT: Utilities to help testing multiple systems

use strict;
use warnings;
use vars qw( @ISA @EXPORT_OK );

use Carp;
use Exporter;
use File::Spec;
use Sys::HostIP qw/ip ips ifconfig interfaces/;
use Test::More;

@ISA       = qw(Exporter);
@EXPORT_OK = qw( mock_run_ipconfig mock_win32_hostip base_tests );

sub mock_win32_hostip {
    my $file = shift;

    {
        no warnings qw/redefine once/;
        *Sys::HostIP::_run_ipconfig = sub {
            ok( 1, 'Windows was called' );
            return mock_run_ipconfig($file);
        };
    }

    my $hostip = Sys::HostIP->new;

    return $hostip;
}

sub mock_run_ipconfig {
    my $filename = shift;
    my $file     = File::Spec->catfile( 't', 'data', $filename );

    open my $fh, '<', $file or die "Error opening $file: $!\n";
    my @output = <$fh>;
    close $fh or die "Error closing $file: $!\n";

    return @output;
}

sub base_tests {
    my $hostip = shift;

    # -- ip() --
    my $sub_ip   = ip();
    my $class_ip = $hostip->ip;

    diag("Class IP: $class_ip");
    like( $class_ip, qr/^ \d+ (?: \. \d+ ){3} $/x, 'IP by class looks ok' );
    is( $class_ip, $sub_ip, 'IP by class matches IP by sub' );

    # -- ips() --
    my $class_ips = $hostip->ips;
    isa_ok( $class_ips, 'ARRAY', 'scalar context ips() gets arrayref' );
    ok( 1 == grep( /^$class_ip$/, @{$class_ips} ), 'Found IP in IPs by class' );

    # -- interfaces() --
    my $interfaces = $hostip->interfaces;
    isa_ok( $interfaces, 'HASH', 'scalar context interfaces gets hashref' );
    cmp_ok(
        scalar keys ( %{$interfaces} ),
        '==',
        scalar @{$class_ips},
        'Matching number of interfaces and ips',
    );
}

1;

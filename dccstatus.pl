# DCC Status
# Report DCC status

use strict;
use warnings;
use Irssi;
use Irssi::Irc;
use Number::Bytes::Human qw(format_bytes);

use vars qw($VERSION %IRSSI);

$VERSION = '1.0.0';
%IRSSI = (
        authors         => 'Aidy',
        contact         => 'Aidy',
        name            => 'DCC Status',
        description     => 'DCC Status Reporter',
        licence         => 'Freeware',
);

sub _txstat {
    my ($dcc) = @_;

    return format_bytes($dcc->{transfd}) . "B/" . format_bytes($dcc->{size}) . 'B';
}

sub dccstopped {
    my ($dcc) = @_;

    my $reportchan = Irssi::settings_get_str('dccstatus_channel');
    my $server = Irssi::server_find_tag( Irssi::settings_get_str('dccstatus_net') );
    return unless $reportchan && $dcc->{type} eq 'GET';

    my $status = $dcc->{transfd} == $dcc->{size} ? 'Complete' : "\002INCOMPLETE\002";

    my $tx = format_bytes($dcc->{transfd} - ($dcc->{skipped} || 0)) . 'B';
    my $stat = _txstat($dcc);
    my $sec = time - $dcc->{starttime};
    my $txtime = sprintf("%02d:%02d:%02d", ($sec/(60**2)), ($sec/60) % 60, $sec % 60);

    $server->command("MSG $reportchan $status - $dcc->{arg} [$stat]. Transfered $tx in $txtime ");
}

sub dccgetting {
    my ($dcc) = @_;

    my $reportchan = Irssi::settings_get_str('dccstatus_channel');
    my $server = Irssi::server_find_tag( Irssi::settings_get_str('dccstatus_net') );
    return unless $reportchan && $dcc->{type} eq 'GET';

    my $stat = _txstat($dcc);
    $server->command("MSG $reportchan DCC Established: $dcc->{arg} [$stat]");
}

sub dccreport {
    my $reportchan = Irssi::settings_get_str('dccstatus_channel');
    my $server = Irssi::server_find_tag( Irssi::settings_get_str('dccstatus_net') );
    return unless ($reportchan && $_[1] eq '!dcclist' && $_[4] =~ /^$reportchan$/i);

    my @dccs = Irssi::Irc::dccs();

    $server->command("MSG $reportchan " . scalar(@dccs) . " DCCs in progress.");

    foreach my $dcc (@dccs) {
        my $status = $dcc->{type};
        if ($dcc->{starttime} == 0) { $status = "STALLED: " . $status}

        my $spd = $dcc->{starttime} ? ($dcc->{transfd} - $dcc->{skipped}) / (time - $dcc->{starttime}) : 0;

        $spd = format_bytes($spd) . "B/s";
        my $stat = _txstat($dcc);
        
        $server->command("MSG $reportchan $status - $dcc->{arg} [$stat] - $spd");
    }
}

sub dcckill {
    my $file;
    my $reportchan = Irssi::settings_get_str('dccstatus_channel');
    return unless (
        $reportchan
        && ( ($file) = ($_[1] =~ m/^\!kill (.+)$/) )
        && $_[4] =~ /^$reportchan$/i
    );

    my @dccs = Irssi::Irc::dccs();

    foreach my $dcc (@dccs) {
        if ($dcc->{arg} eq $file) {
            $dcc->close;
        }
    }
}


Irssi::signal_add('dcc closed', 'dccstopped');
Irssi::signal_add('dcc connected', 'dccgetting');
Irssi::signal_add('message public', 'dccreport');
Irssi::signal_add('message public', 'dcckill');

Irssi::settings_add_str('DCCStatus', 'dccstatus_channel', '');
Irssi::settings_add_str('DCCStatus', 'dccstatus_net', '');

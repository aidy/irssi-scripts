# DCC Fwd
# Forward DCC requests

use strict;
use warnings;
use Irssi;
use Irssi::Irc;

use vars qw($VERSION %IRSSI);

$VERSION = '1.0.0';
%IRSSI = (
	authors 	=> 'Aidy',
	contact 	=> 'Aidy',
	name		=> 'DCC Fwd',
	description 	=> 'DCC Request forwarder',
	licence		=> 'Freeware',
);

{
	my @cache = ();
	$#cache = 5;

	sub dccfwd_cache {
		my ($dcc) = @_;
		shift @cache;
		push @cache, $dcc;
	}

	sub dccfwd_dccfind {
		my ($file) = @_;

		foreach (grep defined, @cache) {
			return $_ if $_->{file} eq $file;
		}
	}
}

sub dccfwd_resume {
	my ($server, $cmd, $from_user, $uhost, $dest_user) = @_;
	my $fwd_nick = Irssi::settings_get_str('dccfwd_nick');
	if ($cmd =~ m/^DCC RESUME ([\S]+) /) {
		my $dcc = dccfwd_dccfind($1);
		$dcc->{server}->command("CTCP $dcc->{nick} $cmd");
		Irssi::signal_stop();
	} elsif ($cmd =~ m/^DCC ACCEPT/) {
		(&dccfwd_server)->command("CTCP $fwd_nick $cmd");
		Irssi::signal_stop();
	} elsif($cmd =~ m/^DCC SEND ([\S]+) /) {
		dccfwd_cache( { file => $1, server => $server, nick => $from_user });
		(&dccfwd_server)->command("CTCP $fwd_nick $cmd");
		Irssi::signal_stop();
	}
}

sub dccfwd_server {
	return Irssi::server_find_tag( Irssi::settings_get_str('dccfwd_net') );
}

Irssi::signal_add('ctcp msg', 'dccfwd_resume');
Irssi::settings_add_str('DCCFwd', 'dccfwd_nick', '');
Irssi::settings_add_str('DCCFwd', 'dccfwd_net', '');

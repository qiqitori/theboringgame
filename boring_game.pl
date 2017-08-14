#!/usr/bin/perl -w

# The boring game.
# By sneep.
# 2017-08-14.

use strict;
use Time::HiRes qw(usleep);
use Term::ReadKey;

my $DEBUG = 0;

my $USLEEP = 80000;
my @STATE_CHANGE_PROBABILITY = (0.1, 0.4, 0.1);
my $MAX_ALTITUDE = 120; # (1 == one column). Need a few more columns to display the current funds
my $MOUNTAIN_CHAR = '.';
my $MOUNTAIN_OUTLINE_CHAR = '#';
my $PLAYER_CHAR = '@';
my $UP_CMD = 'k';
my $DOWN_CMD = 'j';
my $QUIT_CMD = 'q';
# my $TUNNEL_CMD = 't'; # automatic

# Game settings
my $UP_COST = -50; # per column (unit of altitude)
my $DOWN_REWARD = 10; # per column
my $FLYING_COST = -20;
my $TUNNEL_COST = -200; # per line
my $TUNNEL_UP_COST = -50; # (in addition to $TUNNEL_COST)
my $TUNNEL_REWARD_FACTOR = 250; # per line

sub min($$) {
    return $_[0] if $_[0] < $_[1];
    return $_[1];
}
sub max($$) {
    return $_[1] if $_[0] < $_[1];
    return $_[0];
}

# Game state
my $draw_state = 1; # indicates uphill, level, or downhill
my $tunnel_started_n_frames_ago = -1;
my $current_altitude = 1; # current current_altitude (or height of mountain if you so will)
my $funds = 10000; # current funds
my $player_altitude = 10;
my $distance_survived = 0;
my $n_tunnels_built = 0;
my $total_funds_made = 0;
my $total_funds_spent = 0;

my $funds_debug;

sub check_game_over($) {
    my $forced = shift;

    if ($forced || $funds < 0) {
        print "\n";
        print (($forced ? "Forced g" : "G") . "ame over.\n");
        print "You survived $distance_survived rows, bored $n_tunnels_built tunnel(s), spent \$" . -$total_funds_spent . ", and made \$$total_funds_made in total.\n";
        cleanup();
    }
}
sub adjust_funds($) {
    my $value = shift;

    $funds += $value;
    if ($value < 0) {
        $total_funds_spent += $value;
        $funds_debug .= "  -$value" if $DEBUG;
    } else {
        $total_funds_made += $value;
        $funds_debug .= "  -$value" if $DEBUG;
    }
}

sub cleanup {
    ReadMode('normal');
    exit 1;
};
$SIG{INT} = sub { check_game_over(1) };

print "Welcome to the boring game.
Press $UP_CMD to go up (costs \$" . -$UP_COST . "), $DOWN_CMD (rewards \$$DOWN_REWARD) to go down. Press $QUIT_CMD to quit.
Boring tunnels costs " . -$TUNNEL_COST . " per row. Going up in tunnels costs an additional " . -$TUNNEL_UP_COST . ".\n\n";

ReadMode('cbreak');
for (;;) {
    $funds_debug = '' if $DEBUG;

    # input
    my $input = ReadKey(-1) || '';
    if ($input eq $UP_CMD) {
        adjust_funds($tunnel_started_n_frames_ago != -1 ? $TUNNEL_UP_COST : $UP_COST);
        $player_altitude++;
        print "\b";
    } elsif ($input eq $DOWN_CMD) {
        if ($tunnel_started_n_frames_ago == -1) {
            adjust_funds($DOWN_REWARD);
            $player_altitude--;
        }
    } elsif ($input eq $QUIT_CMD) {
        check_game_over(1);
    }

    # that may have cost us some funds, so check for game over
    check_game_over(0);

    # graphics
    my $line = $MOUNTAIN_CHAR x max($current_altitude-1, 0) . $MOUNTAIN_OUTLINE_CHAR;
    $line .= ' ' x max($player_altitude-$current_altitude, 0);
    substr $line, $player_altitude, 1, $PLAYER_CHAR; # put player char at player's altitude
    print "$line          \$$funds";

    # game logic
    if ($player_altitude < $current_altitude) { # tunneling
        adjust_funds($TUNNEL_COST);
        $tunnel_started_n_frames_ago++;
    } elsif ($player_altitude > $current_altitude) { # flying
        if ($tunnel_started_n_frames_ago != -1) {
            adjust_funds($tunnel_started_n_frames_ago * $TUNNEL_REWARD_FACTOR);
            $tunnel_started_n_frames_ago = -1;
        } else {
            adjust_funds($FLYING_COST);
        }
    } elsif ($player_altitude == $current_altitude) {
        if ($tunnel_started_n_frames_ago == -1) { # if we aren't in a tunnel already, we just entered one!
            adjust_funds($TUNNEL_COST);
            $tunnel_started_n_frames_ago = 1;
            $n_tunnels_built++;
        }
    }

    # next graphics state
    if ($draw_state == 1) {
        $current_altitude++;
        $draw_state = 2 if (rand() < $STATE_CHANGE_PROBABILITY[$draw_state-1] || $current_altitude > $MAX_ALTITUDE);
    } elsif ($draw_state == 2) {
        $draw_state = 3 if (rand() < $STATE_CHANGE_PROBABILITY[$draw_state-1]);
    } else {
        $current_altitude--;
        $draw_state = 1 if (rand() < $STATE_CHANGE_PROBABILITY[$draw_state-1] || $current_altitude < 1)
    }

    print "$funds_debug" if $DEBUG;
    print "\n";
    check_game_over(0);
    $distance_survived++;
    usleep($USLEEP);
}

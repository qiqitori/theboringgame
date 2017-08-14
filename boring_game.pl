#!/usr/bin/perl

# The boring game.
# By sneep.
# 2017-08-14.

use strict;
use Time::HiRes qw(usleep);

my $USLEEP = 40000;
my @STATE_CHANGE_PROBABILITY = (0.1, 0.4, 0.1);
my $MAX_COLUMN = 120; # plus a few to display the current funds

my $state = 1;
my $length = 1;

for (;;) {
    print "#" x $length, "\n";
    if ($state == 1) {
        $length++;
        $state = 2 if (rand() < $STATE_CHANGE_PROBABILITY[$state-1] || $length > $MAX_COLUMN);
    } elsif ($state == 2) {
        $state = 3 if (rand() < $STATE_CHANGE_PROBABILITY[$state-1]);
    } else {
        $length--;
        $state = 1 if (rand() < $STATE_CHANGE_PROBABILITY[$state-1] || $length < 1)
    }
    usleep(40000);
}

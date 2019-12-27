##############################################
# $Id: 99_myUtils.pm 2019-10-25
#
#  myUtilsTemplate.pm 7570 2015-01-14 18:31:44Z rudolfkoenig $
#
# Save this file as 99_myUtils.pm, and create your own functions in the new
# file. They are then available in every Perl expression.
#
# 

package main;

use strict;
use warnings;
use POSIX;
use Readonly

sub
myUtils_Initialize($$)
{
    my ($hash) = @_;
}

# Enter you functions below _this_ line.

##############################################
# Use

use Time::Piece;
#use Time::Seconds;

##############################################
# ALLGEMEIN

# Präsenzzustände
Readonly our $PRES_ZUHAUSE  =>  3;
Readonly our $PRES_SCHLAF   =>  2;
Readonly our $PRES_WEG      =>  1;
Readonly our $PRES_URLAUB   =>  0;

our $status_presence = $PRES_ZUHAUSE;

# Lichtzustände                                     # Zustandsübergänge
Readonly our $LICHT_STD_AUS =>  'Licht_std_aus';    # ->LICHT_MAN_AN, ->LICHT_BEW_AN, ->LICHT_ZEIT_AN
Readonly our $LICHT_MAN_AN  =>  'Licht_man_an';     # ->LICHT_MAN_AUS, ->LICHT_ZEIT_AN, ->LICHT_STD_AUS
Readonly our $LICHT_MAN_AUS =>  'Licht_man_aus';    # ->LICHT_STD_AUS, ->LICHT_MAN_AN
Readonly our $LICHT_BEW_AN  =>  'Licht_bew_an';     # ->LICHT_BEW_AUS, ->LICHT_MAN_AUS, ->LICHT_ZEIT_AN
Readonly our $LICHT_BEW_AUS =>  'Licht_bew_aus';    # ->LICHT_STD_AUS, ->LICHT_MAN_AUS, ->LICHT_ZEIT_AN
Readonly our $LICHT_ZEIT_AN =>  'Licht_zeit_an';    # ->LICHT_STD_AUS, ->LICHT_MAN_AUS

our $simulated_bed_time;
our $simulated_work_time;

# Einmal nachts ausführen
sub execute_once_per_night
{
    set_simulated_bed_time();
    set_timers($simulated_bed_time, $simulated_work_time);

    1;
}

# Anwesenheitssimulation
sub set_simulated_bed_time
{
    my $time = Time::Piece->new;    # jetzt
    my $date = $time->date;         # heute

    my $earliest_bed_time_piece = Time::Piece->strptime("$date $main::EARLIEST_BED_TIME_HH_MM", "%Y-%m-%d %H:%M");

    my $rnd_secs1 = int(rand(($main::RANDOM_RANGE_M/2)*60));
    my $rnd_secs2 = int(rand(($main::RANDOM_RANGE_M/2)*60));
    # Zufallsverteilung mit mittigem Schwerpunkt
    $simulated_bed_time = $earliest_bed_time_piece + ($rnd_secs1 + $rnd_secs2);
    $simulated_work_time = $simulated_bed_time - ($main::WORK_END_BEFORE_SLEEP_M*60);

    # Convert to "HH:MM" format
    $simulated_bed_time = $simulated_bed_time->strftime('%T');
    $simulated_work_time = $simulated_work_time->strftime('%T');

    1;
}

##############################################
# FLUR

# set fl_decke
sub set_fl_decke_on
{
    fhem("set FL_Decke_RGB ct 360; set FL_Decke_RGB pct 100");
}

sub set_fl_decke_night
{
    fhem("set FL_Decke_RGB rgb 1D0505");
}

sub set_fl_decke_off
{
    fhem("set FL_Decke_RGB off");
}

sub set_fl_decke_nomotion_timer
{
    fhem("defmod FL_nomotiontimer at +00:00:20 { set_state_fl_std_aus(); }");
}

sub reset_fl_decke_nomotion_timer
{
    fhem("delete FL_nomotiontimer");
}

# states
our $status_fl_licht = $LICHT_STD_AUS;

sub set_state_fl_std_aus
{
    $status_fl_licht = $LICHT_STD_AUS;
    set_fl_decke_off();
}

sub set_state_fl_man_an
{
    $status_fl_licht = $LICHT_MAN_AN;
    set_fl_decke_on();
    # TODO set a man_on timer to go to argument function
    #https://stackoverflow.com/questions/1234640/passing-a-function-object-and-calling-it
    # This shall save the manual setting for a time until it returns to the state which is provided by the argument.
}

sub set_state_fl_man_aus
{
    $status_fl_licht = $LICHT_MAN_AUS;
    set_fl_decke_off();
    # TODO set a man_off timer to go to argument function
    #https://stackoverflow.com/questions/1234640/passing-a-function-object-and-calling-it
    # This shall save the manual setting for a time until it returns to the state which is provided by the argument.
}

sub set_state_fl_bew_an
{
    $status_fl_licht = $LICHT_BEW_AN;
    if( $PRES_SCHLAF == $status_presence ) {
        set_fl_decke_night();
    } else {
        set_fl_decke_on();
    }
}

# starts timer to switch light off
sub set_state_fl_bew_aus
{
    $status_fl_licht = $LICHT_BEW_AUS;
    set_fl_decke_nomotion_timer();
}

sub set_state_fl_zeit_an
{
    $status_fl_licht = $LICHT_ZEIT_AN;
    set_fl_decke_on();
}

# Actions

# Lichtschalter betätigt
sub action_fl_lightswitch
{
    if(     $LICHT_MAN_AN == $status_fl_licht ||
            $LICHT_BEW_AN == $status_fl_licht )
    {
        set_state_fl_man_aus();
        # TODO set argument to afterwards go $LICHT_STD_AUS
    }
    elsif(  $LICHT_ZEIT_AN == $status_fl_licht )
    {
        set_state_fl_man_aus();
        # TODO set argument to afterwards go $LICHT_ZEIT_AN
    }
    elsif(  $LICHT_BEW_AUS == $status_fl_licht )
    {
        set_state_fl_man_aus();
        # TODO set argument to afterwards go $LICHT_STD_AUS
        reset_fl_decke_nomotion_timer();
    }
    else { # LICHT_STD_AUS & LICHT_MAN_AUS
        set_state_fl_man_an();
        # TODO set argument to afterwards go $LICHT_STD_AUS
    }
}

# Bewegung erkannt
sub action_fl_motion_on
{
    if(     $LICHT_STD_AUS == $status_fl_licht )
    {
        set_state_fl_bew_an();
    }
    elsif(  $LICHT_BEW_AUS == $status_fl_licht)
    {
        reset_fl_decke_nomotion_timer();
        set_state_fl_bew_an();
    }
    else { }
    # $LICHT_MAN_AN
    # nothing
    # $LICHT_MAN_AUS
    # nothing
    # $LICHT_BEW_AN
    # nothing
    # $LICHT_ZEIT_AN
    # nothing
}

# TODO
sub action_fl_motion_off
{
    if(     $LICHT_BEW_AN == $status_fl_licht )
    {
        set_state_fl_bew_aus();
    }
    else { }
    # $LICHT_STD_AUS
    # nothing
    # $LICHT_MAN_AN
    # nothing
    # $LICHT_MAN_AUS
    # nothing
    # $LICHT_BEW_AUS
    # nothing
    # $LICHT_ZEIT_AN
    # nothing
}

# TODO
sub action_fl_timer_on
{
    if(     $LICHT_STD_AUS == $status_fl_licht )
    {
        set_state_fl_bew_an();
    }
    else { }
    # $LICHT_MAN_AN
    # nothing
    # $LICHT_MAN_AUS
    # nothing
    # $LICHT_BEW_AN
    # nothing
    # $LICHT_BEW_AUS
    # nothing
    # $LICHT_ZEIT_AN
    # nothing
}

# TODO
sub action_fl_timer_off
{
    if(     $LICHT_STD_AUS == $status_fl_licht )
    {
        set_state_fl_bew_an();
    }
    else { }
    # $LICHT_MAN_AN
    # nothing
    # $LICHT_MAN_AUS
    # nothing
    # $LICHT_BEW_AN
    # nothing
    # $LICHT_BEW_AUS
    # nothing
    # $LICHT_ZEIT_AN
    # nothing
}

1;

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
# ALLGEMEIN

# Präsenzzustände
Readonly our $PRES_ZUHAUSE  =>  'Pres_zuhause';
Readonly our $PRES_SCHLAF   =>  'Pres_schlaf';
Readonly our $PRES_WEG      =>  'Pres_weg';
Readonly our $PRES_URLAUB   =>  'Pres_urlaub';

our $status_presence = $PRES_ZUHAUSE;

# Lichtzustände                                     # Zustandsübergänge
Readonly our $LICHT_STD_AUS =>  'Licht_std_aus';    # ->LICHT_MAN_AN, ->LICHT_BEW_AN, ->LICHT_ZEIT_AN
Readonly our $LICHT_MAN_AN  =>  'Licht_man_an';     # ->LICHT_MAN_AUS, ->LICHT_ZEIT_AN, ->LICHT_STD_AUS
Readonly our $LICHT_MAN_AUS =>  'Licht_man_aus';    # ->LICHT_STD_AUS, ->LICHT_MAN_AN
Readonly our $LICHT_BEW_AN  =>  'Licht_bew_an';     # ->LICHT_STD_AUS, ->LICHT_MAN_AUS, ->LICHT_ZEIT_AN
Readonly our $LICHT_ZEIT_AN =>  'Licht_zeit_an';    # ->LICHT_STD_AUS, ->LICHT_MAN_AUS

##############################################
# FLUR

# set fl_decke
set_fl_decke_on
{
    fhem("set FL_Decke_RGB ct 360; set FL_Decke_RGB pct 100");
}

set_fl_decke_night
{
    fhem("set FL_Decke_RGB rgb 1D0505");
}

set_fl_decke_off
{
    fhem("set FL_Decke_RGB off");
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
}

sub set_state_fl_man_aus
{
    $status_fl_licht = $LICHT_MAN_AUS;
    set_fl_decke_off();
    # TODO set a man_off timer to go to argument function
    #https://stackoverflow.com/questions/1234640/passing-a-function-object-and-calling-it
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
            $LICHT_BEW_AN == $status_fl_licht ) {
        set_state_fl_man_aus();
        # TODO set argument to afterwards go $LICHT_STD_AUS
    }
    elsif(  $LICHT_ZEIT_AN == $status_fl_licht ) {
        set_state_fl_man_aus();
        # TODO set argument to afterwards go $LICHT_ZEIT_AN
    }
    else { # LICHT_STD_AUS & LICHT_MAN_AUS
        set_state_fl_man_an();
        # TODO set argument to afterwards go $LICHT_STD_AUS
    }
}

sub action_fl_motion_on
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
    # $LICHT_ZEIT_AN
    # nothing
}

sub action_fl_motion_off
{
    fhem ("");
    if(     $LICHT_BEW_AN == $status_fl_licht )
    {
        fhem ("defmod FL_nomotiontimer at +00:00:20 { set_state_fl_std_aus(); }");
    }
    else { }
    # $LICHT_STD_AUS
    # nothing
    # $LICHT_MAN_AN
    # nothing
    # $LICHT_MAN_AUS
    # nothing
    # $LICHT_ZEIT_AN
    # nothing
}

sub action_fl_timer_on
{
    if( LICHT_STD_AUS == $status_fl_licht )
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
    # $LICHT_ZEIT_AN
    # nothing
}

sub action_fl_timer_off
{
    if( LICHT_STD_AUS == $status_fl_licht )
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
    # $LICHT_ZEIT_AN
    # nothing
}

1;
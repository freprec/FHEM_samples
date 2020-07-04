##############################################
# $Id: 99_myUtils.pm 2020-07-02
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

sub
myUtils_Initialize($$)
{
    my ($hash) = @_;
    # Präsenzzustände
    our $PRES_ZUHAUSE  =  3;
    our $PRES_SCHLAF   =  2;
    our $PRES_WEG      =  1;
    our $PRES_URLAUB   =  0;

    our $status_presence = $PRES_ZUHAUSE;

    # Lichtzustände                                     # Zustandsübergänge
    our $LICHT_STD_AUS =  'Licht_std_aus';    # ->LICHT_MAN_AN, ->LICHT_BEW_AN, ->LICHT_ZEIT_AN
    our $LICHT_MAN_AN  =  'Licht_man_an';     # ->LICHT_MAN_AUS, ->LICHT_ZEIT_AN, ->LICHT_STD_AUS
    our $LICHT_MAN_AUS =  'Licht_man_aus';    # ->LICHT_STD_AUS, ->LICHT_MAN_AN
    our $LICHT_BEW_AN  =  'Licht_bew_an';     # ->LICHT_BEW_AUS, ->LICHT_MAN_AUS, ->LICHT_ZEIT_AN
    our $LICHT_BEW_AUS =  'Licht_bew_aus';    # ->LICHT_STD_AUS, ->LICHT_MAN_AUS, ->LICHT_ZEIT_AN
    our $LICHT_ZEIT_AN =  'Licht_zeit_an';    # ->LICHT_STD_AUS, ->LICHT_MAN_AUS
    our $LICHT_NACHT   =  'Licht_nacht';      # ->LICHT_MAN_AN, ->LICHT_BEW_AUS

    our $simulated_bed_time;
    our $simulated_work_time;

    our $status_bz_strip = $LICHT_STD_AUS;
    our $status_fl_licht = $LICHT_STD_AUS;

    our $ct_max = 500;
    our $ct_min = 154;

    our $pct_max = 100;
    our $pct_min = 5;

    our $bz_strip_ct = 270;
    our $bz_strip_pct = 100;
}

# Enter you functions below _this_ line.

##############################################
# Use

use Time::Piece;
#use Time::Seconds;

##############################################
# ALLGEMEIN

# Einmal nachts ausführen
sub execute_once_per_night
{
    set_simulated_bed_time();
    set_timers($main::simulated_bed_time, $main::simulated_work_time);

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
    $main::simulated_bed_time = $earliest_bed_time_piece + ($rnd_secs1 + $rnd_secs2);
    $main::simulated_work_time = $main::simulated_bed_time - ($main::WORK_END_BEFORE_SLEEP_M*60);

    # Convert to "HH:MM" format
    $main::simulated_bed_time = $main::simulated_bed_time->strftime('%T');
    $main::simulated_work_time = $main::simulated_work_time->strftime('%T');

    1;
}

##############################################
# ALLGEMEIN

# states presence
sub set_state_presence_zuhause()
{
    $main::status_presence = $main::PRES_ZUHAUSE;
    
    fhem("attr Abends_Flurlicht disable 1");
    fhem("attr Abends_Arbeitszimmerlicht disable 1");
    fhem("set teleBot message Anwesenheit: aktiviert");

    1;
}

sub set_state_presence_schlaf()
{
    $main::status_presence = $main::PRES_SCHLAF;
    
    1;
}

sub set_state_presence_weg()
{
    $main::status_presence = $main::PRES_WEG;
    
    fhem("attr Abends_Flurlicht disable 0");
    fhem("attr Abends_Arbeitszimmerlicht disable 0");
    fhem("set teleBot message Anwesenheit: deaktiviert");

    1;
}

sub set_state_presence_urlaub()
{
    $main::status_presence = $main::PRES_URLAUB;
    
    fhem("attr Abends_Flurlicht disable 0");
    fhem("attr Abends_Arbeitszimmerlicht disable 0");
    fhem("set teleBot message Anwesenheit: deaktiviert");

    1;
}

# actions presence
sub action_presence_switch()
{
    if (       $main::PRES_WEG eq $main::status_presence ||
            $main::PRES_SCHLAF eq $main::status_presence)
    {
        fhem("set FL_Decke_RGB rgb 1DFF0D");
        fhem("set FL_Decke_RGB blink 2 0.9");
        set_state_presence_zuhause();
    }
    elsif ($main::PRES_ZUHAUSE eq $main::status_presence)
    {
        fhem("set FL_Decke_RGB rgb FF0808");
        fhem("set FL_Decke_RGB blink 2 0.9");
        set_state_presence_weg();
    }
    else{}

    1;
}

sub action_sleep_trigger()
{
    if ($main::PRES_ZUHAUSE eq $main::status_presence)
    {
        set_state_presence_schlaf();
    }
    else{}

    1;
}

sub action_wake_trigger()
{
    if ($main::PRES_SCHLAF eq $main::status_presence)
    {
        set_state_presence_zuhause();
    }
    else{}
    
    1;
}

##############################################
# FLUR

# set fl_decke
sub set_fl_decke_on
{
    fhem("set FL_Decke_RGB ct 360; set FL_Decke_RGB pct 100");
    1;
}

sub set_fl_decke_night
{
    fhem("set FL_Decke_RGB rgb 1D0505");
    1;
}

sub set_fl_decke_off
{
    fhem("set FL_Decke_RGB off");
    1;
}

sub set_fl_decke_nomotion_timer
{
    fhem("defmod FL_nomotiontimer at +00:00:20 { set_state_fl_std_aus() };");
    1;
}

sub reset_fl_decke_nomotion_timer
{
    fhem("delete FL_nomotiontimer");
    1;
}

# states
sub set_state_fl_std_aus
{
    $main::status_fl_licht = $main::LICHT_STD_AUS;
    reset_fl_decke_nomotion_timer();
    set_fl_decke_off();
    1;
}

sub set_state_fl_man_an
{
    $main::status_fl_licht = $main::LICHT_MAN_AN;
    reset_fl_decke_nomotion_timer();
    set_fl_decke_on();
    # TODO set a man_on timer to go to argument function
    #https://stackoverflow.com/questions/1234640/passing-a-function-object-and-calling-it
    # This shall save the manual setting for a time until it returns to the state which is provided by the argument.
    1;
}

sub set_state_fl_man_aus
{
    set_state_fl_std_aus(); # until below TODO is implemented
    #$main::status_fl_licht = $main::LICHT_MAN_AUS;
    reset_fl_decke_nomotion_timer();
    set_fl_decke_off();
    # TODO set a man_off timer to go to argument function
    #https://stackoverflow.com/questions/1234640/passing-a-function-object-and-calling-it
    # This shall save the manual setting for a time until it returns to the state which is provided by the argument.
    1;
}

sub set_state_fl_bew_an
{
    $main::status_fl_licht = $main::LICHT_BEW_AN;
    reset_fl_decke_nomotion_timer();
    set_fl_decke_on();
    1;
}

# starts timer to switch light off
sub set_state_fl_bew_aus
{
    $main::status_fl_licht = $main::LICHT_BEW_AUS;
    set_fl_decke_nomotion_timer();
    1;
}

sub set_state_fl_zeit_an
{
    $main::status_fl_licht = $main::LICHT_ZEIT_AN;
    set_fl_decke_on();
    1;
}

sub set_state_fl_nacht_an
{
    $main::status_fl_licht = $main::LICHT_NACHT;
    reset_fl_decke_nomotion_timer();
    set_fl_decke_night();
    1;
}

# Actions

# Lichtschalter betätigt
sub action_fl_lightswitch
{
    if(     $main::LICHT_MAN_AN eq $main::status_fl_licht ||
            $main::LICHT_BEW_AN eq $main::status_fl_licht)
    {
        set_state_fl_man_aus();
        # TODO set argument to afterwards go $main::LICHT_STD_AUS
    }
    elsif(  $main::LICHT_ZEIT_AN eq $main::status_fl_licht)
    {
        set_state_fl_man_aus();
        # TODO set argument to afterwards go $main::LICHT_ZEIT_AN
    }
    elsif(  $main::LICHT_BEW_AUS eq $main::status_fl_licht)
    {
        set_state_fl_man_aus();
        # TODO set argument to afterwards go $main::LICHT_STD_AUS
        
    }
    else { # LICHT_STD_AUS, LICHT_MAN_AUS, LICHT_NACHT
        set_state_fl_man_an();
        # TODO set argument to afterwards go $main::LICHT_STD_AUS
    }
    1;
}

# Bewegung erkannt
sub action_fl_motion_on
{
    if (   $main::PRES_WEG eq $main::status_presence ||
        $main::PRES_URLAUB eq $main::status_presence)
    {
        fhem("set teleBot message Flur: Bewegung detektiert.");
    }

    # fl_licht
    if(     $main::LICHT_STD_AUS eq $main::status_fl_licht)
    {
        if ($main::PRES_SCHLAF eq $main::status_presence)
        {
            set_state_fl_nacht_an();
        }
        else
        {
            set_state_fl_bew_an();
        }
    }
    elsif(  $main::LICHT_BEW_AUS eq $main::status_fl_licht)
    {
        if ($main::PRES_SCHLAF eq $main::status_presence)
        {
            set_state_fl_nacht_an();
        }
        else
        {
            set_state_fl_bew_an();
        }
    }
    else { }
    # $main::LICHT_MAN_AN
    # nothing
    # $main::LICHT_MAN_AUS
    # nothing
    # $main::LICHT_BEW_AN
    # nothing
    # $main::LICHT_ZEIT_AN
    # nothing
    # $main::LICHT_NACHT
    # nothing

    # bz_strip
    if ($main::LICHT_STD_AUS eq $main::status_bz_strip)
    {
        if ($main::PRES_SCHLAF eq $main::status_presence)
        {
            set_state_bz_strip_nacht_an();
        }
        else { }
    }
    elsif ($main::LICHT_BEW_AUS eq $main::status_bz_strip)
    {
        if ($main::PRES_SCHLAF eq $main::status_presence)
        {
            set_state_bz_strip_nacht_an();
        }
        else { }
    }
    else { }
    # $main::LICHT_MAN_AN
    # nothing
    # $main::LICHT_MAN_AUS
    # nothing
    # $main::LICHT_BEW_AN
    # nothing
    # $main::LICHT_ZEIT_AN
    # nothing
    # $main::LICHT_NACHT
    # nothing
    1;
}

# TODO
sub action_fl_motion_off
{
    if (  $main::LICHT_BEW_AN eq $main::status_fl_licht
        || $main::LICHT_NACHT eq $main::status_fl_licht)
    {
        set_state_fl_bew_aus();
    }
    else { }
    # $main::LICHT_STD_AUS
    # nothing
    # $main::LICHT_MAN_AN
    # nothing
    # $main::LICHT_MAN_AUS
    # nothing
    # $main::LICHT_BEW_AUS
    # nothing
    # $main::LICHT_ZEIT_AN
    # nothing

    if (  $main::LICHT_BEW_AN eq $main::status_bz_strip
        || $main::LICHT_NACHT eq $main::status_bz_strip)
    {
        set_state_bz_strip_bew_aus();
    }
    # $main::LICHT_STD_AUS
    # nothing
    # $main::LICHT_MAN_AN
    # nothing
    # $main::LICHT_MAN_AUS
    # nothing
    # $main::LICHT_BEW_AUS
    # nothing
    # $main::LICHT_ZEIT_AN
    # nothing
    1;
}

# TODO
sub action_fl_timer_on
{
    if ($main::LICHT_STD_AUS eq $main::status_fl_licht)
    {
        set_state_fl_bew_an();
    }
    else { }
    # $main::LICHT_MAN_AN
    # nothing
    # $main::LICHT_MAN_AUS
    # nothing
    # $main::LICHT_BEW_AN
    # nothing
    # $main::LICHT_BEW_AUS
    # nothing
    # $main::LICHT_ZEIT_AN
    # nothing
    1;
}

# TODO
sub action_fl_timer_off
{
    if ($main::LICHT_STD_AUS eq $main::status_fl_licht)
    {
        set_state_fl_bew_an();
    }
    else { }
    # $main::LICHT_MAN_AN
    # nothing
    # $main::LICHT_MAN_AUS
    # nothing
    # $main::LICHT_BEW_AN
    # nothing
    # $main::LICHT_BEW_AUS
    # nothing
    # $main::LICHT_ZEIT_AN
    # nothing
    1;
}


##############################################
# BADEZIMMER

# set bz_strip
sub set_bz_strip_on
{
    fhem("set BZ_Flexstrip pct ".$main::bz_strip_pct);
    fhem("set BZ_Flexstrip ct ".$main::bz_strip_ct);
    1;
}
sub set_bz_strip_night
{
    fhem("set BZ_Flexstrip rgb 1D0505");
    1;
}

sub set_bz_strip_nomotion_timer
{
    fhem("defmod FL_BZStrip_nomotiontimer at +00:05:00 { set_state_bz_strip_std_aus() };");
    1;
}

sub reset_bz_strip_nomotion_timer
{
    fhem("delete FL_BZStrip_nomotiontimer");
    1;
}

sub set_bz_strip_off
{
    fhem("set BZ_Flexstrip off");
    1;
}

# set bz_strip states
sub set_state_bz_strip_man_an
{
    $main::status_bz_strip = $main::LICHT_MAN_AN;
    reset_bz_strip_nomotion_timer();
    set_bz_strip_on();
    1;
}

sub set_state_bz_strip_man_aus
{
    set_state_bz_strip_std_aus();
    #$main::status_bz_strip = $main::LICHT_MAN_AUS;
    #reset_bz_strip_nomotion_timer();
    #set_bz_strip_off();
    1;
}


sub set_state_bz_strip_std_aus
{
    $main::status_bz_strip = $main::LICHT_STD_AUS;
    reset_bz_strip_nomotion_timer();
    set_bz_strip_off();
    1;
}

sub set_state_bz_strip_nacht_an
{    
    $main::status_bz_strip = $main::LICHT_NACHT;
    reset_bz_strip_nomotion_timer();
    set_bz_strip_night();
    1;
}

# starts timer to switch light off
sub set_state_bz_strip_bew_aus
{
    $main::status_bz_strip = $main::LICHT_BEW_AUS;
    set_bz_strip_nomotion_timer();
    1;
}

# actions BZ_Dimmschalter
sub action_bz_switch
{
    # bz_strip
    if (   $main::LICHT_STD_AUS eq $main::status_bz_strip
        || $main::LICHT_MAN_AUS eq $main::status_bz_strip)
    {
        set_state_bz_strip_man_an();
    }
    elsif (  $main::LICHT_NACHT eq $main::status_bz_strip
        ||  $main::LICHT_MAN_AN eq $main::status_bz_strip
        ||  $main::LICHT_BEW_AN eq $main::status_bz_strip
        || $main::LICHT_BEW_AUS eq $main::status_bz_strip)
    {
        set_state_bz_strip_man_aus();
    }
    elsif( $main::LICHT_ZEIT_AN eq $main::status_bz_strip)
    {
        set_state_bz_strip_man_aus();
        # TODO set argument to afterwards go $main::LICHT_ZEIT_AN
    }
    else { }

    1;
}

sub action_bz_dimup
{
    $main::bz_strip_pct = $main::bz_strip_pct + 15;
    if ($main::pct_max < $main::bz_strip_pct)
    {
        $main::bz_strip_pct = $main::pct_max;
    }
    set_state_bz_strip_man_an();
    1;
}
sub action_bz_dimdown
{
    $main::bz_strip_pct = $main::bz_strip_pct - 15;
    if ($main::pct_min > $main::bz_strip_pct)
    {
        $main::bz_strip_pct = $main::pct_min;
    }
    set_state_bz_strip_man_an();
    1;
} 
sub action_bz_left
{
    $main::bz_strip_ct = $main::bz_strip_ct - 30;
    if ($main::ct_min > $main::bz_strip_ct)
    {
        $main::bz_strip_ct = $main::ct_min;
    }
    set_state_bz_strip_man_an();
    1;
}
sub action_bz_right
{
    $main::bz_strip_ct = $main::bz_strip_ct + 30;
    if ($main::ct_max < $main::bz_strip_ct)
    {
        $main::bz_strip_ct = $main::ct_max;
    }
    set_state_bz_strip_man_an();
    1;
}

1;

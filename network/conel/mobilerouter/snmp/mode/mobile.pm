#
# Copyright 2017 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets the needs in IT infrastructure and application monitoring for service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for 
# the specific language governing permissions and limitations under the License.
#
package network::conel::mobilerouter::snmp::mode::mobile;

use base qw(centreon::plugins::mode);

use POSIX;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use Time::HiRes qw(time);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '0.5';
    $options{options}->add_options(arguments =>
	                            {
				      "warning:s" => { name => 'warning', default => '' },
				      "critical:s" => { name => 'critical', default => '' },
				    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_mobile_technology = (
    0 => 'none',
    2 => 'gprs',
    4 => 'edge',
    6 => 'umts',
    8 => 'hsdpa',
    10 => 'hsupa',
    12 => 'hspa',
    14 => 'lte',
    16 => 'cdma',
    18 => 'evdo',
    20 => 'evdo0',
    22 => 'evdoA',
    24 => 'evdoB' );

my %map_mobile_card = (
    0 => 'primary',
    1 => 'secondary',
    2 => 'tertiary' );

my %map_mobile_registration = (
    0 => 'unknown',
    1 => 'idle',
    2 => 'search',
    3 => 'denied',
    4 => 'home',
    5 => 'foreign' );

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    # oids
    my $oid_mobileTechnology = '.1.3.6.1.4.1.30140.4.1.0';
    my $oid_mobilePLMN = '.1.3.6.1.4.1.30140.4.2.0';
    my $oid_mobileCell = '.1.3.6.1.4.1.30140.4.3.0';
    my $oid_mobileChannel = '.1.3.6.1.4.1.30140.4.4.0';
    my $oid_mobileSignalStrength = '.1.3.6.1.4.1.30140.4.5.0';
    my $oid_mobileChannelN1 = '.1.3.6.1.4.1.30140.4.6.0';
    my $oid_mobileSignalStrengthN1 = '.1.3.6.1.4.1.30140.4.7.0';
    my $oid_mobileChannelN2 = '.1.3.6.1.4.1.30140.4.8.0';
    my $oid_mobileSignalStrengthN2 = '.1.3.6.1.4.1.30140.4.9.0';
    my $oid_mobileChannelN3 = '.1.3.6.1.4.1.30140.4.10.0';
    my $oid_mobileSignalStrengthN3 = '.1.3.6.1.4.1.30140.4.11.0';
    my $oid_mobileChannelN4 = '.1.3.6.1.4.1.30140.4.12.0';
    my $oid_mobileSignalStrengthN4 = '.1.3.6.1.4.1.30140.4.13.0';
    my $oid_mobileChannelN5 = '.1.3.6.1.4.1.30140.4.14.0';
    my $oid_mobileSignalStrengthN5 = '.1.3.6.1.4.1.30140.4.15.0';
    my $oid_mobileUpTime = '.1.3.6.1.4.1.30140.4.16.0';
    my $oid_mobileConnect = '.1.3.6.1.4.1.30140.4.17.0';
    my $oid_mobileDisconnect = '.1.3.6.1.4.1.30140.4.18.0';
    my $oid_mobileCard = '.1.3.6.1.4.1.30140.4.19.0';
    my $oid_mobileIPAddress = '.1.3.6.1.4.1.30140.4.20.0';
    my $oid_mobileLatency = '.1.3.6.1.4.1.30140.4.21.0';
    my $oid_mobileReportPeriod = '.1.3.6.1.4.1.30140.4.22.0';
    my $oid_mobileRegistration = '.1.3.6.1.4.1.30140.4.23.0'; # enum(0 => 'unknown', 1 => 'idle', 2 => 'search', 3 => 'denied', 4 => 'home', 5 => 'foreign');
    my $oid_mobileOperator = '.1.3.6.1.4.1.30140.4.24.0';
    my $oid_mobileLAC = '.1.3.6.1.4.1.30140.4.25.0';
    my $oid_mobileSignalQuality = '.1.3.6.1.4.1.30140.4.26.0';
    my $oid_mobileCSQ = '.1.3.6.1.4.1.30140.4.27.0';

    my $result = $self->{snmp}->get_leef(oids => [ $oid_mobileTechnology, $oid_mobilePLMN, $oid_mobileCell, $oid_mobileChannel, $oid_mobileSignalStrength, $oid_mobileChannelN1,
					           $oid_mobileSignalStrengthN1, $oid_mobileChannelN2, $oid_mobileSignalStrengthN2, $oid_mobileChannelN3,
						   $oid_mobileSignalStrengthN3, $oid_mobileChannelN4, $oid_mobileSignalStrengthN4, $oid_mobileChannelN5,
					           $oid_mobileSignalStrengthN5, $oid_mobileUpTime, $oid_mobileConnect, $oid_mobileDisconnect, $oid_mobileCard,
						   $oid_mobileIPAddress, $oid_mobileLatency, $oid_mobileReportPeriod, $oid_mobileRegistration, $oid_mobileOperator,
						   $oid_mobileLAC, $oid_mobileSignalQuality, $oid_mobileCSQ
 	                                         ], nothing_quit => 1);
    
    my $operator = $result->{$oid_mobileOperator};
    my $ip_address = $result->{$oid_mobileIPAddress};
    my $technology = 'n/a';
    $technology = $map_mobile_technology{$result->{$oid_mobileTechnology}} if defined $result->{$oid_mobileTechnology};
    my $card = $map_mobile_card{$result->{$oid_mobileCard}};
    my $registration = $map_mobile_registration{$result->{$oid_mobileRegistration}};
    my $plmn = $result->{$oid_mobilePLMN};
    my $cell = $result->{$oid_mobileCell};

    $self->{output}->output_add(severity => 'OK',
	                        short_msg => sprintf('Operator \'%s\' - IP Address : %s - %s card - Tech : %s - Registration \'%s\' - PLMN : \'%s\' - Cell : \'%s\'',
					             $operator,
						     $ip_address,
						     $card,
						     $technology,
						     $registration,
						     $plmn,
						     $cell
					             ));
    $self->{output}->output_add(long_msg => sprintf('Operator (CONEL-MOBILE-MIB::mobileOperator.0) : \'%s\'', $operator));
    $self->{output}->output_add(long_msg => sprintf('IP Address (CONEL-MOBILE-MIB::mobileIPAddress.0) : \'%s\'', $ip_address));
    $self->{output}->output_add(long_msg => sprintf('Technology (CONEL-MOBILE-MIB::mobileTechnology.0) : \'%s\'', $technology));
    $self->{output}->output_add(long_msg => sprintf('Card (CONEL-MOBILE-MIB::mobileCard.0) : \'%s\'', $card));
    $self->{output}->output_add(long_msg => sprintf('Registration (CONEL-MOBILE-MIB::mobileRegistration.0) : \'%s\'', $registration));
    $self->{output}->output_add(long_msg => sprintf('Registration (CONEL-MOBILE-MIB::mobilePLMN.0) : \'%s\'', $plmn));
    $self->{output}->output_add(long_msg => sprintf('Registration (CONEL-MOBILE-MIB::mobileCell.0) : \'%s\'', $cell));

    # "Graph" card slor
    my $mon_cardSlot = ($result->{$oid_mobileCard} + 1);
    $self->{output}->perfdata_add(label => 'card', unit => 'slt', value => $mon_cardSlot, min => 0);
    
    # Channels
    my $channel = $result->{$oid_mobileChannel};
    my $channel_signal = $result->{$oid_mobileSignalStrength};
    if ($channel ne "" && $channel_signal != 0)
    {
        $self->{output}->output_add(severity => 'OK',
		                    short_msg => sprintf('Channel: \'%s\' - Signal strength : %d dB',
					                 $channel,
							 $channel_signal));
        $self->{output}->perfdata_add(label => 'signal', unit => 'dB', value => $channel_signal, min => -109, max => -53);
	$self->{output}->output_add(long_msg => sprintf('Channel (CONEL-MOBILE-MIB::mobileChannel.0) : \'%s\' - Signal (CONEL-MOBILE-MIB::mobileSignalStrength.0) : %d dB', $channel, $channel_signal));
    }
    
    my $channel_N1 = $result->{$oid_mobileChannelN1};
    my $channel_signal_N1 = $result->{$oid_mobileSignalStrengthN1};
    if ($channel_N1 ne "" && $channel_signal_N1 != 0)
    {
        $self->{output}->output_add(severity => 'OK',
	                            short_msg => sprintf('Channel N1: \'%s\' - Signal strength N1: %d',
	                                                 $channel_N1,
	                                                 $channel_signal_N1));
	$self->{output}->perfdata_add(label => 'signal', unit => 'dB', value => $channel_signal_N1, min => -109, max => -53);
	$self->{output}->output_add(long_msg => sprintf('Channel N1 (CONEL-MOBILE-MIB::mobileChannelN1.0) : \'%s\' - Signal (CONEL-MOBILE-MIB::mobileSignalStrengthN1.0) : %d dB', $channel_N1, $channel_signal_N1));
    }
    
    my $channel_N2 = $result->{$oid_mobileChannelN2};
    my $channel_signal_N2 = $result->{$oid_mobileSignalStrengthN2};
    if ($channel_N2 ne "" && $channel_signal_N2 != 0)
    {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf('Channel N2: \'%s\' - Signal strength N2: %d',
                                                         $channel_N2,
                                                         $channel_signal_N2));
        $self->{output}->perfdata_add(label => 'signal', unit => 'dB', value => $channel_signal_N2, min => -109, max => -53);
        $self->{output}->output_add(long_msg => sprintf('Channel N2 (CONEL-MOBILE-MIB::mobileChannelN2.0) : \'%s\' - Signal (CONEL-MOBILE-MIB::mobileSignalStrengthN2.0) : %d dB', $channel_N2, $channel_signal_N2));
    }

    my $channel_N3 = $result->{$oid_mobileChannelN3};
    my $channel_signal_N3 = $result->{$oid_mobileSignalStrengthN3};
    if ($channel_N3 ne "" && $channel_signal_N3 != 0)
    {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf('Channel N3: \'%s\' - Signal strength N3: %d',
                                                         $channel_N3,
                                                         $channel_signal_N3));
        $self->{output}->perfdata_add(label => 'signal', unit => 'dB', value => $channel_signal_N3, min => -109, max => -53);
        $self->{output}->output_add(long_msg => sprintf('Channel N3 (CONEL-MOBILE-MIB::mobileChannelN3.0) : \'%s\' - Signal (CONEL-MOBILE-MIB::mobileSignalStrengthN3.0) : %d dB', $channel_N3, $channel_signal_N3));
    }
    
    my $channel_N4 = $result->{$oid_mobileChannelN4};
    my $channel_signal_N4 = $result->{$oid_mobileSignalStrengthN4};
    if ($channel_N4 ne "" && $channel_signal_N4 != 0)
    {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf('Channel N4: \'%s\' - Signal strength N4: %d',
                                                         $channel_N4,
                                                         $channel_signal_N4));
        $self->{output}->perfdata_add(label => 'signal', unit => 'dB', value => $channel_signal_N4, min => -109, max => -53);
        $self->{output}->output_add(long_msg => sprintf('Channel N4 (CONEL-MOBILE-MIB::mobileChannelN4.0) : \'%s\' - Signal (CONEL-MOBILE-MIB::mobileSignalStrengthN4.0) : %d dB', $channel_N4, $channel_signal_N4));
    }

    my $channel_N5 = $result->{$oid_mobileChannelN5};
    my $channel_signal_N5 = $result->{$oid_mobileSignalStrengthN5};
    if ($channel_N5 ne "" && $channel_signal_N5 != 0)
    {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf('Channel N5: \'%s\' - Signal strength N5: %d',
                                                         $channel_N5,
                                                         $channel_signal_N5));
        $self->{output}->perfdata_add(label => 'signal', unit => 'dB', value => $channel_signal_N5, min => -109, max => -53);
        $self->{output}->output_add(long_msg => sprintf('Channel N5 (CONEL-MOBILE-MIB::mobileChannelN5.0) : \'%s\' - Signal (CONEL-MOBILE-MIB::mobileSignalStrengthN5.0) : %d dB', $channel_N5, $channel_signal_N5));
    }
    
    # Uptime
    my $value = $result->{$oid_mobileUpTime};
    $value = floor($value / 100);
    $self->{output}->perfdata_add(label => 'uptime', unit => 's',
                                  value => $value,
                                  min => 0);
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("System uptime is: %s",
                                                     centreon::plugins::misc::change_seconds(value => $value, start => 'd')),
				long_msg => sprintf("System Uptime (CONEL-MOBILE-MIB::mobileUpTime) : %s",
				                     centreon::plugins::misc::change_seconds(value => $value)));
    
    # Signal Quality
    my $signal_quality = $result->{$oid_mobileSignalQuality};
    $self->{output}->perfdata_add(label => 'signal_quality', unit => 'dB', value => $signal_quality);
    $self->{output}->output_add(severity => 'OK', short_msg => sprintf("Signal quality : %s", $signal_quality),
	                                          long_msg => sprintf("Signal quality (CONEL-MOBILE-MIB::mobileSignalQuality) : %s dB", $signal_quality));

    # Latency
    my $latency = $result->{$oid_mobileLatency};
    $self->{output}->perfdata_add(label => 'latency', unit => 's',
	                          value => $latency,
				  min => 0);
    $self->{output}->output_add(severity => 'OK', short_msg => sprintf("Latency : %s", $latency),
				long_msg => sprintf("Latency (CONEL-MOBILE-MIB::mobileLatency) : %s", $latency));

    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Conel Mobile Router mobile infos (CONEL-MOBILE-MIB).

=over 8

=item B<--warning>

Threshold warning .

=item B<--critical>

Threshold critical.

=back

=cut

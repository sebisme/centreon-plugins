#
# Copyright 2017 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package network::alcatel::6900::snmp::mode::transceiverddm;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "interface:s"   => { name => 'interface' },
                                  "warning:s"     => { name => 'warning', default => '' },
                                  "critical:s"    => { name => 'critical', default => '' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
	my ($self, %options) = @_;
	$self->{snmp} = $options{snmp};

	my $oid_ddmTemperature = '.1.3.6.1.4.1.6486.801.1.2.1.5.1.1.2.5.1.1';
	my $oid_ddmSupplyVoltage = '.1.3.6.1.4.1.6486.801.1.2.1.5.1.1.2.5.1.6';
	my $oid_ddmTxBiasCurrent = '.1.3.6.1.4.1.6486.801.1.2.1.5.1.1.2.5.1.11';
	my $oid_ddmTxOutputPower = '.1.3.6.1.4.1.6486.801.1.2.1.5.1.1.2.5.1.16';
	my $oid_ddmRxOpticalPower = '.1.3.6.1.4.1.6486.801.1.2.1.5.1.1.2.5.1.21';

	my $result = $self->{snmp}->get_multiple_table(oids => [
		                                                    { oid => $oid_ddmTemperature },
		                                                    { oid => $oid_ddmSupplyVoltage },
		                                                    { oid => $oid_ddmTxBiasCurrent },
		                                                    { oid => $oid_ddmTxOutputPower },
		                                                    { oid => $oid_ddmRxOpticalPower },
		                                                   ], nothing_quit => 1);

	foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_ddmTemperature}})) {
		$oid =~ /^$oid_ddmTemperature\.(.*)$/;
		my $if = $1;
		next if (defined($self->{option_results}->{interface}) && $self->{option_results}->{interface} != $if);
		my $ddmTemperature = $result->{$oid_ddmTemperature}->{$oid_ddmTemperature.'.'.$if};
		my $ddmSupplyVoltage = $result->{$oid_ddmSupplyVoltage}->{$oid_ddmSupplyVoltage.'.'.$if};
		my $ddmTxBiasCurrent = $result->{$oid_ddmTxBiasCurrent}->{$oid_ddmTxBiasCurrent.'.'.$if};
		my $ddmTxOutputPower = $result->{$oid_ddmTxOutputPower}->{$oid_ddmTxOutputPower.'.'.$if};
		my $ddmRxOpticalPower = $result->{$oid_ddmRxOpticalPower}->{$oid_ddmRxOpticalPower.'.'.$if};
		$self->{output}->output_add(severity => 'OK',
			                        short_msg => sprintf("interface %s => temperature : %.3f C, voltage : %.3f V, current : %.3f mA, output %.3f dBm, input : %.3f dBm",
			                        	                 $if,
			                        	                 $ddmTemperature / 1000,
			                        	                 $ddmSupplyVoltage / 1000,
			                        	                 $ddmTxBiasCurrent / 1000,
			                        	                 $ddmTxOutputPower / 1000,
			                        	                 $ddmRxOpticalPower / 1000));
		$self->{output}->perfdata_add(label => 'temp_'.$if, unit => 'C', value => $ddmTemperature / 1000, min => 0);
		$self->{output}->perfdata_add(label => 'voltage_'.$if, unit => 'V', value => $ddmSupplyVoltage / 1000, min => 0);
		$self->{output}->perfdata_add(label => 'current_'.$if, unit => 'mA', value => $ddmTxBiasCurrent / 1000, min => 0);
		$self->{output}->perfdata_add(label => 'output_'.$if, unit => 'dBm', value => $ddmTxOutputPower / 1000);
		$self->{output}->perfdata_add(label => 'input_'.$if, unit => 'dBm', value => $ddmRxOpticalPower / 1000);
	}

	$self->{output}->display();
	$self->{output}->exit();
}

1;

__END__

=head1 MODE

Check interface ddm transceiver usage (ALCATEL-IND1-PORT-MIB::ddmInfoTable).

=over 8

=item B<--interface>

If set, limit the output to this interface's id

=item B<--warning>

Threshold warning in percent (1m,1h).

=item B<--critical>

Threshold critical in percent (1m,1h).

=back

=cut
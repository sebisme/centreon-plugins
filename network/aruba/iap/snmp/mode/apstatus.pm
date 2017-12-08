#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package network::aruba::iap::snmp::mode::apstatus;

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
                                    "filter-name:s"           => { name => 'filter_name' },
                                    "warning:s"               => { name => 'warning', },
                                    "critical:s"              => { name => 'critical', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_aiAccessPointTable = '.1.3.6.1.4.1.14823.2.3.3.1.2.1';
    my $oid_aiAPMACAddress = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.1';
    my $oid_aiAPName = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.2';
    my $oid_aiAPIPAddress = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.3';
    my $oid_aiAPSerialNum = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.4';
    my $oid_aiAPModel = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.5';
    my $oid_aiAPModelName = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.6';
    my $oid_aiAPCPUUtilization = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.7';
    my $oid_aiAPMemoryFree = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.8';
    my $oid_aiAPUptime = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.9';
    my $oid_aiAPTotalMemory = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.10';
    my $oid_aiAPStatus = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.11';

    $self->set_oids_status;

    my $result = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_aiAPName },
                                                            { oid => $oid_aiAPMACAddress },
                                                            { oid => $oid_aiAPIPAddress },
                                                            { oid => $oid_aiAPSerialNum },
                                                            { oid => $oid_aiAPStatus },
                                                        ], nothing_quit => 1);

    my $ap_total_count = scalar(keys %{$result->{$oid_aiAPName}});
    
    my $ap_count = 0;
    my $up_iaps = 0;
    my $down_iaps = 0;
    my $down_iaps_name = '';
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_aiAPStatus}})) {
        $oid =~ /^$oid_aiAPStatus\.(.*)$/;
        my $ap_id = $1;
        my $apname = $result->{$oid_aiAPName}->{$oid_aiAPName.'.'.$ap_id};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $apname !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add('long_msg' => "skipping  '" . $apname . "': no matching filter.", debug => 1);
            next;
        }
        my $apmac = $self->convert_decimal_to_hexstring(string => $ap_id);
        my $apip = $result->{$oid_aiAPIPAddress}->{$oid_aiAPIPAddress.'.'.$ap_id};
        my $apserial = $result->{$oid_aiAPSerialNum}->{$oid_aiAPSerialNum.'.'.$ap_id};
        my $apstatus = $result->{$oid_aiAPStatus}->{$oid_aiAPStatus.'.'.$ap_id};
        $ap_count++;
        if ($apstatus eq 2) { $down_iaps++; }
        if ($apstatus eq 1) { $up_iaps++; }
        
        my $apstatustxt = $self->{oid_aiAPStatus_mapping}->{$apstatus};
        $self->{output}->output_add('long_msg' => sprintf('%s is %s. IP address %s - MAC address %s - Serial number : %s',
                                                    $apname,
                                                    $apstatustxt,
                                                    $apip,
                                                    $apmac,
                                                    $apserial
                                                ));
    }
    my $exit = $self->{perfdata}->threshold_check(value => $ap_count,
                                                  threshold => [
                                                    { label => 'critical', exit_litteral => 'critical' },
                                                    { label => 'warning', exit_litteral => 'warning' }
                                                  ]);

    $self->{output}->output_add('short_msg' => $ap_count.' AP found', severity => $exit);
    $self->{output}->perfdata_add(label => 'apcount',
                                  unit => undef,
                                  value => $ap_count,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0,
                                  max => undef);
    if ($ap_count > $up_iaps) {
        $self->{output}->output_add(severity => 'warning', short_msg => $ap_count.' AP found.'.$down_iaps.' IAP down');
    }
    $self->{output}->display();
    $self->{output}->exit();
}

sub convert_decimal_to_hexstring {
    my ($self, %options) = @_;
    my $decimac = $options{string};
    my @decimac = split /\./, $decimac;
    my @mac = ();
    foreach my $num (@decimac) {
        push(@mac,sprintf('%x', $num));
    }
    return join ':', @mac;
}

sub set_oids_status {
    my ($self, %options) = @_;
    $self->{oid_aiAPStatus_mapping} = { 1 => 'up', 2 => 'down' };
}

1;

__END__

=head1 MODE

Check AP count (aruba-systemext).

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=back

=cut
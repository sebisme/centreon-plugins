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

package network::aruba::iap::mode::networkcount;

use Data::Dumper;
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
    my $oid_aiAPStatus = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.11';

    my $oid_aiWlanTable = '.1.3.6.1.4.1.14823.2.3.3.1.2.3';
    my $oid_aiWlanAPMACAddress = '.1.3.6.1.4.1.14823.2.3.3.1.2.3.1.1';
    my $oid_aiWlanIndex = '.1.3.6.1.4.1.14823.2.3.3.1.2.3.1.2';
    my $oid_aiWlanESSID = '.1.3.6.1.4.1.14823.2.3.3.1.2.3.1.3';
    my $oid_aiWlanMACAddress = '.1.3.6.1.4.1.14823.2.3.3.1.2.3.1.4';
    my $oid_aiWlanTxDataBytes = '.1.3.6.1.4.1.14823.2.3.3.1.2.3.1.7';
    my $oid_aiWlanRxDataBytes = '.1.3.6.1.4.1.14823.2.3.3.1.2.3.1.10';

    $self->set_oids_status;
    my $result = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_aiAPIPAddress },
                                                            { oid => $oid_aiAPName },
                                                            { oid => $oid_aiAPStatus },
                                                            { oid => $oid_aiWlanAPMACAddress },
                                                            { oid => $oid_aiWlanIndex },
                                                            { oid => $oid_aiWlanESSID },
                                                            { oid => $oid_aiWlanMACAddress },
                                                            { oid => $oid_aiWlanTxDataBytes },
                                                            { oid => $oid_aiWlanRxDataBytes },
                                                        ], nothing_quit => 1);

    my $ap_count = scalar(keys %{$result->{$oid_aiAPName}});
    $self->{all_aps} = [];

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_aiAPStatus}})) {
        $oid =~ /^$oid_aiAPStatus\.(.*)$/;
        my $ap_id = $1;
        my $apname = $result->{$oid_aiAPName}->{$oid_aiAPName.'.'.$ap_id};
        my $apip = $result->{$oid_aiAPIPAddress}->{$oid_aiAPIPAddress.'.'.$ap_id};
        my $apstatus = $result->{$oid_aiAPStatus}->{$oid_aiAPStatus.'.'.$ap_id};
        my $apstatustxt = $self->{oid_aiAPStatus_mapping}->{$apstatus};
        my $ap = {name => $apname, instance => $ap_id, status => $apstatustxt, ip => $apip, mac => $self->convert_decimal_to_hexstring(string => $ap_id)};
        push @{$self->{all_aps}}, $ap;
    }
    my $client_count = scalar(keys %{$result->{$oid_aiWlanESSID}});
    $self->{all_networks} = [];
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_aiWlanESSID}})) {
        $oid =~ /^$oid_aiWlanESSID\.(.*)\.(.*)$/;
        my $instance = $1.'.'.$2;
        my $oidindex = $2;
        my $oidapmc = $1;
        my $wlanESSID = $result->{$oid_aiWlanESSID}->{$oid_aiWlanESSID.'.'.$instance};
        my $wlanIndex = $result->{$oid_aiWlanIndex}->{$oid_aiWlanIndex.'.'.$instance};
        my $wlanMAC = $result->{$oid_aiWlanMACAddress}->{$oid_aiWlanMACAddress.'.'.$instance};
        my $wlanApMAC = $result->{$oid_aiWlanAPMACAddress}->{$oid_aiWlanAPMACAddress.'.'.$instance};
        my $wlanTxDataBytes = $result->{$oid_aiWlanTxDataBytes}->{$oid_aiWlanTxDataBytes.'.'.$instance};
        my $wlanRxDataBytes = $result->{$oid_aiWlanRxDataBytes}->{$oid_aiWlanRxDataBytes.'.'.$instance};
        # my $wlanAp = $self->get_ap_name_from_mac($wlanApMAC);
        my $wlan = {essid => $wlanESSID, index => $wlanIndex, instance => $instance, mac => $self->convert_decimal_to_hexstring(string => $instance), ap => $self->convert_decimal_to_hexstring(string => $oidapmc), apmac => $wlanApMAC};
        push @{$self->{all_networks}}, $wlan;
    }
    # TODO : remove print / dumper / exit and format output nicely
    print Dumper($self->{all_networks});
    exit();
    foreach my $ap (@{$self->{all_aps}}) {
        my $apname = $ap->{name};
        foreach my $client (@{$self->{all_clients}}) {
            next if ($client->{apip} ne $ap->{ip});
            my $apsid = $ap->{mac};
            $apsid =~ s/[:]//g;
            $self->{output}->output_add('long_msg' => 'Client '.$client->{name}.' is connected on ap '.$ap->{name}.' with IP address '.$client->{ip}.' on '.$client->{os}.' ('.$apsid.')');
        }
    }
    $self->{output}->display();
    $self->{output}->exit();
}

sub set_oids_status {
    my ($self, %options) = @_;
    $self->{oid_aiAPStatus_mapping} = { 1 => 'up', 2 => 'down' };
}

sub count_aps {
    my ($self, %options) = @_; 
}

sub get_ap_name_from_ip {
    my ($self, $ip) = @_;
    
    foreach my $ap (@{$self->{all_aps}}) {
        if ($ap->{ip} eq $ip) { return $ap->{name}; }
    }
}
sub get_ap_name_from_mac {
    my ($self, $mac) = @_;
    
    foreach my $ap (@{$self->{all_aps}}) {
        if ($ap->{mac} eq $mac) { return $ap->{name}; }
    }
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

1;

__END__

=head1 MODE

Check AP networks count.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=back

=cut
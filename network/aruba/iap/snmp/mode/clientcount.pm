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

package network::aruba::iap::snmp::mode::clientcount;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

use Data::Dumper;

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
    my $oid_aiAPStatus = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.11';

    my $oid_aiClientTable = '.1.3.6.1.4.1.14823.2.3.3.1.2.4';
    my $oid_aiClientMACAddress = '.1.3.6.1.4.1.14823.2.3.3.1.2.4.1.1';
    my $oid_aiClientIPAddress = '.1.3.6.1.4.1.14823.2.3.3.1.2.4.1.3';
    my $oid_aiClientAPIPAddress = '.1.3.6.1.4.1.14823.2.3.3.1.2.4.1.4';
    my $oid_aiClientName = '.1.3.6.1.4.1.14823.2.3.3.1.2.4.1.5';
    my $oid_aiClientOperatingSystem = '.1.3.6.1.4.1.14823.2.3.3.1.2.4.1.6';
    my $oid_aiClientUptime = '.1.3.6.1.4.1.14823.2.3.3.1.2.4.1.16';

    $self->set_oids_status;
    my $result = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_aiAPIPAddress },
                                                            { oid => $oid_aiAPName },
                                                            { oid => $oid_aiAPStatus },
                                                            { oid => $oid_aiClientMACAddress },
                                                            { oid => $oid_aiClientIPAddress },
                                                            { oid => $oid_aiClientAPIPAddress },
                                                            { oid => $oid_aiClientName },
                                                            { oid => $oid_aiClientOperatingSystem },
                                                        ], nothing_quit => 1);

    my $ap_count = scalar(keys %{$result->{$oid_aiAPName}});
    $self->{all_aps} = [];
    $self->{excluded_aps} = [];
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_aiAPStatus}})) {
        $oid =~ /^$oid_aiAPStatus\.(.*)$/;
        my $ap_id = $1;
        my $apname = $result->{$oid_aiAPName}->{$oid_aiAPName.'.'.$ap_id};
        my $apip = $result->{$oid_aiAPIPAddress}->{$oid_aiAPIPAddress.'.'.$ap_id};
        my $apstatus = $result->{$oid_aiAPStatus}->{$oid_aiAPStatus.'.'.$ap_id};
        my $apstatustxt = $self->{oid_aiAPStatus_mapping}->{$apstatus};
        my $ap = {name => $apname, instance => $ap_id, status => $apstatustxt, ip => $apip, mac => $self->convert_decimal_to_hexstring(string => $ap_id)};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $apname !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add('long_msg' => "skipping  '" . $apname . "': no matching filter.", debug => 1);
            push @{$self->{excluded_aps}}, $ap;
            next;
        }
        push @{$self->{all_aps}}, $ap;
    }

    my $client_count = scalar(keys %{$result->{$oid_aiClientName}});
    $self->{all_clients} = [];
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_aiClientName}})) {
        $oid =~ /^$oid_aiClientName\.(.*)$/;
        my $instance = $1;
        my $clientname = $result->{$oid_aiClientName}->{$oid_aiClientName.'.'.$instance};
        my $clientip = $result->{$oid_aiClientIPAddress}->{$oid_aiClientIPAddress.'.'.$instance};
        my $clientapip = $result->{$oid_aiClientAPIPAddress}->{$oid_aiClientAPIPAddress.'.'.$instance};
        my $clientmac = $self->convert_decimal_to_hexstring(string => $instance);
        my $clientos = $result->{$oid_aiClientOperatingSystem}->{$oid_aiClientOperatingSystem.'.'.$instance};
        my $clientap = $self->get_ap_name_from_ip($clientapip);
        my $client = {name => $clientname, ip => $clientip, mac => $clientmac, instance => $instance, os => $clientos, ap => $clientap, apip => $clientapip};
        push @{$self->{all_clients}}, $client;
    }
    
    # print Dumper($self->{all_clients});
    # print Dumper($self->{all_aps});
    
    my $allccnt;
    foreach my $ap (@{$self->{all_aps}}) {
        my $ccnt = 0;
        
        my $apname = $ap->{name};
        my $apmac = $ap->{mac};
        # $apmac =~ s/[:]//g;
        my $apshortname = lc $ap->{name};
        $apshortname =~ s/[-_\s]//g;

        foreach my $client (@{$self->{all_clients}}) {
            next if ($client->{apip} ne $ap->{ip});

            my $clientname = $client->{name};
            my $clientmac = $client->{mac};
            # $clientmac =~ s/[:]//g;
            my $clientshortname = lc $client->{name};
            $clientshortname =~ s/[-_\s]//g;
            
            $self->{output}->output_add('long_msg' => sprintf("Client %s is connected on ap '%s' (%s) with IP address %s on %s (%s).",
                                                        $clientname ne '' ? $clientname : 'with unknown name',
                                                        $apname ne '' ? $apname : 'unknown',
                                                        $apmac,
                                                        $client->{ip},
                                                        $client->{os} ne '' ? $client->{os} : 'unknown system',
                                                        $clientmac
                                                    ));
            $ccnt++;
            $allccnt++;
        }
        $self->{output}->perfdata_add(label => 'ap_'.$apshortname,
                                      unit => undef,
                                      value => $ccnt,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0,
                                      max => undef);
    }

    my $exit = $self->{perfdata}->threshold_check(value => $allccnt,
                                                  threshold => [
                                                                { label => 'critical', exit_litteral => 'critical' },
                                                                { label => 'warning', exit_litteral => 'warning' }
                                                            ]);
    $self->{output}->output_add('short_msg' => $allccnt.' Clients connected', severity => $exit);
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

Check AP client count.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=back

=cut
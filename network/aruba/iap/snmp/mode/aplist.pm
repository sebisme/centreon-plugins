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

package network::aruba::iap::snmp::mode::aplist;
  
use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => defined($options{package}) ? $options{package} : __PACKAGE__, %options);
    bless $self, $class;
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "filter-name:s"        => { name => 'filter_name' },
                                });
    $self->{ap_id_selected} = [];

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    # TODO : check options
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

    $self->manage_selection();
    my $result = $self->get_additional_information();

    foreach (sort @{$self->{ap_id_selected}}) {
        my $ap_name = $result->{$oid_aiAPName . '.' . $_};
        my $status = $result->{$oid_aiAPStatus . '.' . $_};
        
        my $statstr = '';
        $statstr = $statstr . ' - status is ';
        if ($status eq 1) {
            $statstr = $statstr . 'UP.';
        }
        else {
            $statstr = $statstr . 'DOWN.';
        }
        
        $self->{output}->output_add(long_msg => $ap_name.$statstr);
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List AP:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_aiAPName = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.2';
    my $oid_aiAPStatus = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.11';
    my $oids = [{ oid => $oid_aiAPName }]; # , { oid => $oid_bsnAPOperationStatus }, { oid => $oid_bsnAPAdminStatus }];

    $self->{datas} = {};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $oids);
    $self->{datas}->{all_ids} = [];
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_aiAPName}})) {
        next if ($key !~ /^$oid_aiAPName\.(.*)$/);
        $self->{datas}->{$oid_aiAPName . "_" . $1} = $self->{output}->to_utf8($self->{results}->{$oid_aiAPName}->{$key});
        push @{$self->{datas}->{all_ids}}, $1;
    }

    if (scalar(@{$self->{datas}->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't get any AP...");
        $self->{output}->option_exit();
    }

    # Execute some filter checks
    foreach (@{$self->{datas}->{all_ids}}) {
        my $filtered_name = $self->{datas}->{$oid_aiAPName . "_" . $_};
        next if (!defined($filtered_name));
        if (!defined($self->{option_results}->{filter_name})) {
            push @{$self->{ap_id_selected}}, $_;
            next;
        }
        if ($filtered_name =~ /$self->{option_results}->{filter_name}/) {
            push @{$self->{ap_id_selected}}, $_;
        }
    }

    if (scalar(@{$self->{ap_id_selected}}) <= 0 && !defined($options{disco})) {
        $self->{output}->add_option_msg(short_msg => "No AP found");
        $self->{output}->option_exit();
    }
}

sub get_additional_information {
    my ($self, %options) = @_;

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

    my $oids = [];
    push @$oids, $oid_aiAPName;
    push @$oids, $oid_aiAPIPAddress;
    push @$oids, $oid_aiAPSerialNum;
    push @$oids, $oid_aiAPModel;
    push @$oids, $oid_aiAPModelName;
    push @$oids, $oid_aiAPCPUUtilization;
    push @$oids, $oid_aiAPMemoryFree;
    push @$oids, $oid_aiAPUptime;
    push @$oids, $oid_aiAPTotalMemory;
    push @$oids, $oid_aiAPStatus;

    $self->{snmp}->load(oids => $oids, instances => $self->{ap_id_selected}, instance_regexp => '(.*)$');
    return $self->{snmp}->get_leef();
}

sub disco_format {
    my ($self, %options) = @_;

    my $names = ['name', 'ip', 'model', 'status'];
    $self->{output}->add_disco_format(elements => $names);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_aiAPName = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.2';
    my $oid_aiAPIPAddress = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.3';
    my $oid_aiAPModelName = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.6';
    my $oid_aiAPUptime = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.9';
    my $oid_aiAPStatus = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.11';

    $self->manage_selection(disco => 1);
    return if (scalar(@{$self->{ap_id_selected}}) == 0);

    my $result = $self->get_additional_information();
    foreach (sort @{$self->{ap_id_selected}}) {
        my $ap_name = $result->{$oid_aiAPName . '.' . $_};
        my $ap_ip = $result->{$oid_aiAPIPAddress . '.' . $_};
        my $ap_model = $result->{$oid_aiAPModelName . '.' . $_};
        my $ap_status = $result->{$oid_aiAPStatus . '.' . $_};
        
        my $opstr;
        if ($ap_status == 1) { $opstr = 'up'; } else { $opstr = 'down'; }
        $self->{output}->add_disco_entry(name => $ap_name,
                                         ip => $ap_ip,
                                         model => $ap_model,
                                         status => $opstr);
    }
}

1;
  
__END__

=head1 MODE

Get list of connected AP

=over 8

=item B<--filter-name>

Filter AP name (can be a regexp)

=back

=cut
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

package centreon::common::airespace::snmp::mode::aplist;
  
use base qw(centreon::plugins::mode);

use Data::Dumper;

use strict;
use warnings;

my %ap_type = (
      1  => 'ap1000',
      2  => 'ap1030',
      3  => 'mimo',
      4  => 'unknown',
      5  => 'ap1100',
      6  => 'ap1130',
      7  => 'ap1240',
      8  => 'ap1200',
      9  => 'ap1310',
      10 => 'ap1500',
      11 => 'ap1250',
      12 => 'ap1505',
      13 => 'ap3201',
      14 => 'ap1520',
      15 => 'ap800',
      16 => 'ap1140',
      17 => 'ap800agn',
      18 => 'ap3500i',
      19 => 'ap3500e',
      20 => 'ap1260',
      21 => 'ap1040',
      22 => 'ap1550',
      23 => 'ap602i',
      24 => 'ap3500p',
      25 => 'ap802gn',
      26 => 'ap802agn',
      27 => 'ap3600i',
      28 => 'ap3600e',
      29 => 'ap2600i',
      30 => 'ap2600e',
      31 => 'ap802hagn',
      32 => 'ap1600i',
      33 => 'ap1600e',
      34 => 'ap702e',
      35 => 'ap702i',
      36 => 'ap3600p',
      37 => 'ap1530i',
      38 => 'ap1530e',
      39 => 'ap3700e',
      40 => 'ap3700i',
      41 => 'ap3700p',
      42 => 'ap2700e',
      43 => 'ap2700i',
      44 => 'ap702w',
      45 => 'wap2600i',
      46 => 'wap2600e',
      47 => 'wap1600i',
      48 => 'wap1600e',
      49 => 'wap702i',
      50 => 'wap702e',
      51 => 'ap1700i',
      52 => 'ap1700e',
      53 => 'ap1570e',
      54 => 'ap1570i',
      55 => 'ap1852e',
      56 => 'ap1852i',
      57 => 'ap1832i',
      58 => 'unreported',
      59 => 'apmr24',
      60 => 'ap3702',
      61 => 'ap1802i',
      62 => 'ap1810w',
      63 => 'apoeap1810',
      64 => 'ap3802e',
      65 => 'ap3802i',
      66 => 'ap3802p',
      67 => 'ap3802q',
      68 => 'ap2802e',
      69 => 'ap2802i',
      70 => 'ap2802q',
      71 => 'ap1815w',
      72 => 'apoeap1815',
      73 => 'ap1815I',
      74 => 'ap1562e',
      75 => 'ap1562i',
      76 => 'ap1562d',
      77 => 'ap1562ps',
      78 => 'ap1800I',
      79 => 'ap1800S',
      80 => 'ap1815M',
      81 => 'ap1542D',
      82 => 'ap1542I',
      83 => 'ap1815TSN'
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => defined($options{package}) ? $options{package} : __PACKAGE__, %options);
    bless $self, $class;
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "filter-name:s"        => { name => 'filter_name' },
                                    "add-extra-oid:s@"     => { name => 'add_extra_oid' },
                                });
    $self->{ap_id_selected} = [];

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{extra_oids} = {};
    foreach (@{$self->{option_results}->{add_extra_oid}}) {
        next if ($_ eq '');
        my ($name, $oid, $matching) = split /,/;
        $matching = '%{instance}$' if (!defined($matching));
        if (!defined($oid) || $oid !~ /^(\.\d+){1,}$/ || $name eq '') {
            $self->{output}->add_option_msg(short_msg => "Wrong syntax for add-extra-oid '" . $_ . "' option.");
            $self->{output}->option_exit();
        }
        $self->{extra_oids}->{$name} = { oid => $oid, matching => $matching };
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_bsnAPName = ".2.3.6.1.4.1.14179.2.2.1.1.3";
    my $oid_bsnAPModel = ".1.3.6.1.4.1.14179.2.2.1.1.16";
    my $oid_bsnAPType = ".1.3.6.1.4.1.14179.2.2.1.1.22";
    my $oid_bsnAPLocation = ".1.3.6.1.4.1.14179.2.2.1.1.4";
    my $oid_bsnAPOperationStatus = ".1.3.6.1.4.1.14179.2.2.1.1.6";
    my $oid_bsnAPAdminStatus = ".1.3.6.1.4.1.14179.2.2.1.1.37";

    $self->manage_selection();
    my $result = $self->get_additional_information();

    foreach (sort @{$self->{ap_id_selected}}) {
        my $ap_name = $result->{$oid_bsnAPName . '.' . $_};
        my $admin_status = $result->{$oid_bsnAPAdminStatus . '.' . $_};
        my $oper_status = $result->{$oid_bsnAPOperationStatus . '.' . $_};

        my $statstr = '';
        $statstr = $statstr . ' - admin status is ';
        if ($admin_status eq 1) {
            $statstr = $statstr . 'UP.';
        }
        else {
            $statstr = $statstr . 'DOWN.';
        }
        $statstr = $statstr . ' - oper status is ';
        if ($oper_status eq 1) {
            $statstr = $statstr . 'UP.';
        }
        else {
            $statstr = $statstr . 'DOWN.';
        }

        my $extra_values = $self->get_extra_values_by_instance(instance => $_);
        my $extra_display = '';
        foreach my $name (keys %{$extra_values}) {
            $extra_display .= ' - ' . $name . ' : ' . $extra_values->{$name};
        }

        $self->{output}->output_add(long_msg => $ap_name.$statstr.$extra_display);
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List AP:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_bsnAPName = ".1.3.6.1.4.1.14179.2.2.1.1.3";
    my $oid_bsnAPOperationStatus = ".1.3.6.1.4.1.14179.2.2.1.1.6";
    my $oid_bsnAPType = ".1.3.6.1.4.1.14179.2.2.1.1.22";
    my $oid_bsnAPAdminStatus = ".1.3.6.1.4.1.14179.2.2.1.1.37";
    my $oids = [{ oid => $oid_bsnAPName }]; # , { oid => $oid_bsnAPOperationStatus }, { oid => $oid_bsnAPAdminStatus }];

    if (scalar(keys %{$self->{extra_oids}}) > 0) {
        foreach (keys %{$self->{extra_oids}}) {
            push @$oids, { oid => $self->{extra_oids}->{$_}->{oid} };
        }
    }
    
    $self->{datas} = {};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $oids);
    $self->{datas}->{all_ids} = [];
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_bsnAPName}})) {
        next if ($key !~ /^$oid_bsnAPName\.(.*)$/);
        $self->{datas}->{$oid_bsnAPName . "_" . $1} = $self->{output}->to_utf8($self->{results}->{$oid_bsnAPName}->{$key});
        push @{$self->{datas}->{all_ids}}, $1;
    }

    if (scalar(@{$self->{datas}->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't get any AP...");
        $self->{output}->option_exit();
    }

    # Execute some filter checks
    foreach (@{$self->{datas}->{all_ids}}) {
        my $filtered_name = $self->{datas}->{$oid_bsnAPName . "_" . $_};
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

    my $oid_bsnAPName = ".1.3.6.1.4.1.14179.2.2.1.1.3";
    my $oid_bsnAPModel = ".1.3.6.1.4.1.14179.2.2.1.1.16";
    my $oid_bsnAPType = ".1.3.6.1.4.1.14179.2.2.1.1.22";
    my $oid_bsnAPLocation = ".1.3.6.1.4.1.14179.2.2.1.1.4";
    my $oid_bsnAPOperationStatus = ".1.3.6.1.4.1.14179.2.2.1.1.6";
    my $oid_bsnAPAdminStatus = ".1.3.6.1.4.1.14179.2.2.1.1.37";

    my $oids = [];
    push @$oids, $oid_bsnAPName;
    push @$oids, $oid_bsnAPModel;
    push @$oids, $oid_bsnAPType;
    push @$oids, $oid_bsnAPLocation;
    push @$oids, $oid_bsnAPOperationStatus;
    push @$oids, $oid_bsnAPAdminStatus;

    $self->{snmp}->load(oids => $oids, instances => $self->{ap_id_selected}, instance_regexp => '(.*)$');
    return $self->{snmp}->get_leef();
}

sub get_extra_values_by_instance {
    my ($self, %options) = @_;
    
    my $extra_values = {};
    foreach my $name (keys %{$self->{extra_oids}}) {
        my $matching = $self->{extra_oids}->{$name}->{matching};
        $matching =~ s/%\{instance\}/$options{instance}/g;
        next if (!defined($self->{results}->{ $self->{extra_oids}->{$name}->{oid} }));
        
        my $append = '';
        foreach (keys %{$self->{results}->{ $self->{extra_oids}->{$name}->{oid} }}) {
            if (/^$self->{extra_oids}->{$name}->{oid}\.$matching/) {
                $extra_values->{$name} = '' if (!defined($extra_values->{$name}));
                $extra_values->{$name} .= $append . $self->{results}->{$self->{extra_oids}->{$name}->{oid}}->{$_};
                $append = ',';
            }
        }
    }
    return $extra_values;
}

sub disco_format {
    my ($self, %options) = @_;

    my $names = ['name', 'operStatus', 'adminStatus', 'type'];
    if (scalar(keys %{$self->{extra_oids}}) > 0) {
        push @$names, keys %{$self->{extra_oids}};
    }
    $self->{output}->add_disco_format(elements => $names);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_bsnAPName = ".1.3.6.1.4.1.14179.2.2.1.1.3";
    my $oid_bsnAPModel = ".1.3.6.1.4.1.14179.2.2.1.1.16";
    my $oid_bsnAPType = ".1.3.6.1.4.1.14179.2.2.1.1.22";
    my $oid_bsnAPLocation = ".1.3.6.1.4.1.14179.2.2.1.1.4";
    my $oid_bsnAPOperationStatus = ".1.3.6.1.4.1.14179.2.2.1.1.6";
    my $oid_bsnAPAdminStatus = ".1.3.6.1.4.1.14179.2.2.1.1.37";

    $self->manage_selection(disco => 1);
    return if (scalar(@{$self->{ap_id_selected}}) == 0);

    my $result = $self->get_additional_information();
    foreach (sort @{$self->{ap_id_selected}}) {
        my $ap_name = $result->{$oid_bsnAPName . '.' . $_};
        my $admin_status = $result->{$oid_bsnAPAdminStatus . '.' . $_};
        my $oper_status = $result->{$oid_bsnAPOperationStatus . '.' . $_};
        my $ap_type = $self->{ap_type}->{$result->{$oid_bsnAPType . '.' . $_};}

        my ($opstr, $admstr);
        if ($oper_status == 1) { $opstr = 'up'; } else { $opstr = 'down'; }
        if ($admin_status == 1) { $admstr = 'up'; } else { $admstr = 'down'; }

        my $extra_values = $self->get_extra_values_by_instance(instance => $_);
        $self->{output}->add_disco_entry(name => $ap_name,
                                         operStatus => $opstr,
                                         adminStatus => $admstr,
                                         %$extra_values);
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
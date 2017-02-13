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
package cloud::aws::ec2::mode::cpu_credit;

use base qw(centreon::plugins::mode);
use strict;
use warnings;
use centreon::plugins::misc;
use Paws;

sub new
{
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.2';
    $options{options}->add_options(
        arguments => {
            "ec2-instance:s" => {
                name => 'ec2_instance'
            },
            "warning:s" => {
                name => 'warning'
            },
            "critical:s" => {
                name => 'critical'
            }
        }
    );

    $self->{cw_metrics} = {
        namespace => 'AWS/EC2',
        metrics => [
            {
                name => 'CPUCreditUsage',
                unit => 'Count',
                perfdata => 'cpu-credit-usage',
                value_format => '%.2f',
                threshold_format => '%.2f:',
                short_msg => 'CPU Credit Usage : %s',
                long_msg => 'CPU Credit Usage : %s'
            },
            {
                name => 'CPUCreditBalance',
                unit => 'Count',
                perfdata => 'cpu-credit-balance',
                value_format => '%.2f',
                short_msg => 'CPU Credit Usage : %s',
                long_msg => 'CPU Credit Balance : %s'
            }
        ]
    };

    return $self;
}

sub check_options
{
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    my $threshold_format = $self->get_threshold_format();

    if (!$self->{option_results}->{ec2_instance}) {
        $self->{output}->add_option_msg('The instance id is request.');
        $self->{output}->option_exit();
    }
    if (!$self->{option_results}->{warning}) {
        $self->{output}->add_option_msg('The warning threshold is not defined.');
        $self->{output}->option_exit();
    }
    if (!$self->{option_results}->{critical}) {
        $self->{output}->add_option_msg('The critical threshold is not defined.');
        $self->{output}->option_exit();
    }

    if ($threshold_format ne '') {
        if (($self->{perfdata}->threshold_validate(
            label => 'warning',
            value => sprintf($threshold_format, $self->{option_results}->{warning}))) == 0)
        {
            $self->{output}->add_option_msg(
                short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'."
            );
            $self->{output}->option_exit();
        }
        if (($self->{perfdata}->threshold_validate(
            label => 'critical',
            value => sprintf($threshold_format, $self->{option_results}->{critical}))) == 0)
        {
            $self->{output}->add_option_msg(
                short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'."
            );
            $self->{output}->option_exit();
        }
    }
}

sub get_threshold_format
{
    my ($self) = @_;

    foreach my $metric (@{$self->{cw_metrics}{metrics}}) {
        if ($metric->{threshold_format}) {
            return $metric->{threshold_format};
        }
    }
    return ''
}

sub run
{
    my ($self, %options) = @_;

    my %infos = %{$self->{cw_metrics}};
    $infos{instance} = $self->{option_results}{ec2_instance};

    $options{custom}->set_perfdata($self->{perfdata});

    $options{custom}->get_metrics(%infos);
}

1;

__END__

=head1 MODE

Get the CPU credit

=over 8

=item B<--ec2-instance>

The instance id to get metrics (format: i-xxxxx)

=item B<--warning>

The threshold warning : when the cpu credit usage is lower as the threshold

=item B<--critical>

The threshold critical : when the cpu credit usage is lower as the threshold

=back

=cut

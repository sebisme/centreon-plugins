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
package centreon::common::aws::custom::awsapi;

use strict;
use warnings;

use Paws;

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(
            short_msg => "Class Custom: Need to specify 'options' argument."
        );
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(
            arguments => {
                "region:s" => {
                    name => "aws_region",
                    default => "us-east-1"
                }
            }
        );
    }
    $options{options}->add_help(
        package => __PACKAGE__,
        sections => 'REST API OPTIONS',
        once => 1
    );

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {
    my ($self, %options) = @_;

    # Manage default value
    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{mode}) {
            for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                    if (!defined($self->{option_results}->{$opt}[$i])) {
                        $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                    }
                }
            }
        }
    }
}

sub check_options {
    my ($self, %options) = @_;

    $self->{aws_region} = (defined($self->{option_results}->{aws_region})) ? $self->{option_results}->{aws_region} : undef;

    return 0;
}

sub set_perfdata {
    my ($self, $perfdata) = @_;

    $self->{perfdata} = $perfdata;
}

sub get_service {
    my ($self, $service) = @_;

    $self->{aws_service} = Paws->service(
        $service,
        region => $self->{aws_region}
    );

    return $self->{aws_service};
}

sub get_metrics {
    my ($self, %options) = @_;

    $self->get_service('CloudWatch');
    my @metrics;
    my @return;

    my $metricResult;
    my $hasValue = 0;

    foreach my $metric (@{$options{metrics}}) {
        my $value = undef;
        my $exit_code = 'ok';
        my $statistics = ['Average'];
        if ($metric->{get_min_max} && $metric->{get_min_max} == 1) {
          $statistics = ['Average', 'Minimum', 'Maximum'];
        }

        $metricResult = $self->{aws_service}->GetMetricStatistics(
            MetricName => $metric->{name},
            Namespace => $options{namespace},
            Statistics => $statistics,
            ExtendedStatistics => ['p100'],
            EndTime => DateTime->now->iso8601,
            StartTime => DateTime->now->subtract( minutes => 10 )->iso8601,
            Period => 300,
            Unit => $metric->{unit},
            Dimensions => [
                {
                    Name => $options{dimension_key},
                    Value => $options{dimension_value}
                }
            ]
        );

        my $min = $metric->{min};
        my $max = $metric->{max};
        foreach my $datapoint (@{$metricResult->{Datapoints}}) {
            $value = sprintf($metric->{value_format}, $datapoint->{Average});
            if ($metric->{get_min_max} && $metric->{get_min_max} == 1) {
              $min = sprintf($metric->{value_format}, $datapoint->{Minimum});
              $max = sprintf($metric->{value_format}, $datapoint->{Maximum});
            }
        }
        if (defined $value) {
            $hasValue = 1;
            if ($metric->{threshold_format}) {
              $self->{output}->perfdata_add(
                  label => $metric->{perfdata},
                  value => $value,
                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                  min => $min,
                  max => $max
              );
              $exit_code = $self->{perfdata}->threshold_check(
                  value     => $value,
                  threshold => [
                      {label => 'critical', exit_litteral => 'critical'},
                      {label => 'warning', exit_litteral => 'warning'}
                  ]
              );
            } else {
                $self->{output}->perfdata_add(
                    label => $metric->{perfdata},
                    value => $value,
                    min => $min,
                    max => $max
                );
            }
            $self->{output}->output_add(
                long_msg => sprintf($metric->{long_msg}, $value)
            );
            $self->{output}->output_add(
                severity  => $exit_code,
                short_msg => sprintf($metric->{short_msg}, $value)
            );
        }
    }

    if (!$hasValue) {
      $self->{output}->output_add(
          severity => 'unknown',
          short_msg => 'No metrics found for the period'
      );
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__


=head1 CUSTOMMODE

AWS Custommode for API

=over 8

=item B<--region>

The AWS region

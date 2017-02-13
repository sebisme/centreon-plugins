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
package cloud::aws::ec2::mode::list;

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
            "ec2-state:s@" => {
                name => 'ec2_state'
            },
            "ec2-tag:s@" => {
                name => 'ec2_tag'
            },
            "ec2-type:s@" => {
                name => 'ec2_type'
            },
            "ec2-subnet:s@" => {
                name => 'ec2_subnet'
            },
            "ec2-vpc:s@" => {
                name => 'ec2_vpc'
            },
            "only-spot" => {
                name => 'ec2_spot'
            }
        }
    );

    return $self;
}

sub check_options
{
  my ($self, %options) = @_;
  $self->SUPER::init(%options);
}

sub run
{
    my ($self, %options) = @_;

    $self->prepare(%options);

    my $count = scalar @{$self->{result}};

    $self->{output}->output_add(short_msg => "EC2 Instances: $count");

    $self->{output}->output_add(long_msg => "AWS service: EC2");

    foreach my $instance (@{$self->{result}}) {
      $self->{output}->output_add(
        long_msg => sprintf(
          '%s [%s, %s]',
          $instance->{id},
          $instance->{name},
          $instance->{private_ip}
        )
      );
    }

    $self->{output}->display(
        nolabel               => 1,
        force_ignore_perfdata => 1,
        force_long_output     => 1
    );
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    my $names = ['name', 'id', 'state', 'private_ip'];
    $self->{output}->add_disco_format(elements => $names);
}

sub disco_show
{
    my ($self, %options) = @_;
    $self->prepare();
    foreach my $instance (@{$self->{result}}) {
        $self->{output}->add_disco_entry(
            name    => $instance->{name},
            id      => $instance->{id},
            state   => $instance->{state},
            service => $instance->{private_ip}
        );
    }
}

sub prepare
{
    my ($self, %options) = @_;

    @{$self->{result}} = ();

    # Prepare filter query
    my @filters = ();

    if ($self->{option_results}{ec2_state} &&
        (scalar @{$self->{option_results}{ec2_state}}) > 0) {
        my %filter;
        $filter{Name} = "instance-state-name";
        $filter{Values} = $self->{option_results}{ec2_state};
        push(@filters, \%filter);
    } else {
        my %filter;
        $filter{Name} = "instance-state-name";
        $filter{Values} = ['running', 'stopped'];
        push(@filters, \%filter);
    }
    if ($self->{option_results}{ec2_tag} &&
        (scalar @{$self->{option_results}{ec2_tag}}) > 0) {
        my %filter;
        $filter{Name} = "tag";
        $filter{Values} = $self->{option_results}{ec2_tag};
        push(@filters, \%filter);
    }
    if ($self->{option_results}{ec2_type} &&
        (scalar @{$self->{option_results}{ec2_type}}) > 0) {
        my %filter;
        $filter{Name} = "instance-type";
        $filter{Values} = $self->{option_results}{ec2_type};
        push(@filters, \%filter);
    }
    if ($self->{option_results}{ec2_subnet} &&
        (scalar @{$self->{option_results}{ec2_subnet}}) > 0) {
        my %filter;
        $filter{Name} = "subnet-id";
        $filter{Values} = $self->{option_results}{ec2_subnet};
        push(@filters, \%filter);
    }
    if ($self->{option_results}{ec2_vpc} &&
        (scalar @{$self->{option_results}{ec2_vpc}}) > 0) {
        my %filter;
        $filter{Name} = "vpc-id";
        $filter{Values} = $self->{option_results}{ec2_vpc};
        push(@filters, \%filter);
    }
    if ($self->{option_results}{ec2_spot}) {
        my %filter;
        $filter{Name} = "instance-lifecycle";
        $filter{Values} = ["spot"];
        push(@filters, \%filter);
    }

    my $service = $options{custom}->get_service('EC2');

    my $result = $service->DescribeInstances(
      Filters => \@filters
    );

    foreach my $instanceArray (@{$result->{'Reservations'}}) {
        my %instance;
        my $resultInstance = $instanceArray->{Instances}[0];
        $instance{id} = $resultInstance->{InstanceId};

        # Find name
        my $name = '';
        foreach my $tag (@{$resultInstance->{Tags}}) {
            if ($tag->{Key} eq 'Name' && $tag->{Value}) {
                $name = $tag->{Value};
            }
        }
        $instance{name} = $name;
        # Find private ip address
        $instance{private_ip} = $resultInstance->{PrivateIpAddress};
        # Find public ip if exists
        my $public_ip = undef;
        if (exists $resultInstance->{PublicIpAddress}) {
          $public_ip = $resultInstance->{PublicIpAddress};
        }
        # Get the state of the instance
        $instance{state} = $resultInstance->{State}->{Name};

        push(@{$self->{result}}, \%instance);
    }
}

1;

__END__

=head1 MODE

List your EC2 Instance

=over 8

=item B<--ec2-state>

(optional) State to request (default: 'running','stopped')

=item B<--ec2-tag>

(optional) Filter by tag the list

=item B<--ec2-type>

(optional) Filter by instance type (example: t2.medium)

=item B<--ec2-subnet>

(optional) Filter by subnet id

=item B<--ec2-vpc>

(optional) Filter by vpc id

=item B<--only-spot>

(optional) List only the spot instance

=back

=cut

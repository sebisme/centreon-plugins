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
package cloud::aws::s3::mode::list;

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
    # $options{options}->add_options(
    #     arguments => {
    #         "ec2-state:s@" => {
    #             name => 'ec2_state'
    #         },
    #         "ec2-tag:s@" => {
    #             name => 'ec2_tag'
    #         },
    #         "ec2-type:s@" => {
    #             name => 'ec2_type'
    #         },
    #         "ec2-subnet:s@" => {
    #             name => 'ec2_subnet'
    #         },
    #         "ec2-vpc:s@" => {
    #             name => 'ec2_vpc'
    #         },
    #         "only-spot" => {
    #             name => 'ec2_spot'
    #         }
    #     }
    # );

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

    $self->{output}->output_add(short_msg => "S3 Bukcets: $count");

    $self->{output}->output_add(long_msg => "AWS service: S3");

    foreach my $bucket (@{$self->{result}}) {
      $self->{output}->output_add(
        long_msg => sprintf(
          '%s',
          $bucket->{name},
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

    my $names = ['name', 'creationt_date'];
    $self->{output}->add_disco_format(elements => $names);
}

sub disco_show
{
    my ($self, %options) = @_;
    $self->prepare(%options);
    foreach my $bucket (@{$self->{result}}) {
        $self->{output}->add_disco_entry(
            name    => $bucket->{name},
            creation_date => $bucket->{creation_date}
        );
    }
}

sub prepare
{
    my ($self, %options) = @_;

    @{$self->{result}} = ();

    # Remove warn for beta S3
    my $sig_bak = $SIG{__WARN__};
    local $SIG{__WARN__} = sub { };
    my $service = $options{custom}->get_service('S3');

    my $result = $service->ListBuckets();

    # Reset sig
    $SIG{__WARN__} = $sig_bak;

    foreach my $bucketArray (@{$result->{'Buckets'}}) {
        my %bucket;
        # Bucket name
        $bucket{name} = $bucketArray->{Name};
        # Get the state of the instance
        $bucket{creationt_date} = $bucketArray->{CreationDate};

        push(@{$self->{result}}, \%bucket);
    }
}

1;

__END__

=head1 MODE

List your S3 instance

=over 8

=back

=cut

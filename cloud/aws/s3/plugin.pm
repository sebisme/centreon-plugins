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

package cloud::aws::s3::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new
{
    my ($class, %options) = @_;
    my $self = $class->SUPER::new( package => __PACKAGE__, %options );
    bless $self, $class;

    $self->{version} = '0.2';
    %{$self->{modes}} = (
        'list' => 'cloud::aws::s3::mode::list',
        'size' => 'cloud::aws::s3::mode::size',
        'number_objects' => 'cloud::aws::s3::mode::number_objects'
    );

    $self->{custom_modes}{awsapi} = 'centreon::common::aws::custom::awsapi';

    return $self;
}

sub init
{
    my ($self, %options) = @_;

    $self->SUPER::init(%options);
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Amazon AWS cloud.

=over 8

For this plugins you need the perl module Paws >= 0.30.

=back

=cut

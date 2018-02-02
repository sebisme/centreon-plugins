#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package network::alcatel::6900::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
                        'cpu'               => 'network::alcatel::6900::snmp::mode::cpu',
                        'hardware'          => 'network::alcatel::6900::snmp::mode::hardware',
                        'interfaces'        => 'snmp_standard::mode::interfaces', 
                        'list-interfaces'   => 'snmp_standard::mode::listinterfaces',
                        'flash-memory'      => 'network::alcatel::6900::snmp::mode::flashmemory',
                        'memory'            => 'network::alcatel::6900::snmp::mode::memory',
                        'spanning-tree'     => 'snmp_standard::mode::spanningtree',
                        'transceiver-ddm'   => 'network::alcatel::6900::snmp::mode::transceiverddm',
                        );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Alcatel 6900 in SNMP.

=cut

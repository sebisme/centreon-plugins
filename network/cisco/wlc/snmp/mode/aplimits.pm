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

package network::cisco::wlc::snmp::mode::aplimits;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

my %map_client_protocoml = (
    1  => 'dot11a',
    2  => 'dot11b',
    3  => 'dot11g',
    4  => 'unknown',
    5  => 'mobile',
    6  => 'dot11n24',
    7  => 'dot11n5',
    8  => 'ethernet',
    9  => 'dot3',
    10 => 'dot11ac5'
);

my $oid_cldcClientProtocol = '.1.3.6.1.4.1.9.9.599.1.3.1.1.6'; # Get client protocol. 

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Cisco Wireless Lan Controller in SNMP.

=cut

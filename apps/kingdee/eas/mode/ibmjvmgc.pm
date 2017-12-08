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
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::ibmjvmgc;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
            {
            "urlpath:s"         => { name => 'url_path', default => "/easportal/tools/nagios/checkgc_j9gen.jsp" },
            "warning:s"         => { name => 'warning' },
            "critical:s"        => { name => 'critical' },
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
        
    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});

    if ($webcontent !~ /CollectionCount=\d+/mi) {
        $self->{output}->output_add(
            severity  => 'UNKNOWN',
            short_msg => "Cannot find ibm jdk j9 gc status."
        );
        $self->{output}->option_exit();
    }
    
    my ($collectioncount, $collectiontime) = (0, 0);

    ($collectioncount, $collectiontime) = ($1, $2) if ($webcontent =~ /CollectionCount=(\d+)\sCollectionTime=(\d+)/mi);

    $self->{output}->output_add(severity => "ok", short_msg => sprintf("CollectionCount: %d", $collectioncount));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("CollectionTime: %dms", $collectiontime));

    $self->{output}->perfdata_add(label => "c[CollectionCount]", unit => '',
                                  value => sprintf("%d", $collectioncount),
                                  );
    $self->{output}->perfdata_add(label => "c[CollectionTime]", unit => 'ms',
                                  value => sprintf("%d", $collectiontime),
                                  );
 
    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check EAS application jvm gc status.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkgc_j9.jsp')

=item B<--warning>

Warning Threshold for class loaded

=item B<--critical>

Critical Threshold for class unloaded

=back

=cut

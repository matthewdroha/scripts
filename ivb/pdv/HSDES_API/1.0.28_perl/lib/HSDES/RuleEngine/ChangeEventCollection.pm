#! perl

#
# HSD-ES - High Speed Database - Extremely Simple, Extremely Speedy
#
# INTEL CONFIDENTIAL
# 
# Copyright 2013 Intel Corporation All Rights Reserved. 
# 
# The source code contained or described herein and all documents related
# to the source code ("Material") are owned by Intel Corporation or its
# suppliers or licensors. Title to the Material remains with Intel
# Corporation or its suppliers and licensors. The Material contains trade
# secrets and proprietary and confidential information of Intel or its 
# suppliers and licensors. The Material is protected by worldwide copyright
# and trade secret laws and treaty provisions. No part of the Material may
# be used, copied, reproduced, modified, published, uploaded, posted,
# transmitted, distributed, or disclosed in any way without Intels
# prior express written permission.
# 
# No license under any patent, copyright, trade secret or other intellectual
# property right is granted to or conferred upon you by disclosure or
# delivery of the Materials, either expressly, by implication, inducement,
# estoppel or otherwise. Any license under such intellectual property rights
# must be express and approved by Intel in writing.
# 

use strict;
use warnings;

=head1 NAME

ChangeEventCollection
=cut

=head1 SYNOPSIS
=cut

=head1 DESCRIPTION
=cut

package HSDES::RuleEngine::ChangeEventCollection;

use Data::Dumper;

=head1 METHODS
=cut

########################################################################
=head2 new(fieldName, alwaysAfterRules)

=cut
########################################################################

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
        fieldName => shift,
	alwaysAfterRules => shift,
	changeHandlers => [ ]
    };
    bless ($self, $class);
    return $self;
}

########################################################################
=head2 handler

This is the event handler that calls the wrapped handlers,
and then the AlwaysAfterEvent actions afterwards.

=cut
########################################################################
sub handler {
    my $self = shift;
    my $newValue = shift;
    my $oldValue = shift;
    my $callback = shift;
    my $handlers = $self->{changeHandlers};
    my $remainingCallbacks = scalar @{ $handlers };

    my $runLast = sub {
	$self->{alwaysAfterRules}->executeWithCallback($callback);
    };
    my $counterProc = sub {
	if ( --$remainingCallbacks == 0 ) {
	    &{$runLast}();
	}
    };

    # assert( $remainingCallbacks > 0 );

    foreach my $handler ( @{ $handlers } ) {
	&{$handler}($newValue, $oldValue, $counterProc);
    }

}

########################################################################
=head2 registerHandler(handler)

=cut
########################################################################
sub registerHandler {
    my $self = shift;
    my $handler = shift;

    unshift @{$self->{changeHandlers}}, $handler;
}

1;

__END__

#! perl

#
# HSD-ES - High Speed Database - Extremely Simple, Extremely Speedy
#
# INTEL CONFIDENTIAL
# 
# Copyright 2012 Intel Corporation All Rights Reserved. 
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

ValueContextImpl
=cut

=head1 SYNOPSIS

A context that returns new and old values from an OnChangeEvent.
=cut

=head1 DESCRIPTION
=cut

package HSDES::RuleEngine::ValueContextImpl;

=head1 METHODS
=cut

########################################################################
=head2 new(rulesRemaining, callback)

=cut
########################################################################

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
        parentContext => shift,       	      	
	newValue => shift,
	oldValue => shift
    };
    bless ($self, $class);
    return $self;
}

########################################################################
=head2 getCurrentFieldValue

=cut
########################################################################
sub getCurrentFieldValue {
    my $self = shift;
    return $self->{newValue};
}

########################################################################
=head2 getPreviousFieldValue

=cut
########################################################################
sub getPreviousFieldValue {
    my $self = shift;
    return $self->{oldValue};
}

########################################################################
=head2 dispose

=cut
########################################################################
sub dispose {
    my $self = shift;
    $self->{parentContext}->dispose();
}

########################################################################
=head2 actionCompleted

=cut
########################################################################
sub actionCompleted {
    my $self = shift;
    $self->{parentContext}->actionCompleted();
}

1;

__END__

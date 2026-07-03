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

RuleCollection
=cut

=head1 SYNOPSIS
=cut

=head1 DESCRIPTION
=cut

package HSDES::RuleEngine::RuleCollection;

use Data::Dumper;

use HSDES::RuleEngine::CountedActionContext;

=head1 METHODS
=cut

########################################################################
=head2 new()

=cut
########################################################################

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
	rules => [ @_ ]
    };
    bless ($self, $class);
    return $self;
}

########################################################################
=head2 executeWithCallback

=cut
########################################################################
sub executeWithCallback {
    my $self = shift;
    my $callback = shift;
    my $actionsRemaining = $self->_getActionCount();

    my $context = HSDES::RuleEngine::CountedActionContext->new($actionsRemaining, $callback);
    $self->executeWithContext( $context );
    $context->dispose();
}

########################################################################
=head2 executeWithCallback

=cut
########################################################################
sub executeWithContext {
    my $self = shift;
    my $context = shift;

    foreach my $rule ( @{$self->{rules}} ) {
	$rule->execute($context);
    }
}

########################################################################
=head2 push

=cut
########################################################################
sub push {
    my $self = shift;

    push @{$self->{rules}}, @_
}

########################################################################
#
sub _getActionCount {
    my $self = shift;

    my $sum = 0;
    foreach my $rule ( @{$self->{rules}} ) {
	$sum += $rule->getActionCount();
    }
    return $sum;
}

1;

__END__

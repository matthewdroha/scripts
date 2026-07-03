#! perl

#
# HSD-ES - High Speed Database - Extremely Simple, Extremely Speedy
#
# INTEL CONFIDENTIAL
# 
# Copyright 2014 Intel Corporation All Rights Reserved. 
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

RuleEngine
=cut

=head1 SYNOPSIS
=cut

=head1 DESCRIPTION
=cut

package HSDES::RuleEngine::ConditionChecker;

use HSDES::RuleEngine::FunctionHelper;
use HSDES::RuleEngine::StringUtil;

use Data::Dumper;

=head1 METHODS
=cut

########################################################################
=head2 new(RuleEngineDelegate)

=cut
########################################################################

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = { };
    bless ($self, $class);

    $self->{delegate} = shift;

    return $self;
}

########################################################################
=head2 isConditionSatisified(condition_obj)

=cut
########################################################################

sub isConditionSatisfied {
    my $self = shift;
    my $condition_obj = shift;

    return $self->_checkSatisfiedList( @{$condition_obj->{Kids}} );
}

########################################################################
#
sub _checkSatisfiedList {
    my $self = shift;
    my @conditions = @_;

    return $self->_checkSatisfiedAndLogic(@conditions);
}

########################################################################
#
sub _checkSatisfied {
    my $self = shift;
    my $element = shift;

    my ( $class ) = ref($element) =~ /.*::(\w+)$/;

    my %lookup = ();
    $lookup{'Equals'} =	sub {
	$self->_checkSatisfiedEqualsOp($element);
    };
    $lookup{'Or'} = sub {
	$self->_checkSatisfiedOrOp($element);
    };
    $lookup{'And'} = sub {
	$self->_checkSatisfiedAndOp($element);
    };

    my $func = $lookup{$class};
    if ( defined $func ) {
	return &{$func}($element);
    } else {
	return 0;
    }
}

########################################################################
#
sub _checkSatisfiedEqualsOp {
    my $self = shift;
    my $element = shift;
    my $satisfied = 0;

    if ( defined $element->{Field} ) {
	my $current = '';
	if ( defined($element->{UseSavedValue}) && lc($element->{UseSavedValue}) eq "true" ) {
	    $current = $self->{delegate}->getSavedFieldValue( $element->{Field} );
	} else {
	    $current = $self->{delegate}->getCurrentFieldValue( $element->{Field} );
	}
	my $expected = '';
	foreach my $text ( @{$element->{Kids}} ) {
	    $expected .= $text->{Text} if ( defined $text->{Text} );
	}

	$expected = substituteParameters( $self->{delegate}, undef, $expected );

	$satisfied = 1 if (areStringsEqRegexp( $element, $satisfied, $expected, $current ));
    }

    if ( defined $element->{Negate} && lc($element->{Negate}) eq "true" ) {
	$satisfied = ! $satisfied;
    }

    return $satisfied;
}

########################################################################
#
sub _checkSatisfiedOrOp {
    my $self = shift;
    my $element = shift;

    return $self->_checkSatisfiedOrLogic(@{$element->{Kids}});
}

########################################################################
#
sub _checkSatisfiedAndOp {
    my $self = shift;
    my $element = shift;
 
    return $self->_checkSatisfiedAndLogic(@{$element->{Kids}});
}

########################################################################
#
sub _checkSatisfiedAndLogic {
    my $self = shift;
    my @conditions = @_;
    my $satisfied = 1;

    foreach ( @_ ) {
	$satisfied &= $self->_checkSatisfied($_);
	last if ( ! $satisfied );
    }

    return $satisfied;
}

########################################################################
#
sub _checkSatisfiedOrLogic {
    my $self = shift;
    my @conditions = @_;
    my $satisfied = 0;

    foreach ( @_ ) {
	$satisfied |= $self->_checkSatisfied($_);
    }

    return $satisfied;
}

1;

__END__

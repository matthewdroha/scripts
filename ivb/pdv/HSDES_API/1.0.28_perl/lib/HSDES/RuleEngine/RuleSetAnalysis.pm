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

RuleMerger
=cut

=head1 SYNOPSIS
=cut

=head1 DESCRIPTION
=cut

package HSDES::RuleEngine::RuleSetAnalysis;

use Data::Dumper;
use HSDES::RuleEngine::Exceptions;
use HSDES::Schema::RuleSet::RuleSet;
use Clone qw(clone);


=head1 METHODS
=cut

########################################################################
=head2 new(ruleSet, criteria...)

=cut
########################################################################

sub new {
    my $proto = shift;
    my $ruleSet = shift;
    my @criterion = @_;
    my $class = ref($proto) || $proto;
    my $self  = { };
    bless ($self, $class);

    HSDES::RuleEngine::Exception::InvalidArgument->throw("new: Invalid argument ruleSet")
	if ( ! defined($ruleSet) );

    $self->{'ruleSet'} = $ruleSet;
    $self->{'criteria'} = \@criterion;

    return $self;
}

########################################################################
=head2 analyze(collector)

=cut
########################################################################

sub analyze {
    my $self = shift;
    my $collector = shift;

    $collector->initialize();

    foreach my $rule ( @{$self->{ruleSet}->{Kids}} ) {
	next if ( ref($rule) =~ /Characters$/ );  # skip text nodes
	$self->_iterateRule($rule, $collector);
    }

    return $collector->getResult();
}


########################################################################
=head2 _iterateRule(rule, collector)

=cut
########################################################################

sub _iterateRule {
    my $self = shift;
    my $rule = shift;
    my $collector = shift;

    if ( $rule->{Kids} && scalar($rule->{Kids}) > 0 ) {
	foreach my $action ( @{$rule->{Kids}} ) {
	    my ( $action_class ) = ref($action) =~ /.*::(\w+)$/;
	    next if ( $action_class =~ /Characters$/ );  # skip text nodes
	    if ( $action_class eq 'MessageBox' ) {
		# Recursive iteration (messagebox)
		$self->_iterateRule($action, $collector);
	    } else {
		if ( $self->_evaluateCriteria($rule, $action) ) {
		    $collector->collect($rule, $action);
		}
	    }
	}
    } else {
	# Iterate the rule even if there are no actions
	if ( $self->_evaluateCriteria($rule, undef) ) {
	    $collector->collect($rule, undef);
	}
    }
}


########################################################################
=head2 _evaluateCriteria(rule,action)

=cut
########################################################################

sub _evaluateCriteria {
    my $self = shift;
    my $rule = shift;
    my $action = shift;
    my $result = 1;

    foreach my $c ( @{$self->{'criteria'}} ) {
	$result &= $c->check($rule,$action);
	last if ( !$result );
    }

    return $result;
}

1;

__END__

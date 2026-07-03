#! perl

#
# HSD-ES - High Speed Database - Extremely Simple, Extremely Speedy
#
# INTEL CONFIDENTIAL
# 
# Copyright 2011 Intel Corporation All Rights Reserved. 
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

ChangeManager
=cut

=head1 SYNOPSIS
=cut

=head1 DESCRIPTION
=cut

package HSDES::RuleEngine::ChangeManager;
use base qw(HSDES::RuleEngine::Events::HasName HSDES::RuleEngine::Events::HasChangeHandlers);

use Data::Dumper;


=head1 METHODS
=cut

########################################################################
=head2 new(\&callback, \(field1,...fieldN))

=cut
########################################################################

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
	callback => shift,
	changeHandlers => { },
	changeHandlersPreinitialized => 0
    };
    bless ($self, $class);

    my $fields = shift;
    if ( $fields ) {
	foreach ( @{$fields} ) {
	    $self->{changeHandlers}->{$_} = [];
	}
	$self->{changeHandlersPreinitialized} = 1;
    }
    return $self;
}

########################################################################
=head2 getName(desiredName)

=cut
########################################################################

sub getName {
    my $self = shift;
    my $desiredName = shift;

    return $desiredName if ( ! $self->{changeHandlersPreinitialized} );
    return $desiredName if ( exists( $self->{changeHandlers}->{$desiredName} ) );
    return undef;
}

########################################################################
=head2 addChangeHandler(field, \&handler)

=cut
########################################################################

sub addChangeHandler {
    my $self = shift;
    my $field = shift;
    my $handler = shift;

    push @{$self->{changeHandlers}->{$field}}, $handler;
}

########################################################################
=head2 onFieldChanged(field, newValue, oldValue)

=cut
########################################################################
sub onFieldChanged {
    my $self = shift;
    my $field = shift;
    my $newValue = shift;
    my $oldValue = shift;

    if ( !defined($self->{changeHandlers}) ||
	 !defined($self->{changeHandlers}->{$field}) ||
	 0 == scalar($self->{changeHandlers}->{$field}) ) {
	&{$self->{callback}} if ( $self->{callback} );
	return;
    }

    my $remainingCallbacks = scalar(@{$self->{changeHandlers}->{$field}});
    foreach my $handler ( @{$self->{changeHandlers}->{$field}} ) {
	&{$handler}( $newValue, $oldValue, sub {
	    if ( --$remainingCallbacks == 0 ) {
		&{$self->{callback}} if ( $self->{callback} );
	    }
	});
    }
}

1;

__END__

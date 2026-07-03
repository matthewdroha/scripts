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

package HSDES::RuleEngine::StateManager::InternalState;

use Data::Dumper;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
	visible => 1,
	enabled => 1,
	required => 0,
	unfiltered => 1,
	filter => []
    };
    bless ($self, $class);

    my $src = shift;
    if ( ref($src) && $src->isa(qw(HSDES::RuleEngine::StateManager::InternalState))) {
	$self->{visible} = $src->{visible};
	$self->{enabled} = $src->{enabled};
	$self->{required} = $src->{required};
	$self->{unfiltered} = $src->{unfiltered};
	$self->{filter} = [ @{$src->{filter}} ];
    }
    return $self;
}

=head1 NAME

StateManager
=cut

=head1 SYNOPSIS
=cut

=head1 DESCRIPTION
=cut

package HSDES::RuleEngine::StateManager;
use base qw(HSDES::RuleEngine::Events::HasName HSDES::RuleEngine::Events::HasEventSink);

use Data::Dumper;


=head1 METHODS
=cut

########################################################################
=head2 new(field1,...fieldN)

=cut
########################################################################

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
	fieldState => { },
	savedState => { },
	preinitializedState => 0
    };
    bless ($self, $class);

    if ( @_ ) {
	foreach (@_) {
	    $self->{fieldState}->{$_} = HSDES::RuleEngine::StateManager::InternalState->new();
	}
	$self->{preinitializedState} = 1;
    }

    return $self;
}

########################################################################
=head2 getFields

Returns array reference to fields that are tracked in the state manager

=cut
########################################################################

sub getFields {
    my $self = shift;
    my @keys = keys %{$self->{fieldState}};
    return \@keys;
}

########################################################################
=head2 isVisible(field)

=cut
########################################################################

sub isVisible {
    my $self = shift;
    my $field = shift;

    return $self->_getState($field)->{visible};
}

########################################################################
=head2 isEnabled(field)

=cut
########################################################################

sub isEnabled {
    my $self = shift;
    my $field = shift;

    return $self->_getState($field)->{enabled};
}

########################################################################
=head2 isRequired

=cut
########################################################################

sub isRequired {
    my $self = shift;
    my $field = shift;

    return $self->_getState($field)->{required};
}

########################################################################
=head2 isUnfiltered(field)

=cut
########################################################################

sub isUnfiltered {
    my $self = shift;
    my $field = shift;

    return $self->_getState($field)->{unfiltered};
}

########################################################################
=head2 getFilter(field)

=cut
########################################################################

sub getFilter {
    my $self = shift;
    my $field = shift;

    return @{$self->_getState($field)->{filter}};
}

########################################################################
=head2 getName(desiredName)

=cut
########################################################################

sub getName {
    my $self = shift;
    my $desiredName = shift;

    return $desiredName if ( ! $self->{preinitializedState} );
    return $desiredName if ( exists( $self->{fieldState}->{$desiredName} ) );
    return undef;
}

########################################################################
=head2 handleEvent(event)

=cut
########################################################################

sub handleEvent {
    my $self = shift;
    my $event = shift;
    my $field = $event->getTarget();

    my ( $event_class ) = ref($event) =~ /.*::(\w+)$/;

    my %handlermap = ();
    $handlermap{'VisibleStateEvent'} = sub {
	$self->_getState($field)->{visible} = $event->getState();
    };
    $handlermap{'EnabledStateEvent'} = sub {
	$self->_getState($field)->{enabled} = $event->getState();
    };
    $handlermap{'RequiredStateEvent'} = sub {
	$self->_getState($field)->{required} = $event->getState();
    };
    $handlermap{'LookupChangeEvent'} = sub {
	$self->_handleLookupChange($self->_getState($field),$event);
    };
    $handlermap{'SaveStateEvent'} = sub {
	$self->_saveState($event->getTarget());
    };
    $handlermap{'RestoreStateEvent'} = sub {
	$self->_restoreState($event->getTarget());
    };

    my $handler = $handlermap{$event_class};
    &{$handler}($event) if ( defined $handler );
}

########################################################################
#
sub _getState {
    my $self = shift;
    my $field = shift;

    if ( ! exists( $self->{fieldState}->{$field} ) ) {
	$self->{fieldState}->{$field} = HSDES::RuleEngine::StateManager::InternalState->new();
    }

    return $self->{fieldState}->{$field};
}

########################################################################
#
sub _handleLookupChange {
    my $self = shift;
    my $state = shift;
    my $event = shift;

    my %handlers = ();
    $handlers{$HSDES::RuleEngine::Events::LookupChangeEvent::DO_RELOAD} = sub {
	$state->{unfiltered} = 1;
	$state->{filter} = [];
	my @values = $event->getValues();
	my %seen = (); 
	foreach (@values) {
	    $state->{unfiltered} = 0;
	    next if ( $seen{lc($_)} );  # dup check
	    push @{$state->{filter}}, $_;
	    $seen{lc($_)} = 1;
	}
    };
    $handlers{$HSDES::RuleEngine::Events::LookupChangeEvent::DO_FILTER} = sub {
	my @values = $event->getValues();
	if ( $state->{unfiltered} ) {
	    # set up filter from scratch, as if reload
	    my %seen = ();
	    foreach (@values) {
		$state->{unfiltered} = 0;
		next if ( $seen{lc($_)} );  # dup check
		push @{$state->{filter}}, $_;
		$seen{lc($_)} = 1;
	    }
	} else {
	    # filter existing filter some more
	    my %legal = ();
	    foreach (@values) {
		$legal{lc($_)} = 1;
	    }
	    for (my $i = 0 ; $i < @{$state->{filter}} ; ) {
		if ( $legal{lc($state->{filter}->[$i])} ) {
		    ++$i;
		} else {
		    splice @{$state->{filter}}, $i, 1;
		}
	    }
	}
    };
    $handlers{$HSDES::RuleEngine::Events::LookupChangeEvent::DO_ADD} = sub {
	my @values = $event->getValues();
	if ( ! $state->{unfiltered} ) {
	    # set up filter from scratch, as if reload
	    my %seen = ();
	    foreach (@{$state->{filter}}) {
		$seen{lc($_)} = 1;
	    }
	    foreach (@values) {
		next if ( $seen{lc($_)} );  # dup check
		push @{$state->{filter}}, $_;
		$seen{lc($_)} = 1;
	    }
	}
    };

    my $changeType = $event->getChangeType();
    my $handler = $handlers{$changeType};
    &{$handler}();
}


########################################################################
#
sub _saveState {
    my $self = shift;
    my $field = shift;

    $self->{savedState}->{$field} = 
	HSDES::RuleEngine::StateManager::InternalState->new(
	    $self->_getState($field) );
}

########################################################################
#
sub _restoreState {
    my $self = shift;
    my $field = shift;

    if ( exists $self->{savedState}->{$field} ) {
	$self->{fieldState}->{$field} = 
	    HSDES::RuleEngine::StateManager::InternalState->new(
		$self->{savedState}->{$field} );
    } else {
	delete $self->{fieldState}->{$field};
    }
}

1;

__END__

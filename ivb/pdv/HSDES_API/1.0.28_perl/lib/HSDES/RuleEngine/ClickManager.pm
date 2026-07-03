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

ClickManager
=cut

=head1 SYNOPSIS
=cut

=head1 DESCRIPTION
=cut

package HSDES::RuleEngine::ClickManager;
use base qw(HSDES::RuleEngine::Events::HasName HSDES::RuleEngine::Events::HasClickHandlers);

use Data::Dumper;


=head1 METHODS
=cut

########################################################################
=head2 new(\&callback, \(button1,...buttonN))

=cut
########################################################################

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
	callback => shift,
	clickHandlers => { },
	clickHandlersPredefined => 0
    };
    bless ($self, $class);

    my $buttons = shift;
    if ( $buttons ) {
	foreach ( @{$buttons} ) {
	    $self->{clickHandlers}->{$_} = [];
	}
	$self->{clickHandlersPredefined} = 1;
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

    return $desiredName if ( ! $self->{clickHandlersPredefined} );
    return $desiredName if ( exists( $self->{clickHandlers}->{$desiredName} ) );
    return undef;
}

########################################################################
=head2 addClickHandler(button, \&handler)

=cut
########################################################################

sub addClickHandler {
    my $self = shift;
    my $button = shift;
    my $handler = shift;

    push @{$self->{clickHandlers}->{$button}}, $handler;
}

########################################################################
=head2 onButtonClicked(button)

=cut
########################################################################
sub onButtonClicked {
    my $self = shift;
    my $button = shift;

    if ( !defined($self->{clickHandlers}) ||
	 !defined($self->{clickHandlers}->{$button}) ||
	 0 == scalar($self->{clickHandlers}->{$button}) ) {
	&{$self->{callback}} if ( $self->{callback} );
	return;
    }

    my $remainingCallbacks = scalar(@{$self->{clickHandlers}->{$button}});
    foreach my $handler ( @{$self->{clickHandlers}->{$button}} ) {
	&{$handler}( sub {
	    if ( --$remainingCallbacks == 0 ) {
		&{$self->{callback}} if ( $self->{callback} );
	    }
	});
    }
}

1;

__END__

#! perl -w

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

=head1 NAME

RuleEngineDelegate
=cut

=head1 SYNOPSIS
=cut

=head1 DESCRIPTION
=cut

package HSDES::RuleEngineDelegate;

=head1 INTERFACE METHODS
=cut

########################################################################
=head2 new()

=cut
########################################################################

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);
    return $self;
}

########################################################################
=head2 messageBox($$$$$$$$)

=cut
########################################################################

sub messageBox {
    die "Implement this method";
}

########################################################################
=head2 errorIfRequiredFieldsMissing($)

=cut
########################################################################

sub errorIfRequiredFieldsMissing {
    die "Implement this method";
}

########################################################################
=head2 errorMessage($$)

=cut
########################################################################

sub errorMessage {
    die "Implement this method";
}

########################################################################
=head2 evaluateFunction($$)

=cut
########################################################################

sub evaluateFunction {
    die "Implement this method";
}

########################################################################
=head2 getCurrentFieldValue($)

=cut
########################################################################

sub getCurrentFieldValue {
    die "Implement this method";
}

########################################################################
=head2 getSavedFieldValue($)

=cut
########################################################################

sub getSavedFieldValue {
    die "Implement this method";
}

########################################################################
=head2 runServerAction($$$$)
    Arg 1: Server action name (string)
    Arg 2: Current field values (hash)
    Arg 3: Saved field values (hash)
    Arg 4: Continuation (sub reference)

=cut
########################################################################

sub runServerAction {
    die "Implement this method";
}

1;

__END__

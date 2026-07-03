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

FieldChangeCriteria
=cut

=head1 SYNOPSIS
=cut

=head1 DESCRIPTION
=cut

package HSDES::RuleEngine::Analysis::FieldChangeCriteria;

use base qw(HSDES::RuleEngine::Analysis::AnalysisCriteria);

use Data::Dumper;
use Clone qw(clone);

=head1 METHODS
=cut

########################################################################
=head2 new

=cut
########################################################################

sub new {
    my $self = shift()->SUPER::new(@_);
    return $self;
}

########################################################################
=head2 check(rule,action)

=cut
########################################################################

sub check {
    my $self = shift;
    my $rule = shift;
    my $action = shift;

    my ( $rule_class ) = ref($rule) =~ /.*::(\w+)$/;

    return ($rule_class eq 'AlwaysAfterEvent') || ($rule_class eq 'OnChangeEvent');
}

1;

__END__

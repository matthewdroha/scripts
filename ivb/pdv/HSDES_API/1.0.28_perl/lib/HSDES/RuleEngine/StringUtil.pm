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

FunctionHelper
=cut

=head1 SYNOPSIS
=cut

=head1 DESCRIPTION
=cut

package HSDES::RuleEngine::StringUtil;
use base qw(Exporter);

our @EXPORT    = qw(areStringsEqRegexp);
our @EXPORT_OK = qw();

use Data::Dumper;

=head1 FUNCTIONS
=cut

########################################################################
=head2 areStringsEqRegexp (auto-exported)

=cut
########################################################################

sub areStringsEqRegexp {
    my $xmlNode = shift;
    my $answer = shift;
    my $parameterValue = shift;
    my $actualValue = shift;

    if ( $xmlNode && exists($xmlNode->{Regexp}) && lc($xmlNode->{Regexp}) eq "true" ) {
	#print Dumper($actualValue =~ $parameterValue, $actualValue, $parameterValue);
	eval {
	    $answer = defined($actualValue) && ($actualValue =~ $parameterValue);
	};
	$answer = 0 if ($@); # If exception occurs, fail RE match 
    } else {
   	
	$answer = defined($actualValue) && lc($parameterValue) eq lc($actualValue);
    }
    return $answer;
}

1;

__END__

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

FunctionHelper
=cut

=head1 SYNOPSIS
=cut

=head1 DESCRIPTION
=cut

package HSDES::RuleEngine::FunctionHelper;
use base qw(Exporter);

our @EXPORT    = qw(substituteParameters substituteParametersForServerCall);
our @EXPORT_OK = qw();

use Data::Dumper;

use HSDES::RuleEngine::CountedActionContext;

=head1 FUNCTIONS
=cut

########################################################################
#
sub _DefaultTransform {
	return shift;
}

########################################################################
#
sub _SingleQuoteTransform {
	my $s = shift;
	 $s = "" if (!defined($s));
	$s =~ s/'/''/g;
	return "$s";
}


########################################################################
=head2 substituteParameters (auto-exported)

=cut
########################################################################

sub substituteParameters {
    my $delegate = shift;
    my $context = shift;
    my $originalText = shift;
    my $retval = $originalText;

    $retval = _replaceCurrentOrPreviousValue($context, $retval, \&_DefaultTransform);
    $retval = _replaceFieldValues($delegate, $retval, \&_DefaultTransform);
    return $retval;
}

########################################################################
=head2 substituteParametersForServerCall (auto-exported)

=cut
########################################################################

sub substituteParametersForServerCall {
    my $delegate = shift;
    my $context = shift;
    my $originalText = shift;
    my $retval = $originalText;

    $retval = _replaceCurrentOrPreviousValue($context, $retval, \&_SingleQuoteTransform);
    $retval = _replaceFieldValues($delegate, $retval, \&_SingleQuoteTransform);
    return $retval;
}

########################################################################
#
sub _replaceCurrentOrPreviousValue {
    my $context = shift;
    my $retval = shift;
    my $transform = shift;

    if ( $context && $context->can("getCurrentFieldValue")){
	my $currentValue = &{$transform}($context->getCurrentFieldValue());
	$retval =~ s/\${value}/$currentValue/ig;
	if ( $context->can("getPreviousFieldValue") ) {
	    my $oldValue = &{$transform}($context->getPreviousFieldValue());
	    $retval =~ s/\${old_value}/$oldValue/ig if ( defined($oldValue) );
	}
    }
    return $retval;
}

########################################################################
#
sub _replaceFieldValues {
    my $delegate = shift;
    my $originalText = shift;
    my $transform = shift;

    return undef if ( ! defined($originalText) );

    my $retval = $originalText;
    my $indexOfStartToken = -1;
    while ( ($indexOfStartToken = index($retval, '${')) >= 0 ) {
	my $indexOfEndToken = index($retval, '}', $indexOfStartToken);
	last if ( $indexOfEndToken < 0 );

	my $fieldName = substr($retval, $indexOfStartToken+2, $indexOfEndToken-$indexOfStartToken-2);
	my $replacementVal = "";
	if ( $fieldName =~ /^SAVED:/ ) {
	    my $xformFieldName = $fieldName;
	    $xformFieldName =~ s/^SAVED://;
	    $replacementVal = &{$transform}($delegate->getSavedFieldValue($xformFieldName));
	} else {
	    $replacementVal = &{$transform}($delegate->getCurrentFieldValue($fieldName));
	}
	$replacementVal = '' if ( !defined $replacementVal );  # guard against undef from above
	my $matchVal = '${' . $fieldName . '}';
	#print $retval, $indexOfStartToken, $matchVal,'xx', $replacementVal, "\n";
	substr $retval, $indexOfStartToken, length($matchVal), $replacementVal;
	#print $retval, "\n";
    }

    return $retval;
}

1;

__END__

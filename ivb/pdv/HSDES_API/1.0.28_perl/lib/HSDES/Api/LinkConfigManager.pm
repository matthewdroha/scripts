package HSDES::Api::LinkConfigManager;

=head1 Name

HSDES::Api::LinkConfigManager - This object will be used to get information about configured  ES link_types

=cut


use warnings;
use strict;

use Carp;
use Data::Dumper;
use HSDES::Api::Util;
use HSDES::Api::Error;

my $_apiHandle;

sub new {
	my $class = shift;
	$_apiHandle = shift;
	my $self = {};
	bless ($self, $class);
	return $self;
}


=head1 SYNOPSIS

	 getLinkType();

=head2 Get all valid linkTypes between a pair of source subject/tenant and target subject/tenant.

=begin html
<BR>sourcetenant: tenant of the Source record.(parentRecord). Required.
<BR>sourceSubject:subject of the Source record. (parentRecord).Required.
<BR>targetTenant:tenant of the target record. Required.
<BR>targetSubject: subject of the target Record.Required.
<BR>relationship: relationship value (related-link, parent-child)
<BR>flags: Internal use
<BR>Returns: list of valid linkTypes between the given pair of source subject/tenant and target subject/tenant. 

=end html


=cut

sub getLinkType {
	my $self = shift;
	my $sourceTenant = shift;
	my $sourceSubject = shift;
	my $targetTenant = shift;
	my $targetSubject = shift;
	my $relationship = shift;
	my $flags = shift;
	
	if(!$sourceTenant) {
		$self->{_lastErr} = "Must provide value for source Tenant";
                return undef;
	}
	
	if(!$sourceSubject) {
		$self->{_lastErr} = "Must provide value for source Subject";
                return undef;
	}
	
	if(!$targetTenant) {
		$self->{_lastErr} = "Must provide value for target Tenant ";
                return undef;
	}
	
	if(!$targetSubject) {
		$self->{_lastErr} = "Must provide value for target Subject";
                return undef;
	}

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Link","getLinkType", 
			{sourceTenant=>$sourceTenant, sourceSubject=>$sourceSubject, targetTenant=>$targetTenant, targetSubject=>$targetSubject, 
			relationship=>$relationship, flags=>$flags});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		return $rows;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return undef;
	}
}

1;

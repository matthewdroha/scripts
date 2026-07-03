package HSDES::Api::LinkManager;

=head1 Name

HSDES::Api::LinkManager - This object will be used to manage ES links 

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

	addLink();

=head2 Add link between parent and child records 

=begin html
<BR>sourceID: parent record ID. Required.
<BR>targetDList: CSV child record IDs. Required.
<BR>linkType: link type.
<BR>relationship: relationship.
<BR>flags: For Internal use Only.
<BR>tag: Custom tags for links.
<BR>Returns: action status for each child

=end html


=cut

sub addLink {
	my $self = shift;
	my $sourceID = shift;
	my $targetIDList = shift;
	my $linkType = shift;
	my $relationship = shift;
	my $flags = shift;
	my $tag = shift;

	if(!$sourceID) {
		$self->{_lastErr} = "Must provide value for sourceID";
                return undef;
	}

	if(!$targetIDList) {
		$self->{_lastErr} = "Must provide value(s) for targetIDList";
                return undef;
	}

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Link","addLink", 
			{sourceID=>$sourceID, targetIDList=>$targetIDList,linkType=>$linkType, relationship=>$relationship,
			flags=>$flags, tag=>$tag});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		return $rows;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return undef;
	}
}

=head1 SYNOPSIS

	updateLink();

=head2 Update existing relationship link. 

=begin html
<BR>sourceID: parent record ID. Required.
<BR>targetIDList: CSV child record IDs. Required.
<BR>oldLinkType: existing relationship type. Required.
<BR>relationship: existing relationship type.
<BR>newlinkType: new linktype. 
<BR>newTag: new custom tag.
<BR>flags: For Internal use only.
<BR>Returns: action status for each child

=end html


=cut

sub updateLink {
	my $self = shift;
	my $sourceID = shift;
	my $targetIDList = shift;
	my $oldLinkType = shift;
	my $relationship = shift;
	my $newLinkType = shift;
	my $newTag = shift;
	my $flags = shift;
	

	if(!$sourceID) {
		$self->{_lastErr} = "Must provide value for sourceID";
                return undef;
	}

	if(!$targetIDList) {
		$self->{_lastErr} = "Must provide value(s) for targetIDList";
                return undef;
	}

	if(!$oldLinkType) {
		$self->{_lastErr} = "Must provide value for oldLinkType";
                return undef;
	}


	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Link","updateLink", 
			{sourceID=>$sourceID, targetIDList=>$targetIDList, 
			oldLinkType=>$oldLinkType, relationship=>$relationship, newLinkType=>$newLinkType , newTag=>$newTag ,flags=>$flags});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		return $rows;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return undef;
	}
}


=head1 SYNOPSIS

	deleteLink();

=head2 Delete existing link 

=begin html
<BR>sourceID: parent record ID. Required.
<BR>targetIDList: CSV child record IDs. Required.
<BR>linkType: relationship type. Required.
<BR>flag: for Internal User only.
<BR>Returns: action status for each child

=end html


=cut

sub deleteLink {
	my $self = shift;
	my $sourceID = shift;
	my $targetIDList = shift;
	my $linkType = shift;
	my $flags = shift;

	if(!$sourceID) {
		$self->{_lastErr} = "Must provide value for parentID";
                return undef;
	}

	if(!$targetIDList) {
		$self->{_lastErr} = "Must provide value(s) for childIDList";
                return undef;
	}

	if(!$linkType) {
		$self->{_lastErr} = "Must provide value for linkType";
                return undef;
	}
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Link","deleteLink", 
			{sourceID=>$sourceID, targetIDList=>$targetIDList, linkType=>$linkType, flags=>$flags});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		return $rows;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return undef;
	}
}



=head1 SYNOPSIS

	moveNode();

=head2 Change the parent of existing link. 

=begin html

<BR>oldParentID: existing parent ID. Required.
<BR>childID: child record ID to be reparented. Required.
<BR>oldLinkType: existing link type. Required.
<BR>newParentID: new parent ID. Required.
<BR>newLinkType: new relationship type.
<BR>nodeAfterID: record ID after which childID will move.


=end html


=cut

sub moveNode {
	my $self = shift;
	my $childID = shift;
	my $oldParentID = shift;
	my $oldLinkType = shift;
	my $newParentID = shift;
	my $newLinkType = shift;
	my $nodeAfterID = shift;
	
	if(!$childID) {
		$self->{_lastErr} = "Must provide value for id";
                return 0;
	}

	if(!$oldParentID) {
		$self->{_lastErr} = "Must provide value for oldParentID";
                return 0;
	}

	if(!$oldLinkType) {
		$self->{_lastErr} = "Must provide value for oldLinkType";
                return 0;
	}

	if(!$newParentID) {
		$self->{_lastErr} = "Must provide value for newParentID";
                return 0;
	}

	
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Link","moveNode", 
			{childID=>$childID, oldParentID=>$oldParentID, oldLinkType=>$oldLinkType,
			newParentID=>$newParentID, newLinkType=>$newLinkType, nodeAfterID=>$nodeAfterID });
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if (!$isSuccess) {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
	}
	return $isSuccess;
}


=head1 SYNOPSIS

	reorderNode();

=head2 Change the order of existing link. 

=begin html
<BR>parentID: existing parent ID. Required.
<BR>nodeID: Child record that will be moved. Required.
<BR>nodeAfterID: Child after which to move the nodeID.If nodeAfterID is not provided, the nodeID will be moved to the top of the tree.


=end html


=cut

sub reorderNode {
	my $self = shift;
	my $parentID = shift;
	my $nodeID = shift;
	my $nodeAfterID =shift;

	print $parentID . "\n";
	print $nodeID. "\n";
	print $nodeAfterID. "\n";
	
	if(!$parentID) {
		$self->{_lastErr} = "Must provide value for parentID";
                return 0;
	}
	
	if(!$nodeID) {
		$self->{_lastErr} = "Must provide value for nodeID";
                return 0;
	}

	
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Link","reorderNode", 
			{parentID=>$parentID, nodeID=>$nodeID, nodeAfterID=>$nodeAfterID});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if (!$isSuccess) 
	{
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
	}

	return $isSuccess;
}


=head1 SYNOPSIS

	getRelatedRecords();

=head2 Get records related to the given reocrd 

=begin html
<BR>id: existing record ID. Required.
<BR>subject: subject.
<BR>tenant: tenant.
<BR>selectFields: selectFields.
<BR>filter: whereClause.
<BR>orderByClause: orderByClause.
<BR>Returns: list of records related to the given record

=end html


=cut

sub getRelatedRecords {
	my $self = shift;
	my $id = shift;
	my $subject = shift;
	my $tenant = shift;
	my $selectFields = shift;
	my $filter = shift;
	my $orderByClause = shift;
	
	
	if(!$id) {
		$self->{_lastErr} = "Must provide value for id";
                return undef;
	}

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Link","getRelatedRecords", 
			{id=>$id, subject=>$subject, tenant=>$tenant, select_fields=>$selectFields, filter=>$filter, order_by_clause=>$orderByClause});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		return $rows;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return undef;
	}
}


sub getLastErrorMessage {
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	return $self->{_lastErr};
}



1;

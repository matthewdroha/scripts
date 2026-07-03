package HSDES::Api::RelationManager;

=head1 Name

HSDES::Api::RelationManager - This object will be used to manage ES relationship 

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

	addLinkByType();

=head2 Add link between parent and child records 

=begin html
<BR>parentID: parent record ID. Required.
<BR>childIDList: CSV child record IDs. Required.
<BR>forwardAction: forward action
<BR>backwardAction: action action
<BR>linkType: relationship type
<BR>Returns: action status for each child

=end html


=cut

sub addLinkByType {
	my $self = shift;
	my $parentID = shift;
	my $childIDList = shift;
	my $forwardAction = shift;
	my $backwardAction = shift;
	my $linkType = shift;

	if(!$parentID) {
		$self->{_lastErr} = "Must provide value for parentID";
                return undef;
	}

	if(!$childIDList) {
		$self->{_lastErr} = "Must provide value(s) for childIDList";
                return undef;
	}

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Relation","addLinkByType", 
			{parentID=>$parentID, childIDList=>$childIDList, forwardAction=>$forwardAction,
			backwardAction=>$backwardAction, linkType=>$linkType});
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

	updateLinkByType();

=head2 Update existing relationship link. 

=begin html
<BR>parentID: parent record ID. Required.
<BR>childIDList: CSV child record IDs. Required.
<BR>oldLinkType: existing relationship type. Required.
<BR>linkType: new relationship type. Required.
<BR>Returns: action status for each child

=end html


=cut

sub updateLinkByType {
	my $self = shift;
	my $parentID = shift;
	my $childIDList = shift;
	my $oldLinkType = shift;
	my $linkType = shift;

	if(!$parentID) {
		$self->{_lastErr} = "Must provide value for parentID";
                return undef;
	}

	if(!$childIDList) {
		$self->{_lastErr} = "Must provide value(s) for childIDList";
                return undef;
	}

	if(!$oldLinkType) {
		$self->{_lastErr} = "Must provide value for oldLinkType";
                return undef;
	}

	if(!$linkType) {
		$self->{_lastErr} = "Must provide value for linkType";
                return undef;
	}

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Relation","updateLinkByType", 
			{parentID=>$parentID, childIDList=>$childIDList, 
			oldLinkType=>$oldLinkType, linkType=>$linkType});
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

	deleteLinkByType();

=head2 Delete existing link 

=begin html
<BR>parentID: parent record ID. Required.
<BR>childIDList: CSV child record IDs. Required.
<BR>linkType: relationship type. Required.
<BR>Returns: action status for each child

=end html


=cut

sub deleteLinkByType {
	my $self = shift;
	my $parentID = shift;
	my $childIDList = shift;
	my $linkType = shift;

	if(!$parentID) {
		$self->{_lastErr} = "Must provide value for parentID";
                return undef;
	}

	if(!$childIDList) {
		$self->{_lastErr} = "Must provide value(s) for childIDList";
                return undef;
	}

	if(!$linkType) {
		$self->{_lastErr} = "Must provide value for linkType";
                return undef;
	}
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Relation","deleteLinkByType", 
			{parentID=>$parentID, childIDList=>$childIDList, linkType=>$linkType});
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

	reparentByType();

=head2 Change the parent of existing link. 

=begin html
<BR>id: child record ID. Required.
<BR>oldParentID: existing parent ID. eRequired.
<BR>oldLinkType: existing relationship type. Required.
<BR>newParentID: new parent ID. eRequired.
<BR>linkType: new relationship type. Required.
<BR>Returns: action status for each child

=end html


=cut

sub reparentByType {
	my $self = shift;
	my $id = shift;
	my $oldParentID = shift;
	my $oldLinkType = shift;
	my $newParentID = shift;
	my $linkType = shift;

	if(!$id) {
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

	if(!$linkType) {
		$self->{_lastErr} = "Must provide value for linkType";
                return 0;
	}

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Record","reparentByType", 
			{id=>$id, oldParentID=>$oldParentID, oldLinkType=>$oldLinkType,
			newParentID=>$newParentID, linkType=>$linkType});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if (!$isSuccess) {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
	}
	return $isSuccess;
}


=head1 SYNOPSIS

	reorderLinksByType();

=head2 Change the order of existing link. 

=begin html
<BR>parentID: existing parent ID. Required.
<BR>childLinkOrder ref to array of hashes. Required.
Format 1:
[
	{id=>123, link_type=>1012816455, link_direction=>'Forward Link', link_order=>50},
	{id=>456, link_type=>1012816455, link_direction=>'Forward Link', link_order=>60},
]

Format 2:
[
	{id=>123, link_order=>50},
	{id=>456, link_order=>60},
]

<BR>Returns: action status for each child

=end html


=cut

sub reorderLinks {
	my $self = shift;
	my $parentID = shift;
	my $childLinkOrder = shift;

	if(!$parentID) {
		$self->{_lastErr} = "Must provide value for parentID";
                return 0;
	}

	my $childLinkOrderCSV= &childLinkOrderToCSV($self, $childLinkOrder);

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Relation","reorderLinks", 
			{parentID=>$parentID, childIDAndLinkList=>$childLinkOrderCSV});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		return $rows;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return undef;
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
<BR>Returns: list of records related to the given record

=end html


=cut

sub getRelatedRecords {
	my $self = shift;
	my $id = shift;
	my $subject = shift;
	my $tenant = shift;

	if(!$id) {
		$self->{_lastErr} = "Must provide value for id";
                return undef;
	}

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Record","getRelatedRecordsByTypeID", 
			{id=>$id, subject=>$subject, tenant=>$tenant});
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

	getChilHierarchy();

=head2 Get reocrd hierarchy 

=begin html
<BR>id: existing record ID. Required.
<BR>Returns: the hierarchy of the given record

=end html

=cut

sub getChildHierarchy {
	my $self = shift;
	my $id = shift;

	# must be called on a OBJECT
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	if (!$id) {
		$self->{_lastErr} = "Must provide record ID.";
		return undef;
	}

	# get optional parameters
	my $depth              = shift;
	my $filter             = shift;
	my $orderByClause      = shift; 
	my $selectFields       = shift;
	my $maxRecordsPerLevel = shift;
	my $flags              = shift;


	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Record","getChildHierarchy", 
			{id=>$id, depth=>$depth, filter=>$filter, orderByClause=>$orderByClause,
			 selectFields=>$selectFields, maxRecordsPerLevel=>$maxRecordsPerLevel, flag=>$flags});
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

sub childLinkOrderToCSV {
    my $self = shift;
    my $childLinkOrder    = shift;
    my $childLinkOrderCSV = "";

    if(!$childLinkOrder) {
	$self->{_lastErr} = "Must provide value for childLinkOrder";
	return undef;
    }

    if(!ref($childLinkOrder)) {
	$self->{_lastErr} = "childLinkOrder must be array reference";
	return undef;
    }

    # Check the values
    my $index=0;
    foreach my $entry (@$childLinkOrder) {
	if(!$entry->{"id"}) {
	    $self->{_lastErr} = "Must provide 'ID' value for childLinkOrder entry: $index";
	    return undef;
	}
	elsif(!$entry->{"link_order"}) {
	    $self->{_lastErr} = "Must provide 'link_order' value for childLinkOrder entry: $index";
	    return undef;
	}

	# TBD
	# Translate link_type
	#if($entry->{"link_type"}) {
	#    $entry=&translateLinkType($entry);
	#}

	# Convert it to CSV
    	$childLinkOrderCSV .= "," if($index > 0);
	$childLinkOrderCSV .= join(":", values %$entry);
	$index++;
    }

    return $childLinkOrderCSV;
}

1;

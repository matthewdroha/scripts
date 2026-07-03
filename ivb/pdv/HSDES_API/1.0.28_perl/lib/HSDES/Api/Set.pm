package HSDES::Api::Set;

use warnings;
use strict;
use Data::Dumper;

my $_apiHandle;

sub new {
	my $class = shift;
	$_apiHandle = shift;
	return bless {}, $class;
}

sub adoptIntoSet {
	my $self = shift;
	my $parentID = shift;
	my $childID = shift;

	if ( !( defined($parentID) and defined($childID) ) )
	{
		$self->{_lastErr} = "Must provide the following: parentID and childID.";
        return undef;
	}


	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Record", "AdoptIntoSet", {
		parentID => $parentID,
		childID => $childID
		});


	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if (! $isSuccess) {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
	}
	return $isSuccess;

}


sub getSetsRecords {
	my $self = shift;
	my $id = shift;
	my $subject = shift;
	my $tenant = shift;

	if ( !( defined($id) and defined($subject) and defined($tenant) ) )
	{
		$self->{_lastErr} = "Must provide the following: id, subject, and tenant.";
        return undef;
	}

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Record", "getSetsRecords", {
		id => $id,
		subject => $subject,
		tenant => $tenant
		});

	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		return $rows;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}

}

sub getUnionRecords {
	my $self = shift;
	my $id = shift;
	my $subject = shift;
	my $tenant = shift;

	if ( !( defined($id) and defined($subject) and defined($tenant) ) )
	{
		$self->{_lastErr} = "Must provide the following: id, subject, and tenant.";
        return undef;
	}


	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Record", "getUnionRecords", {
		id => $id,
		subject => $subject,
		tenant => $tenant
		});


	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		return $rows;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}

}

sub unionSets {
	my $self = shift;
	my $idList = shift;

	if ( !defined($idList) )
	{
		$self->{_lastErr} = "Must provide the following: idList.";
        return undef;
	}


	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Record", "unionSets", {
		idList => $idList
		});


	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if (! $isSuccess) {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
	}
	return $isSuccess;

}

sub undoUnionForSets {
	my $self = shift;
	my $idList = shift;

	if ( !defined($idList) )
	{
		$self->{_lastErr} = "Must provide the following: idList.";
        return undef;
	}


	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Record", "undoUnionForSets", {
		idList => $idList
		});


	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if (! $isSuccess) {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
	}
	return $isSuccess;

}


1;
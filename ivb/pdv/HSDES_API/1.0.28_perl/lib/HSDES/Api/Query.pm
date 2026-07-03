package HSDES::Api::Query;

use warnings;
use strict;
use File::Basename;
use Carp;
use HSDES::Api::Util;

my $_apiHandle;

sub new {
	my $class = shift;
	$_apiHandle = shift;
	my $self = {};
	bless ($self, $class);
	return $self;
}


sub execQuery {
	my $self = shift;
	# must be called on a OBJECT
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}


	my $sqlString = shift;
	if (!defined $sqlString) {
		$self->{_lastErr} = "Need to pass in a string to execute.";
		return 0;
	}

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Query","executeByEQL", {eql=>$sqlString});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		return $rows;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}

sub addWithXML {
	my $self = shift;
	my $queryTitle = shift;
	my $queryCategory = shift;
	my $queryXML = shift;


	if (!defined $queryTitle) {
		$self->{_lastErr} = "Must define Query Title";
		return 0;
	}

	if (!defined $queryCategory) {
		$self->{_lastErr} = "Must define Query Category: Public, Private or Official";
		return 0;
	}


	if (!defined $queryXML) {
		$self->{_lastErr} = "Must define Query XML";
		return 0;
	}

	my $response = HSDES::Api::Util::callToWService(
					$_apiHandle, 
					"Query",
					"addWithXML",
					{ 
						queryXML=>$queryXML,
						category=>$queryCategory,
						title=>$queryTitle

					}
				);
		
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $queryRecord = $response->{DATA}[0];
		return $queryRecord->{newID};
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}


sub executeByXML {
	my $self = shift;
	my $queryXML = shift;

	if (!defined $queryXML) {
		$self->{_lastErr} = "Must define Query XML";
		return 0;
	}
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Query","executeByXML", {xml=>$queryXML});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		# remove system columns
		my $rows = $response->{DATA};
		return $rows;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}


=head1 SYNOPSIS
This function allows you to retrieve the EQL for an existing query.
Input: Query ID
Output: EQL string
=cut
sub getEQLByID {

	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	my $queryID = shift;

	if (!defined $queryID) {
		$self->{_lastErr} = "Must define QueryID";
		return 0;
	}

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Query","getEQLByID", {queryID=>$queryID});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		return $response->{DATA}[0]{eql};
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}

}

sub executeByID {
	my $self = shift;
	my $queryID = shift;

	if (!defined $queryID) {
		$self->{_lastErr} = "Must define QueryID";
		return 0;
	}
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Query","executeByID", {queryID=>$queryID});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		# remove system columns
		my $rows = $response->{DATA};
		return $rows;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}

sub executeByName {

	my $self = shift;
	my $magazineName = shift;
	my $queryName = shift;


	if (!defined $magazineName) {
		$self->{_lastErr} = "Must define Magazine Name";
		return 0;
	}

	if (!defined $queryName) {
		$self->{_lastErr} = "Must define Query Name";
		return 0;
	}

	# step 1
	# get All Queries of this magazine
	my $magazineObject = $_apiHandle->magazine();
	my $allQueries = $magazineObject->getQueries($magazineName);
	if (!$allQueries) {
		$self->{_lastErr} = $magazineObject->getLastErrorMessage();
		return 0;
	}

	# step 2
	# get QueryID of a query in this magazine with the $queryName
	my $foundQueryID = 0;
	foreach my $queryID ( keys %$allQueries ) {
		if ($allQueries->{$queryID} eq $queryName) {
			$foundQueryID =  $queryID;
			last;
		}
	}

	if ($foundQueryID != 0) {
		return $self->executeByID($foundQueryID);
	} else {
		$self->{_lastErr} = "Unable to find Query: $queryName in Magazine: $magazineName.\n";
		return 0;
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

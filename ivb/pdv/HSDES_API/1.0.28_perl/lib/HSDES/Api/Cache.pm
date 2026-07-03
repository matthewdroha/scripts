package HSDES::Api::Cache;

use warnings;
use strict;

use Carp;
use Data::Dumper;
use HSDES::Api::Error;

my %fieldcache		= ();
my %lookupFieldValue	= ();

my $_lastErr;
my $_apiHandle;
my $_viewportName;


sub new {
	my $class = shift;
	$_apiHandle = shift;
	my $self = {};
	bless ($self, $class);
	return $self;
}

=head1 SYNOPSIS
	This is an internal function that will make a call to ES
	in order to load the field info for a particular viewport
	This will return success/failure

=cut
sub _loadFieldInfoFromDB {
	my $self = shift;
	my $viewportName = shift;

	my $response = HSDES::Api::Util::callToWService($_apiHandle,"Viewport","getFieldInfo", {viewPortName=>$viewportName});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $fieldcache = $response->{DATA};	
		$self->{$viewportName}{ALLFIELDSCACHE} = $fieldcache;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}




	# now save all the different types of fields so we can easily get to them
	# step 2 - get subject fields
	my @allSubjectFields = ();
	foreach my $singleField (@{$self->{$viewportName}{ALLFIELDSCACHE}}) {
		if (!($singleField->{field} =~ /^private./)) {
			push (@{$self->{$viewportName}{SUBJECTFIELDS}}, $singleField->{field});
		}

		if($singleField->{kind} =~ /^People$/i) {
			push (@{$self->{$viewportName}{PEOPLEFIELDS}}, $singleField->{field});
		}
		
		if($singleField->{kind} =~ /^Person$/i) {
			push (@{$self->{$viewportName}{PERSONFIELDS}}, $singleField->{field});
		}

		if($singleField->{logical_field_type} =~ /^singlesel$/i) {
			push (@{$self->{$viewportName}{SINGLESELFIELDS}}, $singleField->{field});
		}

		if($singleField->{logical_field_type} =~ /^multisel$/i) {
			push (@{$self->{$viewportName}{MULTISEL}}, $singleField->{field});
		}

		if ($singleField->{is_virtual_field} eq "1") {
			push (@{$self->{$viewportName}{VIRTUALFIELDS}}, $singleField->{field});
		}
		
		if($singleField->{logical_field_type} =~ /^binary$/i) {
			push (@{$self->{$viewportName}{BINARYFIELDS}}, $singleField->{field});
		}

		# should we SKIP validation of lookups for this field?
		if($singleField->{validate_lu} eq "0") {
			push (@{$self->{$viewportName}{SKIPLUVALIDATION}}, $singleField->{field});
		}
	}
}

# Get the lookup field info and cache it.
sub getLookupFieldValue {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	
	my $field = shift;
	my $viewportName = shift;
	my $reload = shift;

	if (!(defined $reload)) {
		$reload = 0;
	}

	# get the tenant and subject
	my @view    = split("\\.", $viewportName);
	my $tenant  = $view[0];
	my $subject = $view[1];


	my $key = $viewportName . "#" . $field;

	# get the values from cache first
	if (!(defined $self->{$key}) || $reload == 1) {
		# lets load from DB
		my @valueList;
		my $metadataHandle = $_apiHandle->metadata();	
		@valueList = $metadataHandle->getLookupValue($field, $subject, $tenant);
		if(!@valueList) {
			return @valueList;
		}

		# cache the values
		foreach my $value (@valueList) {
			push(@{$self->{$key}}, $value);
		}
	}
	return @{$self->{$key}};
}

=head1 SYNOPSIS
	Returns the last error message that was set
=cut
sub getLastErrorMessage() {
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	return $self->{_lastErr};
}

=head1 SYNOPSIS
	Returns an array of all fields which are of type People
	for a given viewport. People is 1 or more comma separated idsid
=cut
sub getPeopleFields {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	
	my $viewportName = shift;
	
	if (!(defined $self->{$viewportName})) {
		# lets load from DB
		_loadFieldInfoFromDB($self,$viewportName);
	}

	if (exists $self->{$viewportName}{PEOPLEFIELDS}) {
		return @{$self->{$viewportName}{PEOPLEFIELDS}};
	} else {
		return ();
	}
}


=head1 SYNOPSIS
	Returns an array of all fields which are of type Person
	for a given viewport. Person is single idsid
=cut
sub getPersonFields {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	
	my $viewportName = shift;
	
	if (!(defined $self->{$viewportName})) {
		# lets load from DB
		_loadFieldInfoFromDB($self,$viewportName);
	}

	if (exists $self->{$viewportName}{PERSONFIELDS}) {
		return @{$self->{$viewportName}{PERSONFIELDS}};
	} else {
		return ();
	}
}


=head1 SYNOPSIS
	Returns an array of all fields which are of type singlesel
	for a given viewport. 
=cut
sub getSingleselFields {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	
	my $viewportName = shift;
	
	if (!(defined $self->{$viewportName})) {
		# lets load from DB
		_loadFieldInfoFromDB($self,$viewportName);
	}

	if (exists $self->{$viewportName}{SINGLESELFIELDS}) {
		return @{$self->{$viewportName}{SINGLESELFIELDS}};
	} else {
		return ();
	}
}


=head1 SYNOPSIS
	Returns an array of all fields which are of type multisel
	for a given viewport. 
=cut
sub getMultiselFields {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	
	my $viewportName = shift;
	
	if (!(defined $self->{$viewportName})) {
		# lets load from DB
		_loadFieldInfoFromDB($self,$viewportName);
	}
	
	if (exists $self->{$viewportName}{MULTISEL}) {
		return @{$self->{$viewportName}{MULTISEL}};
	} else {
		return ();
	}
}

=head1 SYNOPSIS
	Returns an array of all fields which are of type multisel/singlesel
	for a given viewport. 
=cut
sub getAllLookupFields {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	
	my $viewportName = shift;
	
	my @singleselFields = getSingleselFields($self,$viewportName);
	my @multiselFields  = getMultiselFields($self,$viewportName);
	return (@singleselFields, @multiselFields);
}


=head1 SYNOPSIS
	Returns an array of all fields for which we are SUPPOSED to skip lookup validation
=cut
sub getAllSkipLUValidationFields {

	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	
	my $viewportName = shift;
	
	if (!(defined $self->{$viewportName})) {
		# lets load from DB
		_loadFieldInfoFromDB($self,$viewportName);
	}

	if (exists $self->{$viewportName}{SKIPLUVALIDATION}) {
		return @{$self->{$viewportName}{SKIPLUVALIDATION}};
	} else {
		return ();
	}
}


=head1 SYNOPSIS
	Returns an array of all fields which are virtual
=cut
sub getVirtualFields {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	
	my $viewportName = shift;
	
	if (!(defined $self->{$viewportName})) {
		# lets load from DB
		_loadFieldInfoFromDB($self,$viewportName);
	}

	if (exists $self->{$viewportName}{VIRTUALFIELDS}) {
		return @{$self->{$viewportName}{VIRTUALFIELDS}};
	} else {
		return ();
	}
}


=head1 SYNOPSIS
	Returns an array of all fields which are binary 
=cut
sub getBinaryFields {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	
	my $viewportName = shift;
	
	if (!(defined $self->{$viewportName})) {
		# lets load from DB
		_loadFieldInfoFromDB($self,$viewportName);
	}

	if (exists $self->{$viewportName}{BINARYFIELDS}) {
		return @{$self->{$viewportName}{BINARYFIELDS}};
	} else {
		return ();
	}
}

=head1 SYNOPSIS
	Returns all fields that exist for a tenant.subject
	This will ignore the private.* fields
=cut
sub getAllFields {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	
	my $viewportName = shift;
	
	if (!(defined $self->{$viewportName})) {
		# lets load from DB
		_loadFieldInfoFromDB($self,$viewportName);
	}

	if (exists $self->{$viewportName}{SUBJECTFIELDS}) {
		return @{$self->{$viewportName}{SUBJECTFIELDS}};
	} else {
		return ();
	}
}


1;

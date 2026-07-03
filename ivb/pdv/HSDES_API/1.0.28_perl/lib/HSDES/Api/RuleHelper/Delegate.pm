package HSDES::Api::RuleHelper::Delegate;

my $_apiHandle;
use Data::Dumper;

sub new {
	my $class = shift;
	$_apiHandle = shift;
	my $self = {};
	bless ($self, $class);
	return $self;
}

sub evaluateFunction() {
	my $self = shift;	
	my $function = shift;
	my $continuation = shift;


	my @returnValue = ();
	my $returnValue = "";
	my $response = HSDES::Api::Util::callGenericService($_apiHandle, {serviceInfo =>$function});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $data = $response->{DATA};
		for my $singleHash (@{$data}) {
			foreach my $key ( keys %$singleHash ) {
				push(@returnValue, $singleHash->{$key});
			}
		}
	} else {
		die HSDES::Api::Util::GET_ERROR_MSG($response);	
	}

	&{$continuation}( @returnValue);
}

sub messageBox {
	#TBD
	#NOP for now
}

sub runServerAction {
	my $self          = shift;
	my $actionName    = shift;
	my $currentValues = shift;
	my $savedValues   = shift;
	my $continuation  = shift;

	my %valuesToSend;

	# Save action
	$valuesToSend{"___actionName"} = $actionName;
	
	# Copy current values
	while( my($k,$v) = each %$currentValues) {
		$valuesToSend{$k} = $v;
	} 

	# Copy saved values
	# Prefix $k with "SAVED:"
	while( my($k,$v) = each %$savedValues) {
		$valuesToSend{"SAVED:$k"} = $v;
	} 

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Generic","runServerAction", \%valuesToSend);
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $encodedCommands = $response->{DATA};
		&{$continuation}($encodedCommands);
	} else {
		die HSDES::Api::Util::GET_ERROR_MSG($response);	
	}
}

sub setData {
	my $self = shift;
	my $datahash = shift;

	# we need to save both the original data
	# and the reference to the current record hash
	my %origData = %$datahash;
	$self->{origData} = \%origData;
	$self->{recordData} = $datahash;
}

sub getCurrentFieldValue {
	my ($self, $field) = @_;

	# get IDSID
	if($field =~ m/^\$LOGONID$/) {
		return getUserIDSID();
	}
	else {
		return $self->{recordData}{$field};
	}

}

# getUserIDSID
# this is sub is used internally
sub getUserIDSID {

	if(defined $_apiHandle->_isImpersonate()) {
		# get the user from impersonation
		return $_apiHandle->_getImpersonatedUser();
	}
	elsif($_apiHandle->_isHSDAuthEnabled()) {
		# get the user from .hsd 
		return $_apiHandle->_getHSDUsername();
	}
	else {

		if ( $^O eq "linux" ) {
			return getlogin || getpwuid($<);
		}
		else {
			# get the user from Windows env.
			return Win32::LoginName();
		}
	}
}



sub getSavedFieldValue {
	my ($self, $field) = @_;

	# return the original value (as loaded from DB)
	return $self->{origData}{$field};
}

sub errorMessage {
	die _buildErrorMessage(@_);
}

sub errorIfRequiredFieldsMissing {
	die _buildErrorMessage(@_);
}

sub _buildErrorMessage {
	my ($self, $errorMessage) = @_;

	# lets build a nice error message
	my $completeErrorMessage = "Error " ;
	my $subjectTenant;
	if (defined $self->{origData}{tenant}) {
		$subjectTenant = $self->{recordData}{tenant} . ".";
	}
	if (defined $self->{origData}{subject}) {
		$subjectTenant .= $self->{recordData}{subject};
	}

	if (defined $subjectTenant) {
		$completeErrorMessage .= "for $subjectTenant: ";
	}

	$completeErrorMessage .= $errorMessage;
	return $completeErrorMessage;
}

1;

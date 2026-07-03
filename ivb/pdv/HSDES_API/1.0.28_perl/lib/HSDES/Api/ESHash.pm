package HSDES::Api::ESHash;

use 5.006;
use strict;
use warnings;

#use HSDES::Api::MetaData;
use Tie::Hash;
use Carp;
use Data::Dumper;
use vars qw(@ISA $VERSION);


@ISA = qw(Tie::ExtraHash);

$VERSION = sprintf "%d", '$Revision: 19 $ ' =~ /(\d+)/;

=head1 METHODS

=head2 TIEHASH

Creates a tied hash containing all the keys initialised to C<undef>.

=cut

use constant MARKERFORINTERNALFIELDS => "#_*";


sub TIEHASH {
	my $class = shift;
	my $data = shift;

	# we send some extra data along 
	# such as statemanager, changeManager, clickManager
	my $changeManager       = shift;
	my $clickManager        = shift;
	my $stateManager 	= shift;
	my $cacheObj 		= shift;

	# copy hash
	my $self = ();

	foreach my $key ( keys %$data ) {
		$self->[0]{$key} = $data->{$key};
	}

	# These ITEMS will not show up to end user as 
	# normal HASH keys since they are stored at index 1
	# while the user exposed ones are at index 0
	# that we can get them using {} notation. 
	# This works for us since no ES field can being with #_*
	my $secretKey = MARKERFORINTERNALFIELDS . "CHANGEMANAGER";
	$self->[1]{$secretKey} = $changeManager;

	$secretKey = MARKERFORINTERNALFIELDS . "CLICKMANAGER";
	$self->[1]{$secretKey} = $clickManager;

	# save for future retrieve
	$secretKey = MARKERFORINTERNALFIELDS . "STATEMANAGER";
	$self->[1]{$secretKey} = $stateManager;

	$secretKey = MARKERFORINTERNALFIELDS . "CACHEOBJ";
	$self->[1]{$secretKey} = $cacheObj;


	bless ($self, $class);
}

=head2 FETCH

=cut
sub FETCH {
	my ($self, $key) = @_;

	# by default; look in index 0 for hash items
	# unless we are looking for secret items
	my $hashIndex = 0;
	my $secretKey = MARKERFORINTERNALFIELDS;
	if ($key =~ m/^$secretKey/) {
		$hashIndex = 1;
	}

	my $stateManagerObj = $self->[1]{MARKERFORINTERNALFIELDS . "STATEMANAGER"};
	my $hiddenFields = $stateManagerObj->getHiddenFields();
	
	my $parent = (caller(1))[3];
	
	#if(exists $hiddenFields->{$key})
	#{	
	#	if(not defined($parent) or  $parent !~ /Dumper/)
	#	{
	#		croak "Cannot access hidden field $key";
	#	}
	#}

	return $self->[$hashIndex]{$key};
}
=head2 STORE

Attempts to store a value in the hash. If the key isn't in the valid
list (i.e. it doesn't already exist) the program croaks.

=cut

sub STORE {
	my ($self, $key, $newVal) = @_;
	my $oldVal = $self->[0]{$key};
	my $viewportName = $self->[0]{"tenant"} . "." . $self->[0]{"subject"};

	# who called me	
	my $parent = ( caller(1) )[3];
	

	# If the user is setting a binary field check if the file path is valid  
	my $cacheObj = $self->[1]{MARKERFORINTERNALFIELDS . "CACHEOBJ"};
	my @binaryFields = $cacheObj->getBinaryFields($viewportName);
	if (HSDES::Api::Util::DOES_KEY_EXIST_IN_ARRAY(\@binaryFields, $key) && !-e $newVal) {
		croak "No such a file '$newVal'\n";
	}


	# we should not RESPECT rules if the changes being made
	# are due to some internal functions (such as statemanager)
	my $ignoreReadOnlyRules = 0;
	if (defined($parent) && $parent eq "HSDES::Api::RuleHelper::StateManager::handleEvent") {
		$ignoreReadOnlyRules = 1;
	}

	# sanity check - do we have this field
	unless (exists $self->[0]{$key}) {
		croak "invalid key [$key] in hash\n";
	}

	# convert newlines in description to html <p>
	if($key eq 'description') {
		$newVal = HSDES::Api::Util::newlinesToHtmlParagraph($newVal);
		$self->[0]{$key} = $newVal;
	}

	# nsshergi
	# there are certain fields that a end user should NOT be able to modify
	# lets get a handle on those
	my $stateManagerObj = $self->[1]{MARKERFORINTERNALFIELDS . "STATEMANAGER"};
	my $readonlyFields = $stateManagerObj->getReadOnlyFields();
	my $hiddenFields = $stateManagerObj->getHiddenFields();

	# only complain if caller WAS NOT a handle event from statemanager
	croak "$key is a read only field." if exists $readonlyFields->{$key} && $ignoreReadOnlyRules == 0;

	croak "$key is a hidden field." if exists $hiddenFields->{$key} && $ignoreReadOnlyRules == 0;


	# user should not be able to modify virtual fields
	my @virtualFields = $cacheObj->getVirtualFields($viewportName);
	if (HSDES::Api::Util::DOES_KEY_EXIST_IN_ARRAY(\@virtualFields, $key)) { 
		croak "$key is a virtual field which can not be modified.";
	}

	# is the user trying to set the field to a value that SHOULD NOT
	# be allowed. Think of a state machine where the list of possible
	# values is to be filtered
	my $filterLookups = $stateManagerObj->getFilterLookups();
	my @allLookupFields = $cacheObj->getAllLookupFields($viewportName);
	my @skipLuValidationFields = $cacheObj->getAllSkipLUValidationFields($viewportName);
	my @allSingleselFields = $cacheObj->getSingleselFields($viewportName);

	if ($ignoreReadOnlyRules == 0) {

	    # rules returned lookup fields and their values 
	    if ( exists $filterLookups->{$key}) {
		# for each value provided by user; make sure its valid
		# if field is a singlesel; and user gave us comma separated value; thats bad
		    my @userValues = split(",",$newVal);
		    if ( (HSDES::Api::Util::DOES_KEY_EXIST_IN_ARRAY(\@allSingleselFields, $key)) 
			    && scalar(@userValues) > 1 ) {
			croak "$key is a singlesel. Please provide only single value";
		    }


		    my @actualValues;
		    foreach my $singleValue (@userValues) {
			    $singleValue = HSDES::Api::Util::Trim($singleValue);
			    if (!(HSDES::Api::Util::DOES_KEY_EXIST_IN_ARRAY($filterLookups->{$key}, $singleValue))) {
					# There are 2 reasons we did not find a match
					# 1) We had an invalid value from user
					# 2) We had empty filter values from business rules
				    if(@{$filterLookups->{$key}}) { 
					    croak "$newVal is not a valid value for $key. Valid Values are: " 
						    . join(',',@ {$filterLookups->{$key}});
				    }
				    else {
					    croak ("No values found in the Rules for $key. ".
							    "Please contact your project Administrator.\n"); 
				    }
			    } # did we find a match
			    push(@actualValues, $singleValue);
		    } # for each value

		    # Use the actual BE instead of the user provided
		    if(@actualValues) {
		    	$newVal = join(',', @actualValues);
		    }
	    } elsif(HSDES::Api::Util::DOES_KEY_EXIST_IN_ARRAY(\@skipLuValidationFields, $key) eq 0
	    	    && (HSDES::Api::Util::DOES_KEY_EXIST_IN_ARRAY(\@allLookupFields,$key)) 
	    	   ) {
		# there are no rules; but lets validate against all possible lookup values
		# get the lookup field values list 
		# for each value provided by user; make sure its valid
		    my @userValues = split(",",$newVal);

		    if ( (HSDES::Api::Util::DOES_KEY_EXIST_IN_ARRAY(\@allSingleselFields, $key)) 
			    && scalar(@userValues) > 1 ) {
			croak "$key is a singlesel. Please provide only single value";
		    }

		    my @possibleValues = $cacheObj->getLookupFieldValue($key,$viewportName); 
		    my @actualValues;
		    foreach my $singleValue (@userValues) {
			    $singleValue = HSDES::Api::Util::Trim($singleValue);
			    if (!(HSDES::Api::Util::DOES_KEY_EXIST_IN_ARRAY(\@possibleValues, $singleValue))) {
				    # nsshergi - lets reload and check again
				    my $reload = 1;
				    @possibleValues = $cacheObj->getLookupFieldValue($key,$viewportName, $reload); 
				    if (!(HSDES::Api::Util::DOES_KEY_EXIST_IN_ARRAY(\@possibleValues, $singleValue))) {
					    croak ("$singleValue is not a valid value for $key. Valid Values are: "
						    . join(',',@possibleValues));	
				    }
			    }
			    push(@actualValues, $singleValue);
		    }
		    # Use the actual BE instead of the user provided
		    if(@actualValues) {
		    	$newVal = join(',', @actualValues);
		    }
	    }
	} # not readOnly

	# for some fields; we need to trigger ON CHANGE event
	my $secretKey = MARKERFORINTERNALFIELDS . "CHANGEMANAGER";
	my $changeManager = $self->[1]{$secretKey};

	$self->[0]{$key} = $newVal;

	$changeManager->onFieldChanged($key,$newVal,$oldVal) if $ignoreReadOnlyRules == 0;
}


=head2 DELETE

Delete a value from the hash. Actually it just sets the value back to
C<undef>.

=cut

sub DELETE {
  my ($self, $key) = @_;

  return unless exists $self->[0]{$key};

  my $ret = $self->[0]{$key};
  $self->[0]{$key} = undef;
  return $ret;
}

=head2 CLEAR

Clears all values but resetting them to C<undef>.

=cut

sub CLEAR {
  my $self = shift;

  $self->[0]{$_} = undef foreach keys %$self;
}

1;


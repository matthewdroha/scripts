package HSDES::Api::RuleHelper::StateManager;

use strict;

use Data::Dumper;
use HSDES::RuleEngine::StateManager;

our @ISA = qw (HSDES::RuleEngine::StateManager);       


sub handleEvent {
    my $self = shift;
    my $event = shift;
    my $field = $event->getTarget();


	# call the base object
	# The perl Rule Engine is going to handle the event
	# and save the following attributes for each field
	# enabled -> 1 or 0
	# filter  -> array or empty
	# required -> 1 or 0
	# visible  -> 1 or 0
	# unfiltered -> 1 or 0

	HSDES::RuleEngine::StateManager::handleEvent($self,$event);


 # Event may be like HSDES::RuleEngine::Events::RequiredStateEvent
 # we only want the part at the end
    my ( $event_class ) = ref($event) =~ /.*::(\w+)$/;


	if (ref($event) && $event->isa(qw(HSDES::RuleEngine::Events::EnabledStateEvent))) {
		# we will get this for enabling disabling a field
		my $state = $event->getState();
		_markFieldEnabledDisabled($self,$field,$state);

	} elsif (ref($event) && $event->isa(qw(HSDES::RuleEngine::Events::VisibleStateEvent))) {
		# we will get this for enabling disabling a field
		my $state = $event->getState();
		_markFieldVisibleHidden($self,$field,$state);

	}  elsif ( ref($event) && $event->isa(qw(HSDES::RuleEngine::Events::SetValueEvent))) {
		my @values = $event->getValues();
		my $valueToSet = join(",",@values);

		# we could be overwriting a value or appending it
		# this all depends on the action type and the CLEAR flag
		my $actionType = $event->getAction();
		my $clearFlag  = $event->getClear();


		if ($actionType eq "ADD") {
			# typically this would mean ADD to the value
			# unless the clear flag is set
			if (defined($self->{recordData}{$field})) {
				if (length($self->{recordData}{$field}) > 0 && $clearFlag != "1") {

					# before appending; make sure we aren't appending duplicates
					my $oldValue = $self->{recordData}{$field};
					my @oldValuesArray = split(",",$oldValue);

					# convert to a hash for easy manipulation
					my %oldValuesHash = map {$_=>1} @oldValuesArray;
					
					# add new values to this hash
					# get an array first
					my @myArray = split(",",$valueToSet);
					foreach (@myArray)
					{
						$oldValuesHash{$_} = 1;
					}

					# get unique keys + sort them
					my @onlyUnique = sort keys %oldValuesHash;
					
					$valueToSet = join(",",@onlyUnique);
				} 
			}
		} elsif ($actionType eq "REMOVE") {
			# imagine we have comma separated values
			# we need to remove from values
			if (defined($self->{recordData}{$field})) {
				if (length($self->{recordData}{$field}) > 0) {
					my $oldValue = $self->{recordData}{$field};
				
					# convert it to array and then remove any values which are 
					# found in the @values array
					my @oldValuesArray = split(",",$oldValue);

					my %second = map {$_=>1} @values;
					my @onlyInFirst = grep { !$second{$_} } @oldValuesArray; 
					$valueToSet = join(",",@onlyInFirst);

				} else {
					# nothing to remove
					$valueToSet = "";
				}
			} else {
				# nothing to remove
				$valueToSet = "";
			}


		}
		
		$self->{recordData}{$field} = $valueToSet;
	} elsif (ref($event) && $event->isa(qw(HSDES::RuleEngine::Events::RequiredStateEvent))) {
		# we are either making it required or OPTIONAL

		my $required = $event->getState();
		_markFieldRequiredOptional($self,$field,$required);
		
	} elsif (ref($event) && $event->isa(qw(HSDES::RuleEngine::Events::LookupChangeEvent))) {
		# we will be filtering out some lookup values
		my $changeType = $event->getChangeType();


		# got back an array with X elements
		my @valueToSet = $event->getValues();

		# what we should do is save this in a internal data structure
		# just like we do for required fields and read only fields
		if (!defined($self->{filterLookupHash})) {
			my $filterLookupHash = {};
			$self->{filterLookupHash} = $filterLookupHash;
		}

		# now based on the changeType; do the following
		# RELOAD -> replace
		# FILTER -> intersect	
		# ADD -> union

		if ($changeType eq "RELOAD") {
			# remove old and set new
			delete $self->{filterLookupHash}{$field} if exists $self->{filterLookupHash}{$field};
			foreach my $newLookup (@valueToSet) {
				push(@{$self->{filterLookupHash}{$field}},$newLookup);
			}
		} elsif ($changeType eq "ADD") {
			foreach my $newLookup (@valueToSet) {
				push(@{$self->{filterLookupHash}{$field}},$newLookup);
			}
		} elsif ($changeType eq "FILTER") {
			# Goal is to REMOVE lookup values that are NOT in the @valueToSet
			# If the lookup has values(A,B) and the operation is filter(A), then value B is removed from the lookup.
			# If the lookup has values(A,B) and the operation is filter(A,B,C), there is no change.
			if (exists $self->{filterLookupHash}{$field}) {
				# save the intersections of whats saved and new list
				my @existingValues = @{$self->{filterLookupHash}{$field}};
				my @newValues = ();
				my %legal = ();
				foreach (@valueToSet) {
					$legal{lc($_)} = 1;
				}

				foreach my $newLookup (@existingValues) {
					if ($legal{lc($newLookup)}) {
						# found it
						push(@newValues, $newLookup);
					}
				}

				$self->{filterLookupHash}{$field} = \@newValues;
			} else {
				# no existing values found
				$self->{filterLookupHash}{$field} = \@valueToSet;
			}

		}
	} elsif (ref($event) && $event->isa(qw(HSDES::RuleEngine::Events::SaveStateEvent))) {
		# we need to save the state for this field in the event that someone
		# later on may call RestoreEvent. For example; if a field has A,B as valid lookups
		# and then we call SaveState followed by RestoreState; we should restore A,B
		# as the only valid lookups
			

		# NO NEED for us to do anything since we already called the base function
		# which already saves the state internally. We need to really handle the RESTORE
	} elsif (ref($event) && $event->isa(qw(HSDES::RuleEngine::Events::RestoreStateEvent))) {

		# make sure we have some state to restore before we proceed
		if (exists $self->{fieldState}->{$field}) {
			# restore the read only property
			my $enabled = $self->{fieldState}->{$field}->{enabled};	
			_markFieldEnabledDisabled($self,$field,$enabled);

			# restore the required property
			my $required = $self->{fieldState}->{$field}->{required};	
			_markFieldRequiredOptional($self,$field,$required);

			# restore the visible property
			# for PERL; visible just means same as READ ONLY or NOT
			# perhaps we can actually remove it from the hash; but that would be 
			# kinda strange for end user
			my $visible = $self->{fieldState}->{$field}->{visible};
			_markFieldVisibleHidden($self,$field,$visible);

			
			# if isUnfiltered is 1; then that means all lookup values are valid
			# else; we have a list of lookup values from which the user
			# must chose 1
			my $isUnfiltered = $self->{fieldState}->{$field}->{unfiltered};
			my @values = @{$self->{fieldState}->{$field}->{filter}};

			_markFieldLookupFiltered($self,$field,$isUnfiltered,\@values);
		} else {
			# we have no state to restore. So that means restoree it as default
			# What that means for us is to remove any special markings
			# we have done for it
			_restoreFieldState($self,$field);
		}

	}
}



sub getRequiredFields {
	# return a reference to the hash as it may change again
	my $self = shift;
	return $self->{requiredHash};
}

sub getReadOnlyFields {
	# return a reference to the hash as it may change again
	my $self = shift;
	return $self->{readonlyHash};
}

sub getHiddenFields {
	# return a reference to the hash as it may change again
	my $self = shift;
	return $self->{hiddenHash};
}

sub getFilterLookups {
	# return a reference to the hash as it may change again
	my $self = shift;
	return $self->{filterLookupHash};
}

sub setData {
	my $self = shift;
	my $datahash = shift;
	$self->{recordData} = $datahash;
}




# internal functions


=head2 _restoreFieldState
	# 1) Remove field from enable/disable list
	# 2) Remove field from filtered lookups
	# 3) Remove field from required hash

=cut
sub _restoreFieldState {

	my $self = shift;
	my $field = shift;
	delete $self->{readOnlyHash}{$field} if exists $self->{readOnlyHash}{$field};
	delete $self->{hiddenHash}{$field} if exists $self->{hiddenHash}{$field};
	delete $self->{requiredHash}{$field} if exists $self->{requiredHash}{$field};
	delete $self->{filterLookupHash}{$field} if exists $self->{filterLookupHash}{$field};

}


sub _markFieldEnabledDisabled {
	my $self = shift;
	my $field = shift;
	my $enabled = shift;


	# make sure we have an array to save these read only field
	if (!(defined($self->{readonlyHash}))) {
		my $readonlyHash = {};
		$self->{readonlyHash} = $readonlyHash;
	} 

	# depending on the state; we either save it as READONLY 
	# or remove it from a list of READONLY
	if ($enabled) {
		delete $self->{readonlyHash}{$field};
	} else {
		# disabled means its READ ONLY
		$self->{readonlyHash}{$field} = 1;
	}
}

sub _markFieldVisibleHidden {
	my $self = shift;
	my $field = shift;
	my $visible = shift;


	# make sure we have an array to save these hidden fields
	if (!(defined($self->{hiddenHash}))) {
		my $hiddenHash = {};
		$self->{hiddenHash} = $hiddenHash;
	} 

	# depending on the state, we either save it as hidden fields
	# or remove it from a list of hidden fields
	if ($visible) {
		delete $self->{hiddenHash}{$field};
	} else {
		# disabled means its READ ONLY
		$self->{hiddenHash}{$field} = 1;
	}
}

sub _markFieldRequiredOptional {
	my $self = shift;
	my $field = shift;
	my $required = shift;

	# we want to save this in a ARRAY 
	if (!(defined($self->{requiredHash}))) {
		my $requiredHash = {};
		$self->{requiredHash} = $requiredHash;
	} 

	if ($required) {
		$self->{requiredHash}{$field} = 1;
	} else {
		# remove from our hash if we put it in there
		delete $self->{requiredHash}{$field} if exists $self->{requiredHash}{$field};
	}
}

sub _markFieldLookupFiltered {
	my $self = shift;
	my $field = shift;
	my $isUnfiltered = shift;
	my $values = shift;

	my @arrayOfLVs = @$values;

	if (!defined($self->{filterLookupHash})) {
		my $filterLookupHash = {};
		$self->{filterLookupHash} = $filterLookupHash;
	}

	# remove old 
	delete $self->{filterLookupHash}{$field};

	if (!($isUnfiltered)) {
		# set the new filtered list to be the following
		for my $newLookup (@arrayOfLVs) {
			push(@{$self->{filterLookupHash}{$field}},$newLookup);
		}
	}

}

1;

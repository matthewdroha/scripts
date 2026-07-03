package HSDES::Api::ChildRecord;

use warnings;
use strict;

use Carp;
use Data::Dumper;

my $_lastErr;
my $_apiHandle;

sub new {
	my $class = shift;
	$_apiHandle = shift;
	my $data = shift;

	
	my $self = {};

	# add 'send_mail' field to the let the user disable sending email 
        $data->{send_mail} = "true";

	my $tenant = $data->{tenant};
	my $subject = $data->{subject};

	# load the rule engine for this tenant/subject
	# run the onNewRecord EVENTS (such as setting some default values)
	my $combinedRules = HSDES::Api::RuleHelper::RuleUtil::GetRules($_apiHandle, $tenant, $subject);
	my $delegate = new HSDES::Api::RuleHelper::Delegate($_apiHandle);
	my $ruleEngineObj = new HSDES::RuleEngine($delegate);
	$ruleEngineObj->setRules($combinedRules);

	# register customer managers
	my $stateManager = new HSDES::Api::RuleHelper::StateManager();
	my $changeManager = new HSDES::RuleEngine::ChangeManager();
	my $clickManager = new HSDES::RuleEngine::ClickManager();
	$ruleEngineObj->registerWidgets($stateManager, $changeManager, $clickManager);
	$ruleEngineObj->wireUp();


	# give the current hash to the delegate/statemanager so it can SET some values
	$delegate->setData($data);
	$stateManager->setData($data);

	# run the onLoadRecordEvent
	$ruleEngineObj->onLoadRecord();


	# We get back references to hash
	my $requiredFields = $stateManager->getRequiredFields();
	my $readonlyFields = $stateManager->getReadOnlyFields();
	my $hiddenFields = $stateManager->getHiddenFields();
	my $filterLookups  = $stateManager->getFilterLookups();

	# create a cache object
	my $cacheObj = new HSDES::Api::Cache($_apiHandle);
	tie %$data, 'HSDES::Api::ESHash', $data, $changeManager, $clickManager, $stateManager, $cacheObj;

	$self->{_data} = $data;

	# nsshergi
	#  make a COPY not a ref
	my %origdata = %$data;
	$self->{_origdata} = {%origdata};
	bless ($self, $class);
	return $self;
}

sub data {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		die "Should call it on a object\n";
		return 0;
	}
	return $self->{_data};
}

sub update {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		die "Should call it on a object\n";
		return 0;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Unable to find data. Object not constructed propery";
		return 0;
	}

	my $tenant = $self->{_data}{tenant};
	my $subject = $self->{_data}{subject};


	# fire the btnSave event
	my $secretKey = HSDES::Api::ESHash::MARKERFORINTERNALFIELDS . "CLICKMANAGER";
	my $clickManager = $self->{_data}->{$secretKey};
	$clickManager->onButtonClicked("btnSave");

	# does user have ALL required fields set?
	$secretKey = HSDES::Api::ESHash::MARKERFORINTERNALFIELDS . "STATEMANAGER";
	my $stateManager = $self->{_data}->{$secretKey};
	my $requiredFields = $stateManager->getRequiredFields();

	my @missingRequiredFields = ();
	for my $field (keys %$requiredFields) {
		if ($self->{_data}->{$field} eq '') {
			push (@missingRequiredFields, $field);
		}
	}

	if (scalar(@missingRequiredFields)) {
		$self->{_lastErr} = "The following fields are required for $tenant.$subject: " . join(',',@missingRequiredFields);
		return 0;
	}




	# lets figure out what you changed
	my @changedFields = ();
	foreach my $key (keys %{$self->{_data}}) {
		if (defined($self->{_data}->{$key}) && $self->{_data}->{$key} ne $self->{_origdata}->{$key}) {
			push(@changedFields, $key);
		}
	}

	if (scalar(@changedFields)) {
		my $id = $self->{_data}->{id};
		my $rev = $self->{_data}->{rev};

		my %updateData = ();
		foreach my $singleField (@changedFields) {
			$updateData{$singleField} = $self->{_data}->{$singleField};
		}

		my $response = HSDES::Api::Util::callToUpdateService($_apiHandle, $tenant,$subject, $id, $rev, %updateData);
		my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
		if ($isSuccess) {
			return 1;
		} else {
			$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
			return $isSuccess;
		}
	} else {
		$self->{_lastErr} = "No change found\n";
		return 0;
	}

}

sub getLastErrorMessage {
	my $self = shift;
	unless (ref $self) {
		die "Should call it on a object\n";
		return 0;
	}
	return $self->{_lastErr};
}



1;

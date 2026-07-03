package HSDES::Api::Article;

use warnings;
use strict;

use Carp;

use HSDES::Api::ESHash;
use HSDES::Api::ChildRecord;
use HSDES::Api::Cache;
use HSDES::Api::Error;
use HSDES::Api::RuleHelper::RuleUtil;
use Data::Dumper;

# rule engine includes
use HSDES::Api::RuleHelper::Delegate;
use HSDES::Api::RuleHelper::StateManager;
use HSDES::RuleEngine::ChangeManager;
use HSDES::RuleEngine::ClickManager;

my $_apiHandle;
my $_stateManager;

sub new {
	my $class = shift;
	$_apiHandle = shift;
	my $self = {};
	bless ($self, $class);
	return $self;
}

sub load {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	my $id = shift;
	if (!defined $id) {
		$self->{_lastErr} = "Must define id to load article.";
		return 0;
	}

	# technically; the user can give us tenant/subject also
	# but lets treat them as OPTIONAL
	my $tenant = shift;
	my $subject = shift;

	$tenant = "" unless defined($tenant);
	$subject = "" unless defined($subject);

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Record","getRecord", {id=>$id,tenant=>$tenant,subject=>$subject});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $data = $response->{DATA}[0];

		# did we get back anything?
		if (!(defined $data)) {
			my $errMsg = "No article found with id: $id";
			if ($tenant ne "") {
				$errMsg .= " tenant: $tenant";
			}
			if ($subject ne "") {
				$errMsg .= " subject: $subject";
			}
			$self->{_lastErr} = $errMsg;
			return 0;
		}

		# add 'send_mail' field to the let the user disable sending email
                $data->{send_mail} = "true";

		#idayah
		# Moved saving origdata to here before the rules run
		#fix: OnLoad setValues are ignored since origdata and data contain same setValue
		#  make a COPY not a ref
		my %origdata = %$data;
		$self->{_origdata} = {%origdata};

		$tenant = $data->{tenant};
		$subject = $data->{subject};

		# load the rule engine for this tenant/subject
		# run the onNewRecord EVENTS (such as setting some default values)
		my $combinedRules = HSDES::Api::RuleHelper::RuleUtil::GetRules($_apiHandle, $tenant, $subject);
		my $delegate = new HSDES::Api::RuleHelper::Delegate($_apiHandle);
		my $ruleEngineObj = new HSDES::RuleEngine($delegate);
		$ruleEngineObj->setRules($combinedRules);

		# register customer managers
		$_stateManager = new HSDES::Api::RuleHelper::StateManager();
		my $changeManager = new HSDES::RuleEngine::ChangeManager();
		my $clickManagerObj = new HSDES::RuleEngine::ClickManager();
		$ruleEngineObj->registerWidgets($_stateManager, $changeManager, $clickManagerObj);


		# give the current hash to the delegate/statemanager so it can SET some values
		$delegate->setData($data);
		$_stateManager->setData($data);

		$ruleEngineObj->wireUp();
		# run the onLoadRecordEvent
		$ruleEngineObj->onLoadRecord();

		my $cacheObj = $_apiHandle->_getCache();

		tie %$data, 'HSDES::Api::ESHash', $data, $changeManager, $clickManagerObj, $_stateManager, $cacheObj;
		$self->{_data} = $data;


		return $data;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}




sub update {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "must call LOAD first\n";
		return 0;
	}

	my $tenant = $self->{_data}->{tenant};
	my $subject = $self->{_data}->{subject};

	# check user provided fields
	return 0 if(!fieldMissing($self, $self->{_data}));

	my @changedFields = ();
	foreach my $key (keys %{$self->{_data}}) {
		if ($self->{_data}->{$key} ne $self->{_origdata}->{$key}) {
			push(@changedFields, $key);
		}
	}

	if (HSDES::Api::Util::isValidUpdate(\@changedFields)) {
		my $id = $self->{_data}->{id};
		my $rev = $self->{_data}->{rev};

		my %updateData = ();
		foreach my $singleField (@changedFields) {
			$updateData{$singleField} = $self->{_data}->{$singleField};
		}

		# check if the user changes are valid
		return 0 if(!validChanges($self, "$tenant.$subject", \%updateData));

		my $response;
		# May be updating binary data
		if(_containsBinaryField($self, "$tenant.$subject", \%updateData)) {
			$response = HSDES::Api::Util::callToUpdateBinaryService($_apiHandle, $tenant,$subject, $id, $rev, %updateData);
		}
		else {
			$response = HSDES::Api::Util::callToUpdateService($_apiHandle, $tenant,$subject, $id, $rev, %updateData);
		}

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

=head2 newChildArticle
	Creates an empty hash resembling the child subject
	Must pass in childSubject name
=cut
sub newChildArticle {

	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Must call LOAD FIRST\n";
		return 0;
	}

	my $childSubject = shift;
	if (!defined $childSubject) {
		$self->{_lastErr} = "Must provided a child subject name\n";
		return 0;
	}

	return _newChildRecord($self,$childSubject);
}


=head2 newApproval
	Creates an empty hash resembling an approval
=cut
sub newApproval {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Must call LOAD FIRST\n";
		return 0;
	}

	return _newChildRecord($self,"approval");
}


sub newAR {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Must call LOAD FIRST\n";
		return 0;
	}

	return _newChildRecord($self,"ar");
}

sub newAttachment {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Must call LOAD FIRST\n";
		return 0;
	}

	return _newChildRecord($self,"document");
}


sub newComment {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Must call LOAD FIRST\n";
		return 0;
	}

	return _newChildRecord($self,"comments");
}


sub _newChildRecord {
	my $self = shift;
	my $childName = shift;

	my $tenant = $self->{_data}->{tenant};
	my $parentID = $self->{_data}->{id};
	my $subject = $childName;

	# try to get all field names
	my $viewPortName = $tenant . "." . $childName;
	my @validFields = $_apiHandle->_getCache()->getAllFields($viewPortName);

	if (!@validFields) {
		# unable to load field info
		$self->{_lastErr} = $_apiHandle->_getCache()->getLastErrorMessage();
		return 0;
	}
	# make a empty hash and send that back to user
	my %emptyChildHash = ();
	foreach my $singlField (@validFields) {
		$emptyChildHash{$singlField} = "";
	}

	# set these fields by default
	$emptyChildHash{"tenant"} = $tenant;
	$emptyChildHash{"subject"} = $subject;
	$emptyChildHash{"parent_id"} = $parentID;

=pod
	# Create a draft record
	my $module = "Record";
	my $function = "getNewID";
	my $newIDResponse = HSDES::Api::Util::callToWService(
				$_apiHandle, $module, $function,
				{subject=>$subject,tenant=>$tenant,parentID=>$parentID});
	my $newIDSuccess = HSDES::Api::Util::IS_SUCCESS($newIDResponse);
	if ($newIDSuccess) {
		$emptyChildHash{"id"} = $newIDResponse->{DATA}[0]{newID};
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($newIDResponse);
		return $newIDSuccess;
	}
=cut

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
	$delegate->setData(\%emptyChildHash);
	$stateManager->setData(\%emptyChildHash);
	$ruleEngineObj->onNewRecord();

	tie %emptyChildHash, 'HSDES::Api::ESHash', \%emptyChildHash, $changeManager, $clickManager, $stateManager, $_apiHandle->_getCache();

	return \%emptyChildHash;
}


sub newArticle {
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	my $tenant = shift;
	my $subject = shift;

	if (!defined $tenant) {
		$self->{_lastErr} = "Must define tenant to create new article.";
		return 0;
	}

	if (!defined $subject) {
		$self->{_lastErr} = "Must define SUBJECT to create new article.";
		return 0;
	}

	my $viewPortName = $tenant . "." . $subject;
	my @validFields = $_apiHandle->_getCache()->getAllFields($viewPortName);

	if (!(@validFields)) {
		# unable to load field info
		$self->{_lastErr} = $_apiHandle->_getCache()->getLastErrorMessage();
		return 0;
	}


	# make a empty hash and send that back to user
	my %emptyHash = ();
	foreach my $singlField (@validFields) {
		$emptyHash{$singlField} = "";
	}

	# set these fields by default
	$emptyHash{"tenant"} = $tenant;
	$emptyHash{"subject"} = $subject;

=pod
	# retrieve new ID (goes in as draft record)
	my $module = "Record";
	my $function = "getNewID";
	my $newIDResponse = HSDES::Api::Util::callToWService(
				$_apiHandle, $module, $function,
				{subject=>$subject,tenant=>$tenant});
	my $newIDSuccess = HSDES::Api::Util::IS_SUCCESS($newIDResponse);
	if ($newIDSuccess) {
		$emptyHash{"id"} = $newIDResponse->{DATA}[0]{newID};
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($newIDResponse);
		return $newIDSuccess;
	}
=cut

	# load the rule engine for this tenant/subject
	# run the onNewRecord EVENTS (such as setting some default values)
	my $combinedRules = HSDES::Api::RuleHelper::RuleUtil::GetRules($_apiHandle, $tenant, $subject);
	my $delegate = new HSDES::Api::RuleHelper::Delegate($_apiHandle);
	my $ruleEngineObj = new HSDES::RuleEngine($delegate);
	$ruleEngineObj->setRules($combinedRules);

	# register customer managers
	$_stateManager = new HSDES::Api::RuleHelper::StateManager();
	my $changeManager = new HSDES::RuleEngine::ChangeManager();
	my $clickManager = new HSDES::RuleEngine::ClickManager();
	$ruleEngineObj->registerWidgets($_stateManager, $changeManager, $clickManager);
	$ruleEngineObj->wireUp();


	# give the current hash to the delegate/statemanager so it can SET some values
	$delegate->setData(\%emptyHash);
	$_stateManager->setData(\%emptyHash);
	$ruleEngineObj->onNewRecord();

	# pass these along to the hash
	tie %emptyHash, 'HSDES::Api::ESHash', \%emptyHash, $changeManager, $clickManager, $_stateManager, $_apiHandle->_getCache();

	return \%emptyHash;
}



=pod

=cut
sub addChildArticle {

	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Must call LOAD FIRST\n";
		return 0;
	}

	my $childSubject = shift;
	if (!defined $childSubject) {
		$self->{_lastErr} = "Must provided a child subject name\n";
		return 0;
	}


	my $childData = shift;
	return _insertChild($self,$childSubject,$childData);
}


sub addAR {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Must call LOAD FIRST\n";
		return 0;
	}

	my $arData = shift;
	return _insertChild($self,"ar",$arData);
}

sub addApproval {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Must call LOAD FIRST\n";
		return 0;
	}

	my $arData = shift;
	return _insertChild($self,"approval",$arData);
}

sub addAttachment {
	# must be called on a OBJECT
	my $self = shift;
	my $attachmentData = shift;

	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Must call LOAD FIRST\n";
		return 0;
	}

	# Default field/values
	my %defaultFields = (
		'parent_id' => '',
		'title' => '',
		'document.file' => '',
		'document.path' => '',
		'tag' => '',
		'tenant' => '',
		'subject' => '',
		'description' => '',
		'document.file_name' => '',
		'document.version' => '',
		'document.height' => '',
		'document.width' => '',
		'document.size' => '',
		'relationship' => 'attachment',
		'send_mail' => 'false',
	);

	# Get user values for the fields
	foreach my $k (keys %defaultFields) {
	    $attachmentData->{$k} = $defaultFields{$k} if(!exists($attachmentData->{$k}));
	}

	return _insertChild($self,"document",$attachmentData);
}

sub downloadAttachment {
	# must be called on a OBJECT
	my $self = shift;
	my $id = shift;
	my $fileName = shift;
	my $filePath = shift;

	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# must provide id
	if (!$id) {
		$self->{_lastErr} = "Must provide record ID to download attachment from.\n";
		return 0;
	}

	# must provide file name
	if (!$fileName) {
		$self->{_lastErr} = "Must provide file name for the attachment.\n";
		return 0;
	}

	# must provide path
	if (!$filePath || !-w $filePath) {
		$self->{_lastErr} = "Must provide path to save the attachment.\n";
		return 0;
	}

	my $response = HSDES::Api::Util::callToDownloadBinaryService($_apiHandle, $id, $fileName, $filePath);
	return HSDES::Api::Util::IS_SUCCESS($response);
}

sub addComment {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Must call LOAD FIRST\n";
		return 0;
	}

	my $arData = shift;
	return _insertChild($self,"comments",$arData);
}

sub insert {
	my $self = shift;
	my $data = shift;
	my $tenant = $data->{tenant};
	my $subject = $data->{subject};

	# Check user provided fields
        return 0 if(!fieldMissing($self, $data));

	# we should only take fields that user set some value to
	my %insertHash = ();
	foreach my $singleField (keys %$data) {
		if (defined $data->{$singleField} && $data->{$singleField} ne '') {
			$insertHash{$singleField} = $data->{$singleField};
		}
	}

	# check if the user changes are valid
	return 0 if(!validChanges($self, "$tenant.$subject", \%insertHash));

	my $response;
	if(_containsBinaryField($self, "$tenant.$subject", \%insertHash)) {
		$response = HSDES::Api::Util::callToInsertBinaryService($_apiHandle, $tenant,$subject, \%insertHash);
	}
	else {
		$response = HSDES::Api::Util::callToInsertService($_apiHandle, $tenant,$subject, \%insertHash);
	}

	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $record = $response->{DATA}[0];
		return $record->{newId};
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}

sub _insertChild {
	my $self = shift;
	my $subject = shift;
	my $childData = shift;
	my $id = $self->{_data}->{id};
	my $tenant = $self->{_data}->{tenant};



	my $secretKey = HSDES::Api::ESHash::MARKERFORINTERNALFIELDS . "STATEMANAGER";
	my $stateManager = $childData->{$secretKey};
	my $requiredFields = $stateManager->getRequiredFields();

	my @missingRequiredFields = ();
	for my $field (keys %$requiredFields) {
		if ($childData->{$field} eq '') {
			push (@missingRequiredFields, $field);
		}
	}

	if (scalar(@missingRequiredFields)) {
		$self->{_lastErr} = "The following fields are required for $tenant.$subject: " . join(',',@missingRequiredFields);
		return 0;
	}

	# we should only take fields that user set
	my %insertChildHash = ();
	foreach my $singleField (keys %$childData) {
		if (defined $childData->{$singleField} && $childData->{$singleField} ne '') {
			$insertChildHash{$singleField} = $childData->{$singleField};
		}
	}

	# check if the user changes are valid
	return 0 if(!validChanges($self, "$tenant.$subject", \%insertChildHash));

	$insertChildHash{'parent_id'} = $id;

	my $response;
	if(_containsBinaryField($self, "$tenant.$subject", \%insertChildHash)) {
		$response = HSDES::Api::Util::callToInsertBinaryService($_apiHandle, $tenant,$subject, \%insertChildHash);
	}
	else {
		$response = HSDES::Api::Util::callToInsertService($_apiHandle, $tenant,$subject, \%insertChildHash);
	}

	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $record = $response->{DATA}[0];
		return $record->{newId};
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}

=head2 getChildArticles
	Must pass in the name of the child subject
=cut
sub getChildArticles {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Must call LOAD FIRST\n";
		return 0;
	}


	my $childSubject = shift;
	if (!defined $childSubject) {
		$self->{_lastErr} = "Must provided a child subject name\n";
		return 0;
	}

	my $parentID = $self->{_data}->{id};
	my $searchText = "[parent_id] = $parentID";

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Viewport","execute", {viewportName=>$childSubject,searchText=>$searchText});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {

		my @childArray = ();
		foreach my $singleAR (@{$response->{DATA}}) {
			HSDES::Api::Util::REMOVE_SYSTEM_FIELDS($singleAR);
			my $arOBj = HSDES::Api::ChildRecord->new($_apiHandle, $singleAR);
			push (@childArray, $arOBj);
		}

		return @childArray;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}

}

sub getApprovals {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Must call LOAD FIRST\n";
		return 0;
	}

	my $id = $self->{_data}->{id};
	my $tenant = $self->{_data}->{tenant};

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Record","getApprovals", {id=>$id,tenant=>$tenant});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {

		my @approvalArray = ();
		foreach my $singleAR (@{$response->{DATA}}) {
			HSDES::Api::Util::REMOVE_SYSTEM_FIELDS($singleAR);
			my $arOBj = HSDES::Api::ChildRecord->new($_apiHandle, $singleAR);
			push (@approvalArray, $arOBj);
		}

		return @approvalArray;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}

}

sub getARS {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Must call LOAD FIRST\n";
		return 0;
	}

	my $id = $self->{_data}->{id};
	my $tenant = $self->{_data}->{tenant};

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Record","getArs", {id=>$id,tenant=>$tenant});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {

		my @arArray = ();
		foreach my $singleAR (@{$response->{DATA}}) {
			HSDES::Api::Util::REMOVE_SYSTEM_FIELDS($singleAR);
			my $arOBj = HSDES::Api::ChildRecord->new($_apiHandle, $singleAR);
			push (@arArray, $arOBj);
		}

		return @arArray;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}


sub getComments {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "Must call LOAD FIRST\n";
		return 0;
	}

	my $id = $self->{_data}->{id};
	my $tenant = $self->{_data}->{tenant};

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Record","getComments", {id=>$id,tenant=>$tenant});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {

		my @commentArray = ();
		foreach my $singleComment (@{$response->{DATA}}) {
			HSDES::Api::Util::REMOVE_SYSTEM_FIELDS($singleComment);
			my $commentObj = HSDES::Api::ChildRecord->new($_apiHandle, $singleComment);
			push (@commentArray, $commentObj);
		}

		return @commentArray;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}


sub getLinkedRecords {
	# must be called on a OBJECT
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	# do we have data?
	if (!defined $self->{_data}) {
		$self->{_lastErr} = "must call LOAD first\n";
		return 0;
	}
	my $id = $self->{_data}->{id};
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Record","getRelatedRecords", {id=>$id});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $data = $response->{DATA};
		return $data;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}

sub getLastErrorMessage {
	my $self = shift;
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}
	return $self->{_lastErr};
}

sub _containsBinaryField {
	my $self = shift;
	my $viewportName = shift;
	my $data = shift;

	# Binary fields
	my @binaryFields = $_apiHandle->_getCache()->getBinaryFields($viewportName);

	# Check if data has binary field
	foreach my $field (keys %{$data}) {
		if (HSDES::Api::Util::DOES_KEY_EXIST_IN_ARRAY(\@binaryFields, $field)) {
			return 1;
		}
	}
	return 0;
}

sub fieldMissing {
	my $self = shift;
	my $data = shift;
	my $tenant = $data->{tenant};
	my $subject = $data->{subject};

	# fire the btnSave event
	my $secretKey = HSDES::Api::ESHash::MARKERFORINTERNALFIELDS . "CLICKMANAGER";
	my $clickManager = $data->{$secretKey};
	eval {$clickManager->onButtonClicked("btnSave");};
	if($@) {
		$self->{_lastErr} = $@;
		return 0;
	}

	$secretKey = HSDES::Api::ESHash::MARKERFORINTERNALFIELDS . "STATEMANAGER";
	my $stateManager = $data->{$secretKey};
	my $requiredFields = $stateManager->getRequiredFields();
	my @missingRequiredFields = ();
	for my $field (keys %$requiredFields) {
		if ($data->{$field} eq '') {
			push (@missingRequiredFields, $field);
		}
	}

	if (scalar(@missingRequiredFields)) {
		$self->{_lastErr} = "The following fields are required for $tenant.$subject: " . join(',',@missingRequiredFields);
		return 0;
	}
	return 1;
}

=head1 SYNOPSIS
	This subj will be used to do some data validation
	before calling the MiddleTier.
	As of ww21_2013; this is only checking the People/Person fields

	This is being called from
		1) update
		2) insert
		3) _insertChild

	Author: nsshergi
=cut
sub validChanges {
	my $self         = shift;
        my $viewportName = shift;
	my $changes      = shift;

	# we are only going to check the People/Person fields
	# iterate over all changes and do further checks if
	# one of the changed field is of type person/people
	my @personFields = $_apiHandle->_getCache()->getPersonFields($viewportName);
	my @peopleFields = $_apiHandle->_getCache()->getPeopleFields($viewportName);

        # Check user modified fields; mainly Person/People fields
        foreach my $field (keys %$changes) {
		# what type of field is this?
		if (HSDES::Api::Util::DOES_KEY_EXIST_IN_ARRAY(\@personFields, $field)) {
			# this is a single person. There should be no comma/semicolon in here
			# Technically we should be able tos end the value as is to BE and have it return true/false
			# but BE SP treats semicolon separated idsid as valid. We have to break it up :(
			my $valueToCheck = $changes->{$field};
			if ($valueToCheck =~ /\;/) {
				$self->{_lastErr} = "Error: field '$field' cannot contain ';'.";
				return 0;
			}

			if ($valueToCheck =~ /\,/) {
				$self->{_lastErr} = "Error: field '$field' cannot contain ','.";
				return 0;
			}

			# whatever we get now; assume its single idsid and let db validate it
			if(!HSDES::Api::Util::IsValidIDSID($_apiHandle, $valueToCheck)) {
				$self->{_lastErr} = "Error: $valueToCheck is an invalid idsid for [$field]";
				return 0;
			}

		} # if person field

		if (HSDES::Api::Util::DOES_KEY_EXIST_IN_ARRAY(\@peopleFields, $field)) {
			# This must be a comma separated list of idsid
			# Technically we should be able tos end the value as is to BE and have it return true/false
			# but BE SP treats semicolon separated idsid as valid. We have to break it up :(
			my $valueToCheck = $changes->{$field};
			if ($valueToCheck =~ /\;/) {
				$self->{_lastErr} = "Error: field '$field' cannot contain ';'.";
				return 0;
			}

			# what is left; split it on a comma and verify each one
			my @people = split(",", $changes->{$field});
			foreach my $person (@people) {
				if(!HSDES::Api::Util::IsValidIDSID($_apiHandle, $person)) {
					$self->{_lastErr} = "Error: $person is an invalid idsid for [$field]";
					return 0;
				}
			}
		} # if people field
	} # for each changed field

	return 1;
}

sub getReadOnlyFields {
	my $self = shift;

	if(!$_stateManager) {
		$self->{_lastErr} = "Error: unable to get read only fields.\nPlease call load() or newArticle() first.";
		return undef;
	}
	return $_stateManager->getReadOnlyFields();
}

sub getHiddenFields {
	my $self = shift;

	if(!$_stateManager) {
		$self->{_lastErr} = "Error: unable to get hidden fields.\nPlease call load() or newArticle() first.";
		return undef;
	}
	return $_stateManager->getHiddenFields();
}

sub getRequiredFields {
	my $self = shift;

	if(!$_stateManager) {
		$self->{_lastErr} = "Error: unable to get required fields.\nPlease call load() or newArticle() first.";
		return undef;
	}
	return $_stateManager->getRequiredFields();
}

sub getLookupFields {
	my $self = shift;

	if(!$_stateManager) {
		$self->{_lastErr} = "Error: unable to get lookup fields.\nPlease call load() or newArticle() first.";
		return undef;
	}
	return $_stateManager->getFilterLookups();
}


1;

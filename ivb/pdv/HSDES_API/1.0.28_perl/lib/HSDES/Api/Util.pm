package HSDES::Api::Util;

use warnings;
use strict qw(vars refs);
use Carp;
use File::Spec;
use HTTP::Response;

# conditionally compile libcurl
BEGIN { if($^O eq "linux") { require WWW::Curl::Easy; WWW::Curl::Easy->import; require WWW::Curl::Multi; require WWW::Curl::Form;}}
use Data::Dumper;
use JSON;
use HSDES::Api::Constant;

my %SERVERMAPPING  = (
	'INTEGRATION' => 'hsdes-int.intel.com',
	'HTTPTEST' => 'httpstat.us/502',
	'PREPRODUCTION' => 'hsdes-api-pre.intel.com',
	'PRODUCTION' => 'hsdes-api.intel.com',
	'STABLE' => 'hsdes-api-stable.intel.com',
	'LOCALHOST'  => 'localhost:8888',
	#'LOCALHOST'  => '10.19.149.7:8888',
);

my $_uuid;
my $_utcOffset = "";

# number of times to retry for Perl SLES10
# incomplete data from Apache issue
use constant MAXRETRY => "5";
use constant HSDAUTHREALM => "HSD";

sub callGenericService {
	my ($apiHandle, $args) = @_;
	my $module = "Generic";
	my $function = "callService";

	return callToWService($apiHandle, $module, $function, $args);
}

sub callToWService {
	my ($apiHandle, $module, $function, $args) = @_;

	my %header_hash = _getHeaderForJSON($apiHandle, $module,$function);
	my %data_hash = ('DATA'=>$args);
	my %big_hash = ('HEADER'=>\%header_hash, 'DATA'=>$args);
	my $json = encode_json \%big_hash;

	return _sendJsonToWService($json,$apiHandle);
}

sub callToWServiceVarArgs {
	my ($apiHandle, $module, $function, $reqArgs, $varArgs) = @_;

	my %header_hash = _getHeaderForJSON($apiHandle, $module, $function);
	my %big_hash = ('HEADER'=>\%header_hash, 'DATA'=>$reqArgs, 'ARGS'=>$varArgs);
	my $json = encode_json \%big_hash;

	return _sendJsonToWService($json,$apiHandle);
}

sub callToInsertService {
	my ($apiHandle, $tenant, $subject, $args) = @_;

	my %header_hash = _getHeaderForJSON($apiHandle, "Inserter","insert");
	my %data_section = ('tenant'=>$tenant, 'subject'=>$subject);
	my %big_hash = ('HEADER'=>\%header_hash, 'DATA'=>\%data_section, 'ARGS'=>$args);
	my $json = encode_json \%big_hash;

	return _sendJsonToWService($json,$apiHandle);
}

sub callToInsertBinaryService {
	my ($apiHandle, $tenant, $subject, $args) = @_;
	my $wsOutput;

	$args->{'REQUESTED_MODULE'} = "Inserter";
	$args->{'REQUESTED_FUNCTION'} = "insert";

	# Add command
	if ( $^O eq "linux" ) {
		$wsOutput =  _sendJsonToBinaryWServiceLinux($apiHandle, $tenant, $subject, $args);
	} else {
		die("The API doesn't currently support binary data for Windows\n");
	}

	$_uuid = $wsOutput->{HEADER}[0]{UUID};
	return $wsOutput;
}

sub callToDownloadBinaryService {
	my ($apiHandle, $id, $fileName, $filePath) = @_;
	my $wsOutput;

	my %args;
	$args{'REQUESTED_MODULE'} = "BinaryDownload";
	$args{'REQUESTED_FUNCTION'} = "downloadAttachment";
	$args{'MTcore_id'} = $id;

	# Add command
	if ( $^O eq "linux" ) {
		$wsOutput =  _sendJsonToDownloadBinaryWServiceLinux($apiHandle, $fileName, $filePath, \%args);
	} else {
		die("The API doesn't currently support binary data for Windows\n");
	}

	$_uuid = $wsOutput->{HEADER}[0]{UUID};
	return $wsOutput;
}


sub callToUpdateBinaryService {
	my $apiHandle = shift;
	my $tenant = shift;
	my $subject = shift;
	my $id = shift;
	my $rev = shift;
	my %args = @_;
	my $wsOutput;

	$args{'REQUESTED_MODULE'} = "Updater";
	$args{'REQUESTED_FUNCTION'} = "update";

	# FileUpload WS requires ID and Rev to be passed in these two fields
	$args{'MTcore_id'} = $id;
	$args{'MTcore_rev'} = $rev;

	# Add command
	if ( $^O eq "linux" ) {
		$wsOutput =  _sendJsonToBinaryWServiceLinux($apiHandle, $tenant, $subject, \%args);
	} else {
		die("The API doesn't currently support binary data for Windows\n");
	}

	return $wsOutput;
}


sub callToUpdateService {
	my $apiHandle = shift;
	my $tenant = shift;
	my $subject = shift;
	my $id = shift;
	my $rev = shift;
	my %args = @_;

	my %header_hash = _getHeaderForJSON($apiHandle, "Updater","update");
	my %data_section = ('tenant'=>$tenant, 'subject'=>$subject, 'id'=>$id, 'rev'=>$rev);
	my %big_hash = ('HEADER'=>\%header_hash, 'DATA'=>\%data_section, 'ARGS'=>\%args);
	my $json = encode_json \%big_hash;

	return _sendJsonToWService($json,$apiHandle);
}

sub _sendJsonToWService {
	my $wsOutput;
	if ( $^O eq "linux" ) {
		$wsOutput =  _sendJsonToWServiceLinux(@_);
	} else {
		require Win32::OLE;
		Win32::OLE->import();
		$wsOutput =  _sendJsonToWServiceWindows(@_);
	}

	$_uuid = $wsOutput->{HEADER}[0]{UUID};
	return $wsOutput;
}

=pod
=head2 _getHeaderForJSON
This will build up a baseline json section that must be
passed with EACH call to the ES WS

=cut
sub _getHeaderForJSON {
	my ($apiHandle, $module, $function) = @_;

	# figure out UTC offset
	my $utcOffset = _getUTCOffset($apiHandle);

	# add in application name
	my $applicationName = "HSD-ES Perl API ".$apiHandle->VERSION." ".$0;
	my %header_hash = ('APPLICATION_NAME' => $applicationName, 'REQUESTED_MODULE'=>"$module", 'REQUESTED_FUNCTION'=>"$function", 'UTCOFFSET'=>"$utcOffset");

        # send the UUID if available
	$header_hash{'UUID'} = $_uuid if($_uuid);

	return %header_hash;
}

sub _sendJsonToDownloadBinaryWServiceLinux {
	my ($apiHandle, $fileName, $filePath, $args)  = @_;

	my $form = WWW::Curl::Form->new();
	foreach my $k (keys %{$args}) {
		$form->formadd($k, $args->{$k});
	}

  	#Open the filehandle
	my $fh;
  	open($fh, ">$filePath/$fileName") or die "\nopen: $!\n\n";
  	binmode $fh;

	my $mode = $apiHandle->_getMode();
	my $wsEndpoint = "/ws/fileupload/upload";
	if ($apiHandle->_isHSDAuthEnabled()) {
		$wsEndpoint = "/ws/basicauth";
	}

	my $customHTTPSPort = $apiHandle->_getHTTPSPort();

	my $completeUrl = "https://" . $SERVERMAPPING{$mode} . ":$customHTTPSPort" . $wsEndpoint;
	# Change prefix to Url http if running on localhost
        if($mode eq 'LOCALHOST') {
		$completeUrl = "http://" . $SERVERMAPPING{$mode} . $wsEndpoint;
        }

	# set User-Agent headr string for the API
	my $apiVersion = "HSD-ES Perl API ".$apiHandle->VERSION." ".$0;

	my $curl = WWW::Curl::Easy->new();
	$curl->setopt(CURLOPT_CAPATH, '/usr/intel/common/pkgs/openssl/certs');
	$curl->setopt(CURLOPT_CONNECTTIMEOUT, 30);
	$curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
	$curl->setopt(CURLOPT_POST, 1);
	$curl->setopt(CURLOPT_HTTPAUTH, CURLAUTH_GSSNEGOTIATE);

	# ignore ssl verification
	$curl->setopt(CURLOPT_SSL_VERIFYPEER,0);

	# do this to make the subjectAltName working
	$curl->setopt(CURLOPT_SSLVERSION, CURL_SSLVERSION_TLSv1);

	my $loginid = getlogin || getpwuid($<);

	if ($apiHandle->_isHSDAuthEnabled()) {
		# send along the hsd username and password
		# hsdes-api-int.intel.com:443
		$loginid = $apiHandle->_getHSDUsername;
		$curl->setopt(CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
		$curl->setopt(CURLOPT_USERNAME, $loginid);
		$curl->setopt(CURLOPT_PASSWORD, $apiHandle->_getHSDPassword());
	}

	$curl->setopt(CURLOPT_USERNAME, $loginid);

	my $response;
	$curl->setopt(CURLOPT_WRITEDATA, \$response);
	$curl->setopt(CURLOPT_URL, $completeUrl);
	$curl->setopt(CURLOPT_HTTPPOST, $form);
	$curl->setopt(CURLOPT_FILE, *$fh);
	my $retcode = $curl->perform();

	close($fh);
#=pod
	my $httpstatus = $curl->getinfo(CURLINFO_HTTP_CODE);

	if ($httpstatus == 200) {
		my %wsOutput = % {decode_json(_buildSuccessMessage())};
		return \%wsOutput;
	} else {
		my %output = % {decode_json(_buildErrorMessage($httpstatus, $response))};
		return \%output;
	}
#=cut
}

sub _sendJsonToBinaryWServiceLinux {
	my ($apiHandle, $tenant, $subject, $args)  = @_;

	# FileUpload WS requires tenant and subject be passed in these 2 fields
	$args->{'MTcore_tenant'} = $tenant;
	$args->{'MTcore_subject'} = $subject;

	my $mode = $apiHandle->_getMode();
	my $wsEndpoint = "/ws/fileupload/upload";
	if ($apiHandle->_isHSDAuthEnabled()) {
		#$wsEndpoint = "/ws/basicauth";
		$wsEndpoint = "/ws/ESService/fileupload/upload/auth";
		$args->{'command'} = 'insert_attachment';
		$args->{'id'} = $args->{'parent_id'};
	}

	# Get the binary fields
	my @binaryFields = $apiHandle->_getCache()->getBinaryFields("$tenant.$subject");

	my $form = WWW::Curl::Form->new();
	foreach my $k (keys %{$args}) {
	    if (HSDES::Api::Util::DOES_KEY_EXIST_IN_ARRAY(\@binaryFields, $k)) {
        	$form->formaddfile($args->{$k}, $k, 'multipart/form-data');
    	    } else {
        	$form->formadd($k, $args->{$k});
    	    }
	}

	my $customHTTPSPort = $apiHandle->_getHTTPSPort();

	my $completeUrl = "https://" . $SERVERMAPPING{$mode} . ":$customHTTPSPort" . $wsEndpoint;
	# Change prefix to Url http if running on localhost
        if($mode eq 'LOCALHOST') {
		$completeUrl = "http://" . $SERVERMAPPING{$mode} . $wsEndpoint;
        }

	# set User-Agent headr string for the API
	my $apiVersion = "HSD-ES Perl API ".$apiHandle->VERSION." ".$0;

	my $curl = WWW::Curl::Easy->new();
	$curl->setopt(CURLOPT_CAPATH, '/usr/intel/common/pkgs/openssl/certs');
	$curl->setopt(CURLOPT_CONNECTTIMEOUT, 30);
	$curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
	$curl->setopt(CURLOPT_POST, 1);
	$curl->setopt(CURLOPT_HTTPAUTH, CURLAUTH_GSSNEGOTIATE);

	# ignore ssl verification
	$curl->setopt(CURLOPT_SSL_VERIFYPEER,0);

	# do this to make the subjectAltName working
	$curl->setopt(CURLOPT_SSLVERSION, CURL_SSLVERSION_TLSv1);

	my $loginid = getlogin || getpwuid($<);

	if ($apiHandle->_isHSDAuthEnabled()) {
		# send along the hsd username and password
		# hsdes-api-int.intel.com:443
		$loginid = $apiHandle->_getHSDUsername;
		$curl->setopt(CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
		$curl->setopt(CURLOPT_USERNAME, $loginid);
		$curl->setopt(CURLOPT_PASSWORD, $apiHandle->_getHSDPassword());
	}

	$curl->setopt(CURLOPT_USERNAME, $loginid);

	my $response;
	$curl->setopt(CURLOPT_WRITEDATA, \$response);
	$curl->setopt(CURLOPT_URL, $completeUrl);
	$curl->setopt(CURLOPT_HTTPPOST, $form);
	my $retcode = $curl->perform();

	my $httpstatus = $curl->getinfo(CURLINFO_HTTP_CODE);
	if ($httpstatus == 200) {
		my %wsOutput = % {decode_json($response)};
		# consider existense of reponse as public API (this is document upload case with basic auth)
		if ( exists $wsOutput{responses} ) {
			$wsOutput{HEADER} = $wsOutput{responses};
			$wsOutput{HEADER}[0]{STATUS} = uc($wsOutput{HEADER}[0]{status});
			$wsOutput{DATA}[0] = $wsOutput{responses}[0]{result_params};
			$wsOutput{DATA}[0]{DETAILS} = $wsOutput{responses}[0]{messages}[0];
		}
		return \%wsOutput;
	} else {
		my %output = % {decode_json(_buildErrorMessage($httpstatus, $response))};
		return \%output;
	}
}

sub _sendJsonToWServiceLinux {
	my $json = shift;
	my $apiHandle = shift;


	my $mode = $apiHandle->_getMode();
	my $wsEndpoint = "/ws/eswebservice";
	if ($apiHandle->_isHSDAuthEnabled()) {
		$wsEndpoint = "/ws/basicauth";
	}

	my $customHTTPSPort = $apiHandle->_getHTTPSPort();

	my $completeUrl = "https://" . $SERVERMAPPING{$mode} . ":$customHTTPSPort" . $wsEndpoint;
	# Change prefix to Url http if running on localhost
    if($mode eq 'LOCALHOST') {
		$completeUrl = "http://" . $SERVERMAPPING{$mode} . $wsEndpoint;
    }
    if($mode eq 'HTTPTEST') {
    	$completeUrl = "http://" . $SERVERMAPPING{$mode};
    }

	# set User-Agent headr string for the API
	my $apiVersion = "HSD-ES Perl API ".$apiHandle->VERSION." ".$0;

	my $curl = WWW::Curl::Easy->new();
	$curl->setopt(CURLOPT_CAPATH, '/usr/intel/common/pkgs/openssl/certs');
	$curl->setopt(CURLOPT_CONNECTTIMEOUT, 30);
	$curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
	$curl->setopt(CURLOPT_POST, 1);
	$curl->setopt(CURLOPT_HTTPHEADER, ['Content-Type: text/json', 'User-Agent: ' . $apiVersion ]);
	$curl->setopt(CURLOPT_HTTPAUTH, CURLAUTH_GSSNEGOTIATE);

	# ignore ssl verification
	$curl->setopt(CURLOPT_SSL_VERIFYPEER,0);
	$curl->setopt(CURLOPT_SSL_VERIFYHOST,0);

	# do this to make the subjectAltName working
	$curl->setopt(CURLOPT_SSLVERSION, CURL_SSLVERSION_TLSv1);

	# enable gzip compression
	$curl->setopt(CURLOPT_ENCODING, "gzip, deflate");

	my $loginid = getlogin || getpwuid($<);

	if ($apiHandle->_isHSDAuthEnabled()) {
		# send along the hsd username and password
		# hsdes-api-int.intel.com:443
		$loginid = $apiHandle->_getHSDUsername;
		$curl->setopt(CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
		$curl->setopt(CURLOPT_USERNAME, $loginid);
		$curl->setopt(CURLOPT_PASSWORD, $apiHandle->_getHSDPassword());
	}

	$curl->setopt(CURLOPT_USERNAME, $loginid);

	my $response;
	$curl->setopt(CURLOPT_WRITEDATA, \$response);
	$curl->setopt(CURLOPT_URL, $completeUrl);
	$curl->setopt(CURLOPT_POSTFIELDS, $json);
	my $retcode = $curl->perform();

	my $httpstatus = $curl->getinfo(CURLINFO_HTTP_CODE);
	if ($httpstatus == 200) {
		my %wsOutput = % {decode_json($response)};
		return \%wsOutput;
	} else {
		my %output = % {decode_json(_buildErrorMessage($httpstatus, $response))};
		return \%output;
	}

}

sub _sendJsonToWServiceWindows {
    my $json = shift;
    my $apiHandle = shift;


    my $mode = $apiHandle->_getMode();
    my $wsEndpoint = "/ws/eswebservice";
    if ($apiHandle->_isHSDAuthEnabled()) {
	    $wsEndpoint = "/ws/basicauth";
    }

    my $customHTTPSPort = $apiHandle->_getHTTPSPort();
    my $completeUrl = "https://" . $SERVERMAPPING{$mode} . ":$customHTTPSPort" . $wsEndpoint;
	# Change prefix to Url http if running on localhost
    if($mode eq 'LOCALHOST') {
	    $completeUrl = "http://" . $SERVERMAPPING{$mode} . $wsEndpoint;
    }

    my $xmlhttp = Win32::OLE->new('MSXML2.XMLHTTP.6.0');

    # set User-Agent headr string for the API
    my $apiVersion = "HSD-ES Perl API ".$apiHandle->VERSION." ".$0;

    # send Basic Auth headers if enabled
    if ($apiHandle->_isHSDAuthEnabled()) {
        $xmlhttp->open('POST', $completeUrl, 0, $apiHandle->_getHSDUsername, $apiHandle->_getHSDPassword );
        $xmlhttp->setRequestHeader('Authorization', 'Basic');
     }
     else {
        $xmlhttp->open('POST', $completeUrl, 0, "", "" );
     }
    $xmlhttp->setRequestHeader('Content-type', 'text/json');
    $xmlhttp->setRequestHeader('User-Agent', $apiVersion);
    $xmlhttp->send($json);
    my $olestatus = Win32::OLE->LastError();
    if ( $olestatus != 0 ) {
	print $olestatus;
	return undef;
    }

    my $status = $xmlhttp->{status};

    if ( $status >= 200 && $status < 300 ) {

	my %wsOutput = %{decode_json($xmlhttp->{responseText})};
	return \%wsOutput;
    } else {
	die $xmlhttp->{statusText};
    }
}


=pod
Builds a ES compatible JSON error message
=cut
sub _buildErrorMessage {
	my ($httpstatus, $response) = @_;

	my $detailMsg = "";

	if ($httpstatus == 401) {
		$detailMsg = "Unable to authenticate to HSD-ES";
	} elsif (!$httpstatus && !$response) {
		$detailMsg = "No response from HTTPS.";
		if ( $ENV{HTTPS_PROXY} ) { $detailMsg .= " Try to unsetenv HTTPS_PROXY" };
		if ( $ENV{https_proxy} ) { $detailMsg .= " Try to unsetenv https_proxy" };
	} else {
		$detailMsg = "Unable to communicate to HSDES API Server: $response";
	}

	my $errorData = {
		HEADER => [{ 'STATUS', 'ERROR' }],
		DATA => [{ 'SUMMARY',  'ERROR' ,
			  'DETAILS', $detailMsg}
			],
	};
	return encode_json($errorData);
}

=pod
Builds a ES compatible JSON error message
=cut
sub _buildSuccessMessage {

	my $successData = {
		HEADER => [{ 'STATUS', 'SUCCESS' }],
		DATA => [{ 'SUMMARY',  'SUCCESS' ,
			  'DETAILS', 'Call completed successfully'}
			],
	};
	return encode_json($successData);
}


sub IS_SUCCESS {
	my $response = shift;

	my $status = $response->{HEADER}[0]{STATUS};
	if ($status eq "SUCCESS") {
		return 1;
	} else {
		return 0;
	}
}


sub GET_ERROR_MSG {
	my $response = shift;
	if (!IS_SUCCESS($response)) {
		return $response->{DATA}[0]->{DETAILS};
	}
}


sub IS_VALID_MODE {
	my $mode = shift;
	defined $mode or return 0;

	if (!defined $SERVERMAPPING{$mode}) {
		return 0;
	}
	return 1;
}

sub CURRENT_FCN_NAME {
	return (caller(1))[3];
}

sub REMOVE_SYSTEM_FIELDS {
	my $hashToClean = shift;
	my $field;
	my $value;
	while (($field, $value) = each %$hashToClean) {
		# do not return private data
		if ($field =~ /^private./) {
			delete $hashToClean->{$field};
		}
	}
}

# Try to see if key exists in array
# Map the array to a hash and use exists
sub DOES_KEY_EXIST_IN_ARRAY {
	# Note: Array came in as a reference
	my $array = shift;
	my $key = shift;

	my %hash = map { $_ => 1 } @ {$array};

	if(exists($hash{$key})) {
		return 1;
	} else {
		return 0;
	}
}

# Try to see if key exists in array
# Map the array to a hash and use exists
sub DOES_KEY_EXIST_IN_ARRAY_IGNORE_CASE {
	# Note: Array came in as a reference
	my $array = shift;
	my $key = shift;

	my %hash = map { lc($_) => $_ } @ {$array};

	# Change key case
	my $newKey = lc($key);

	if(exists($hash{$newKey})) {
		return $hash{$newKey};
	} else {
		return undef;
	}
}


sub READDOTHSDFILE {

	my $username = "";
	my $password = "";

	# Step 1
	# find .hsd file. (Either default location ~/ or HSD_HOME env
	my $dotHSDLocation = $ENV{"HOME"};

	# on windows; we save in %appdata%
	$dotHSDLocation = $ENV{"APPDATA"} . "\\HSD_HOME" unless ($^O eq "linux");


	if (defined $ENV{"HSD_HOME"}) {
		$dotHSDLocation = $ENV{"HSD_HOME"};
	}

	my $dotHSDFile = File::Spec->catfile($dotHSDLocation,".hsd");
	if (-e $dotHSDFile) {

		# idayah
		# section => { key=>value,...}
		my %hsdFileData;

		# now read the username and password
		open(DOTHSDFILE, "<$dotHSDFile") or croak "Unable to open $dotHSDFile";
	        my $section;
		while (<DOTHSDFILE>) {
		    chomp;
		    if (/^\s*\[(\w+)\].*/) {
			$section = $1;
		    }
		    if (/^\s*(\w+)\s*=(.*)$/) {
			my $key   = $1;
			my $value = $2 ;

			if(!$section) {
				die("Unable to parse $dotHSDFile\n");
			}

			# put them into hash
			$hsdFileData{$section}{$key} = $value;
		    }
		}
		close DOTHSDFILE;

		# process section values
		if($hsdFileData{"hsdes"}) {
			$username = $hsdFileData{"hsdes"}{"username"};
			$password = $hsdFileData{"hsdes"}{"password"};
		}
		elsif($hsdFileData{"default"}) {
			$username = $hsdFileData{"default"}{"username"};
			$password = $hsdFileData{"default"}{"password"};
		}
		else {
			die("Unable to find username and password from $dotHSDFile\n");
		}

		if($username eq "" || $password eq "") {
			die("Unable to find username and password from $dotHSDFile\n");
		}
	} else {
		croak HSDES::Api::Error::MISSING_DOTHSDFILE . " [$dotHSDFile]";
	}

	return ($username, $password);
}

# If comments/description fields contains multiline strings
# replace enclose each line with <p> and </p> as done in the webUI.
sub newlinesToHtmlParagraph {
	my $desc = shift;

	# Parse description
	if($desc =~ m/\n/) {
		my @text = split("\n", $desc);
	 	my $tmp_desc;

		foreach my $line (@text) {
			$tmp_desc .= "<p>$line</p>";
		}
		$desc = $tmp_desc if($tmp_desc);
	}

	return $desc;
}

sub _getUTCOffset {
	my $apiHandle = shift;

	# return a custom UTC Offset if the user has provided one
	# else we will figure one out
	if (defined $apiHandle->_getUTCOffset()) {
		return $apiHandle->_getUTCOffset();
	} else {


		if ($_utcOffset eq "") {
			use Time::Local;
			my @t = localtime(time);
			my $gmt_offset_in_seconds = timegm(@t) - timelocal(@t);
			$_utcOffset = $gmt_offset_in_seconds/60;
		}
		return $_utcOffset;
	}
}

sub _getUUID {
	return $_uuid;
}

=head1 SYNOPSIS
	This will check if a particular idsid is valid or not

	Author: nsshergi
=cut
sub IsValidIDSID {
	my $apiHandle = shift;
	my $idsidToCheck = shift;

	# idayah
	# It's ok to clear the person field
	if(defined($idsidToCheck) && $idsidToCheck eq "") {
		return 1;
	}

	my $response = HSDES::Api::Util::callToWService($apiHandle, "Directory","getInfo", {searchString=>$idsidToCheck});

	if(!HSDES::Api::Util::IS_SUCCESS($response) || !defined($response->{DATA}[0])) {
		return 0;
	}
	return 1;
}

=head1 SYNOPSIS
	Trim whitespace from both sides

	Author: nsshergi
=cut
sub Trim {
	my $value = shift;
	$value =~ s/^\s*(.*?)\s*$/$1/;
	return $value;
}

=head1 SYNOPSIS
	This is not valid update if only sending these fields:
	send_mail

	Author: idayah
=cut
sub isValidUpdate {
	my $changedFields = shift;

	# Ingored list
	my @ignoredFields = ("send_mail");

	# Loop thru fields and return true for the first field not in the ignored list
	foreach my $field (@$changedFields) {
		if(!DOES_KEY_EXIST_IN_ARRAY_IGNORE_CASE(\@ignoredFields, $field)) {
			return 1;
		}
	}
	return 0;
}

1;

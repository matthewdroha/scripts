use v5.12;
package HSDES::Api;

=head1 Name

HSDES::Api - Primary object for interacting with HSDES

=cut

=head1 VERSION

Version 1.0.28

=cut

our $VERSION = 'v1.0.28';

=head1 SYNOPOSIS
	use HSD::Api;
	my $api = HSDES::Api->new();

=cut

use warnings;
use strict;
use Carp;

use HSDES::Api::Article;
use HSDES::Api::Cache;
use HSDES::Api::Error;
use HSDES::Api::Magazine;
use HSDES::Api::MetaData;
use HSDES::Api::Query;
use HSDES::Api::RelationManager;
use HSDES::Api::Util;
use HSDES::Api::LinkManager;
use HSDES::Api::LinkConfigManager;
use HSDES::Api::DataSharing;
use HSDES::Api::Set;

my $mode;
my $_customUTCOffset;
my $_customHTTPSPort;
my $_hsdAuthEnabled;
my $_hsdusername;
my $_hsdpassword;
my $_impersonate;
my $_impersonatedUser;

sub new {
	my $class = shift;
	$mode = "INTEGRATION";
	$_hsdAuthEnabled = 0;
	$_hsdusername = "";
	$_hsdpassword = "";
	$_customHTTPSPort = "443";
	$_customUTCOffset = undef;
	return bless {}, $class;
}

sub init {
	my $self = shift;
	$mode = shift;
	defined $mode or croak HSDES::Api::Error::MODE_MISSING;

	HSDES::Api::Util::IS_VALID_MODE($mode) or croak HSDES::Api::Error::INVALID_MODE;
}

###############################################################################
=head2 enableHSDAuth
This will enable the user to use a .hsd file to connect to ES
This is only meant to be used for FACELESS accounts


=cut
###############################################################################
sub enableHSDAuth {

	# This could fail for the following reasons
	# no .hsd file found
	# no username/password in .hsd file
	# logged in user NOT EQUAL to username in .hsd file
	($_hsdusername, $_hsdpassword) = HSDES::Api::Util::READDOTHSDFILE();
	$_hsdAuthEnabled = 1;

}


sub _getHTTPSPort {
	return $_customHTTPSPort;
}

sub _getUTCOffset {
	return $_customUTCOffset;
}

sub _isHSDAuthEnabled {
	return $_hsdAuthEnabled;
}

sub _getHSDUsername {
	return $_hsdusername;
}

sub _getHSDPassword {
	return $_hsdpassword;
}

sub _isImpersonate {
	return $_impersonate;
}

sub _getImpersonatedUser {
	return $_impersonatedUser;
}

sub _getMode {
	return $mode;
}

sub article {
	my $self = shift;
	return HSDES::Api::Article->new($self);
}

sub query {
	my $self = shift;
	return HSDES::Api::Query->new($self);
}

sub magazine {
	my $self = shift;
	return HSDES::Api::Magazine->new($self);
}

sub metadata {
	my $self = shift;
	return HSDES::Api::MetaData->new($self);
}

sub relation {
	my $self = shift;
	return HSDES::Api::RelationManager->new($self);
}

sub datashare {
	my $self = shift;
	return HSDES::Api::DataSharing->new($self);
}

sub link {
	my $self = shift;
	return HSDES::Api::LinkManager->new($self);
}

sub linkconfig {
	my $self = shift;
	return HSDES::Api::LinkConfigManager->new($self);
}

sub set {
	my $self = shift;
	return HSDES::Api::Set->new($self);
}

###############################################################################
=head2 startImpersonate
This function let's the API user to impersonate 'user'.

=cut
###############################################################################
sub startImpersonate {
	my $self = shift;

	my $user = shift;
        if(!$user || $user eq "") {
		$self->{_lastErr} = "Invalid user: '".$user."'\n";
         	return 0;
        }

	# start impersonating the user
	my $response = HSDES::Api::Util::callToWService($self, "Security","startImpersonate", {userToImpersonate=>$user});
	if(!HSDES::Api::Util::IS_SUCCESS($response)) {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return 0;
	}

	# the info is used in MedataData::getUserIDSID
	$_impersonate      = 1;
	$_impersonatedUser = $user;

	return 1;
}

###############################################################################
=head2 stopImpersonate
This function let's the API user to stop impersonating 'user'.

=cut
###############################################################################

sub stopImpersonate {
	my $self = shift;
	my $user = shift;

        if(!$user || $user eq "") {
		$self->{_lastErr} = "Invalid user: '".$user."'\n";
         	return 0;
        }

	# start impersonating the user
	my $response = HSDES::Api::Util::callToWService($self, "Security","stopImpersonate", {userToImpersonate=>$user});
	if(!HSDES::Api::Util::IS_SUCCESS($response)) {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return 0;
	}

	# the info is used in MedataData::getUserIDSID
	$_impersonate      = 0;
	$_impersonatedUser = undef;

	return 1;
}


=head1
	Advance Users only
	No documentation provided. You have to know what you are doing
=cut
sub callGenericFunction {
	my $self = shift;
	my $moduleName   = shift;
	my $functionName = shift;
	my $functionArgs = shift;

	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}

	my $response = HSDES::Api::Util::callToWService($self, $moduleName, $functionName, $functionArgs);
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		return 1;
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


=head1 SYNOPOSIS
	Advance user only
	This is provided if you want to override the port
	that will be used for https

=cut
sub setCustomHTTPSPort {
	my $self = shift;
	$_customHTTPSPort = shift;
}

=head1 SYNOPOSIS
	Advance user only
	This is provided in order for a user to override the UTC OFFSET
	The API will use this offset in order to translate all datetime fields
	to UTC; as opposed to figuring out this info dynamically
=cut
sub setUTCOffset {
	my $self = shift;
	$_customUTCOffset = shift;
}


sub _getCache {
	my $self = shift;
	if (! (defined $self->{CACHEOBJ})) {
		my $cacheObj = new HSDES::Api::Cache($self);
		$self->{CACHEOBJ} = $cacheObj;
	}

	return $self->{CACHEOBJ};
}

1;

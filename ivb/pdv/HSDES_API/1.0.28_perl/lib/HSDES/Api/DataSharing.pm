package HSDES::Api::DataSharing;

use warnings;
use strict;


my $_apiHandle;

sub new {
	my $class = shift;
	$_apiHandle = shift;
	return bless {}, $class;
}

=head1 SYNOPSIS

	clone($parentID, $srcTenant, $srcSubject, $destinationTenant, $destinationSubject,
		  $sendMail, $isFailSafeClone, $copyAttachment, $copyComment,
		  {
			"owner" => "gsebasti",
			"title" => "Cloned Record"
		  });

=head2 clone

Returns the id of the new record from cloning.

=begin html
<b>Parameters:</b>
<BR>parentID: ID of the parent record.
<BR>srcTenant
<BR>srcSubject
<BR>destinationTenant
<BR>destinationSubject
<BR>sendMail (optional)
<BR>isFailSafeClone (optional)
<BR>copyAttachment (optional)
<BR>copyComment (optional)
<BR>User Provided Arguments of Field-Value Mapping (hash refrence) (optional)
<b>Returns:</b>
<BR>ID of New Cloned Record

=end html

=cut

sub clone {
	my $self = shift;
	my $parentID = shift;
	my $srcTenant = shift;
	my $srcSubject = shift;
	my $destinationTenant = shift;
	my $destinationSubject = shift;
	my $sendMail = shift;
	my $isFailSafeClone = shift;
	my $copyAttachment = shift;
	my $copyComment = shift;
	my $varArgs = shift;

	if ( !( defined($parentID) and defined($srcTenant) and defined($srcSubject) and defined($destinationTenant) and defined($destinationSubject) ) )
	{
		$self->{_lastErr} = "Must provide the following: parentID, srcTenant, srcSubject, destinationTenant, destinationSubject.";
        return undef;
	}

	if (!defined($sendMail))
	{
		$sendMail = "true";
	}

	if (!defined($isFailSafeClone))
	{
		$isFailSafeClone = "false";
	}	

	if (!defined($copyAttachment))
	{
		$copyAttachment = "true";
	}

	if (!defined($copyComment))
	{
		$copyComment = "true";
	}

	my $response = HSDES::Api::Util::callToWServiceVarArgs($_apiHandle, "Datasharing", "clone", {
		parentID => $parentID,
		srcTenant => $srcTenant,
		srcSubject => $srcSubject,
		destinationTenant => $destinationTenant,
		destinationSubject => $destinationSubject,
		sendMail => $sendMail,
		isFailSafeClone => $isFailSafeClone,
		copyAttachment => $copyAttachment,
		copyComment => $copyComment
		},
		$varArgs);


	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $responseDataObj = $response->{DATA}[0];
		return $responseDataObj->{newID};
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}

1;
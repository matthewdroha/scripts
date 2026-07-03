package HSDES::Api::MetaData;

=head1 Name

HSDES::Api::MetaData - This object will be used to retrieve ES metata

=cut


use warnings;
use strict;

use Carp;
use Data::Dumper;
use HSDES::Api::Util;
use HSDES::Api::Error;

my $_apiHandle;

sub new {
	my $class = shift;
	$_apiHandle = shift;
	my $self = {};
	bless ($self, $class);
	return $self;
}

=head1 SYNOPSIS

	getTenants();

=head2 getTenants

Returns information from every tenant into a hash array
Fields in each hash returned are id, name, code, owner, description, and org_grp


=begin html
<b>Returns:</b>
<BR>hash array containing tenant info

=end html


=cut

sub getTenants {
	my $self = shift;
	my @hash_array;
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Tenant","getInfo", {});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		for my $singleRow (@$rows) {
			my %hash=();
			while ( (my $field, my $value) = each %$singleRow )  {
				if ( $field eq "sys_tenant.name" ||
				     $field eq "id"              ||
				     $field eq "sys_tenant.code" ||
				     $field eq "owner"           ||
				     $field eq "description"     ||
				     $field eq "sys_tenant.org_grp") {

				     $hash{$field} = $value;
				}
			}

			push @hash_array, \%hash;
		}
		return \@hash_array;

	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}

=head1 SYNOPSIS

	getTenantInfo($tenantName);

=head2 getTenantInfo

Returns information from one tenant into a hash
Fields in hash returned are id, name, code, owner, description, and org_grp

=begin html
<b>Parameters:</b>
<BR>tenantName: for which you want more info
<BR>
<BR>
<b>Returns:</b>
<BR>hash containing info for a tenant

=end html

=cut

sub getTenantInfo {
	my $self = shift;
	my $tenantName = shift;

        if (!defined $tenantName) {
                $self->{_lastErr} = "Must define tenant name";
                return 0;
        }

	my $tenantFound = 0;
	my $tenantRow = {};
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Tenant","getInfo", {tenant_name=>$tenantName});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		for my $singleRow (@$rows) {
			while ( (my $field, my $value) = each %$singleRow )  {
				if ( $field eq "sys_tenant.name" &&
				     $value eq $tenantName) {

					$tenantRow = $singleRow;
					$tenantFound = 1;
				}
			}
		}
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}

	if ($tenantFound == 0) {
		$self->{_lastErr} = "Unable to fin tenant name: $tenantName.\n";
		return 0;
	}
	#Tenant must be found when we reach here
	my %rtntenant = ();
	while ((my $key, my $value) = each %$tenantRow) {

		if ( $key eq "sys_tenant.name"    ||
		     $key eq "sys_tenant.code"    ||
		     $key eq "sys_tenant.org_grp" ||
		     $key eq "id"                 ||
		     $key eq "owner"              ||
		     $key eq "description" ) {

		     $rtntenant{$key} = $value;
		}
	}
	return \%rtntenant;
}

=head1 SYNOPSIS

	getSubjects();

=head2 getSubjects

Returns information from every subject into a hash array
Fields in each hash returned are name, owner, description, and subject type

Here is a definition of the different subject types

1. Standard MRC converged (Bugeco/requirement/feature etc)
2. System Internal to ES
3. Custom Any subject created by a custom which is not MRC
4. Built in Created by ES team. Such as baseline, url, comments etc


=begin html
<b>Returns:</b>
<BR>array of subject hash

=end html

=cut

sub getSubjects {
	my $self = shift;
	my @hash_array;
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Subject","getInfo", {});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		for my $singleRow (@$rows) {
			my %hash=();
			while ( (my $field, my $value) = each %$singleRow )  {
				if ( $field eq "sys_subject.name" ||
				     $field eq "owner"            ||
				     $field eq "description"      ||
				     $field eq "sys_subject.type") {

				     $hash{$field} = $value;
				}
			}
			push @hash_array, \%hash;
		}
		return \@hash_array;

	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}


}

=head1 SYNOPSIS

	getSubjectInfo($subjectName);

=head2 getSubjectInfo

Returns information from one subject into a hash
Fields in hash returned are name, owner, description, and subject type

=begin html
<b>Parameters:</b>
<BR>subjectName: name of the subject
<BR>
<BR>
<b>Returns:</b>
<BR>hash containing info for a subject

=end html

=cut

sub getSubjectInfo {
	my $self = shift;
	my $subjectName = shift;
	my $subjectRow = {};
        if (!defined $subjectName) {
                $self->{_lastErr} = "Must define subject name";
                return 0;
        }
	my $subjectFound = 0;
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Subject","getInfo", {});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		for my $singleRow (@$rows) {
			while ( (my $field, my $value) = each %$singleRow )  {
				if ( $field eq "sys_subject.name" &&
				     $value eq $subjectName) {
					$subjectRow = $singleRow;
					$subjectFound = 1;
				}
			}
		}
		if ($subjectFound == 0) {
			$self->{_lastErr} = "Unable to fin subject name: $subjectName.\n";
			return 0;
		}

	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
	#Subject must found when we reach here
	my %rtnsubject = ();
	while ((my $key, my $value) = each %$subjectRow) {
		if ( $key eq "sys_subject.name" ||
		     $key eq "sys_subject.type" ||
		     $key eq "owner"            ||
		     $key eq "description" ) {
		     $rtnsubject{$key} = $value;
		}
	}
	return \%rtnsubject;
}

=head1 SYNOPSIS

	getDeployedSubjectForTenant($tenant);

=head2 getDeployedSubjectForTenant

Returns deployed subject from one tenant into array

=begin html
<b>Parameters:</b>
<BR>tenant: name of the tenant
<BR>
<BR>
<b>Returns:</b>
<BR>array containing all subjects deployed for the tenant

=end html

=cut

sub getDeployedSubjectForTenant {
	my $self = shift;
	my $tenantName = shift;

        if (!defined $tenantName) {
                $self->{_lastErr} = "Must define tenant name";
                return 0;
        }
	my $tenantFound = 0;
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Tenant","getInfo", {tenant_name=>$tenantName});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	my $tenantRow = {}; #null;
	if ($isSuccess) {
		my $rows = $response->{DATA};
		for my $singleRow (@$rows) {
			while ( (my $field, my $value) = each %$singleRow )  {
				if ( $field eq "sys_tenant.name" &&
 				     $value eq $tenantName ) {
					$tenantRow = $singleRow;
					$tenantFound = 1;
				}
			}
		}
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}

	if ($tenantFound == 0) {
		$self->{_lastErr} = "Unable to find tenant name: $tenantName.\n";
		return 0;
	} else { #found the tenant
		while ( (my $field, my $value) = each %$tenantRow )  {
			if ( $field eq "sys_tenant.deployed_subjects" ) {
				my @deployName=split(',', $value);
				return  @deployName;
			}
		}
	}
}

=head1 SYNOPSIS

	getRecordHistory($tenant, $subject, $id, $rev);

=head2 getRecordHistory

For a valid id, rev, subject, and tenant, the function returns the history of a record.

=begin html
<b>Parameters:</b>
<BR>subject: name of the subject
<BR>tenant: name of the tenant
<BR>id: record ID
<BR>rev: revision number (optional)
<BR>
<BR>
<b>Returns:</b>
<BR>array containing record history

=end html

=cut

sub getRecordHistory {
	my $self = shift;
	my $tenant = shift;
	my $subject = shift;
	my $id = shift;
	my $rev = shift;

	# check user inputs
	# tenant
        if (!defined $tenant) {
                $self->{_lastErr} = "Must provide tenant name";
                return undef;
        }
	# subject
        if (!defined $subject) {
                $self->{_lastErr} = "Must provide subject name";
                return undef;
        }
	# ID
        if (!defined $id) {
                $self->{_lastErr} = "Must provide record ID";
                return undef;
        }

	my $subjectFound = 0;
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Record","getRecordHistory",
                                                        {id=>$id, rev=>$rev, tenant=>$tenant, subject=>$subject});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		return $rows;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return undef;
	}
}


=head1 SYNOPSIS

	getFields($subjectName, $tenantName);

=head2 getFields

Returns information regarding the fields in a subject.
If only subject is provided; then you will get back system/global/subject If a subject + tenant is provided; then you will get back; system/global/subject/custom fields.

=begin html
<b>Parameters:</b>
<BR>subjectName: name of the subject
<BR>tenantName: name of the tenant
<BR>
<BR>
<b>Returns:</b>
<BR>hash containing all field info for a subject

=end html

=cut

sub getFields {
	my $self = shift;
	my $subjectName = shift;
	my $tenantName = shift;
	my @hash_array;
        if (!defined $subjectName) {
                $self->{_lastErr} = "Must define subject name";
                return 0;
        }

	# use tenant if provided
	my $viewportName = $subjectName;
        $viewportName = $tenantName.".".$viewportName if(defined $tenantName);

	my $subjectFound = 0;
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Viewport","getFieldInfo", {viewPortName=>$viewportName});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		for my $singleRow (@$rows) {
			push @hash_array, $singleRow;
		}
		return \@hash_array;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}


=head1 SYNOPSIS

	getLookupValue($fieldName, $subjectName, $tenantName);

=head2 getLookupValue

Returns all possible lookup values for a field.

=begin html
<b>Parameters:</b>
<BR>fieldName: required
<BR>subjectName: required
<BR>tenantName: optional
<BR>
<BR>
<b>Returns:</b>
<BR>Array containing all lookup value for a field

=end html

=cut

sub getLookupValue {
	my $self = shift;
	my $fieldName = shift;
	my $subject = shift;
	my $tenantList = shift;

	my @field_array;
        if (!defined $fieldName) {
                $self->{_lastErr} = "Must define field name";
                return 0;
        }
        if (!defined $subject) {
                $self->{_lastErr} = "Must define subject name";
                return 0;
        }
	my $subjectFound = 0;
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Lookup","getValue", {fieldName=>$fieldName, subject=>$subject, tenantList=>$tenantList});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		for my $singleRow (@$rows) {
                        while ( (my $field, my $value) = each %$singleRow )  {
                                if ( $field eq "sys_lookup.value" ) {
					push(@field_array, $value);
                                }
                        }
		}
		return @field_array;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}

#used inside this package only
sub getQualifiedFieldValue {
	#my $self = shift;
	my $tenant = shift;
	my $subject = shift;
	my $fieldName = shift;
	my @hash_array;
        if (!defined $fieldName) {
                #$self->{_lastErr} = "Must define field name";
                return 0;
        }
	my $completeSubjectName = "$tenant.$subject";
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Viewport","getFieldInfo", {viewPortName=>$completeSubjectName});
	my $subjectFound = 0;
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		for my $singleRow (@$rows) {
			while ( (my $field, my $value) = each %$singleRow )  {
				if ( $field eq "field" ) {
					if($value =~ m/$fieldName/) {
						return $value;
					 }
				}
			}
		}

	} else {
		#$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}

#used inside this package only
sub getLookupGroupValue {
	#my $self = shift;
	my $tenant = shift;
	my $subject = shift;
	my $qualifiedFieldName = shift;
        if (!defined $qualifiedFieldName) {
                #$self->{_lastErr} = "Must define qualified field name";
                return 0;
        }

	## Following SP is suggested by BE group, Fahd. To get correct lookupGroup name
	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Lookup","getLuRefInfo", {fieldName=>$qualifiedFieldName,subjec=>$subject,tenant=>$tenant});
	#my $response = HSDES::Api::Util::callToWService($_apiHandle, "Lookup","getValue", {fieldName=>$qualifiedFieldName,subjec=>$subject,tenantList=>$tenant});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		my $i=0;
		for my $singleRow (@$rows) {
			while ( (my $key, my $value) = each %$singleRow )  {
				#if ( $key eq "sys_lookup.lookup_group" ) {
				if ( $key eq "lu_ref" ) {
					return $value;
				}
			}
		}
	} else {
		#$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}

=head1 SYNOPSIS

    getLookupGroupInfo($tenant, $subject, $lookupGroup);

=head2 getLookupGroupInfo

Get information about Lookup Group

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>subject: required
<BR>lookupGroup: required
<BR>
<BR>
<b>Returns:</b>
<BR>Info hash

=end html

=cut

sub getLookupGroupInfo {
    my ( $self, $tenant, $subject, $lookupGroup ) = @_;

    if (!defined $tenant) {
        $self->{_lastErr} = "Must define tenant name";
        return 0;
    }

    if (!defined $subject) {
        $self->{_lastErr} = "Must define subject name";
        return 0;
    }

    if (!defined $lookupGroup) {
        $self->{_lastErr} = "Must define lookup group";
        return 0;
    }

    my $results = ();

    my $response = HSDES::Api::Util::callToWService($_apiHandle, "LookupGroup", "getInfo", {lookupGroup=>$lookupGroup, tenant=>$tenant, subject=>$subject});
    my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);

    if ($isSuccess) {
        my $data = $response->{DATA};
        for my $singleRow (@$data) {
            while ( (my $field, my $value) = each %$singleRow )  {
                $results->{ $field } = $value
            }
        }
    } else {
        die HSDES::Api::Util::GET_ERROR_MSG($response);
    }

    return $results;
}

=head1 SYNOPSIS

    addLookupGroup($tenant, $subject, $lookupGroup);

=head2 addLookupGroup

Create new lookup group

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>subject: required
<BR>lookupGroup: required
<BR>
<BR>
<b>Returns:</b>
<BR>Results

=end html

=cut

sub addLookupGroup {
    my ( $self, $tenant, $subject, $lookupGroup ) = @_;

    if (!defined $tenant) {
        $self->{_lastErr} = "Must define tenant name";
        return 0;
    }

    if (!defined $subject) {
        $self->{_lastErr} = "Must define subject name";
        return 0;
    }

    if (!defined $lookupGroup) {
        $self->{_lastErr} = "Must define lookup group";
        return 0;
    }

    my $results = getLookupGroupInfo($self, $tenant, $subject, $lookupGroup);

    if (!defined($results)) {
        my $response = HSDES::Api::Util::callToWService($_apiHandle, "LookupGroup", "add", {lookupGroup=>$lookupGroup, tenant=>$tenant, subject=>$subject});
        my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
        if ($isSuccess) {
            $results = getLookupGroupInfo($self, $tenant, $subject, $lookupGroup);
        } else {
            die HSDES::Api::Util::GET_ERROR_MSG($response);
        }
    }
    return $results;
}

=head1 SYNOPSIS

    deleteLookupGroup($tenant, $subject, $lookupGroup);

=head2 deleteLookupGroup

Delete lookup group

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>subject: required
<BR>lookupGroup: required
<BR>
<BR>
<b>Returns:</b>
<BR>Results

=end html

=cut

sub deleteLookupGroup {
    my ( $self, $tenant, $subject, $lookupGroup ) = @_;

    if (!defined $tenant) {
        $self->{_lastErr} = "Must define tenant name";
        return 0;
    }

    if (!defined $subject) {
        $self->{_lastErr} = "Must define subject name";
        return 0;
    }

    if (!defined $lookupGroup) {
        $self->{_lastErr} = "Must define lookup group";
        return 0;
    }

    my $response = HSDES::Api::Util::callToWService($_apiHandle, "LookupGroup", "delete", {lookupGroup=>$lookupGroup, tenant=>$tenant, subject=>$subject});
    my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);

    if (!$isSuccess) {
        die HSDES::Api::Util::GET_ERROR_MSG($response);
    }

    return 1;
}

=head1 SYNOPSIS

    addStaticLookup($tenant, $subject, $field, $lookupGroup);

=head2 addStaticLookup

Assign static lookup group to a field

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>subject: required
<BR>field: required
<BR>lookupGroup: required
<BR>
<BR>
<b>Returns:</b>
<BR>Lookup values hash

=end html

=cut

sub addStaticLookup {
    my ( $self, $tenant, $subject, $field, $lookupGroup ) = @_;

    if (!defined $tenant) {
        $self->{_lastErr} = "Must define tenant name";
        return 0;
    }

    if (!defined $subject) {
        $self->{_lastErr} = "Must define subject name";
        return 0;
    }

    if (!defined $field) {
        $self->{_lastErr} = "Must define field";
        return 0;
    }

    if (!defined $lookupGroup) {
        $self->{_lastErr} = "Must define lookup group";
        return 0;
    }

    my $results = getLookupGroupInfo($self, $tenant, $subject, $lookupGroup);

    if (defined($results)) {
        my $response = HSDES::Api::Util::callToWService($_apiHandle, "Lookup", "addStaticLuRef", {lookupGroup=>$lookupGroup, tenant=>$tenant, subject=>$subject, fieldName=>$field});
        my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
        if (!$isSuccess) {
            die HSDES::Api::Util::GET_ERROR_MSG($response);
        }
    } else {
        $self->{_lastErr} = "Specified lookup group is missing";
        return 0;
    }

    return $results;
}


=head1 SYNOPSIS

    deleteStaticLookup($tenant, $subject, $field, $lookupGroup);

=head2 deleteStaticLookup

Unassign static lookup group from a field

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>subject: required
<BR>field: required
<BR>lookupGroup: required
<BR>
<BR>
<b>Returns:</b>
<BR>Lookup values hash

=end html

=cut

sub deleteStaticLookup {
    my ( $self, $tenant, $subject, $field, $lookupGroup ) = @_;

    if (!defined $tenant) {
        $self->{_lastErr} = "Must define tenant name";
        return 0;
    }

    if (!defined $subject) {
        $self->{_lastErr} = "Must define subject name";
        return 0;
    }

    if (!defined $field) {
        $self->{_lastErr} = "Must define field";
        return 0;
    }

    if (!defined $lookupGroup) {
        $self->{_lastErr} = "Must define lookup group";
        return 0;
    }

    my $results = getLookupGroupInfo($self, $tenant, $subject, $lookupGroup);

    if (defined($results)) {
        my $response = HSDES::Api::Util::callToWService($_apiHandle, "Lookup", "deleteStaticLuRef", {lookupGroup=>$lookupGroup, tenant=>$tenant, subject=>$subject, fieldName=>$field});
        my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
        if (!$isSuccess) {
            die HSDES::Api::Util::GET_ERROR_MSG($response);
        }
    } else {
        $self->{_lastErr} = "Specified lookup group is missing";
        return 0;
    }

    return $results;
}
=head1 SYNOPSIS

    addDynamicLookup($tenant, $subject, $field, $tenantRef, $subjectRef, $fieldRef);

=head2 addDynamicLookup

Assign dynamic lookup values to a field using reference tenant subject field

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>subject: required
<BR>field: required
<BR>tenantRef: required
<BR>subjectRef: required
<BR>fieldRef: required
<BR>
<BR>
<b>Returns:</b>
<BR>Lookup values hash

=end html

=cut

sub addDynamicLookup {
    my ( $self, $tenant, $subject, $field, $tenantRef, $subjectRef, $fieldRef ) = @_;

    if (!defined $tenant) {
        $self->{_lastErr} = "Must define tenant name";
        return 0;
    }

    if (!defined $subject) {
        $self->{_lastErr} = "Must define subject name";
        return 0;
    }

    if (!defined $field) {
        $self->{_lastErr} = "Must define field";
        return 0;
    }

    if (!defined $tenantRef) {
        $self->{_lastErr} = "Must define lookup tenant reference";
        return 0;
    }

    if (!defined $subjectRef) {
        $self->{_lastErr} = "Must define lookup subject reference";
        return 0;
    }

    if (!defined $fieldRef) {
        $self->{_lastErr} = "Must define lookup field reference";
        return 0;
    }

    my $response = HSDES::Api::Util::callToWService($_apiHandle, "Lookup", "addDynamicLuRef", {tenant=>$tenant, subject=>$subject, fieldName=>$field, tenantReferenced=>$tenantRef, subjectReferenced=>$subjectRef, fieldReferenced=>$fieldRef});
    my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
    if (!$isSuccess) {
        die HSDES::Api::Util::GET_ERROR_MSG($response);
    }

    return 1;
}

=head1 SYNOPSIS

    addLookupGroupValue($tenant, $subject, $groupName, $value);


=head2 addLookupGroupValue

Add lookup value for a field.

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>subject: required
<BR>groupName: required
<BR>value: required
<BR>alias: optional
<BR>order: optional
<BR>acceptableValues: optional
<BR>description: optional
<BR>
<BR>
<b>Returns:</b>
<BR>Result

=end html

=cut

sub addLookupGroupValue {
    my $self     = shift;
    my $tenant   = shift;
    my $subject  = shift;
    my $lookupGroup = shift;
    my $value    = shift;
    my $alias    = shift;
    my $order    = shift;
    my $acceptableValues = shift;
    my $description = shift;

    if (!defined $lookupGroup) {
            $self->{_lastErr} = "Must define lookup group name";
            return 0;
    }

    if (!defined $tenant) {
            $self->{_lastErr} = "Must define tenant name";
            return 0;
    }

    if (!defined $subject) {
            $self->{_lastErr} = "Must define subject name";
            return 0;
    }

    if (!defined $value) {
            $self->{_lastErr} = "Must define value name";
            return 0;
    }

    my $response = HSDES::Api::Util::callToWService($_apiHandle, "Lookup","add", {lookupGroup=>$lookupGroup, value=>$value, alias=>$alias, order=>$order, acceptableValues=>$acceptableValues,description=>$description});
    my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
    if ($isSuccess) {
        my $rows = $response->{DATA};
        for my $singleRow (@$rows) {
            while ( (my $field, my $value) = each %$singleRow )  {
                if ( $field eq "newID" ) {
                    return  $value;
                }
            }
        }
    } else {
        $self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
        return $isSuccess;
    }
}

=head1 SYNOPSIS

	addLookupValue($tenant, $subject, $fieldName, $value, $alias, $order, $acceptableValues, $description);


=head2 addLookupValue

Add lookup value for a field.

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>subject: required
<BR>fieldName: required
<BR>value: required
<BR>alias: optional
<BR>order: optional
<BR>acceptableValues: optional
<BR>description: optional
<BR>
<BR>
<b>Returns:</b>
<BR>new ID

=end html

=cut

sub addLookupValue {
	my $self     = shift;
	my $tenant   = shift;
	my $subject  = shift;
	my $fieldName= shift; ## normal display field name on web ui
	my $value    = shift;
	my $alias    = shift;
	my $order    = shift;
	my $acceptableValues = shift;
	my $description = shift;

        if (!defined $fieldName) {
                $self->{_lastErr} = "Must define feild name";
                return 0;
        }

        if (!defined $tenant) {
                $self->{_lastErr} = "Must define tenant name";
                return 0;
        }

        if (!defined $subject) {
                $self->{_lastErr} = "Must define subject name";
                return 0;
        }

        if (!defined $value) {
                $self->{_lastErr} = "Must define value name";
                return 0;
        }


	## In backend there are different notation/format for any field
	## some system, global field will have value just the field name, ie. 'status'
	## some subject field have value like 'issue.phase'
	## custom field will have field like 'hsd-es.issue.disposition'
	## those qualified field is needed when try to search lookupGroup info
	## and operation on lookup value,add/update, need to have correct lookupGroup name
	my $qfieldName = getQualifiedFieldValue($tenant, $subject, $fieldName);
	my $luGrpName  = getLookupGroupValue($tenant, $subject, $qfieldName);

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Lookup","add", {lookupGroup=>$luGrpName, value=>$value, alias=>$alias, order=>$order, acceptableValues=>$acceptableValues,description=>$description});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		for my $singleRow (@$rows) {
			while ( (my $field, my $value) = each %$singleRow )  {
				if ( $field eq "newID" ) {
					return  $value;
				}
			}
		}
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}

=head1 SYNOPSIS

	updateLookupValue($tenant, $subject, $fieldName, $value, $alias, $order, $acceptableValues, $description);


=head2 updateLookupValue

Update lookup value for a field.

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>subject: required
<BR>fieldName: required
<BR>value: required
<BR>alias: optional
<BR>order: optional
<BR>acceptableValues: optional
<BR>description: optional
<BR>
<BR>
<b>Returns:</b>
<BR>1

=end html

=cut

sub updateLookupValue {
	my $self = shift;
	my $tenant   = shift;
	my $subject  = shift;
	my $fieldName= shift;
	my $value = shift;
	my $alias = shift;
	my $order = shift;
	my $acceptableValues = shift;
	my $description = shift;

        if (!defined $fieldName) {
                $self->{_lastErr} = "Must define feild's lookupGroup name";
                return 0;
        }


        if (!defined $tenant) {
                $self->{_lastErr} = "Must define tenant name";
                return 0;
        }

        if (!defined $subject) {
                $self->{_lastErr} = "Must define subject name";
                return 0;
        }

        if (!defined $value) {
                $self->{_lastErr} = "Must define value name";
                return 0;
        }


	## In backend there are different notation/format for any field
	## some system, global field will have value just the field name, ie. 'status'
	## some subject field have value like 'issue.phase'
	## custom field will have field like 'hsd-es.issue.disposition'
	## those qualified field is needed when try to search lookupGroup info
	## and operation on lookup value,add/update, need to have correct lookupGroup name

	my $qfieldName = getQualifiedFieldValue($tenant, $subject, $fieldName);
	my $luGrpName  = getLookupGroupValue($tenant, $subject, $qfieldName);

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Lookup","updateAttributes", {lookupGroup=>$luGrpName, value=>$value, alias=>$alias, order=>$order, acceptableValues=>$acceptableValues,description=>$description});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		return $isSuccess;
	} else {
		$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
}

=head1 SYNOPSIS

    addProjAdmin($tenant, $idsid);

=head2 addProjAdmin

Add user to proj admin group

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>idsid: required
<BR>
<BR>
<b>Returns:</b>
<BR>Status

=end html

=cut

sub addProjAdmin {
    my ($self, $tenant, $idsid) = @_;

    if (!defined $tenant) {
        $self->{_lastErr} = "Must define tenant";
        return 0;
    }

    if (!defined $idsid) {
        $self->{_lastErr} = "Must define user idsid";
        return 0;
    }

    my $internalGroup = "${tenant}_proj_admin";

    return $self->addUserToInternalGroup($tenant, $idsid, $internalGroup, "");
}

=head1 SYNOPSIS

    addPermAdmin($tenant, $idsid);

=head2 addPermAdmin

Add user to perm admin group

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>idsid: required
<BR>
<BR>
<b>Returns:</b>
<BR>Status

=end html

=cut

sub addPermAdmin {
    my ($self, $tenant, $idsid) = @_;

    if (!defined $tenant) {
        $self->{_lastErr} = "Must define tenant";
        return 0;
    }

    if (!defined $idsid) {
        $self->{_lastErr} = "Must define user idsid";
        return 0;
    }

    my $internalGroup = "${tenant}_perm_admin";

    return $self->addUserToInternalGroup($tenant, $idsid, $internalGroup, "");
}

=head1 SYNOPSIS

    addProjSubjAdmin($tenant, $subject, $idsid);

=head2 addProjSubjAdmin

Add user to Proj Subj admin group

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>subject: required
<BR>idsid: required
<BR>
<BR>
<b>Returns:</b>
<BR>Status

=end html

=cut

sub addProjSubjAdmin {
    my ($self, $tenant, $subject, $idsid) = @_;

    if (!defined $tenant) {
        $self->{_lastErr} = "Must define tenant";
        return 0;
    }

    if (!defined $subject) {
        $self->{_lastErr} = "Must define subject";
        return 0;
    }

    if (!defined $idsid) {
        $self->{_lastErr} = "Must define user idsid";
        return 0;
    }

    my $internalGroup = "${tenant}_${subject}_projsubj_admin";

    return $self->addUserToInternalGroup($tenant, $idsid, $internalGroup, "");
}

=head1 SYNOPSIS

    addUserToInternalGroup($tenant, $idsid, $internalGroup, $fullName);

=head2 addUserToInternalGroup

Add user to admin groups

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>idsid: required
<BR>internalGroup: required
<BR>fullName: required
<BR>
<BR>
<b>Returns:</b>
<BR>Status

=end html

=cut

sub addUserToInternalGroup {
    my ( $self, $tenant, $idsid, $internalGroup, $fullName ) = @_;

    if (!defined $tenant) {
        $self->{_lastErr} = "Must define tenant";
        return 0;
    }

    if (!defined $idsid) {
        $self->{_lastErr} = "Must define user idsid";
        return 0;
    }

    if (!defined $internalGroup) {
        $self->{_lastErr} = "Must define internalGroup";
        return 0;
    }

    $fullName ||= "";

    my $response = HSDES::Api::Util::callToWService($_apiHandle, "Security", "addUserToInternalGroup", {tenant=>$tenant, idsid=>$idsid, internalGroup=>$internalGroup, fullName=>$fullName});
    my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
    if (!$isSuccess) {
        die HSDES::Api::Util::GET_ERROR_MSG($response);
    }

    return $response;
}

# deleteUserFromInternalGroup(String idsid,String internalGroup,String tenant,String subject


=head1 SYNOPSIS

    deleteProjAdmin($tenant, $subject, $idsid);

=head2 deleteProjAdmin

Remove user from proj admin group

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>subject: required
<BR>idsid: required
<BR>
<BR>
<b>Returns:</b>
<BR>Status

=end html

=cut

sub deleteProjAdmin {
    my ($self, $tenant, $subject, $idsid) = @_;

    if (!defined $tenant) {
        $self->{_lastErr} = "Must define tenant";
        return 0;
    }

    if (!defined $subject) {
        $self->{_lastErr} = "Must define subject";
        return 0;
    }

    if (!defined $idsid) {
        $self->{_lastErr} = "Must define user idsid";
        return 0;
    }

    my $internalGroup = "${tenant}_proj_admin";

    return $self->deleteUserFromInternalGroup($tenant, $subject, $idsid, $internalGroup);
}

=head1 SYNOPSIS

    deletePermAdmin($tenant, $subject, $idsid);

=head2 deletePermAdmin

Remove user from perm admin groups

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>subject: required
<BR>idsid: required
<BR>
<BR>
<b>Returns:</b>
<BR>Status

=end html

=cut

sub deletePermAdmin {
    my ($self, $tenant, $subject, $idsid) = @_;

    if (!defined $tenant) {
        $self->{_lastErr} = "Must define tenant";
        return 0;
    }

    if (!defined $subject) {
        $self->{_lastErr} = "Must define subject";
        return 0;
    }

    if (!defined $idsid) {
        $self->{_lastErr} = "Must define user idsid";
        return 0;
    }

    my $internalGroup = "${tenant}_perm_admin";

    return $self->deleteUserFromInternalGroup($tenant, $subject, $idsid, $internalGroup);
}

=head1 SYNOPSIS

    deleteProjSubjAdmin($tenant, $subject, $idsid);

=head2 deleteProjSubjAdmin

Delete user from Proj Subj admin group

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>subject: required
<BR>idsid: required
<BR>
<BR>
<b>Returns:</b>
<BR>Status

=end html

=cut

sub deleteProjSubjAdmin {
    my ($self, $tenant, $subject, $idsid) = @_;

    if (!defined $tenant) {
        $self->{_lastErr} = "Must define tenant";
        return 0;
    }

    if (!defined $subject) {
        $self->{_lastErr} = "Must define subject";
        return 0;
    }

    if (!defined $idsid) {
        $self->{_lastErr} = "Must define user idsid";
        return 0;
    }

    my $internalGroup = "${tenant}_${subject}_projsubj_admin";

    return $self->deleteUserFromInternalGroup($tenant, $subject, $idsid, $internalGroup);
}

=head1 SYNOPSIS

    deleteUserFromInternalGroup($tenant, $subject, $idsid, $internalGroup, $fullName);

=head2 deleteUserFromInternalGroup

Delete users from admin groups

=begin html
<b>Parameters:</b>
<BR>tenant: required
<BR>subject: required
<BR>idsid: required
<BR>internalGroup: required
<BR>
<BR>
<b>Returns:</b>
<BR>Status

=end html

=cut

sub deleteUserFromInternalGroup {
    my ( $self, $tenant, $subject, $idsid, $internalGroup ) = @_;

    if (!defined $tenant) {
        $self->{_lastErr} = "Must define tenant";
        return 0;
    }

    if (!defined $subject) {
        $self->{_lastErr} = "Must define tenant";
        return 0;
    }

    if (!defined $idsid) {
        $self->{_lastErr} = "Must define user idsid";
        return 0;
    }

    if (!defined $internalGroup) {
        $self->{_lastErr} = "Must define internalGroup";
        return 0;
    }

    my $response = HSDES::Api::Util::callToWService($_apiHandle, "Security", "deleteUserFromInternalGroup", {tenant=>$tenant, subject=>$subject, idsid=>$idsid, internalGroup=>$internalGroup});
    my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
    if (!$isSuccess) {
        die HSDES::Api::Util::GET_ERROR_MSG($response);
    }

    return $response;
}


sub getIDSIDfromEmail {
	my $self = shift;
	# must be called on a OBJECT
	unless (ref $self) {
		croak HSDES::Api::Error::INVALID_CALL_NOTATION;
	}


	my $email = shift;
	if (!defined $email) {
		$self->{_lastErr} = "Need to pass in a email to convert to idsid";
		return 0;
	}

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "User","getIDISDFromEmail", {email=>$email});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		return $response->{DATA}[0]->{idsid};
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

sub getCodeInfo {
    my $self = shift;
    my $id   = shift;

    # must be called on a OBJECT
    unless (ref $self) {
        croak HSDES::Api::Error::INVALID_CALL_NOTATION;
    }

    if(!defined($id)) {
        $self->{_lastErr} = "Must provide Error Code.";
        return undef;
    }

    my $response = HSDES::Api::Util::callToWService($_apiHandle, "Event","getCodeInfo", {id=>$id});
    my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
    if ($isSuccess) {
	my $rows = $response->{DATA};
	return $rows;
    } else {
	$self->{_lastErr} = HSDES::Api::Util::GET_ERROR_MSG($response);
	return undef;
    }
}
1;

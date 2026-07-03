package HSDES::Api::Magazine;

use warnings;
use strict;

use Data::Dumper;
use HSDES::Api::Util;

my $_lastErr;
my $_apiHandle;

sub new {
	my $class = shift;
	$_apiHandle = shift;
	return bless {}, $class;
}

sub getQueries {
	my $self = shift;
	my $magazineName = shift;
	my $magazineID = 0;;

	if (!defined $magazineName) {
		$_lastErr = "Must define MagazineName";
		return 0;
	}

	my $response = HSDES::Api::Util::callToWService($_apiHandle, "Magazine","getInfo",{});
	my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA};
		for my $singleRow (@$rows) {
			if ($singleRow->{title} eq $magazineName) {
				$magazineID = $singleRow->{id};
				last;
			}
		}

		# lets see if $magazineID is valid
		if ($magazineID != 0) {
		
			my %queryIDHash = ();
			# make another ws call to get all queries in that magazine
			my $response = HSDES::Api::Util::callToWService($_apiHandle, "Magazine","getItems",{'magazineID' => $magazineID});
			my $isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
			if ($isSuccess) {
				my $rows = $response->{DATA};
				for my $singleRow (@$rows) {
					if ($singleRow->{type} eq "query" && $singleRow->{relation_status} eq "active") {
						$queryIDHash{$singleRow->{id}} = $singleRow->{title};
					}
				}
				
				return \%queryIDHash;
			} else {
				$_lastErr = "No Items found in magazine: [" . $magazineName . "]";
				return 0;
			}
		} else {
			$_lastErr = "No magazine found with name: [" . $magazineName . "]";
			return 0;
		}
	} else {
		$_lastErr = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}




}

sub getLastErrorMessage {
	return $_lastErr;
}

1;

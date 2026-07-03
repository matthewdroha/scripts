package HSDES::Api::RuleHelper::RuleUtil;

use warnings;
use strict;

use XML::Parser;
use Data::Dumper;
use HSDES::Api::Util;
use HSDES::RuleEngine;

my $_lastErr;
my $_apiHandle;


sub GetRules {
	my ($apiHandle, $tenant, $subject) = @_;

	# local vars
	my $response;
	my $isSuccess;
	my $data;
	my $mergedXML;

	# we take the merged rules From MT and we Parse them from XML to perl style 
	
	my $viewport = $tenant . "." . $subject;
	$response = HSDES::Api::Util::callToWService($apiHandle, "Viewport", "getUIRulesMerged", {subject => $subject,tenant => $tenant});

	$isSuccess = HSDES::Api::Util::IS_SUCCESS($response);
	if ($isSuccess) {
		my $rows = $response->{DATA}[0];
		$mergedXML = $rows->{'xml'};
	} else {
		$_lastErr = HSDES::Api::Util::GET_ERROR_MSG($response);
		return $isSuccess;
	}
	my $parser = new XML::Parser( Style => 'Objects', NoLPW => 1, Pkg => 'HSDES::Schema::RuleSet' );
	my $merged =$parser->parse($mergedXML);
	my $finalRules = $merged->[0];

	return $finalRules;
}

1;

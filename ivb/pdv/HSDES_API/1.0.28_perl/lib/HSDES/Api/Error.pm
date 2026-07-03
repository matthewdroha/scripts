package HSDES::Api::Error;

use warnings;
use strict;


use constant INVALID_CALL_NOTATION  => "You must call this method on a object of this type.";
use constant MODE_MISSING => "You must specify mode for this call.";
use constant INVALID_MODE => "Mode must be INTEGRATION,PREPRODUCTION,STABLE, or PRODUCTION.";


# dot hsd file related
use constant MISSING_DOTHSDFILE => "Unable to find a .hsd file.";
use constant MISSING_USERNAME_IN_DOTHSDFILE => "Unable to find a username in .hsd file";
use constant MISMATCH_USERNAME_IN_DOTHSDFILE => "Mismatch between username found in .hsd file and logged in user";

1;

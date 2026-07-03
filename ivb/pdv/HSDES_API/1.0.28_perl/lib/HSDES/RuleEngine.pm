#! perl

#
# HSD-ES - High Speed Database - Extremely Simple, Extremely Speedy
#
# INTEL CONFIDENTIAL
#
# Copyright 2014 Intel Corporation All Rights Reserved.
#
# The source code contained or described herein and all documents related
# to the source code ("Material") are owned by Intel Corporation or its
# suppliers or licensors. Title to the Material remains with Intel
# Corporation or its suppliers and licensors. The Material contains trade
# secrets and proprietary and confidential information of Intel or its
# suppliers and licensors. The Material is protected by worldwide copyright
# and trade secret laws and treaty provisions. No part of the Material may
# be used, copied, reproduced, modified, published, uploaded, posted,
# transmitted, distributed, or disclosed in any way without Intels
# prior express written permission.
#
# No license under any patent, copyright, trade secret or other intellectual
# property right is granted to or conferred upon you by disclosure or
# delivery of the Materials, either expressly, by implication, inducement,
# estoppel or otherwise. Any license under such intellectual property rights
# must be express and approved by Intel in writing.
#

use strict;
use warnings;

=head1 NAME

RuleEngine - HSD-ES Rule Engine
=cut

=head1 SYNOPSIS
=cut

=head1 DESCRIPTION
=cut

package HSDES::RuleEngine;

our $VERSION = '1.20.0';

use Data::Dumper;

use HSDES::RuleEngine::ActionCollection;
use HSDES::RuleEngine::ChangeEventCollection;
use HSDES::RuleEngine::ClickEventCollection;
use HSDES::RuleEngine::ConditionChecker;
use HSDES::RuleEngine::Exceptions;
use HSDES::RuleEngine::FunctionHelper;
use HSDES::RuleEngine::RuleCollection;
use HSDES::RuleEngine::StringUtil;
use HSDES::RuleEngine::ValueContextImpl;
use HSDES::RuleEngine::Events::SaveStateEvent;
use HSDES::RuleEngine::Events::RestoreStateEvent;
use HSDES::RuleEngine::Events::EnabledStateEvent;
use HSDES::RuleEngine::Events::RequiredStateEvent;
use HSDES::RuleEngine::Events::VisibleStateEvent;
use HSDES::RuleEngine::Events::SetValueEvent;
use HSDES::RuleEngine::Events::LookupChangeEvent;
use HSDES::Schema::RuleSet::RuleSet;

=head1 METHODS
=cut

########################################################################
=head2 new

=cut
########################################################################

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
	# true after wireUp()
	wiredUp => 0,
	# empty ruleset initially
	ruleSet => HSDES::Schema::RuleSet::RuleSet->new(),
	# managed widgets
	widgets => [ ],
	# events to fire that are comon to onNew/onLoad
	onInitRecordListeners => HSDES::RuleEngine::RuleCollection->new(),
	# events to fire on new record
	onNewRecordListeners => HSDES::RuleEngine::RuleCollection->new(),
	# events to fire on load record
	onLoadRecordListeners => HSDES::RuleEngine::RuleCollection->new(),
	# events to fire after every event
	alwaysAfterListeners => HSDES::RuleEngine::RuleCollection->new(),
	# collection of change handlers ( string->ChangeEventCollection )
	changeHandlerMap => { },
	# collection of click handlers ( string->ClickEventCollection )
	clickHandlerMap => { }
    };
    bless ($self, $class);

    $self->{delegate} = shift;

    return $self;
}

########################################################################
=head2 wireUp

=cut
########################################################################

sub wireUp {
    my $self = shift;

    HSDES::RuleEngine::Exception::IllegalState->throw("wireUp: Cannot call twice")
	if ( $self->{wiredUp} );

    foreach my $rule ( @{$self->{ruleSet}->{Kids}} ) {
	next if ( ref($rule) =~ /Characters$/ );  # skip text nodes

	my $handlers = $self->_makeHandlerList( $rule->{Kids} );
	$self->_attachActions($rule, $handlers);
    }

    $self->{wiredUp} = 1;
}

########################################################################
=head2 onNewRecord

=cut
########################################################################

sub onNewRecord {
    my $self = shift;
    my $callback = shift;

    my $lastOne = sub {
	$self->{alwaysAfterListeners}->executeWithCallback($callback);
    };
    my $middleOne = sub {
	$self->{onNewRecordListeners}->executeWithCallback($lastOne);
    };
    $self->{onInitRecordListeners}->executeWithCallback($middleOne);
}

########################################################################
=head2 onLoadRecord

=cut
########################################################################

sub onLoadRecord {
    my $self = shift;
    my $callback = shift;

    my $lastOne = sub {
	$self->{alwaysAfterListeners}->executeWithCallback($callback);
    };
    my $middleOne = sub {
	$self->{onLoadRecordListeners}->executeWithCallback($lastOne);
    };
    $self->{onInitRecordListeners}->executeWithCallback($middleOne);
}

########################################################################
=head2 setRules

=cut
########################################################################

sub setRules {
    my $self = shift;
    my $rules = shift;

    $rules = $rules->[0] if (ref($rules) eq "ARRAY");

    HSDES::RuleEngine::Exception::InvalidArgument->throw("setRules: Invalid argument")
	if ( ! defined($rules) );

    HSDES::RuleEngine::Exception::InvalidArgument->throw("setRules: Invalid argument type")
	if ( ref($rules) !~ /::RuleSet$/ );

    HSDES::RuleEngine::Exception::IllegalState->throw("setRules: Cannot set rules after wireUp")
	if ( $self->{wiredUp} );

    $self->{ruleSet} = $rules;
}

########################################################################
=head2 registerWidgets

=cut
########################################################################

sub registerWidgets {
    my $self = shift;

    foreach (@_) {
	push @{$self->{widgets}}, $_ if ( $_->can("getName") );
    }
}

########################################################################
#
sub _makeHandlerList {
    my $self = shift;
    my $actions = shift;
    my $handlers = HSDES::RuleEngine::ActionCollection->new();

    foreach my $a ( @{$actions} ) {
	#print "assigning actions ", Dumper($a);
	$self->_assignActions($handlers, $a);
	#print "done assigning actions ", Dumper($handlers);
    }

    return $handlers;
}

########################################################################
#
sub _assignActions {
    my $self = shift;
    my $handlers = shift;
    my $handlersarr = $handlers->{actions};
    my $action = shift;
    my ( $action_class ) = ref($action) =~ /.*::(\w+)$/;
    my $field = $action->{Field};

    ### Action-tag handlers BEGIN
    my %actionmap = ();
    $actionmap{'Require'} = $actionmap{'Optional'} = sub {
	foreach my $w ( @{$self->{widgets}} ) {
	    next if ( !isEventSink($w, $field) );
	    my $code = sub {
		my $context = shift;
		my $required = $action_class eq "Require";
		my $event = HSDES::RuleEngine::Events::RequiredStateEvent->new( $field, $required );
		$w->handleEvent( $event );
		$context->actionCompleted();
	    };
	    push @{$handlersarr}, $code;
	}
    };
    $actionmap{'Show'} = $actionmap{'Hide'} = sub {
	foreach my $w ( @{$self->{widgets}} ) {
	    next if ( !isEventSink($w, $field) );
	    my $code = sub {
		my $context = shift;
		my $required = $action_class eq "Show";
		my $event = HSDES::RuleEngine::Events::VisibleStateEvent->new( $field, $required );
		$w->handleEvent( $event );
		$context->actionCompleted();
	    };
	    push @{$handlersarr}, $code;
	}
    };
    $actionmap{'Enable'} = $actionmap{'Disable'} = sub {
	foreach my $w ( @{$self->{widgets}} ) {
	    next if ( !isEventSink($w, $field) );
	    my $code = sub {
		my $context = shift;
		my $required = $action_class eq "Enable";
		my $event = HSDES::RuleEngine::Events::EnabledStateEvent->new( $field, $required );
		$w->handleEvent( $event );
		$context->actionCompleted();
	    };
	    push @{$handlersarr}, $code;
	}
    };
    $actionmap{'SetValue'} = $actionmap{'SetValues'} = $actionmap{'ChangeValues'} = sub {
	# Initialize state for this instance of the rule
	my $state = {
	    values => [ ],
	    functionExpression => $action->{Function},
	    setValueKind => $HSDES::RuleEngine::Events::SetValueEvent::ACTION_ADD,
	    clearValues => 1
	};
	if ( $action_class eq "SetValue" ) {
	    my $content = '';
	    foreach my $text ( @{$action->{Kids}} ) {
		$content .= $text->{Text} if ( defined $text->{Text} );
	    }
	    push @{$state->{values}}, $content if ( length($content) > 0 );
	} else {
	    # SetValues or ChangeValues
	    if ( $action->{Action} && $action->{Action} eq "remove" ) {
		$state->{setValueKind} = $HSDES::RuleEngine::Events::SetValueEvent::ACTION_REMOVE;
	    }
	    if ( exists $action->{Clear} ) {
		# if Clear attribute is supplied use it
		$state->{clearValues} = ( lc($action->{Clear}) eq lc("true") || $action->{Clear} eq "1" );
	    } elsif ( $action_class eq 'ChangeValues' ) {
		# default for ChangeValues is to not clear
		$state->{clearValues}  = 0;
	    }
	    # else stick with default of clearValues = 1 (SetValue/SetValues)

	    if ( $action->{Kids} ) {
		foreach my $valuetag ( @{$action->{Kids}} ) {
		    my ( $node_class ) = ref($valuetag) =~ /.*::(\w+)$/;
		    next if ( $node_class ne "Value" );  # skip text nodes and other garbage

		    my $content = '';
		    foreach my $text ( @{$valuetag->{Kids}} ) {
			$content .= $text->{Text} if ( defined $text->{Text} );
		    }

		    push @{$state->{values}}, $content;
		}
	    }
	}

	# Wire up handlers
	foreach my $w ( @{$self->{widgets}} ) {
	    next if ( !isEventSink($w, $field) );
	    my $code = sub {
		my $context = shift;
		if ( ! defined($state->{functionExpression}) ) {
		    my @newValues = ( );
		    foreach my $v ( @{$state->{values}} ) {
			my $newv = substituteParameters( $self->{delegate}, $context, $v );
			push @newValues, $newv;
		    }
		    my $event = HSDES::RuleEngine::Events::SetValueEvent->new
			( $field,
			  \@newValues,
			  $state->{setValueKind},
			  $state->{clearValues} );
		    $w->handleEvent( $event );
		    $context->actionCompleted();
		} else {
		    my $formattedFunction = substituteParametersForServerCall( $self->{delegate}, $context, $state->{functionExpression} );
		    my $continuation = sub {
			my @newValues = @_;  # Passed to us from function eval
			my %hashValues = ();
			map { $hashValues{lc($_)} = $_ } @newValues; # add eval values to hash
			foreach my $v ( @{$state->{values}} ) {
			    if ( ! exists $hashValues{lc($v)} ) {
				$hashValues{lc($v)} = $v;
				$v = substituteParameters( $self->{delegate}, $context, $v );
				push @newValues, $v;
			    }
			}
			my $event = HSDES::RuleEngine::Events::SetValueEvent->new
			    ( $field,
			      \@newValues,
			      $state->{setValueKind},
			      $state->{clearValues} );
			$w->handleEvent( $event );
                        $context->actionCompleted();
		    };
		    $self->{delegate}->evaluateFunction($formattedFunction, $continuation);
		}
	    };
	    push @{$handlersarr}, $code;
	}
    };
    $actionmap{'AddLookup'} = $actionmap{'LoadLookup'} = $actionmap{'RestrictLookup'} = sub {
	# Initialize state for this instance of the rule
	my $state = {
	    values => [ ],
	    changeType => undef,
	    functionExpression => $action->{Function}
	};
	my %changetype = (
	    "AddLookup" => $HSDES::RuleEngine::Events::LookupChangeEvent::DO_ADD,
	    "LoadLookup" => $HSDES::RuleEngine::Events::LookupChangeEvent::DO_RELOAD,
	    "RestrictLookup" => $HSDES::RuleEngine::Events::LookupChangeEvent::DO_FILTER
	    );
	$state->{changeType} = $changetype{$action_class};

	# Parse out text of <Value> tags
	if ( $action->{Kids} ) {
	    foreach my $valuetag ( @{$action->{Kids}} ) {
		my ( $node_class ) = ref($valuetag) =~ /.*::(\w+)$/;
		next if ( $node_class ne "Value" );  # skip text nodes and other garbage

		my $content = '';
		foreach my $text ( @{$valuetag->{Kids}} ) {
		    $content .= $text->{Text} if ( defined $text->{Text} );
		}

		push @{$state->{values}}, $content;
	    }
	}

	# Wire up handlers
	foreach my $w ( @{$self->{widgets}} ) {
	    next if ( !isEventSink($w, $field) );
	    my $code = sub {
		my $context = shift;
		if ( ! $state->{functionExpression} ) {
		    my @newValues = ( );
		    foreach my $v ( @{$state->{values}} ) {
			push @newValues, $v;
		    }
		    my $event = HSDES::RuleEngine::Events::LookupChangeEvent->new
			( $field,
			  $state->{changeType},
			  \@newValues );
		    $w->handleEvent( $event );
		    $context->actionCompleted();
		} else {
		    my $formattedFunction = substituteParametersForServerCall( $self->{delegate}, $context, $state->{functionExpression} );
		    my $continuation = sub {
			my @newValues = @_;  # Passed to us from function eval
			my %hashValues = ();
			map { $hashValues{lc($_)} = $_ } @newValues; # add eval values to hash
			foreach my $v ( @{$state->{values}} ) {
			    if ( ! exists $hashValues{lc($v)} ) {
				$hashValues{lc($v)} = $v;
				push @newValues, $v;
			    }
			}
			my $event = HSDES::RuleEngine::Events::LookupChangeEvent->new
			    ( $field,
			      $state->{changeType},
			      \@newValues );
			$w->handleEvent( $event );
                        $context->actionCompleted();
		    };
		    $self->{delegate}->evaluateFunction($formattedFunction, $continuation);
		}
	    };
	    push @{$handlersarr}, $code;
	}
    };
    $actionmap{'MessageBox'} = sub {
	my $nestedHandlers = $self->_makeHandlerList( $action->{Kids} );
	my $nestedAction = sub {
	    my $context = shift;
	    $nestedHandlers->execute($context);
	};
	my $numCancellableActions = $nestedHandlers->getActionCount();
	my $cancelAction = sub {
	    my $context = shift;
	    for ( my $i = 0 ; $i < $numCancellableActions ; ++$i ) {
		$context->actionCompleted();
	    }
	};
	my $code = sub {
	    my $context = shift;
	    $self->{delegate}->messageBox(
		$nestedAction,
		$cancelAction,
		$context,
		$action->{Caption}||"",
		$action->{Text}||"",
		$action->{Yes}||"Yes",
		$action->{No}||"No",
		$action->{Cancel}||"Cancel");
	    $context->actionCompleted(); # MessageBox is its own action
	};
	push @{$handlersarr}, $code;
	$handlers->adjustActionCount( $numCancellableActions );
    };
    $actionmap{'RaiseErrorOnRequiredFields'} = sub {
	my $code = sub {
	    my $context = shift;

	    # Get the message out of the text node child
	    my $content = '';
	    foreach my $text ( @{$action->{Kids}} ) {
		$content .= $text->{Text} if ( defined $text->{Text} );
	    }

	    $self->{delegate}->errorIfRequiredFieldsMissing($content);
	    $context->actionCompleted();
	};
	push @{$handlersarr}, $code;
    };
    $actionmap{'RaiseError'} = sub {
	my $code = sub {
	    my $context = shift;
	    my $doFire = 0;
	    if ( defined($field) && defined($action->{Value}) ) {
		my $currentValue = $self->{delegate}->getCurrentFieldValue($field);
		$doFire = defined($currentValue) && exists($action->{Value}) &&
		    areStringsEqRegexp( $action, 0, $action->{Value}, $currentValue );
	    }
	    # Use ErrorIf for Condition support instead
	    # if ( $action->{Condition} ) {
	    # 	my $condition = $self->_findCondition($action->{Condition});
	    # 	$doFire = HSDES::RuleEngine::ConditionChecker->new($self->{delegate})->isConditionSatisfied($condition);
	    # }
	    if ( $action->{Negate} && lc($action->{Negate}) eq "true" ) {
		$doFire = ! $doFire;
	    }
	    if ( $doFire ) {
		# Get the message out of the text node child
		my $content = '';
		foreach my $text ( @{$action->{Kids}} ) {
		    $content .= $text->{Text} if ( defined $text->{Text} );
		}

		$self->{delegate}->errorMessage($content, $field);
	    }
	    $context->actionCompleted();
	};
	push @{$handlersarr}, $code;
    };
    $actionmap{'RunServerAction'} = sub {
	my $code = sub {
	    my $context = shift;
	    my $currentValues = { };  # Map
	    my $savedValues = { };    # Map

	    #print Dumper($action);
	    if ( defined($action->{Kids}) ) {
		foreach my $sf (@{$action->{Kids}}) {
		    #print "SF->" . ref($sf) . "\n";
		    next if ( ref($sf) !~ /:SendFields$/ );

		    my $theStore;
		    if ( lc($sf->{Context}) eq lc('current') ) {
			$theStore = \$currentValues;
		    } elsif ( lc($sf->{Context}) eq lc('saved') ) {
			$theStore = \$savedValues;
		    }

		    foreach my $fld (@{$sf->{Kids}}) {
			#print "FLD->" . ref($fld) . "\n";
			next if ( ref($fld) !~ /:Field$/ );
			foreach my $chrs (@{$fld->{Kids}}) {
			    #print "CHRS->" . ref($chrs) . "\n";
			    next if ( ref($chrs) !~ /:Characters$/ );
			    my $fname = $chrs->{Text};
			    chomp $fname;
			    my $value = (lc($sf->{Context}) eq lc('saved')) ? $self->{delegate}->getSavedFieldValue($fname)
			    	: $self->{delegate}->getCurrentFieldValue($fname);
			    if ( defined $value ) {
				$$theStore->{$fname} = $value;
				#print "STORE: $fname -> $value\n";
			    }
			}
		    }
		}
	    }

	    #print Dumper($currentValues, $savedValues);

	    my $continuation = sub {
		my $encodedCommands = shift;   # List<Map>
		my $errorCommands = { };       # Map<String,List<String>
		my $setValueCommands = { };    # Map<String,{ Add=0|1>, Clear=0|1>, Values=>[]}>

		#print Dumper($encodedCommands);

		# Build up executable commands from the table
		foreach my $command ( @{$encodedCommands} ) {
		    my $action = $command->{'action'};
		    my $field = $command->{'field'};
		    my $data = $command->{'data'};

		    if ( uc($action) eq uc('MODIFY_FIELD') ) {
			if ( ! defined $setValueCommands->{$field} ) {
			    $setValueCommands->{$field} = { 'Add'=>1, 'Clear'=>1, 'Values'=>[] };
			}
			push @{$setValueCommands->{$field}->{'Values'}}, $data;
		    } elsif ( uc($action) eq uc('SET_CLEAR_VALUE') ) {
			if ( ! defined $setValueCommands->{$field} ) {
			    $setValueCommands->{$field} = { 'Add'=>1, 'Clear'=>1, 'Values'=>[] };
			}
			$setValueCommands->{$field}->{'Clear'} = ("1" eq $data || "true" eq lc($data)) ? 1 : 0;
		    } elsif ( uc($action) eq uc('SET_ADD_VALUE') ) {
			if ( ! defined $setValueCommands->{$field} ) {
			    $setValueCommands->{$field} = { 'Add'=>1, 'Clear'=>1, 'Values'=>[] };
			}
			$setValueCommands->{$field}->{'Add'} = ("1" eq $data || "true" eq lc($data)) ? 1 : 0;
		    } elsif ( uc($action) eq uc('RAISE_ERROR') ) {
			if ( ! defined $errorCommands->{$field} ) {
			    $errorCommands->{$field} = [ ];
			}
			push @{$errorCommands->{$field}}, $data;
		    }
		}

		# Fire off the setvalues
		foreach my $field ( keys %{$setValueCommands} ) {
		    my $options = $setValueCommands->{$field};
		    foreach my $w ( @{$self->{widgets}} ) {
			next if ( !isEventSink($w, $field) );
			my $event = HSDES::RuleEngine::Events::SetValueEvent->new
			    ( $field,
			      $options->{'Values'},
			      $options->{'Add'} ? $HSDES::RuleEngine::Events::SetValueEvent::ACTION_ADD : $HSDES::RuleEngine::Events::SetValueEvent::ACTION_REMOVE,
			      $options->{'Clear'} );
			$w->handleEvent( $event );
		    }
		    #print Dumper($options);
		}

		# Fire off the error conditions
		foreach my $field ( keys %{$errorCommands} ) {
		    foreach my $message ( @{$errorCommands->{$field}} ) {
			$self->{delegate}->errorMessage($message, $field);
		    }
		}

		$context->actionCompleted();
	    };
	    $self->{delegate}->runServerAction($action->{Name}, $currentValues, $savedValues, $continuation);
	};
	push @{$handlersarr}, $code;
    };
    $actionmap{'ErrorIf'} = sub {
	my $code = sub {
	    my $context = shift;
	    my $actionFired = 0;
	    # Get the message out of the text node child
	    my $content = '';
	    foreach my $text ( @{$action->{Kids}} ) {
		$content .= $text->{Text} if ( defined $text->{Text} );
	    }
	    if ( $action->{Condition} ) {
		my $condition = $self->_findCondition($action->{Condition});
		if ( HSDES::RuleEngine::ConditionChecker->new($self->{delegate})->isConditionSatisfied($condition) ) {
		    $self->{delegate}->errorMessage($content, $action->{Field});
		    $actionFired = 1;
		}
		$context->actionCompleted();
	    }
	    if ( (!$actionFired) && $action->{Function} ) {
		my $formattedFunction = substituteParametersForServerCall( $self->{delegate}, $context, $action->{Function} );
		my $continuation = sub {
		    my @newValues = @_;  # Passed to us from function eval
		    if ($#newValues >= 0 && $newValues[0] eq "1" ) {
			$self->{delegate}->errorMessage($content, $action->{Field});
		    }
		    $context->actionCompleted();
		};
		$self->{delegate}->evaluateFunction($formattedFunction, $continuation);
	    }
	};
	push @{$handlersarr}, $code;
    };
    $actionmap{'SaveState'} = $actionmap{'RestoreState'} = sub {
	foreach my $w ( @{$self->{widgets}} ) {
	    next if ( !isEventSink($w, $field) );
	    my $code = sub {
		my $context = shift;
		my $event;
		if ( $action_class eq 'SaveState' ) {
		    $event = HSDES::RuleEngine::Events::SaveStateEvent->new( $field );
		} else {
		    $event = HSDES::RuleEngine::Events::RestoreStateEvent->new( $field );
		}
		$w->handleEvent( $event );
		$context->actionCompleted();
	    };
	    push @{$handlersarr}, $code;
	}
    };
    $actionmap{'Action'} = sub {
	# Test hook - fire generic event at all registered widgets
	#print "**in else ", Dumper($self->{widgets});
	foreach my $w ( @{$self->{widgets}} ) {
	    if ( $w->can("handleEvent") ) {
		my $code = sub {
		    my $context = shift;
		    my $event = HSDES::RuleEngine::Events::Event->new( undef );
		    $w->handleEvent( $event );
		    $context->actionCompleted();
		};
		push @{$handlersarr}, $code;
	    }
	}
    };
    ### Action-tag handlers END

    # Dispatch actions
    &{$actionmap{$action_class}}() if ( $action_class && exists($actionmap{$action_class}) );
}

########################################################################
#
sub _attachActions {
    my $self = shift;
    my $rule = shift;
    my $handlers = shift;
    my ( $action_class ) = ref($rule) =~ /.*::(\w+)$/;

    if ( $action_class eq "InitRecordEvent" ) {
	$self->_attachConditionalRule($self->{onInitRecordListeners}, $rule, $handlers);
    } elsif ( $action_class eq "OnNewRecordEvent" ) {
	$self->_attachConditionalRule($self->{onNewRecordListeners}, $rule, $handlers);
    } elsif ( $action_class eq "OnLoadRecordEvent" ) {
	$self->_attachConditionalRule($self->{onLoadRecordListeners}, $rule, $handlers);
    } elsif ( $action_class eq "OnChangeEvent" ) {
	my $theAction = HSDES::RuleEngine::RuleCollection->new($handlers);
	my $desiredName = $rule->{Field};
	my $matchValue = $rule->{Value};
	my $hasValue = $rule->{HasValue};

	foreach my $w ( @{$self->{widgets}} ) {
	    next if ( !isChangeEventSource($w, $desiredName) );
	    my $compositeHandler = undef;
	    if ( ! exists $self->{changeHandlerMap}->{$desiredName} ) {
		$compositeHandler = HSDES::RuleEngine::ChangeEventCollection->new($desiredName, $self->{alwaysAfterListeners});
		$self->{changeHandlerMap}->{$desiredName} = $compositeHandler;
		$w->addChangeHandler( $desiredName, sub {
		    my $newValue = shift;
		    my $oldValue = shift;
		    my $callback = shift;
		    $compositeHandler->handler($newValue, $oldValue, $callback);
		} );
	    } else {
		$compositeHandler = $self->{changeHandlerMap}->{$desiredName};
	    }
	    my $code = sub {
		my $newValue = shift;
		my $oldValue = shift;
		my $callback = shift;
		my $doFire = 1;

		if ( ! exists $rule->{HasValue} ) {
		    my $matchValue = $rule->{Value};
		    $doFire = ( (!defined($matchValue)) || areStringsEqRegexp( $rule, $doFire, $matchValue, $newValue ) );
		} elsif ( lc($rule->{HasValue}) eq "true" ) {
		    $doFire = defined($newValue) && length($newValue) > 0;
		} else {
		    $doFire = !defined($newValue) || length($newValue) == 0;
		}
		if ( $doFire && exists $rule->{SavedValue} ) {
		    my $savedValue = $self->{delegate}->getSavedFieldValue($desiredName);
		    $doFire = areStringsEqRegexp( $rule, $doFire, $rule->{SavedValue}, $savedValue );
		}
		if ( $doFire && exists($rule->{Condition}) ) {
		    my $condition = $self->_findCondition($rule->{Condition});
		    $doFire = HSDES::RuleEngine::ConditionChecker->new($self->{delegate})->isConditionSatisfied($condition);
		}

		if ( $doFire ) {
		    my $actionsRemaining = $handlers->getActionCount();
#		    my $wrapperCallback = sub {
#			$self->{alwaysAfterListeners}->executeWithCallback($callback);
#		    };
#		    my $countingContext = HSDES::RuleEngine::CountedActionContext->new($actionsRemaining, $wrapperCallback);
		    my $countingContext = HSDES::RuleEngine::CountedActionContext->new($actionsRemaining, $callback);
		    my $valueChangeContext = HSDES::RuleEngine::ValueContextImpl->new($countingContext, $newValue, $oldValue);
		    $theAction->executeWithContext( $valueChangeContext );
		    $countingContext->dispose();
		} elsif ( $callback ) {
		    &{$callback}();
		}
	    };
#	    $w->addChangeHandler( $desiredName, $code );
	    $compositeHandler->registerHandler( $code );
	}
    } elsif ( $action_class eq "OnClickEvent" ) {
	my $theAction = HSDES::RuleEngine::RuleCollection->new($handlers);
	my $desiredName = $rule->{Button};

	foreach my $w ( @{$self->{widgets}} ) {
	    next if ( !isClickEventSource($w, $desiredName) );
	    my $compositeHandler = undef;
	    if ( ! exists $self->{clickHandlerMap}->{$desiredName} ) {
		$compositeHandler = HSDES::RuleEngine::ClickEventCollection->new($desiredName, $self->{alwaysAfterListeners});
		$self->{clickHandlerMap}->{$desiredName} = $compositeHandler;
		$w->addClickHandler( $desiredName, sub {
		    my $callback = shift;
		    $compositeHandler->handler($callback);
		} );
	    } else {
		$compositeHandler = $self->{clickHandlerMap}->{$desiredName};
	    }
	    my $code = sub {
		my $callback = shift;
		my $doFire = 1;

		if ( $doFire && exists($rule->{Condition}) ) {
		    my $condition = $self->_findCondition($rule->{Condition});
		    $doFire = HSDES::RuleEngine::ConditionChecker->new($self->{delegate})->isConditionSatisfied($condition);
		}
		if ( $doFire ) {
#		    my $wrapperCallback = sub {
#			$self->{alwaysAfterListeners}->executeWithCallback($callback);
#			&{$callback}();
#		    };
#		    $theAction->executeWithCallback( $wrapperCallback );
		    $theAction->executeWithCallback( $callback );
		} elsif ( $callback ) {
		    &{$callback}();
		}
	    };
#	    $w->addClickHandler( $desiredName, $code );
	    $compositeHandler->registerHandler( $code );
	}
    } elsif ( $action_class eq "AlwaysAfterEvent" ) {
	if ( exists($rule->{Condition}) ) {
	    my $wrappedHandlers = HSDES::RuleEngine::ActionCollection->new();
	    push @{$wrappedHandlers->{actions}}, sub {
		my $context = shift;
		my $condition = $self->_findCondition($rule->{Condition});
		my $doFire = HSDES::RuleEngine::ConditionChecker->new($self->{delegate})->isConditionSatisfied($condition);

		if ( $doFire ) {
		    $handlers->execute( $context );
		} else {
		    # Count as processed even if it didn't fire
		    for ( my $i = 0 ; $i < $handlers->getActionCount() ; ++$i ) {
			$context->actionCompleted();
		    }
		}
		$context->actionCompleted(); # Since we are a wrapper, count myself as executing
	    };
	    $wrappedHandlers->adjustActionCount( $handlers->getActionCount() );
	    $self->{alwaysAfterListeners}->push($wrappedHandlers);
	} else {
	    $self->{alwaysAfterListeners}->push($handlers);
	}
    }
}


########################################################################
#
sub _attachConditionalRule {
    my $self = shift;
    my $ruleCollection = shift;
    my $rule = shift;
    my $handlers = shift;

    if ( exists($rule->{Condition}) || ( exists($rule->{Field}) && exists($rule->{Value}) ) ) {
	my $wrappedHandlers = HSDES::RuleEngine::ActionCollection->new();
	push @{$wrappedHandlers->{actions}}, sub {
	    my $context = shift;
	    my $doFire = 1;

	    if ( exists($rule->{Field}) && exists($rule->{Value}) ) {
		my $value = $self->{delegate}->getCurrentFieldValue( $rule->{Field} );
		my $compareValue = &substituteParameters($self->{delegate}, undef, $rule->{Value});
		$doFire = &areStringsEqRegexp( $rule, $doFire, $compareValue, $value );
	    }
	    if ( $doFire && exists($rule->{Condition}) ) {
		my $condition = $self->_findCondition($rule->{Condition});
		$doFire = HSDES::RuleEngine::ConditionChecker->new($self->{delegate})->isConditionSatisfied($condition);
	    }
	    if ( $doFire ) {
		$handlers->execute( $context );
	    } else {
		# Count as processed even if it didn't fire
		for ( my $i = 0 ; $i < $handlers->getActionCount() ; ++$i ) {
		    $context->actionCompleted();
		}
	    }
	    $context->actionCompleted(); # Since we are a wrapper, count myself as executing
	};
	$wrappedHandlers->adjustActionCount( $handlers->getActionCount() );
	$ruleCollection->push($wrappedHandlers);
    } else {
	$ruleCollection->push($handlers);
    }
}

########################################################################
#
sub _findCondition {
    my $self = shift;
    my $id = shift;

    return undef if ( !defined $self->{ruleSet}->{Kids} );

    foreach my $node ( @{$self->{ruleSet}->{Kids}} ) {
	my ( $node_class ) = ref($node) =~ /.*::(\w+)$/;
	next if ( lc($node_class) ne "conditionals" );
	foreach ( @{$node->{Kids}} ) {
	    my ( $class ) = ref($_) =~ /.*::(\w+)$/;
	    return $_ if ( lc($class) eq "condition" &&
			   lc($id) eq lc($_->{id}) );
	}
    }
    return undef;
}

########################################################################
#
sub isEventSink {
    # static sub
    my ($w, $field) = @_;
    return $w->can("getName") &&
	$w->can("handleEvent") &&
	$field eq $w->getName($field);
}

########################################################################
#
sub isChangeEventSource {
    # static sub
    my ($w, $field) = @_;
    return $w->can("getName") &&
	$w->can("addChangeHandler") &&
	$field eq $w->getName($field);
}

########################################################################
#
sub isClickEventSource {
    # static sub
    my ($w, $field) = @_;
    return $w->can("getName") &&
	$w->can("addClickHandler") &&
	$field eq $w->getName($field);
}

1;

__END__

#!/usr/intel/pkgs/perl/5.14.1/bin/perl -w 

package facets::FacetChecks;

use strict;
use warnings;

use FindBin();
use File::Basename();

use lib "$ENV{TSA_ROOT}/lib/Perl";
use TSA::InitToolData();

use vars qw($count_process_facets $count_HDK_REL_facets 
            $count_tested_default_facets 
            $count_tested_process_facets $count_simple_tested_process_facets $count_complex_tested_process_facets
            $count_process_toolset_facet_combinations
            $count_toolset_facets );

BEGIN {
    $count_toolset_facets = 0;
    foreach my $baseline (keys %TSA::InitToolData::hdk_baseline_lookup) {
        next if($baseline eq 'default');
        $count_toolset_facets++;
    }
    $count_process_toolset_facet_combinations = 0;
    foreach my $process (keys %TSA::InitToolData::process_defaults) {
        $count_process_toolset_facet_combinations += $count_toolset_facets;
    }
    $count_HDK_REL_facets = scalar(keys %TSA::InitToolData::hdk_baseline_lookup);
    $count_process_facets = scalar(keys %TSA::InitToolData::process_defaults);
    $count_tested_default_facets = scalar(keys %{$TSA::InitToolData::process_defaults{NotSet}});
    $count_tested_process_facets = $count_process_facets;
    $count_simple_tested_process_facets = 0;
    $count_complex_tested_process_facets = 0;
    foreach my $process (keys %TSA::InitToolData::process_defaults) {
        $count_simple_tested_process_facets++;
        foreach my $facet (keys %{$TSA::InitToolData::process_defaults{$process}}) {
            if(ref($TSA::InitToolData::process_defaults{$process}{$facet}) eq '') {
                $count_simple_tested_process_facets++;
            } else {
                foreach my $implication (keys %{$TSA::InitToolData::process_defaults{$process}{$facet}}) {
                    my @conditions = split(/\s*\&\s*/,$implication);
                    $count_complex_tested_process_facets += scalar(@conditions);
                }
                $count_complex_tested_process_facets++;
            }
        }
    }
    $count_tested_process_facets += $count_simple_tested_process_facets;
    $count_tested_process_facets += $count_complex_tested_process_facets;
}
use Test::More;




sub compare_process_defaults {
    my ($run_area, $repo_name) = @_;
    my $out_file = "$run_area/$repo_name/facets.default.out";
    my $cmd = "ToolConfig.pl get_all_facets -ver $run_area/$repo_name >& $out_file";
    ok( !system($cmd), "get_all_facets. Command: $cmd");
    my %cmd_facets = ();
    read_facet_file(\%cmd_facets, $out_file);
    if(is("$cmd_facets{process}", "NotSet", "process defaults to NotSet")) {
        foreach my $facet (keys %{$TSA::InitToolData::process_defaults{NotSet}}) {
            is("$cmd_facets{$facet}", "NotSet", "$facet defaults to NotSet");
        }
    }
}

sub compare_process_env_override {
    my ($run_area, $repo_name, $additional_override) = @_;
    $additional_override ='' if(!defined($additional_override));
    foreach my $process (keys %TSA::InitToolData::process_defaults) {
        my $out_file = "$run_area/$repo_name/facets.${process}.env.out";
        my $apply_override = $additional_override;
        if($additional_override ne '') {
            $out_file .= "$additional_override";
            $out_file =~ s/\s+/_/g;
            $apply_override =~ s/^\-/&& setenv ONECFG_/;
            $apply_override =~ s/\s+\-/ && setenv ONECFG_/;
        }
        my $cmd = "tcsh -c 'cd $run_area/$repo_name && setenv ONECFG_process $process $apply_override && $ENV{TSA_ROOT}/dev/tests/scripts/TestToolConfigEnv.pl >& $out_file'";
        if(ok( !system($cmd), "get_all_facets env $process. Command: $cmd")) {
            _check_facet_value($process, $out_file, 'env var facet', $additional_override);
        }
    }
}
sub compare_process_override {
    my ($run_area, $repo_name, $additional_override) = @_;
    $additional_override ='' if(!defined($additional_override));
    run_command_using_process_facet($run_area, $repo_name, "get_all_facets", "ToolConfig.pl get_all_facets", "", $additional_override);
    run_command_using_process_facet($run_area, $repo_name, "get_all_facets", \&_check_facet_value, "reported facet", $additional_override);
=c
    foreach my $process (keys %TSA::InitToolData::process_defaults) {
        my $out_file = "$run_area/$repo_name/facets.${process}.out";
        if($additional_override ne '') {
            $out_file .= $additional_override;
            $out_file =~ s/\s+/_/g;
        }
        if(ref($user_cmd) ne '') {
            &$user_cmd($process, $toolset, $out_file, $message);
        } else {
            my $cmd = "ToolConfig.pl get_all_facets -1c -process $process $additional_override -1c- -ver $run_area/$repo_name >& $out_file";
            if(ok( !system($cmd), "get_all_facets $process. Command: $cmd")) {
            my %cmd_facets = ();
            read_facet_file(\%cmd_facets, $out_file);
            compare_process_facet_values(\%cmd_facets, $process,'reported facet'.($additional_override ne '' ? "(overriding $additional_override)" : ''));
        }
    }
=cut
}

sub _check_facet_value {
    my ($process, $out_file, $message, $additional_override, $expect_to_fail) = @_; 
    $expect_to_fail = 0 if(!defined($expect_to_fail));
    my %cmd_facets = ();
    read_facet_file(\%cmd_facets, $out_file);
    compare_simple_process_facet_values(\%cmd_facets, $process,$message.($additional_override ne '' ? "(overriding $additional_override)" : ''));
    compare_complex_process_facet_values(\%cmd_facets, $process,$message.($additional_override ne '' ? "(overriding $additional_override)" : ''));
}

sub compare_simple_process_facet_values {
    my ($facet_values, $process, $check_type) = @_;
    is("$facet_values->{process}", "$process", "$check_type process override to $process");
    foreach my $facet (keys %{$TSA::InitToolData::process_defaults{$process}}) {
        if(ref($TSA::InitToolData::process_defaults{$process}{$facet}) eq '') {
            is("$facet_values->{$facet}", $TSA::InitToolData::process_defaults{$process}{$facet}, "$check_type $facet gets expected $process implied setting $TSA::InitToolData::process_defaults{$process}{$facet}");
        }
    }
}
sub compare_complex_process_facet_values {
    my ($facet_values, $process, $check_type) = @_;
    foreach my $facet (keys %{$TSA::InitToolData::process_defaults{$process}}) {
        next if(ref($TSA::InitToolData::process_defaults{$process}{$facet}) eq '');
        ## this facet implication is more complex, and have to find the right setting to match
        my $match = '';
        foreach my $implication (keys %{$TSA::InitToolData::process_defaults{$process}{$facet}}) {
            my @conditions = split(/\s*\&\s*/,$implication);
            my $is_match = 1;
            foreach my $cond (@conditions) {
                if($cond =~ /^\s*(\S+)=(\S+)\s*$/) {
                    my $check = $1;
                    my $expected = $2;
                    ok(exists($facet_values->{$check}),"$check_type $facet implication $implication used check $cond");
                    (my $expected_match =$expected) =~ s/\./\\\./g;
                    $expected_match =~ s/\*/\.\*/g;
                    #print "Using expected_match /$expected_match/\n";
                    $is_match = 0 if($facet_values->{$check} !~ /^$expected_match$/);
                }
            }
            if($is_match) {
                $match = $TSA::InitToolData::process_defaults{$process}{$facet}{$implication}
            }
        }
        print STDOUT "$facet_values->{$facet}\n";
        print STDOUT "match->$match\n";
        print STDOUT "check_type->$check_type\n";
        print STDOUT "facet->$facet\n";
        print STDOUT "process->$process\n";
        print STDOUT "match->$match\n";
        is("$facet_values->{$facet}", $match, "$check_type $facet gets expected $process implied setting $match (complex implication)");
    }
}

sub read_facet_file {
    my ($contentRef, $file) = @_;
    open(F,"<$file") or die "-E- Unable to read $file\n";
    while(my $line = <F>) {
        if($line =~ /^\s*(\S+)\s*\=\>\s*[\"\']?([^\"\',]+)[\"\']?,?\s*$/) {
            $contentRef->{$1} = $2;
        }
    }
    close(F);
}

sub check_valid_tool_version {
    my ($run_area, $repo_name, $tool, $process) = @_;
    my $cmd = "ToolConfig.pl get_tool_version $tool";
    if(!defined($process)) {
        run_command_on_all_process_and_toolset_facet_combinations($run_area, $repo_name, "$tool.version", $cmd, "Attempt get_tool_version $tool");
        run_command_on_all_process_and_toolset_facet_combinations($run_area, $repo_name, "$tool.version", \&_check_tool_version_for_unexpected_facet_combination, $tool);
    } else {
        #run_command_on_all_process_and_toolset_facet_combinations($run_area, $repo_name, "$tool.version", $cmd, "Attempt get_tool_version $tool");
        #run_command_on_all_process_and_toolset_facet_combinations($run_area, $repo_name, "$tool.version", \&_check_tool_version_for_unexpected_facet_combination, $tool);
        run_command_using_toolset_facet($run_area, $repo_name, "$tool.version", $cmd, "Attempt get_tool_version $tool", "-process $process");
        run_command_using_toolset_facet($run_area, $repo_name, "$tool.version", \&_check_tool_version_for_unexpected_facet_combination, "$tool", "-process $process");
    }
    return;
    foreach my $process (keys %TSA::InitToolData::process_defaults) {
        foreach my $baseline (keys %TSA::InitToolData::hdk_baseline_lookup) {
            next if($baseline eq 'default');
            my $toolset = TSA::InitToolData::_get_toolset_from_hdk_rel($baseline);
            my $out_file = "$run_area/$repo_name/$tool.${process}.${toolset}.version.out";
            my $cmd = "ToolConfig.pl get_tool_version $tool -1c -process $process -toolset $toolset -1c- -ver $run_area/$repo_name >& $out_file";
            if(ok( !system($cmd), "Attempt get_tool_version $tool for $process && $toolset. Command: $cmd")) {
                my $version = `/bin/cat $out_file`;
                chomp $version;
                isnt($version,"unexpected_facet_combination", "Checking for unexpected tool version for $tool, for $process && $toolset got $version");
            }
        }
    }
}

sub _check_tool_version_for_unexpected_facet_combination {
    my ($toolset, $out_file, $message, $additional_override, $expect_to_fail) = @_;
    $expect_to_fail = 0 if(!defined($expect_to_fail));
    my $version = `/bin/cat $out_file`;
    chomp $version;
    isnt($version,"unexpected_facet_combination", "Checking for unexpected tool version for $message, for $additional_override -toolset $toolset got $version");
}

sub run_command_using_process_facet {
    my ($run_area, $repo_name, $name, $user_cmd, $message, $additional_override, $expect_to_fail, $fail_on_process_aref) = @_;
    $additional_override ='' if(!defined($additional_override));
    $expect_to_fail = 0 if(!defined($expect_to_fail));
    $fail_on_process_aref = [] if(!defined($fail_on_process_aref));
    foreach my $process (sort keys %TSA::InitToolData::process_defaults) {
        my $expect_process_to_fail = $expect_to_fail;
        $expect_process_to_fail = 1 if(grep {/^$process$/} @$fail_on_process_aref);
        my $out_file = "$run_area/$repo_name/$name.${process}.out";
        if($additional_override ne '') {
            $out_file .= $additional_override;
            $out_file =~ s/\s+/_/g;
        }
        if(ref($user_cmd) ne '') {
            &{$user_cmd}($process, $out_file, $message, $additional_override, $expect_process_to_fail);
        } else {
            my $cmd = ($user_cmd !~ /\s\-ver\s/ && $user_cmd !~ /\bcd\s+/ ? 
                       "cd $run_area/$repo_name ; " : "") .
                       "$user_cmd -1c -process $process $additional_override -1c- ".
                       ($user_cmd !~ /\s\-ver\s/ ? "-ver $run_area/$repo_name" : "").
                       " >& $out_file";
            if($expect_process_to_fail) {
                ok( system($cmd), "Expected to fail: $name running -process $process $additional_override. Command: $cmd");
            } else {
                ok( !system($cmd), "$name running -process $process $additional_override. Command: $cmd");
            }
        }
    }
}

sub run_command_using_toolset_facet {
    my ($run_area, $repo_name, $name, $user_cmd, $message, $additional_override, $expect_to_fail, $fail_on_toolset_aref) = @_;
    $additional_override ='' if(!defined($additional_override));
    $expect_to_fail = 0 if(!defined($expect_to_fail));
    $fail_on_toolset_aref = [] if(!defined($fail_on_toolset_aref));
    foreach my $baseline (sort keys %TSA::InitToolData::hdk_baseline_lookup) {
        next if($baseline eq 'default');
        my $toolset = TSA::InitToolData::_get_toolset_from_hdk_rel($baseline);
        my $expect_toolset_to_fail = $expect_to_fail;
        $expect_toolset_to_fail = 1 if(!$expect_toolset_to_fail && grep {/^$toolset$/} @$fail_on_toolset_aref);
        my $out_file = "$run_area/$repo_name/${name}.${toolset}.out";
        if($additional_override ne '') {
            $out_file .= $additional_override;
            $out_file =~ s/\s+/_/g;
        }
        if(ref($user_cmd) ne '') {
            &{$user_cmd}($toolset, $out_file, $message, $additional_override, $expect_toolset_to_fail);
        } else {
            my $cmd = ($user_cmd !~ /\s\-ver\s/ && $user_cmd !~ /\bcd\s+/ ? 
                       "cd $run_area/$repo_name ; " : "") .
                       "$user_cmd -1c -toolset $toolset $additional_override -1c- ".
                       ($user_cmd !~ /\s\-ver\s/ ? "-ver $run_area/$repo_name" : "").
                       " >& $out_file";

            if($expect_toolset_to_fail) {
                ok( system($cmd), "Expected to fail: $name running -toolset $toolset $additional_override. Command: $cmd");
            } else {
                ok( !system($cmd), "$name running -toolset $toolset $additional_override. Command: $cmd");
            }
        }
    }
}

sub run_command_on_all_process_and_toolset_facet_combinations {
    my ($run_area, $repo_name, $name, $user_cmd, $message, $notset_expected_to_fail) = @_;
    $notset_expected_to_fail = 0 if(!defined($notset_expected_to_fail));
    foreach my $process (keys %TSA::InitToolData::process_defaults) {
        run_command_using_toolset_facet($run_area, $repo_name, $name, $user_cmd, $message, "-process $process", ($notset_expected_to_fail && $process eq 'NotSet' ? 1 : 0));
    }
}

1;

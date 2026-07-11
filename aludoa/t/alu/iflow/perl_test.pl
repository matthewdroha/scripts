#!/usr/intel/pkgs/perl/5.34.0/bin/perl

if (exists $ENV{GLOBAL_VAR1}) {
  print qq(VALUE:$ENV{GLOBAL_VAR1}\n);
} else {
  print qq(VALUE:NO_VALUE\n);
}

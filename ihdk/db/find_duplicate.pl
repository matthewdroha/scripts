#!/usr/bin/perl
use warnings;
use strict;
use File::Find;
use File::Spec;
  
my $directory = shift @ARGV || '/p/sip';
  
find (\&wanted, $directory);

my %path_file;

sub wanted {
	my $path = $File::Find::dir;
	my $filename = File::Spec->abs2rel($File::Find::name, $path);
	if ($path !~ m/snapshot/) {
		push @{$path_file{$filename}}, $path;
	}
}

my (%hashDup, %hashUniq);
while (my ($filename, $paths) = each %path_file){
	if (scalar @$paths >= 2){
		foreach my $item (@$paths) {
			$hashDup{$filename}{$item} = 1;
		}
	} else {
		foreach my $item (@$paths) {
			$hashUniq{$item}{$filename} = 1;
		}
	}
}

##### uniq file ######
foreach my $item (sort keys %hashUniq) {
	foreach my $filename (sort keys %{$hashUniq{$item}}) {
		#print "-I- $item/$filename\n";
	}
}
print "\n";

##### duplicate file ######
print "file,directory\n";
foreach my $item (sort keys %hashDup) {
	#print "$item found in:\n";
	foreach my $filename (sort keys %{$hashDup{$item}}) {
		my $row = join(',', $item, $filename);
		print "$row\n";
	}
	#print "\n";
}

exit;

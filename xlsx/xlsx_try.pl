#!/usr/intel/pkgs/perl/5.34.0/bin/perl

# xlsx_demo.pl
# (C) Copyright Intel Corporation, 2024, Matthew Roha, matthew.d.roha@intel.com
#
# Documentation after __END__
#

use v5.34.0;
use strict;
use warnings;
use English;
use Pod::Usage;
use Excel::Writer::XLSX;


########################
# Run main
main();


sub main {

# Synthesize string dataset
my @dataset;
my @datarow;

say qq(### Input Data ###\n);
my @nums = (1..100);
for (@nums) {
  push (@datarow, $_);
  if (int($_%10) == 0) {
    my $csvrow = join(',', @datarow);
    push(@dataset, $csvrow);
    @datarow = ();
    say($csvrow);
  }
}


# Write Excel
my $xlsx_file = qq(demo.xlsx);
my $workbook = Excel::Writer::XLSX->new($xlsx_file);
my $cellsheet = $workbook->add_worksheet('test sheet');

# Write basic data
# Start with row offset by one to leave room for the eventual header row 
my $rownum = 1;
my $colnum = 0;
foreach my $csvrow (@dataset) {
  $colnum = 0;
  my @rowvalues = split(/,/, $csvrow);
  foreach my $celldata (@rowvalues) {
    $cellsheet->write_string($rownum, $colnum, $celldata);
    $colnum++;
  }
  $rownum++;
}

# Put the data into an Excel table object
$cellsheet->add_table(0, 0, $rownum-1, $colnum-1,
                        {
                          columns => [
                            { header => 'cpp' },
                            { header => 'collage_tb' },
                            { header => 'tool3' },
                            { header => 'tool4' },
                            { header => 'tool5' },
                            { header => 'tool6' },
                            { header => 'tool7' },
                            { header => 'tool8' },
                            { header => 'tool9' },
                            { header => 'tool10' },
                          ]
                        }
);

printf("\nData written to xlsx: worksheet->(%s) rowcount->(%s)\n", $cellsheet->get_name, $rownum-1);

$cellsheet->activate;
$workbook->close;



} # end main

__END__


=pod

=head1 COPYRIGHT

(C) Copyright Intel Corporation, 2024
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: xlsx_demo.pl

=cut

=head1 DESCRIPTION

B<xlsx_demo.pl> Description and usage here

=cut

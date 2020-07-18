#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Std;
use Data::Dumper;

# kill program and print help if no command line arguments were given
if( scalar( @ARGV ) == 0 ){
  &help;
  die "Exiting program because no command line options were used.\n\n";
}

# take command line arguments
my %opts;
getopts( 'd:f:ho:', \%opts );

# if -h flag is used, or if no command line arguments were specified, kill program and print help
if( $opts{h} ){
  &help;
  die "Exiting program because help flag was used.\n\n";
}

# parse the command line
my( $dist, $file, $out ) = &parsecom( \%opts );

# declare variables
my %distances; #hash to hold geographic distances between sites
my @distancelines; #array to hold data from distance file
my @filecontents; #file containing summarized bayesass data

#read in the files
&filetoarray($file, \@filecontents);
&filetoarray($dist, \@distancelines);

&disthash(\@distancelines, \%distances);

&printdata(\@filecontents, \%distances, $out);

#print Dumper(\%distances);

exit;


#####################################################################################################
############################################ subroutines ############################################
#####################################################################################################
# subroutine to print help
sub help{
  
  print "\nbayesass_sum.pl is a perl script developed by Steven Michael Mussmann\n\n";
  print "To report bugs send an email to mussmann\@email.uark.edu\n";
  print "When submitting bugs please include all input files, options used for the program, and all error messages that were printed to the screen\n\n";
  print "Program Options:\n";
  print "\t\t[ -d | -h | -f | -o ]\n\n";
  print "\t-d:\tSpecify your file containing pairwise distances between all sites.\n";
  print "\t\tIf no file is provided, program will exit.\n\n";
  print "\t-h:\tDisplay this help message.\n";
  print "\t\tThe program will die after the help message is displayed.\n\n";
  print "\t-m:\tSpecify your file containing bayesass migration rates.\n";
  print "\t\tThe program will die if a file is not specified.\n\n";
  
}

#####################################################################################################
# subroutine to parse the command line options

sub parsecom{ 
  
	my( $params ) =  @_;
	my %opts = %$params;
  
	# set default values for command line arguments
	my $dist = $opts{d} || die "No input distances file specified.\n\n"; #used to specify input directory
	my $out = $opts{o} || die "No output file specified.\n\n"  ; #used to specify output file name.
	my $file = $opts{f} || die "No bayesass migration rates file specified.\n\n"; #used to specify number of mcmc samples that were retained.

	return( $dist, $file, $out );

}

#####################################################################################################
# subroutine to put file into an array

sub filetoarray{

	my( $infile, $array ) = @_;

  
	# open the input file
	open( FILE, $infile ) or die "Can't open $infile: $!\n\n";

	# loop through input file, pushing lines onto array
	while( my $line = <FILE> ){
		chomp( $line );
		next if($line =~ /^\s*$/);
		push( @$array, $line );
	}

	# close input file
	close FILE;

}

#####################################################################################################
# put distance data into hash

sub disthash{
	my( $arrayref, $hashref ) = @_;

	foreach my $pair( @$arrayref ){
		my @temp = split( /,/, $pair );
		if( $temp[2] < 0 ){
			$temp[2] = 0.0;
		}
		$temp[2] = sprintf("%.2f", $temp[2]);
		$$hashref{$temp[0]}{$temp[1]} = $temp[2];
		$$hashref{$temp[1]}{$temp[0]} = $temp[2];
	}
}

#####################################################################################################
# subroutine to print out data file

sub printdata{
	my ($arrayref, $hashref, $out) = @_;

	my $counter = 0;

	open(OUT, '>', $out) or die "Can't open $out: $!\n\n";

	foreach my $line( @$arrayref ){
		if( $counter == 0 ){
			print OUT $line, "\t", "km";
		}else{
			print OUT $line, "\t";
			my @temp = split(/\s+/, $line);
			if( $temp[0] eq $temp[1] ){
				print OUT 0.0;
			}else{
				print OUT $$hashref{$temp[0]}{$temp[1]};
			}
		}
		print OUT "\n";
		$counter++;
	}

	close OUT;

}

#####################################################################################################

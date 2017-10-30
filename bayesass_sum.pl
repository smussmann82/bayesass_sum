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
getopts( 'hd:o:', \%opts );

# if -h flag is used, or if no command line arguments were specified, kill program and print help
if( $opts{h} ){
  &help;
  die "Exiting program because help flag was used.\n\n";
}

# parse the command line
my( $dir, $out ) = &parsecom( \%opts );

opendir( WD, $dir ) or die "Can't open $dir: $!\n\n";

my @contents = readdir( WD );

foreach my $file( @contents ){
	if( $file =~ /\.out$/ ){
		&getdata( $file, $dir );
	}
}

closedir WD;

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
  print "\t\t[ -h | -d | -o ]\n\n";
  print "\t-h:\tDisplay this help message.\n";
  print "\t\tThe program will die after the help message is displayed.\n\n";
  print "\t-m:\tSpecify your directory containing bayesass output files.\n";
  print "\t\tIf no directory is provided, program will exit.\n\n";
  print "\t-o:\tSpecify the output file name.\n";
  print "\t\tIf no name is provided, the program will exit.\n\n";
  
}

#####################################################################################################
# subroutine to parse the command line options

sub parsecom{ 
  
	my( $params ) =  @_;
	my %opts = %$params;
  
	# set default values for command line arguments
	my $dir = $opts{d} || die "No input directory specified.\n\n"; #used to specify input directory
	my $out = $opts{o} || die "No output file specified.\n\n"  ; #used to specify output file name.

	return( $dir, $out );

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
# subroutine to grab important data from inputs

sub getdata{

	my( $file, $dir ) = @_;

	my @arr;
	my @matrix;
	my @pops;
	&filetoarray("$dir/$file", \@arr);
	foreach my $line( @arr ){
		if( $line =~ /^\s{1}m\[/ ){
			push( @matrix, $line );
		}
		if( $line =~ /0\-\>/ ){
			push( @pops, $line );
		}
	}

	foreach my $line( @matrix ){
		print $line, "\n";
	}

}

#####################################################################################################

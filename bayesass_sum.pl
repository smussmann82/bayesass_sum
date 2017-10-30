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
getopts( 'd:hm:o:', \%opts );

# if -h flag is used, or if no command line arguments were specified, kill program and print help
if( $opts{h} ){
  &help;
  die "Exiting program because help flag was used.\n\n";
}

# parse the command line
my( $dir, $out, $mcmc ) = &parsecom( \%opts );

# declare variables
my %hohoa; #hash of hashes of arrays to hold migration estimates
my %sumhohoa; #hash of summarized migration estimates

#open directory
opendir( WD, $dir ) or die "Can't open $dir: $!\n\n";

#read directory contents
my @contents = readdir( WD );

#close directory
closedir WD;

#operate on bayesass output files in the directory
foreach my $file( @contents ){
	if( $file =~ /\.out$/ ){
		&getdata( $file, $dir, \%hohoa );
	}
}

#summarize the data from the bayesass output files
&summarize( \%hohoa, \%sumhohoa, $mcmc );

#print the data to an output file
&printdata( \%sumhohoa, $out );

#print Dumper(\%hohoa);
#print Dumper(\%sumhohoa);

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
  print "\t\t[ -d | -h | -m | -o ]\n\n";
  print "\t-d:\tSpecify your directory containing bayesass output files.\n";
  print "\t\tIf no directory is provided, program will exit.\n\n";
  print "\t-h:\tDisplay this help message.\n";
  print "\t\tThe program will die after the help message is displayed.\n\n";
  print "\t-m:\tSpecify number of retained MCMC samples.\n";
  print "\t\tThe program will die if number is not specified.\n\n";
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
	my $mcmc = $opts{m} || die "Number of retained MCMC samples not specified.\n\n"; #used to specify number of mcmc samples that were retained.

	return( $dir, $out, $mcmc );

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

	my( $file, $dir, $hohoaref ) = @_;

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

	my $hashref;
	foreach my $line( @pops ){
		#print $line, "\n";
		$hashref = &decode( $line );
	}

	foreach my $line( @matrix ){
		&migmatrix( $line, $hashref, $hohoaref );
		#print $line, "\n";
	}

}

#####################################################################################################
# subroutine to decode line containing populations

sub decode{

	my( $line ) = @_;

	$line =~ s/^\s+//g;
	my %hash;

	my @temp = split( /\s+/, $line );
	foreach my $item( @temp ){
		#print $item, "\n";
		my @pair = split(/\-\>/, $item);
		#for( my $i=0; $i<@pair; $i++ ){
		#	print $pair[$i], "\n";
		#}
		$hash{$pair[0]} = $pair[1];
	}

	#print Dumper(\%hash);
	return( \%hash );
}

#####################################################################################################
# subroutine to store migration matrix data
sub migmatrix{

	my( $line, $hashref, $hohoaref  ) = @_;

	$line =~ s/^\s+//g;

	my @temp = split( /\s+/, $line );
	for( my $i=0; $i<@temp; $i+=2 ){
		#print $temp[$i], "\t", $temp[$i+1], "\n";
		if($temp[$i] =~ /m\[(\d+)\]\[(\d+)\]:/){
			#print $1, "\t", $2, "\n";
			#print $$hashref{$1}, "\t", $$hashref{$2}, "\n";
			push( @{$$hohoaref{$$hashref{$1}}{$$hashref{$2}}}, $temp[$i+1] );
		}
	}

}

#####################################################################################################
# subroutine to summarize migration matrix data
sub summarize{

	my( $hohoaref, $sumhohoaref, $mcmc ) = @_;

	foreach my $pop1( sort keys %$hohoaref ){
		#print $pop1, "\n";
		foreach my $pop2( sort keys %{$$hohoaref{$pop1}} ){
			#print "pop2 is ", $pop2, "\n";
			my @arr; #temporary array to hold all observations of migration calculations
			foreach my $val( @{$$hohoaref{$pop1}{$pop2}} ){
				#print $val, "\n";
				push( @arr, $val );
			}
			my( $n, $mean, $stdev ) = &sumstats( \@arr, $mcmc ); #calculate summary statistics

			$$sumhohoaref{$pop1}{$pop2}{'n'} = $n;
			$$sumhohoaref{$pop1}{$pop2}{'mean'} = $mean;
			$$sumhohoaref{$pop1}{$pop2}{'stdev'} = $stdev;

		}
	}

}

#####################################################################################################
# subroutine to calculate summary stats
sub sumstats{

	my( $arrayref, $mcmc ) = @_;
	
	my $n = 0; #number of sample means included in summary statistic
	my $mean = 0;
	my $stdev = 0;

	if(scalar(@$arrayref) == 1){
		#print $$arrayref[0], "\n";
		if( $$arrayref[0] =~ /(\d\.\d+)\((\d\.\d+)\)/ ){
			$n = 1;
			$mean = $1;
			$stdev = $2;
		}
	}else{
		$n = scalar(@$arrayref);
		my @means;
		my @stdevs;
		foreach my $item( @$arrayref ){
			if( $item =~ /(\d\.\d+)\((\d\.\d+)\)/ ){
				#print $1, "\t", $2, "\n";
				push( @means, $1 );
				push( @stdevs, $2 );
			}
		}
		$mean = &calcmean(\@means, $mcmc, $n);
		$stdev = &calcmean(\@stdevs, $mcmc, $n);
	}

	return( $n, $mean, $stdev );

}
#####################################################################################################
# subroutine to calculate mean from values in an array
sub calcmean{

	my( $arrayref, $mcmc, $n ) = @_;

	my $tot = 0;

	foreach my $val( @$arrayref ){
		$tot += $val;
	}

	my $mean = ($tot/$n);

	return( $mean );

}

#####################################################################################################
sub printdata{

	my( $hohoaref, $out ) = @_;

	open( OUT, '>', $out ) or die "Can't open $out: $!\n\n";

	#print header
	print OUT "into_pop", "\t", "from_pop", "\t", "n", "\t", "mean", "\t", "stdev", "\n";

	#print each line of data
	foreach my $pop1( sort keys %$hohoaref ){
		foreach my $pop2( sort keys %{$$hohoaref{$pop1}} ){
			my $n = $$hohoaref{$pop1}{$pop2}{'n'};
			my $mean = sprintf("%.4f", $$hohoaref{$pop1}{$pop2}{'mean'});
			my $stdev = sprintf("%.4f", $$hohoaref{$pop1}{$pop2}{'stdev'});
			print OUT $pop1, "\t", $pop2, "\t", $n, "\t", $mean, "\t", $stdev, "\n";
		}
	} 

	close OUT;

}

#####################################################################################################

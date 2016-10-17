#!/usr/bin/perl

#check the final files for basic correctness

use File::Basename;

$inputdir = $ARGV[0];
$outputdir = $ARGV[1];

@files = <$inputdir/*.tsv>;
foreach $file (@files) {
  $inputfile = $file;

  open( FILE, "< $inputfile" ) or die "Can't open $inputfile : $!";
  print "processing input file $inputfile\n";

  while( <FILE> ) {
  
    @fields = split(/\t/);
    $line = join('	', @fields);

  	if ($inputfile =~ m/utsystem_single-part/) {
  		#things to verify:
  			#5 columns
  			#first (OCLC) is not blank
  			#second starts with ut. uta. utd. utep. utmda. utmb. utpan. utsa. utsod. utsph.
  			#third is either CH or WD
  			#fourth is blank or BRT
  			#fifth is 0 or 1

  			$len = @fields;
  			if ($len != 5) { print "incorrect # of fields:" . $line; next; }
  			if ($fields[0] eq '') { print "no OCLC:" . $line; next; }
  			if ($fields[0] !~ m/^(\(OCoLC\))?(ocl7|ocm|ocn|on)?[0-9]+(,(\(OCoLC\))?(ocl7|ocm|ocn|on)?[0-9]+)*$/ )
  			    { print "incorrectly formatted OCLC:" . $line; next; }
  			if ($fields[1] !~ m/^(utsw\.|uta\.|utd\.|utep\.|utmda\.|utmb\.|utrgv\.|utsa\.|utsod\.|utsph\.|ut\.)/ ) {
  				print "invalid local code:" . $line; next; }
  			if ($fields[2] !~ m/^(WD|CH|LM)$/ ) { print "invalid Holding Status: " . $line; next; }
  			if ($fields[3] && $fields[3] ne "BRT") { print "invalid Condition:" . $lin; next; }
  			if ($fields[4] !~ m/^[01]$/ ) {print "invalid govdoc: " . $line; next; } 
  			    #note the \r is because as the last field the 'return' seems to be included in the field

  	} elsif ($inputfile =~ m/utsystem_multi-part/) {
  	  	#things to verify:
  			#6 columns
  			#first (OCLC) is not blank
  			#second starts with ut,uta, utd, utsa, etc.
  			#third is either CH or WD
  			#fourth is blank or BRT
  			#fifth
  			#sixth is 0 or 1

  			$len = @fields;
  			if ($len != 6) { print "incorrect # of fields:" . $line; next; }
  			if ($fields[0] eq '') { print "no OCLC:" . $line; next; }
  			if ($fields[0] !~ m/^(\(OCoLC\))?(ocl7|ocm|ocn|on)?[0-9]+(,(\(OCoLC\))?(ocl7|ocm|ocn|on)?[0-9]+)*$/ )
  			    { print "incorrectly formatted OCLC:" . $line; next; }
  			if ($fields[1] !~ m/^(utsw\.|uta\.|utd\.|utep\.|utmda\.|utmb\.|utrgv\.|utsa\.|utsod\.|utsph\.|ut\.)/ ) {
  				print "invalid local code:" . $line; next; }
  			if ($fields[2] !~ m/^(WD|CH|LM)$/ ) { print "invalid Holding Status: " . $line; next; }
  			if ($fields[3] && $fields[3] ne "BRT") { print "invalid Condition:" . $lin; next; }
  			if ($fields[5] !~ m/^[01]$/ ) {print "invalid govdoc: " . $line; next; }
  			    #note the \r is because as the last field the 'return' seems to be included in the field

  	} elsif ($inputfile =~ m/utsystem_serials/) {
  		#things to verify:
  			#4 columns
  			#first (OCLC) is not blank
  			#second starts with ut,uta, utd, utsa, etc.
  			#third is blank or a list of comma separated ISSNs
  			#fourth is 0 or 1

  			$len = @fields;
  			if ($len != 4) { print "incorrect # of fields:" . $line; next; }
  			if ($fields[0] eq '') { print "no OCLC:" . $line; next; }
  			if ($fields[0] !~ m/^(\(OCoLC\))?(ocl7|ocm|ocn|on)?[0-9]+(,(\(OCoLC\))?(ocl7|ocm|ocn|on)?[0-9]+)*$/ )
  			    { print "incorrectly formatted OCLC:" . $line; next; }
  			if ($fields[1] !~ m/^(utsw\.|uta\.|utd\.|utep\.|utmda\.|utmb\.|utrgv\.|utsa\.|utsod\.|utsph\.|ut\.)/ ) {
  				print "invalid local code:" . $line; next; }
  			if ($fields[2] !~ m/^((\d{4}-\d{3}[\dxX])(,\d{4}-\d{3}[\dxX])*)*$/ ) {
  			    print "invalid ISSN list:" . $line; next; }
  			if ($fields[3] !~ m/^[01]$/ ) {print "invalid govdoc: " . $line; next; }		
  			    #note the \r is because as the last field the 'return' seems to be included in the field

  	}
  
#    $_ =~ s/^\s+//; #remove leading spaces, don't remove trailing since we might have empty fields
#    $_ =~ s/\r$//; #remove trailing CRs
    

  }
  print "done processing inputfile\n";
  close FILE;
} 

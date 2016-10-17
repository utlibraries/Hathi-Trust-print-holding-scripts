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

  $outputfile = $inputdir . "/" . basename($file)."_fixed.tsv";
  open( FILE2, "> $outputfile") or die "Can't open $outputfile : $!";

  while( <FILE> ) {
  
    @fields = split(/\t/);
    $line = join('	', @fields);
    
    if ($fields[0] =~/^OCLC/) { print 'skipping OCLC header line: ' . $line; next; }

    if ($inputfile =~ m/ut_single-part/) {
      #things to verify:
        #5 columns
        #first (OCLC) is not blank
        #second starts with ut., if not pre-pend 'ut.' or error if no value
        #third is either CH or WD - if invalid assume CH
        #fourth is blank or BRT - if invalid assume blank
        #fifth is 0 or 1  - a code of 'f' = govdoc and should be reset to 1, all others reset to 0
        
        $len = @fields;
        if ($len != 5) { print "incorrect # of fields:" . $line; next; }
        if ($fields[0] eq '') { print "DELETED LINE: no OCLC:" . $line; next; }
        if ($fields[1] !~ m/^(ut\.)/ ) { 
            if ($fields[1] eq '') {
                print "DELETED LINE NO LOCAL CODE: invalid local code:" . $line; next; }
            else {
                $fields[1] = 'ut.'.$fields[1];
            }
        }
        if ($fields[2] !~ m/WD|CH|LM/ ) { print "invalid BCode: " . $line; next; }
        if ($fields[3] && $fields[3] ne "BRT") { 
            print "invalid Condition:" . $line; next; }
        if ($fields[4] !~ m/0|1/ ) {
            if ($fields[4] !~ m/f/) { 
                $fields[4] = 0;
            } else { 
                $fields[4] = 1;
            }
        }    
          
    } elsif ($inputfile =~ m/ut_multi-part/) {
        #things to verify:
        #6 columns
        #first (OCLC) is not blank
        #second starts with ut., if not pre-pend 'ut.' or error if no value
        #third is either CH or WD - if invalid, assume CH
        #fourth is blank or BRT - if invalid assume blank
        #fifth
        #sixth is 0 or 1  - a code of 'f' = govdoc and should be reset to 1, all others reset to 0

        $len = @fields;
        if ($len != 6) { print "TRY TO FIX: incorrect # of fields:" . $line; next; }
        if ($fields[0] eq '') { print "DELETED LINE: no OCLC:" . $line; next; }
        if ($fields[1] !~ m/^(ut\.)/ ) { 
            if ($fields[1] eq '') {
                print "DELETED LINE NO LOCAL CODE: invalid local code:" . $line; next; }
            else {
                $fields[1] = 'ut.'.$fields[1];
            }
        }
        if ($fields[2] !~ m/WD|CH|LM/ ) { $fields[2] = 'CH'; }
        if ($fields[3] && $fields[3] ne "BRT") { $fields[3] = ''; }
        if ($fields[5] !~ m/0|1/ ) {
            if ($fields[5] !~ m/f/) { 
                $fields[5] = 0;
            } else { 
                $fields[5] = 1;
            }
        }    
        
    } elsif ($inputfile =~ m/ut_serials/) {
      #things to verify/modify:
        #4 columns
        #first (OCLC) is not blank
        #second starts with ut., if not pre-pend 'ut.' or error if no value
        #third
        #fourth is 0 or 1  - a code of 'f' = govdoc and should be reset to 1, all others reset to 0

        $len = @fields;
        if ($len != 4) { print "TRY TO FIX: incorrect # of fields:" . $line; next; }
        if ($fields[0] eq '') { print "DELETED LINE: no OCLC:" . $line; next; }
        if ($fields[1] !~ m/^(ut\.)/ ) { 
            if ($fields[1] eq '') {
                print "DELETED LINE NO LOCAL CODE: invalid local code:" . $line; next; }
            else {
                $fields[1] = 'ut.'.$fields[1];
            }
        }
        if ($fields[3] !~ m/0|1/ ) {
            if ($fields[3] !~ m/f/) { 
                $fields[3] = 0;
            } else { 
                $fields[3] = 1;
            }
        }    

    }
    $line = join('	', @fields);
    print FILE2 "$line"."
";

#    $_ =~ s/^\s+//; #remove leading spaces, don't remove trailing since we might have empty fields
#    $_ =~ s/\r$//; #remove trailing CRs
    

  }
  print "done processing inputfile\n";
  print "processed output file $outputfile\n";
  close FILE2;
  close FILE;
} 

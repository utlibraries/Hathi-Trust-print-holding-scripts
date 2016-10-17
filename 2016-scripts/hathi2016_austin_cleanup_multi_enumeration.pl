#!/usr/bin/perl

#collapse all the enumeration data from multiple fields into one field
#you need to run this before austin_cleanup script
#you will need to replace all the double linebreaks with single linebreaks after the script, not sure why its happening
#to make it look nicer, you will probably want to cleanup the extra commas, but not strictly neccessary
use File::Basename;

$inputdir = $ARGV[0];

@files = <$inputdir/*.tsv>;
foreach $file (@files) {
  $inputfile = $file;

  open( FILE, "< $inputfile" ) or die "Can't open $inputfile : $!";
  print "processing input file $inputfile\n";

  $outputfile = $inputdir . "/" . basename($file)."_volfixed.tsv";
  open( FILE2, "> $outputfile") or die "Can't open $outputfile : $!";

  while( <FILE> ) {
  
    @fields = split(/\t/);
    $line = join('	', @fields);

    #things to verify:
    #6 columns
    #first (OCLC) is not blank
    #second starts with ut., if not pre-pend 'ut.' or error if no value
    #third is either CH or WD - if invalid, assume CH
    #fourth is blank or BRT - if invalid assume blank
    #fifth is the optional enumeration information
    #sixth is 0 or 1  - a code of 'f' = govdoc and should be reset to 1, all others reset to 0
    
    
    $len = @fields;
    $startenum = 4;
    $endenum = $len-2; # last field ($len-1) is govdoc, everything between 5 and ($len-2) is enumeration info
    
    $newfields[0] = $fields[0];
    $newfields[1] = $fields[1];
    $newfields[2] = $fields[2];
    $newfields[3] = $fields[3];
    
    if ($startenum == $endenum) { # there is only one enumeration field
        $newfields[4] = $fields[4];
    } elsif ($startenum > $endenum) {
        print "ERROR: fewer than 6 fields: " . $line; next;
    } else { # multiple enumeration fields we need to combine
        $newfields[4] = $fields[4];
        for ($i = $startenum+1; $i <= $endenum; $i++) {
            $newfields[4] = $newfields[4] . ',' . $fields[$i];
        }
    }
    
    $newfields[5] = $fields[$len-1];
    
    $line = join('	', @newfields);
    print FILE2 "$line"."
";
    
#     $len = @fields;
#     if ($len != 6) { print "TRY TO FIX: incorrect # of fields:" . $line; next; }
#     if ($fields[0] eq '') { print "DELETED LINE: no OCLC:" . $line; next; }
#     if ($fields[1] !~ m/^(ut\.)/ ) { 
#         if ($fields[1] eq '') {
#             print "DELETED LINE NO LOCAL CODE: invalid local code:" . $line; next; }
#         else {
#             $fields[1] = 'ut.'.$fields[1];
#         }
#     }
#     if ($fields[2] !~ m/WD|CH|LM/ ) { $fields[2] = 'CH'; }
#     if ($fields[3] && $fields[3] ne "BRT") { $fields[3] = ''; }
#     if ($fields[5] !~ m/0|1/ ) {
#         if ($fields[5] !~ m/f/) { 
#             $fields[5] = 0;
#         } else { 
#             $fields[5] = 1;
#         }
#     }    
#     
#     $line = join('	', @fields);
#     print FILE2 "$line"."
# ";


  }
  print "done processing inputfile\n";
  print "processed output file $outputfile\n";
  close FILE2;
  close FILE;
} 

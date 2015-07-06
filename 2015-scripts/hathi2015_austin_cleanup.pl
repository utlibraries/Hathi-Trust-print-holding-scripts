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
    #UT Austin 2015 multi-part data header does not start with 'OCLC' so need to check another field
    if ($fields[1] =~/^RECORD/) { print 'skipping RECORD header line: ' . $line; next; }

    if ($inputfile =~ m/utaustin_single-part/) {
      #things to verify:
        #5 columns
        #first OCLC# is not blank, formatted correctly, multiple values comma separated, skip if no value or invalid
        #second local id that starts with ut., if not pre-pend 'ut.', skip if no value
        #third is 'holding status' either CH or WD - if invalid assume CH
        #fourth is 'condition' blank or BRT - if invalid assume blank
        #fifth is 'gov doc' 0 or 1  - a code of 'f' = govdoc and should be set to 1, all others reset to 0
        
        @newfields = ('','','','','');

        $len = @fields;
        #UT Austin 2015 single-part data is missing a field so we only have 4 fields in input
#         if ($len != 5) { 
        if ($len != 4) {
        	print "ERROR: incorrect # of fields:" . $line; next; 
        }
        #strip trailing whitespace
        $fields[0] =~ s/\s+$//;
        if ($fields[0] eq '') {
            print "DELETED LINE: no OCLC:" . $line; next;
        } elsif ($fields[0] !~ m/(\(OCoLC\))?(ocl7|ocm|ocn|on)?[0-9]+(,(\(OCoLC\))?(ocl7|ocm|ocn|on)?[0-9]+)*/ ) {
            print "ERROR: misformatted OCLC:" . $line; next;
        } else {
            $newfields[0] = $fields[0];
        }
        if ($fields[1] !~ m/^(ut\.)/ ) { 
            if ($fields[1] eq '') {
                print "DELETED LINE NO LOCAL CODE:" . $line; next;
            } else {
                $newfields[1] = 'ut.'.$fields[1];
            }
        } else {
            $newfields[1] = $fields[1];
        }
        if ($fields[2] !~ m/WD|CH|LM/ ) {
            $newfields[2] = 'CH';
        } else {
            $newfields[2] = $fields[2];
        }
        #We don't have condition data so just leave it blank as it was initialized
        #this means remaining fields are shifted down one index
        if ($fields[3] !~ m/0|1/ ) {
            if ($fields[3] !~ m/f/) { 
                $newfields[4] = 0;
            } else { 
                $newfields[4] = 1;
            }
        } else {
            $newfields[4] = $fields[3];
            $newfields[4] =~ s/\s+$//; #for some reason this last field can have trailing returns
        }
    } elsif ($inputfile =~ m/utaustin_multi-part/) {
        #things to verify:
        #6 columns
        #first OCLC# is not blank, formatted correctly, multiple values comma separated, skip if no value or invalid
        #second local id that starts with ut., if not pre-pend 'ut.', skip if no value
        #third is 'holding status' either CH or WD - if invalid assume CH
        #fourth is 'condition' blank or BRT - if invalid assume blank
        #fifth is blank or volume - no format rules but only one volume per line, multiple volumes with same OCLC should be on separate lines
        #sixth is 'gov doc' 0 or 1  - a code of 'f' = govdoc and should be set to 1, all others reset to 0

        @newfields = ('','','','','','');

        $len = @fields;
        #UT Austin 2015 - to get volumes on different lines, OCLC and local id's are tab separated
        #so we can't test correct number of fields.  We need to keep the first OCLC and local id (which
        #always starts with a 'b'.  The number of OCLC's will mean the same number of local id's, holding status' and gov doc codes
        #so only keep the first one. Also, condition is missing
        
        $outputIndex = 0;
        $numOCLC = 0; #need to track since all fields have same number of entries except volume info
    
        for ($i=0; $i < $len; $i++) {
            #print $fields[$i].'\n';
            
            if ($outputIndex == 0) { #first column is all OCLC numbers
                if ($fields[$i] =~ m/^b/) { #start of UT system numbers
                    $outputIndex = 1;
                    $newfields[1] = 'ut.'.$fields[$i]; #assign UT system number
                    $i += $numOCLC; #skip rest of UT system numbers
                } else { #this is another OCLC number
                    if ($newfields[0]) { #this is an additional OCLC number
                        #skip extra OCLC numbers but DON'T do a 'next;' because we need to update $numOCLC
#                         if ($fields[$i]) { $newfields[0] .= ','.$fields[$i]; } #ignore blank OCLC entries
                    } else { $newfields[0] = $fields[$i]; } #this is the first OCLC number
                    $numOCLC = $i;
                }
                next;
            }

            if ($outputIndex == 1) {
                #skip rest of UT system numbers, only need first
                if ($fields[$i] =~ m/^b/) {
                    #should be skipped
                    next;
                } else { #this is the first BCODE field
                    $outputIndex = 4;
                    if ($fields[$i] eq '-') { $newfields[2]='CH'; }
                    elsif ($fields[$i] eq 'd') { $newfields[2]='WD'; }
                    elsif ($fields[$i] eq 'n') { $newfields[2]='WD'; }
                    else { $newfields[2]= 'CH'; } #error handling if needed
                    $i += $numOCLC; #skip rest of BCODES
                }
                next;
            }
        
            #outputIndex 3 is 'condition' and is always left blank
        
            if ($outputIndex == 4) { #volume info
                $outputIndex = 5;
                $newfields[4] = $fields[$i];
                next;
            }
        
            if ($outputIndex == 5) {
                #first govdocs field
                #print '5';
                if ($fields[$i] eq 'f') { $newfields[5] = '1'; } 
                else { $newfields[5] = '0'; }
                $i += $numOCLC; #skip rest of govdocs fields
            }
        
        }
        if ($newfields[0] eq '') { next;} # if no OCLC numbers then don't add to results

        
#########
#        if ($len != 6) { print "TRY TO FIX: incorrect # of fields:" . $line; next; }
#        #strip trailing whitespace
#         $fields[0] =~ s/\s+$//;
#         if ($fields[0] eq '') {
#             print "DELETED LINE: no OCLC:" . $line; next;
#         } elsif ($fields[0] !~ m/(\(OCoLC\))?(ocl7|ocm|ocn|on)?[0-9]+(,(\(OCoLC\))?(ocl7|ocm|ocn|on)?[0-9]+)*/ ) {
#             print "ERROR: misformatted OCLC:" . $line; next;
#         } else {
#             $newfields[0] = $fields[0];
#         }
#         if ($fields[1] !~ m/^(ut\.)/ ) { 
#             if ($fields[1] eq '') {
#                 print "DELETED LINE NO LOCAL CODE:" . $line; next;
#             } else {
#                 $newfields[1] = 'ut.'.$fields[1];
#             }
#         } else {
#             $newfields[1] = $fields[1];
#         }
#         if ($fields[2] !~ m/WD|CH|LM/ ) {
#             $newfields[2] = 'CH';
#         } else {
#             $newfields[2] = $fields[2];
#         }
#         #We don't have condition data so just leave it blank as it was initialized
# 
#         #UT Austin 2015 data volume info is spread across multiple fields so all fields from 'holding status' to 'gov doc' are volumes
#         #starting with $field[3] and ending with the 2nd to last element of the array
#         my @vols = ();
#         for (my $i=3; $i <= ($len - 2); $i++) {
#             push @vols, $fields[$i];
#         }
#         $newfields[4] = join(',',@vols);
#         
#         #gov field is last field
#         $govField = $len - 1;
#         if ($fields[$govField] !~ m/0|1/ ) {
#             if ($fields[$govField] !~ m/f/) { 
#                 $newfields[5] = 0;
#             } else { 
#                 $newfields[5] = 1;
#             }
#         } else {
#             $newfields[5] = $fields[$govField];
#             $newfields[5] =~ s/\s+$//; #for some reason this last field can have trailing returns
#         }
    } elsif ($inputfile =~ m/utaustin_serials/) {
      #things to verify/modify:
        #4 columns
        #first OCLC# is not blank, formatted correctly, multiple values comma separated, skip if no value or invalid
        #second local id that starts with ut., if not pre-pend 'ut.', skip if no value
        #third is blank or list of ISSNs, comma separated
        #fourth is 'gov doc' 0 or 1  - a code of 'f' = govdoc and should be set to 1, all others reset to 0

        @newfields = ('','','','');
        
        $len = @fields;
        #UT Austin 2015 data had an extra field (between second and third) so can't check # of fields
#         if ($len != 4) {
#             print "ERROR: incorrect # of fields:" . $line; next;
#         }
        #strip trailing whitespace
        $fields[0] =~ s/\s+$//;
        if ($fields[0] eq '') {
            print "DELETED LINE: no OCLC:" . $line; next;
        } elsif ($fields[0] !~ m/(\(OCoLC\))?(ocl7|ocm|ocn|on)?[0-9]+(,(\(OCoLC\))?(ocl7|ocm|ocn|on)?[0-9]+)*/ ) {
            print "ERROR: misformatted OCLC:" . $line; next;
        } else {
            $newfields[0] = $fields[0];
        }
        if ($fields[1] !~ m/^(ut\.)/ ) { 
            if ($fields[1] eq '') {
                print "DELETED LINE NO LOCAL CODE:" . $line; next;
            } else {
                $newfields[1] = 'ut.'.$fields[1];
            }
        } else {
            $newfields[1] = $fields[1];
        }
        #UT Austin 2015 data has an extra blank field between second and third fields so need to skip $fields[2]
        #and shift the $fields index for the last two fields
        #UT Austin 2015 data has ISSN's space separated instead of comma separated
        if ($fields[3] ne '') {
            @issns = split(/\s/, $fields[3]);
            $newfields[2] = join(',', @issns);
        }
        if ($fields[4] !~ m/0|1/ ) {
            if ($fields[4] !~ m/f/) { 
                $newfields[3] = 0;
            } else { 
                $newfields[3] = 1;
            }
        } else {
            $newfields[3] = $fields[4];
            $newfields[3] =~ s/\s+$//; #for some reason this last field can have trailing returns
        }
    }
    $line = join('	', @newfields);
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

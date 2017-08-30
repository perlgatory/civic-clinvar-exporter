#!/usr/bin/perl

#for now, only do canonical mutations like AA##AA.
#get a list of those from the variant summary file.
#find the variant in the Clinical Summary File and pull the relevant info for ClinVar.
#two files are needed, the variant summary and the clinical summary

use Getopt::Long;
&GetOptions('varsum=s','clinsum=s', 'notused=s');
$varsum = $opt_varsum; $clinsum = $opt_clinsum; $notused = $opt_notused;

#print "this is varsum $varsum and this is clinsum $clinsum\n";
open NOUSE, '>', $notused or die "cannot find file $notused";
open my $varf, '<', $varsum or die "cannot find file $varsum\n";
open my $clinf, '<', $clinsum or die "cannot find file $clinsum\n";

$header = `cat header2.txt`;
print "$header\n";

while (my $line = <$varf>){
  chomp $line;
  @entry = split (/\t/,$line);
  $genev = $entry[2];
  $varv = $entry[4];
  $hgvs = $entry[20];
  $nhgvs = "";
  $genecode = "";
  $varcode = "";
  if ($varv =~ /^[A-Z]\d+[A-Z]$/){ #the variant matches a canonical format. Print out all others to a "not used file" 
    if ($hgvs =~ /^\s*$/){ #the variant does NOT have HGVS
      my @lines = ();
      @lines = `awk '\$1=="$genev" && \$3=="$varv" {print}' $clinsum`; #get the lines and only those lines with chr,start,stop,ref,var because there is no HGVS.
      foreach my $item (@lines){
#	print "THIS IS AN ITEM $item\n";
	chomp $item;
	my @fields = split (/\t/,$item);
	my $dots = "";
	my $genec = $fields[0];
	my $varc = $fields[2];
	my $disease = $fields[3];
	my $doid = $fields[4];
	my $drug = $fields[5];
	my $evtype = $fields[6];
	my $pmid = $fields[11];
	my $comment = $fields[10];
	my $evid = $fields[15];
	my $chr = $fields[18];
	my $start = $fields[19];
	my $stop = $fields[20];
	my $ref = $fields[21];
	my $var = $fields[22];
	#print "THIS IS REF $ref and VAR $var\n";
	my $origin = $fields[31];
	my $drugOther = "$fields[5]" . "_" . "$fields[7]" . "_" . "$fields[9]"; #clinvar AR
	my $ontology = "DiseaseOntology";
	my $assertionMethod = "CIVIC -- Clinical Interpretations of Variants in Cancer";
	my $assertionCitation = "https://civic.genome.wustl.edu/#/help/introduction";
	my $citation = "PMID:" . "$pmid";
	my $CommentClinSig = $fields[10];
	my $collectionMethod = "literature only";
	my $affectedStatus = "unknown";

	if (($chr =~ /^\s*$/) || ($start =~ /^\s*$/) || ($stop =~ /^\s*$/) || ($ref =~ /^\s*$/) || ($var =~ /^\s*$/)){ #if the variant does not have chr, start, stop, ref, var, and does not have HGVS then it cannot be used for a clinvar entry. Print out to a not used file. 
	  print NOUSE "$item\n";
	  next;
	}else{ #the variant has no hgvs but has something in chr, start, stop, ref, var
#print "THIS CAN BE USED $item\n";
	  #print "THISISITEM\t$item\n";
	  $ConditionCategory = ""; #field AF in ClinVar
	  $ClinicalSig = "";
	  if (($evtype =~ m/Predictive/) && ($drug !~ /^\s*$/)){
	    $ConditionCategory = "DrugResponse";
	    $ClinicalSig = "drug response";
	  }elsif (($evtype =~ m/Prognostic/) || ($evtype =~ m/Diagnostic/)){
	    $ConditionCategory = "Finding";
	    $ClinicalSig = "other";
	  }elsif ($evtype =~ /Predisposing/){
	    $ConditionCategory = "Disease";
	    $ClinicalSig = "risk factor";
	  }
	  #print "$genec\t$varc\t$chr\t$start\t$stop\t$ref\t$var\n";
###########DO SOMETHING HERE####################
	  for (my $i = 1; $i<=18; $i++){
	    $dots .= ".\t";
	  }
	  chop $dots;
	  $clinvarline = "$evid\t$evid\t$genec\t.\t.\t$chr\t$start\t$stop\t$ref\t$var\t$dots\t$ontology\t$doid\t$disease\t$ConditionCategory\t.\t.\t.\t$ClinicalSig\t.\t$assertionMethod\t$assertionCitation\t.\t$citation\t.\t$CommentClinSig\t$drugOther\t.\t.\t.\t.\t$collectionMethod\t$origin\t$affectedStatus";
	  print "$clinvarline\n";
	}
      }
	
    }else {  #if there is an HGVS term then use it.
      ##Get the refseq or ENST and the c. variant##
      my @holder = split (/\,/, $hgvs);
      my $genecode = "";
      my $varcode = "";
      foreach my $item (@holder){
	if ($item =~ /NM\_/){
	  $nhgvs = $item;
	  ($genecode,$varcode) = $item =~ /(\S+):(\S+)/;
	 # print "this is gene code $genecode and $varcode \n";
	}
      }
      if ($nhgvs eq ""){
	foreach my $item (@holder){
	  if ($item =~ /ENST/){
	    $nhgvs = $item;
	    ($genecode,$varcode) = $item =~ /(\S+):(\S+)/;
	#    print "this is gene code $genecode and $varcode \n";
	  }
	}
      }
     
      ##get the lines in the clinical file that match the gene and var
      my @lines = `awk '\$1=="$genev" && \$3=="$varv" {print}' $clinsum`;
      foreach my $item (@lines){
	chomp $item;
	my @fields = split (/\t/,$item);
	my $dots = "";
	my $genec = $fields[0];
	my $varc = $fields[2];
	my $disease = $fields[3];
	my $doid = $fields[4];
	my $drug = $fields[5];
	my $evtype = $fields[6];
	my $pmid = $fields[11];
	my $comment = $fields[10];
	my $evid = $fields[15];
	my $chr = $fields[18];
	my $start = $fields[19];
	my $stop = $fields[20];
	my $ref = $fields[21];
	my $var = $fields[22];
	#print "THIS IS REF $ref and VAR $var\n";
	my $origin = $fields[31];
	my $drugOther = "$fields[5]" . "_" . "$fields[7]" . "_" . "$fields[9]"; #clinvar AR
	my $ontology = "DiseaseOntology";
	my $assertionMethod = "CIVIC -- Clinical Interpretations of Variants in Cancer";
	my $assertionCitation = "https://civic.genome.wustl.edu/#/help/introduction";
	my $citation = "PMID:" . "$pmid";
	my $CommentClinSig = $fields[10];
	my $collectionMethod = "literature only";
	my $affectedStatus = "unknown";
	
	if (($chr =~ /^\s*$/) || ($start =~ /^\s*$/) || ($stop =~ /^\s*$/) || ($ref =~ /^\s*$/) || ($var =~ /^\s*$/)){ #if the variant does not have chr, start, stop, ref, var, and does not have HGVS then it cannot be used for a clinvar entry. Print out to a not used file.
	  print NOUSE "$item\n";
	  next;
	}else{ #the variant has no hgvs but has something in chr, start, stop, ref, var
	  print "THISISITEM\t$item";
	  #print "THIS CAN BE USED $item\n";
	  $ConditionCategory = ""; #field AF in ClinVar
	  $ClinicalSig = "";
	  if (($evtype =~ m/Predictive/) && ($drug !~ /^\s*$/)){
	    $ConditionCategory = "DrugResponse";
	    $ClinicalSig = "drug response";
	  }elsif (($evtype =~ m/Prognostic/) || ($evtype =~ m/Diagnostic/)){
	    $ConditionCategory = "Finding";
	    $ClinicalSig = "other";
	  }elsif ($evtype =~ /Predisposing/){
	    $ConditionCategory = "Disease";
	    $ClinicalSig = "risk factor";
	  }
	  #print "$genec\t$varc\t$chr\t$start\t$stop\t$ref\t$var\n";
	  ###########DO SOMETHING HERE####################
	  for (my $i = 1; $i<=18; $i++){
	    $dots .= ".\t";
	  }
	  chop $dots;
	  $clinvarline = "$evid\t$evid\t$genec\t$genecode\t$varcode\t$chr\t$start\t$stop\t$ref\t$var\t$dots\t$ontology\t$doid\t$disease\t$ConditionCategory\t.\t.\t.\t$ClinicalSig\t.\t$assertionMethod\t$assertionCitation\t.\t$citation\t.\t$CommentClinSig\t$drugOther\t.\t.\t.\t.\t$collectionMethod\t$origin\t$affectedStatus";
	  print "$clinvarline\n";
	}
      }
      
#############do the same thing here################
      

      
    }
  }else{ #these variants are not canonical and cannot be used right now in ClinVar 
    print NOUSE "$line\n";
  }
  
}

#
# BioPerl module for Bio::EnsEMBL::DBSQL::ProteinAlignFeatureAdaptor
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::DBSQL::ProteinAlignFeatureAdaptor - 
Adaptor for ProteinAlignFeatures

=head1 SYNOPSIS

    $pfadp = $dbadaptor->get_ProteinAlignFeatureAdaptor();

    my @features = $pfadp->fetch_by_Contig($contig);

    my @features = $pfadp->fetch_by_assembly_location($start,$end,$chr,'UCSC');
 
    $pfadp->store(@features);


=head1 DESCRIPTION


This is an adaptor for protein features on DNA sequence. Like other
feature getting adaptors it has a number of fetch_ functions and a
store function.


=head1 AUTHOR - Ewan Birney

Email birney@ebi.ac.uk

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. 
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::EnsEMBL::DBSQL::ProteinAlignFeatureAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::EnsEMBL::Root

use Bio::EnsEMBL::DBSQL::BaseAlignFeatureAdaptor;
use Bio::EnsEMBL::PepDnaAlignFeature;
use Bio::EnsEMBL::SeqFeature;
@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAlignFeatureAdaptor);


=head2 store

  Arg [1]    : list of Bio::EnsEMBL::DnaPepAlignFeature @sf
  Example    : $protein_align_feature_adaptor->store(@sf);
  Description: stores a list of features in the database
  Returntype : none
  Exceptions : thrown if there is no attached sequence on any of the features,
               if the features are not defined
  Caller     : 

=cut


sub store{
   my ($self ,@sf) = @_;

   if( scalar(@sf) == 0 ) {
       $self->throw("Must call store with list of sequence features");
   }

   my $sth = $self->prepare(
	"INSERT INTO protein_align_feature(contig_id, contig_start, contig_end,
                                           contig_strand, hit_start, hit_end,
                                           hit_name, cigar_line, analysis_id,
                                           score, evalue, perc_ident) 
         VALUES (?,?,?,?,?,?,?,?,?,?, ?, ?)");

   foreach my $sf ( @sf ) {
     if( !ref $sf || !$sf->isa("Bio::EnsEMBL::DnaPepAlignFeature") ) {
       $self->throw("Feature must be a Bio::EnsEMBL::DnaPepAlignFeature, " .
		    "not a [$sf]");
     }
     
     if( !defined $sf->analysis ) {
       $self->throw("Cannot store sequence features without analysis");
     }
     if( !defined $sf->analysis->dbID ) {
       # maybe we should throw here. Shouldn't we always have an 
       # analysis from the database?
       $self->throw("I think we should always have an analysis object " .
		    "which has originated from the database. No dbID, " .
		    "not putting in!");
     }

     my $contig = $sf->entire_seq();
     #print STDERR $contig."\n";
     unless(defined $contig && $contig->isa("Bio::EnsEMBL::RawContig")) { 
       $self->throw("Cannot store feature without Contig attached via " .
		    "attach_seq\n");
     }   
     
     $sth->execute($contig->dbID(), $sf->start, $sf->end,
		   $sf->strand, $sf->hstart, $sf->hend,
		   $sf->hseqname, $sf->cigar_string, $sf->analysis->dbID,
		   $sf->score, $sf->p_value, $sf->percent_id);
     
     $sf->dbID($sth->{'mysql_insertid'});
   }
 }


=head2 _objs_from_sth

  Arg [1]    : DBI statement handle $sth
               an exectuted DBI statement handle generated by selecting 
               the columns specified by _columns() from the table specified 
               by _table()
  Example    : @dna_dna_align_feats = $self->_obj_from_hashref
  Description: PROTECTED implementation of superclass abstract method. 
               Creates DnaDnaAlignFeature objects from a DBI hashref
  Returntype : listref of Bio::EnsEMBL::ProteinAlignFeatures
  Exceptions : none
  Caller     : Bio::EnsEMBL::BaseFeatureAdaptor::generic_fetch

=cut

sub _objs_from_sth {
  my ($self, $sth, $mapper, $slice) = @_;

  my ($protein_align_feature_id, $contig_id, $contig_start, $contig_end,
      $analysis_id, $contig_strand, $hit_start, $hit_end, $hit_name, 
      $cigar_line, $evalue, $perc_ident, $score);
  
  my $rca = $self->db()->get_RawContigAdaptor();
  my $aa = $self->db()->get_AnalysisAdaptor();
  my @features;

  $sth->bind_columns(\$protein_align_feature_id, \$contig_id, \$contig_start, 
		     \$contig_end, \$analysis_id, \$contig_strand, \$hit_start,
		     \$hit_end, \$hit_name, \$cigar_line, \$evalue, 
		     \$perc_ident, \$score);

  my($analysis, $contig);

  my %a_hash;
  my %c_hash;

  if($slice) {
    $analysis = $a_hash{$analysis_id} ||= $aa->fetch_by_dbID($analysis_id);
       my ($chr, $start, $end, $strand);
    my $slice_start = $slice->chr_start() - 1;
    my $slice_name = $slice->name();
    
    while($sth->fetch()) {
      ($chr, $start, $end, $strand) = 
	$mapper->fast_to_assembly($contig_id, $contig_start, 
				  $contig_end, $contig_strand);
      
      unless(defined $start) {
	next;
      }
      
      #use a very fast (hack) constructor - normal object construction is too
      #slow for the number of features we are potentially dealing with
      push @features, Bio::EnsEMBL::PepDnaAlignFeature->new_fast(
                {'_gsf_tag_hash'  =>  {},
		 '_gsf_sub_array' =>  [],
		 '_parse_h'       =>  {},
		 '_analysis'      =>  $analysis,
		 '_gsf_start'     =>  $start - $slice_start,
		 '_gsf_end'       =>  $end - $slice_start,
		 '_gsf_strand'    =>  $strand,
		 '_gsf_score'     =>  $score,
		 '_seqname'       =>  $slice_name,
		 '_percent_id'    =>  $perc_ident,
		 '_p_value'       =>  $evalue,
                 '_hstart'        =>  $hit_start,
                 '_hend'          =>  $hit_end,
                 '_hseqname'      =>  $hit_name,
		 '_gsf_seq'       =>  $slice,
		 '_cigar_string'  =>  $cigar_line,
		 '_id'            =>  $hit_name,
                 '_database_id'   =>  $protein_align_feature_id});
    }    

  } else {

    while($sth->fetch) {
      $analysis = $a_hash{$analysis_id} ||= $aa->fetch_by_dbID($analysis_id);
      $contig   = $c_hash{$contig_id}   ||= $rca->fetch_by_dbID($contig_id);
      
      #use a very fast (hack) constructor - normal object construction is too
      #slow for the number of features we are potentially dealing with
      push @features, Bio::EnsEMBL::PepDnaAlignFeature->new_fast(
                {'_gsf_tag_hash'  =>  {},
		 '_gsf_sub_array' =>  [],
		 '_parse_h'       =>  {},
		 '_analysis'      =>  $analysis,
		 '_gsf_start'     =>  $contig_start,
		 '_gsf_end'       =>  $contig_end,
		 '_gsf_strand'    =>  $contig_strand,
		 '_gsf_score'     =>  $score,
		 '_seqname'       =>  $contig->name,
		 '_percent_id'    =>  $perc_ident,
		 '_p_value'       =>  $evalue,
                 '_hstart'        =>  $hit_start,
                 '_hend'          =>  $hit_end,
                 '_hseqname'      =>  $hit_name,
		 '_gsf_seq'       =>  $contig,
		 '_cigar_string'  =>  $cigar_line,
		 '_id'            =>  $hit_name,
                 '_database_id'   =>  $protein_align_feature_id});
    }
  }


  return \@features;
}


sub _tablename {
  my $self = shift;

  return "protein_align_feature";
}

sub _columns {
  my $self = shift;

  #warning _objs_from_hashref method depends on ordering of this list 
  return qw( protein_align_feature_id contig_id contig_start contig_end
	     analysis_id contig_strand hit_start hit_end hit_name cigar_line
	     evalue perc_ident score );
}







1;

# EnsEMBL module for Ditags
#
# Copyright EMBL-EBI/Wellcome Trust Sanger Center 2006
#
# You may distribute this module under the same terms as perl itself
#
# Cared for by EnsEMBL (ensembl-dev@ebi.ac.uk)

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::Map::Ditag

=head1 SYNOPSIS

  my $feature = Bio::EnsEMBL::Map::Ditag->new (
                                               -dbID      => $tag_id,
                                               -name      => $name,
                                               -type      => $type,
					       -tag_count => $tag_count,
                                               -sequence  => $sequence,
                                               -adaptor   => $dbAdaptor
                                              );

=head1 DESCRIPTION

Represents an unmapped ditag object in the EnsEMBL database. 
Corresponds to original tag containing the full sequence. This can be a single 
piece of sequence like CAGE tags or a ditag with concatenated sequence from 
5' and 3' end like GIS or GSC tags.

=cut

package Bio::EnsEMBL::Map::Ditag;

use strict;
use Carp;
use base qw(Bio::EnsEMBL::Root);



=head2 new

  Arg [1]    : (optional) int $dbID
  Arg [2]    : (optional) string name
  Arg [3]    : (optional) string type
  Arg [4]    : (optional) int tag_count
  Arg [5]    : (optional) string sequence
  Arg [6]    : (optional) Bio::EnsEMBL::Map::DBSQL::DitagAdaptor $adaptor

  Description: Creates a new ditag
  Returntype : Bio::EnsEMBL::Map::Ditag
  Exceptions : none
  Caller     : general

=cut

sub new {
  my ($caller, @args) = @_;

  my ($dbID, $name, $type, $tag_count, $sequence, $adaptor) = $caller->_rearrange(
      [ 'DBID', 'NAME', 'TYPE', 'TAG_COUNT', 'SEQUENCE', 'ADAPTOR' ], @args);
  my $class = ref($caller) || $caller;

  if(!$name or !$type or !$sequence) {
    confess('Missing information for Ditag object:
              Bio::EnsEMBL::Map::Ditag->new (
                                              -dbID      => $tag_id,
                                              -name      => $name,
                                              -type      => $type,
                                              -tag_count => $tag_count,
                                              -sequence  => $sequence,
                                              -adaptor   => $dbAdaptor
                                             );');
  }

  if(!$tag_count){ $tag_count = 0; }

  if(!($sequence =~ /^[ATCGN]+$/i)){
    confess('ditag sequence contains non-standard characters: '.$sequence);
  }

  my $self = bless( {'dbID'        => $dbID,
                     'name'        => $name,
                     'type'        => $type,
		     'tag_count'   => $tag_count,
		     'sequence'    => $sequence,
                     'adaptor'     => $adaptor,
                    }, $class);

  return $self;
}

=head2 name

  Arg [1]    : (optional) string $type
  Example    : $type = $ditag->name;
  Description: Getter/Setter for the name of a ditag
  Returntype : text
  Caller     : general

=cut

sub name {
  my $self = shift;

  if(@_) {
    $self->{'name'} = shift;
  }

  return $self->{'name'};
}

=head2 dbID

  Arg [1]    : (optional) int id
  Example    : $ditag_id = $ditag->dbID;
  Description: Getter/Setter for the dbID of a ditag
  Returntype : int
  Caller     : general

=cut

sub dbID {
  my $self = shift;

  if(@_) {
    $self->{'dbID'} = shift;
  }

  return $self->{'dbID'};
}


=head2 type

  Arg [1]    : (optional) string $type
  Example    : $type = $ditag->type;
  Description: Getter/Setter for the type of a ditag
  Returntype : text
  Caller     : general

=cut

sub type {
  my $self = shift;

  if(@_) {
    $self->{'type'} = shift;
  }

  return $self->{'type'};
}

=head2 tag_count

  Arg [1]    : (optional) string $tag_count
  Example    : $type = $ditag->tag_count;
  Description: Getter/Setter for the tag_count of a ditag
  Returntype : int
  Caller     : general

=cut

sub tag_count {
  my $self = shift;

  if(@_) {
    $self->{'tag_count'} = shift;
  }

  return $self->{'tag_count'};
}

=head2 sequence

  Arg [1]    : (optional) string $sequence
  Example    : $sequence = $ditag->sequence;
  Description: Getter/Setter for the sequence of a ditag
  Returntype : text
  Caller     : general

=cut

sub sequence {
  my $self = shift;

  if(@_) {
    $self->{'sequence'} = shift;
  }

  return $self->{'sequence'};
}


=head2 get_ditagFeatures

  Arg        : none
  Example    : @features = @{$ditag->get_ditagFeatures};
  Description: Fetch ditag_features created from this ditag
  Returntype : listref of Bio::EnsEMBL::Map::DitagFeature
  Caller     : general

=cut

sub get_ditagFeatures {
  my $self = shift;

  return $self->adaptor->db->get_adaptor("ditagFeature")
          ->fetch_all_by_ditagID($self->dbID);
}

1;

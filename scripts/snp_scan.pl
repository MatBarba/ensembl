use strict;
use Bio::EnsEMBL::DBSQL::Obj;
use Bio::EnsEMBL::ExternalData::SNPSQL::DBAdapter;
use IO::Handle;


my $min=shift @ARGV;
my $max=shift @ARGV;


my $dbuser= 'ensro';
my $host='ensrv4.sanger.ac.uk';
my $ensembldb = new Bio::EnsEMBL::DBSQL::Obj( -user =>$dbuser, 
					    -dbname => 'ensembl_freeze17_michele',
					    -host=>$host);

my $host='ecs1b.sanger.ac.uk';
my $snpdb = Bio::EnsEMBL::ExternalData::SNPSQL::DBAdapter->new( -dbname=>'snp', 
						       -user=>'ensadmin',  
						       -host=>$host);

$ensembldb->add_ExternalFeatureFactory($snpdb);
$ensembldb->static_golden_path_type('UCSC');

my $stadaptor = $ensembldb->get_StaticGoldenPathAdaptor();
my $contig=$stadaptor->fetch_VirtualContig_by_chr_name('chr22');



my %features;
foreach my $snp ($contig->get_all_ExternalFeatures) {	 
    #print STDERR "Got snp ".$snp->id."\n";
    #print STDERR "  start: ".$snp->start."\n";
    #print STDERR "    end: ".$snp->end."\n";
    my $start=$snp->start;
    my $end=$snp->end;
    $start-=100;
    $end+=100;
    my $subseq=$contig->primary_seq->subseq($start,$end);
    print ">SNP: ".$snp->id." START:$start END: $end\n";
    print $subseq."\n";
#    $features{$feature->id}=$feature->start;
}



#my @sorted=sort {$features{$a}<=>$features{$b}} keys %features;

#my $last_feature;
#foreach my $snp (@sorted){
#    print STDERR "Got $snp ".$snp->id."\n";
#    print STDERR "  start: ".$snp->start."\n";
#    print STDERR "    end: ".$snp->end."\n";
#}








      

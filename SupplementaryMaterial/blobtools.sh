#!/bin/sh
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --mem=10G
#SBATCH -p cl-intel-shared
#SBATCH --qos=cl-intel-shared
#SBATCH --mail-type=END
#SBATCH --mail-user=gimartinezredondo@gmail.com
#SBATCH -o slurm.%j.out
#SBATCH -e slurm.%j.err
#SBATCH --time=0-2:0

#Load modules

module load ??

#Variables with path and species code
WORKSPACE=
SPECIES=

#Make Blobtools directory
mkdir -p $WORKSPACE/BLOBTOOLS/BlobDir

#Create blobotools database

blobtools create\
	--fasta $WORKSPACE/${SPECIES}.cds \
	--taxid $TAXID \
	--hits $WORKSPACE/${SPECIES}.diamond.blastp.out \
	--hits-cols 1=qseqid,2=staxids,3=bitscore,5=sseqid,10=sstart,11=send,14=evalue\
	--taxrule bestsum \
	--taxdump $BLOBTOOLS/taxdump \
	$WORKSPACE/BLOBTOOLS/BlobDir

#Obtain list of contaminants

python /mnt/netapp2/Store_csbye/scripts/extract_phyla_for_blobtools.py $WORKSPACE/BLOBTOOLS/BlobDir/bestsum_phylum.json | sed "s/', '/,/g" | tr -d "[]'" > $WORKSPACE/BLOBTOOLS/contaminants.txt

PHYLA=$(cat $WORKSPACE/$SPECIES/BLOBTOOLS/contaminants.txt)

#Filter cds and protein file
#Filter cds file
blobtools filter \
     --param bestsum_phylum--Keys="$PHYLA"\
     --taxrule bestsum\
     --fasta $WORKSPACE/${SPECIES}.cds \
     --summary STDOUT\
     --summary-rank kingdom\
     $WORKSPACE/BLOBTOOLS/BlobDir >$WORKSPACE/BLOBTOOLS/${SPECIES}_blobtools.summary

#Filter pep file
blobtools filter \
     --param bestsum_phylum--Keys="$PHYLA"\
     --taxrule bestsum\
     --fasta $WORKSPACE/${SPECIES}.fasta \
     $WORKSPACE/BLOBTOOLS/BlobDir

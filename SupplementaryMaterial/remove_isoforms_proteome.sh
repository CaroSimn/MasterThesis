#!usr/bin/bash

WORKSPACE=/home/metazomics/Desktop/Arthropods_transcriptomes/
SPECIES=ACRA1

#Remove isoforms from downloaded proteomes
#Obtain CDS from gff file and fuse the ones that have the same protein id (come from different mRNAs)
grep -vE "^#" ${SPECIES}.gff \
| awk 'BEGIN{FS="\t"} {if($3=="CDS") {print $9}}' \
| sed 's/ID=cds-\([^\;]*\)\;*.*GeneID:\([0-9]*\).*/\1 \2/g' \
| sort | uniq > ${SPECIES}_geneprot.txt

#Check that number of proteins is correct
if [[ $(wc -l ${SPECIES}_geneprot.txt | cut -d" " -f1) != $(grep -c ">" ${SPECIES}.fasta) ]]
then
	echo "Number of proteins differs between annotation and proteome file"
	exit
fi

#Important! Both files must have genes in the same order.
cut -d" " -f1 ${SPECIES}_geneprot.txt > order_${SPECIES}_geneprot.txt
grep ">" ${SPECIES}.fasta | cut -d" " -f1 | cut -d">" -f2 > order_${SPECIES}.fasta
if [[ $(diff order_${SPECIES}_geneprot.txt order_${SPECIES}.fasta) != "" ]]
then
	echo "Proteins in the proteome file are not sorted"
	exit
fi
rm {order_${SPECIES}_geneprot.txt,order_${SPECIES}.fasta}

#Save original headers
grep ">" $WORKSPACE/$SPECIES/${SPECIES}.fasta >$WORKSPACE/$SPECIES/${SPECIES}_orig_headers.txt

#Execute python script for changing headers to Trinity-style headers
python $WORKSPACE/Scripts/trinity_header_proteome.py -i $WORKSPACE/$SPECIES/${SPECIES}_geneprot.txt -o $WORKSPACE/$SPECIES/${SPECIES}_headers.txt -s $SPECIES

#Change headers with the new ones
< ${SPECIES}_headers.txt  perl -pe '$_ = <STDIN> if /^>/' ${SPECIES}.fasta >${SPECIES}.mod.fasta

#Save new and old headers into a conversion file for further use
paste $WORKSPACE/$SPECIES/${SPECIES}_orig_headers.txt $WORKSPACE/$SPECIES/${SPECIES}_headers.txt > $WORKSPACE/$SPECIES/${SPECIES}_conversion.txt
rm {$WORKSPACE/$SPECIES/${SPECIES}_headers.txt,$WORKSPACE/$SPECIES/${SPECIES}_orig_headers.txt}

#Remove isoforms as usual
python $WORKSPACE/Scripts/fetch_longest_iso.py -i $WORKSPACE/$SPECIES/${SPECIES}.mod.fasta -o $WORKSPACE/$SPECIES/${SPECIES}.filtered.fasta -t -l

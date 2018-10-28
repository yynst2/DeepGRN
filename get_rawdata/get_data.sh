DATAPATH=/storage/htc/bdm/ccm3x/deepGRN/raw/

module load python/python-2.7.12
module load samtools
module load atlas/atlas-3.10.2
module load bedtools/bedtools-2.26.0

pip install numpy pandas h5py theano==0.9.0
pip install pybedtools pyfasta pyBigWig parmap keras==1.2.2 deeptools==2.5.4


mkdir -p $DATAPATHbams
mkdir -p $DATAPATHDNase
mkdir -p $DATAPATHchipseq
mkdir -p $DATAPATHgencode
mkdir -p $DATAPATHlabel/train
mkdir -p $DATAPATHlabel/train_positive
mkdir -p $DATAPATHlabel/train_negative
mkdir -p $DATAPATHlabel/final

# get gencode data
cd $DATAPATHgencode
wget https://github.com/uci-cbcl/FactorNet/raw/master/resources/wgEncodeGencodeBasicV19.cds.merged.bed.gz
wget https://github.com/uci-cbcl/FactorNet/raw/master/resources/wgEncodeGencodeBasicV19.intron.merged.bed.gz
wget https://github.com/uci-cbcl/FactorNet/raw/master/resources/wgEncodeGencodeBasicV19.promoter.merged.bed.gz
wget https://github.com/uci-cbcl/FactorNet/raw/master/resources/wgEncodeGencodeBasicV19.txStart.bed.gz
wget https://github.com/uci-cbcl/FactorNet/raw/master/resources/wgEncodeGencodeBasicV19.utr3.merged.bed.gz
wget https://github.com/uci-cbcl/FactorNet/raw/master/resources/wgEncodeGencodeBasicV19.utr5.merged.bed.gz


# get data from synapse
cd $DATAPATH../src
python get_syn_data.py $DATAPATH

# get bed file for prediction(contains chr1,21,8 only)
cd $DATAPATHlabel/
gzip -d *.gz
awk '$1 == "chr1" {print}' test_regions.blacklistfiltered.bed > predict_region.bed
awk '$1 == "chr21" {print}' test_regions.blacklistfiltered.bed >> predict_region.bed
awk '$1 == "chr8" {print}' test_regions.blacklistfiltered.bed >> predict_region.bed

cd $DATAPATH
wget https://github.com/uci-cbcl/FactorNet/raw/master/resources/blacklist.bed.gz
wget https://raw.githubusercontent.com/uci-cbcl/FactorNet/master/resources/hg19.autoX.chrom.sizes
# get unique 35 data
wget http://hgdownload.cse.ucsc.edu/goldenpath/hg19/encodeDCC/wgEncodeMapability/wgEncodeDukeMapabilityUniqueness35bp.bigWig
wget http://hgdownload.cse.ucsc.edu/goldenpath/hg19/encodeDCC/wgEncodeMapability/wgEncodeDacMapabilityConsensusExcludable.bed.gz

# generate 2 missing bigwig files(A549 and IMR-90) from bams
cd $DATAPATHbams
samtools merge A549.bam DNASE.A549.*
samtools index A549.bam
bamCoverage --bam A549.bam -o ../DNase/A549.1x.bw --outFileFormat bigwig --normalizeTo1x 2478297382 --ignoreForNormalization chrX chrM --Offset 1 --binSize 1 --numberOfProcessors 12 --skipNonCoveredRegions --blackListFileName ../wgEncodeDacMapabilityConsensusExcludable.bed.gz

samtools merge IMR-90.bam DNASE.IMR90.*
samtools index IMR-90.bam 
bamCoverage --bam IMR-90.bam -o ../DNase/IMR-90.1x.bw --outFileFormat bigwig --normalizeTo1x 2478297382 --ignoreForNormalization chrX chrM --Offset 1 --binSize 1 --numberOfProcessors 12 --skipNonCoveredRegions --blackListFileName ../wgEncodeDacMapabilityConsensusExcludable.bed.gz

#generating labels and non_blacklist_bools.csv

cd $DATAPATH../src
python get_blacklist_bool.py
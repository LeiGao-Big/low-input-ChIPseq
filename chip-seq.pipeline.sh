#!/bin/sh

trim=/home/gaolei/software/Trimmomatic-0.36/trimmomatic-0.36.jar
adapter_pe=/home/gaolei/software/Trimmomatic-0.36/adapters/TruSeq3-PE.fa
adapter_se=/home/gaolei/software/Trimmomatic-0.36/adapters/TruSeq3-SE.fa
indexSP64=/media/gaolei/Tools/reference_genome/pSP64_index/pSP64
index_hg19=/media/gaolei/Tools/reference_genome/human/hg19/human.hg19.chrall
index_mm10=/media/gaolei/Tools/reference_genome/mouse/mm10/mouse.mm10.chrall
index_mm10_bt1=/media/gaolei/Tools/reference_genome/mouse/mm10/mouse.mm10.chrall
picard=/home/gaolei/software/picard-2.9.0/picard.jar

dir=/home/gaolei/project/ChIP-seq/humanEmbryo
ppn=7
for sample in HB1NPR1
do
cd ${dir}/${sample}

###Trim (check trim and adapter path!!!)
java -jar $trim PE ${sample}*_1.fq.gz ${sample}*_2.fq.gz $sample\_1p.fq.gz $sample\_1q.fq.gz $sample\_2p.fq.gz $sample\_2q.fq.gz TOPHRED33 CROP:100 ILLUMINACLIP:$adapter:2:30:10 LEADING:5 TRAILING:5 SLIDINGWINDOW:4:20 MINLEN:36 2> ${sample}.log.txt

###Mapping (check index path!!!)
bowtie2 -p $ppn -x $index_hg19 --no-mixed -X 2000 --no-discordant -1 $sample\_1p.fq.gz -2 $sample\_2p.fq.gz -S $sample.pe100.sam 2>> ${sample}.log.txt

if [ $? -eq 0 ]; then
rm $sample\_1p.fq.gz $sample\_1q.fq.gz $sample\_2p.fq.gz $sample\_2q.fq.gz
fi

###convert to sorted bam
samtools view -F 4 -q 10 -@ $ppn -bS $sample.pe100.sam -o $sample.pe100.bam
if [ $? -eq 0]; then
rm $sample.pe100.sam
fi

samtools sort -@ $ppn $sample.pe100.bam  -o $sample.pe100.sorted.bam

###remove duplication (check picard path!!!)
java -jar $picard MarkDuplicates REMOVE_DUPLICATES=true I=$sample.pe100.sorted.bam O=$sample.pe100.rmdup.bam M=$sample.pe100.rmdup.metrics.txt
done

###call peaks
macs2 callpeak -t $sample.pe100.rmdup.bam -c input.bam -f BAM -g hs -n ${sample} --keep-dup all -B  


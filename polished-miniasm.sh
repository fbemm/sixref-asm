#!/bin/bash

SEQ=$1
PE1=$2
PE2=$3
CPU=$4

ASM=$(basename $SEQ .fastq)

IT0=$BSE"_IT0"
IT1=$BSE"_IT1"
IT2=$BSE"_IT2"
IT3=$BSE"_IT3"
IT4=$BSE"_IT4"

# Assembled Long Reads

minimap -Sw5 -L100 -m0 -t$CPU $$EQ $SEQ > $IT0".paf"
miniasm -f $SEQ $IT0".paf" > $ASM".gfa"

# Extract Sequences from GFA

awk '$1 ~/S/ {print ">"$2"\n"$3}' $ASM > $IT0".fasta"

# Run 1st Racon Iteration

minimap -t$CPU $IT0".fasta" $SEQ > $IT1".paf"
racon $SEQ $IT1".paf" $IT0".fasta" $IT1".fasta"  

# Run 2nd Racon Iteration

minimap -t$CPU $IT1".fasta" $SEQ > $IT2".paf"
racon $SEQ $IT2".paf" $IT1".fasta" $IT2".fasta"

# Run 3rd Racon Iteration

minimap -t$CPU $IT2".fasta" $SEQ > $IT3".paf"
racon $SEQ $IT3".paf" $IT2".fasta" $IT3".fasta"

# Run 4th Racon Iteration

minimap -t$CPU $IT3".fasta" $SEQ > $IT4".paf"
racon $SEQ $IT4".paf" $IT3".fasta" $IT4".fasta"

# Run final Pilon polishing

bwa index $IT4".fasta"
bwa mem -t $CPU $IT4".fasta" $PE1 $PE2 | samtools view -bS | samtools sort -@ $CPU > $IT4".bam"
samtools index $IT4".bam"
java -Xmx200G -jar pilon-1.21.jar --genome $IT4".fasta" --frags $IT4".bam" --output $IT5".fasta" --threads $CPU

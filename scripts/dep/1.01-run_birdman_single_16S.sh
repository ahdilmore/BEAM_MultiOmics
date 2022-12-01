#!/bin/bash
#SBATCH --job-name=crossover-birdman
#SBATCH --output=/home/grahman/projects/crossover-birdman/slurm_out/16S-%A_%a.out
#SBATCH --mem=8gb
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4

set -e

source ~/miniconda3/bin/activate birdman-benchmarking
export TBB_CXX_TYPE=gcc

if [ -z ${SLURM_ARRAY_TASK_ID} ]
then
    SLURM_ARRAY_TASK_ID=0
fi

PROJ_DIR="/home/grahman/projects/crossover-birdman"
OUTDIR="${PROJ_DIR}/results/16S/inferences"
mkdir -p $OUTDIR

TABLE="${PROJ_DIR}/data/16S/899703e3-2725-4e61-a492-3ad037af2eb3/data/feature-table.biom"
MD="${PROJ_DIR}/data/16S/16S-matched-metadata.tsv"
FORMULA="first_diet+diet_nocross+timepoint_encoded+cog"
SUBJ_COL="host_subject_id"

echo "Starting script..."
python src/run_birdman_single.py \
    --feature-num ${SLURM_ARRAY_TASK_ID} \
    --formula "${FORMULA}" \
    --chains 4 \
    --num-iter 500 \
    $TABLE \
    $MD \
    $SUBJ_COL \
    $OUTDIR
echo "Finished script!"

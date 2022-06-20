#!/bin/bash
#SBATCH --job-name=crossover-birdman
#SBATCH --output=/panfs/cmartino/beam/slurm_out/metaG-%A_%a.out
#SBATCH --mem=8gb
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4

set -e

source /home/cmartino/miniconda3/bin/activate birdmanv004

export TBB_CXX_TYPE=gcc

if [ -z ${SLURM_ARRAY_TASK_ID} ]
then
    SLURM_ARRAY_TASK_ID=0
fi

PROJ_DIR="/panfs/cmartino/beam"
OUTDIR="${PROJ_DIR}/results/metaG/inferences"
mkdir -p $OUTDIR

TABLE="${PROJ_DIR}/data/metaG/data/metaG-matched-table.biom"
MD="${PROJ_DIR}/data/metaG/metaG-matched-metadata.tsv"
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

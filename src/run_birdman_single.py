import time

import arviz as az
import biom
import click
import pandas as pd

from crossover_model_single import CrossoverModelSingle


@click.command()
@click.argument("feature_table")
@click.argument("metadata")
@click.argument("subject_column")
@click.argument("inference_dir")
@click.option(
    "--feature-num",
    required=True,
    type=int,
    help="Number of feature to fit"
)
@click.option(
    "--formula",
    required=True,
    type=str,
    help="Formula for design matrix"
)
@click.option("--chains", default=4, help="Number of MCMC chains")
@click.option("--num-iter", default=500, help="Number of sampling draws")
@click.option("--beta-prior", default=5)
@click.option("--cauchy-scale", default=5)
@click.option("--subject-prior", default=2)
def run_birdman_single(
    feature_table,
    metadata,
    subject_column,
    inference_dir,
    feature_num,
    formula,
    chains,
    num_iter,
    beta_prior,
    cauchy_scale,
    subject_prior
):
    tbl = biom.load_table(feature_table)
    md = pd.read_table(metadata, sep="\t", index_col=0)
    md.index = md.index.astype(str)
    tbl_samples = tbl.ids(axis="sample")
    md_samples = md.index
    samps_in_common = set(tbl_samples).intersection(md_samples)

    feature_num_str = str(feature_num).zfill(4)

    fids = tbl.ids(axis="observation")
    feature_id = fids[feature_num]

    out_file = f"{inference_dir}/F{feature_num_str}_{feature_id}.nc"

    model = CrossoverModelSingle(
        table=tbl.filter(ids_to_keep=samps_in_common),
        feature_id=feature_id,
        metadata=md.loc[samps_in_common],
        formula=formula,
        subject_column=subject_column,
        num_iter=num_iter,
        chains=chains,
        beta_prior=beta_prior,
        cauchy_scale=cauchy_scale,
        subject_prior=subject_prior
    )
    model.compile_model()

    start_time = time.time()
    model.fit_model()
    end_time = time.time()
    print(end_time - start_time)

    inf = model.to_inference_object()
    print(inf.posterior)
    print(az.loo(inf, pointwise=True))

    inf.to_netcdf(out_file)
    print(out_file)

if __name__ == "__main__":
    run_birdman_single()

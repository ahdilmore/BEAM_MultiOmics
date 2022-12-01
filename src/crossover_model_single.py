import biom
import numpy as np
import pandas as pd

from birdman import SingleFeatureModel

PROJECT_DIR = "/home/grahman/projects/crossover-birdman"

class CrossoverModelSingle(SingleFeatureModel):
    def __init__(
        self,
        table,
        feature_id,
        metadata,
        formula,
        subject_column,
        beta_prior=5.0,
        cauchy_scale=5.0,
        subject_prior=2.0,
        num_iter=500,
        **kwargs
    ):
        filepath = f"{PROJECT_DIR}/src/stan/crossover_model_single.stan"

        super().__init__(
            table=table,
            feature_id=feature_id,
            model_path=filepath,
            num_iter=num_iter,
            **kwargs
        )
        self.create_regression(formula=formula, metadata=metadata)

        subject_series = metadata[subject_column].loc[self.sample_names]
        samp_subject_map = subject_series.astype("category").cat.codes + 1
        self.subjects = np.sort(subject_series.unique())

        param_dict = {
            "depth": np.log(table.sum(axis="sample")),
            "B_p": beta_prior,
            "phi_s": cauchy_scale,
            "S": len(self.subjects),
            "subject_map": samp_subject_map.values,
            "u_p": subject_prior
        }
        self.add_parameters(param_dict)

        self.specify_model(
            params=["beta_var", "reciprocal_phi", "subject_int"],
            dims={
                "beta_var": ["covariate"],
                "subject_int": ["subject"],
                "log_lhood": ["tbl_sample"],
                "y_predict": ["tbl_sample"]
            },
            coords={
                "covariate": self.colnames,
                "tbl_sample": self.sample_names,
                "subject": self.subjects
            },
            include_observed_data=True,
            posterior_predictive="y_predict",
            log_likelihood="log_lhood"
        )

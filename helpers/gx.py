"""All the Great Expectations specific function."""
from __future__ import annotations

import logging
import os

from pandas import DataFrame
from great_expectations.checkpoint.types import CheckpointResult
from great_expectations.data_context import DataContext, BaseDataContext

from utils import ROOT_FOLDER_PATH, rewrite_blob_url


def run_checkpoint(
    context: BaseDataContext, data: DataFrame, checkpoint_name: str | None
) -> tuple[CheckpointResult | None, str | None]:
    """Create the dataframe and run the checkpoint"""
    if checkpoint_name is None:
        return None, None
    result = context.run_checkpoint(
        checkpoint_name=checkpoint_name,
        batch_request={
            "runtime_parameters": {"batch_data": data},
            "batch_identifiers": {"default_identifier_name": ""},
        },
    )
    docs_url = get_docs_site_urls(context, result)
    logging.log(
        logging.INFO if result["success"] else logging.WARNING, "Result: %s", result
    )
    return result, docs_url


def get_context(data_name: str | None = None) -> BaseDataContext:
    """Get the context and set the file name as an environment variable."""
    context = DataContext(context_root_dir=ROOT_FOLDER_PATH)
    if data_name:
        os.environ["FILE_NAME"] = data_name.replace("/", "-")
    return context


def get_docs_site_urls(
    context: BaseDataContext, result: CheckpointResult | None = None
) -> str:
    """Get docs site urls."""
    if result:
        docs_site_urls_list = context.get_docs_sites_urls(
            resource_identifier=list(result.run_results.keys())[0]
        )
    else:
        docs_site_urls_list = context.get_docs_sites_urls()
    return rewrite_blob_url(docs_site_urls_list[0]["site_url"])

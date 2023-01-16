"""Utils and constants for Great Expectations."""
from __future__ import annotations

import os

from great_expectations.data_context import BaseDataContext
from great_expectations.checkpoint.types.checkpoint_result import CheckpointResult

ROOT_FOLDER_PATH = os.getenv("ROOT_FOLDER_PATH", "great_expectations")
URL = "z6.web.core.windows.net/"

CHECKPOINT_LOOKUP = {
    "yellow_tripdata": "taxi_checkpoint",
}


def rewrite_blob_url(url: str) -> str:
    """Rewrite blob web url."""
    return url.replace("blob.core.windows.net/", URL).replace("$web/", "")


def get_docs_site_urls(context: BaseDataContext, result: CheckpointResult) -> str:
    """Get docs site urls."""
    docs_site_urls_list = context.get_docs_sites_urls(
        resource_identifier=list(result.run_results.keys())[0]
    )
    return rewrite_blob_url(docs_site_urls_list[0]["site_url"])


def get_checkpoint_from_filename(name: str) -> str | None:
    """Get checkpoint from filename."""
    filename = name.split("/")[1]
    for key, value in CHECKPOINT_LOOKUP.items():
        if filename.startswith(key):
            return value
    return None

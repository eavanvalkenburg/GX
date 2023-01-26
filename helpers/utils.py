"""Utils and constants for Great Expectations."""
from __future__ import annotations

import logging
import os

from great_expectations.checkpoint.types import CheckpointResult


CHECKPOINT_LOOKUP = {
    "yellow_tripdata": "taxi_checkpoint",
}


def rewrite_blob_url(url: str) -> str:
    """Rewrite blob web url."""
    return url.replace("blob", URL).replace("$web/", "")


def get_checkpoint_from_filename(name: str) -> str | None:
    """Get checkpoint from filename."""
    filename = name.split("/")[1]
    for key, value in CHECKPOINT_LOOKUP.items():
        if filename.startswith(key):
            return value
    return None


def create_event_grid_event(
    data_name: str, result: CheckpointResult, docs_url: str
) -> dict[str, str]:
    """Create an event grid event from the validation result."""
    event_grid_event = {
        "file": data_name,
        "success": result["success"],
        "url": docs_url,
        # "full_result": result.to_json_dict(),
    }
    logging.info("Sample event grid event: %s", event_grid_event)
    return event_grid_event

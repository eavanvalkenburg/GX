"""All data handling functions."""
from __future__ import annotations

from io import BytesIO
import pandas as pd

from enum import Enum


class FileFormat(Enum):
    """File formats supported by the function app."""

    CSV = "csv"
    JSON = "json"
    PARQUET = "parquet"


async def get_data_frame(data: bytes, file_format: FileFormat) -> pd.DataFrame:
    """Get the dataframe from the data"""
    if file_format == FileFormat.CSV:
        return pd.read_csv(BytesIO(data))
    if file_format == FileFormat.JSON:
        return pd.read_json(BytesIO(data))
    return pd.read_parquet(BytesIO(data))


async def get_data_from_blob_folder(
    path: str, connection_string: str, file_format: FileFormat
) -> pd.DataFrame:
    """Get the dataframe from the data"""
    if file_format == FileFormat.CSV:
        return pd.read_csv(
            f"abfs://{path}", storage_options={"connection_string": connection_string}
        )
    if file_format == FileFormat.JSON:
        return pd.read_json(
            f"abfs://{path}", storage_options={"connection_string": connection_string}
        )
    return pd.read_parquet(
        f"abfs://{path}", storage_options={"connection_string": connection_string}
    )

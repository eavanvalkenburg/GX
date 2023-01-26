"""Functions for integrating with azure."""
from __future__ import annotations

import json
import os
from dataclasses import dataclass
from azure.storage.blob.aio import BlobServiceClient


from const import DATA_CONTAINER


@dataclass
class TriggerMessage:
    folder_path: str
    checkpoint_name: str
    process_metadata_file: str
    entity_metadata_file: str


async def load_metadata_file(file_name: str) -> dict[str, str]:
    """Load the metadata file from storage."""
    async with BlobServiceClient.from_connection_string(
        os.environ["DATA_STORAGE"]
    ) as blob_client:
        async with blob_client.get_container_client(DATA_CONTAINER) as container_client:
            blob = await container_client.download_blob(file_name)
            return json.loads(await blob.content_as_text())


# https://edvangestorage.blob.core.windows.net/hnk/VFSA/metadata/VFSA_entity_metadata_2021-06-06T11%253A20%253A12.json
# VFSA/metadata/VFSA_entity_metadata_2021-06-06T11%3A20%3A12.json

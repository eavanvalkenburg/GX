"""Main entrypoint that calls blueprints."""
from __future__ import annotations

import logging
from io import BytesIO
import azure.functions as func
import pandas as pd

from great_expectations.data_context import DataContext

from utils import ROOT_FOLDER_PATH, get_docs_site_urls, get_checkpoint_from_filename

app = func.FunctionApp()


@app.function_name(name="gx_validate_blob")
@app.blob_trigger(
    arg_name="data",
    path="data/{name}",
    connection="DATA_STORAGE",
    data_type=func.DataType.STRING,
)
@app.blob_output(
    arg_name="output",
    path="output/{name}.json",
    connection="DATA_STORAGE",
    data_type=func.DataType.STRING,
)
async def process_file(data: func.InputStream, output: func.Out[str]):
    """Process a file."""
    logging.info("Processing file: %s", data.name)
    assert data.name
    run_name = data.name.replace("/", "-")
    context = DataContext(context_root_dir=ROOT_FOLDER_PATH)

    checkpoint_name = get_checkpoint_from_filename(data.name)
    if not checkpoint_name:
        logging.warning("No checkpoint found for file: %s", data.name)
        return

    data_batch = pd.read_csv(BytesIO(data.read()))
    result = context.run_checkpoint(
        checkpoint_name=checkpoint_name,
        batch_request={
            "runtime_parameters": {"batch_data": data_batch},
            "batch_identifiers": {"default_identifier_name": ""},
        },
        run_name=run_name,
    )
    docs_url = get_docs_site_urls(context, result)
    if result["success"]:
        logging.info("Success: %s", result["success"])
    else:
        logging.warning("Result: %s", result)

    event_grid_event = {
        "file": data.name,
        "success": result["success"],
        "url": docs_url,
        # "full_result": result.to_json_dict(),
    }
    logging.info("Sample event grid event: %s", event_grid_event)

    output.set(str(result.to_json_dict()))


@app.function_name(name="gx_build_docs")
@app.route(
    trigger_arg_name="req",
    methods=[func.HttpMethod.GET],
    route="build_docs",
)
async def rebuild_docs(req: func.HttpRequest) -> func.HttpResponse:
    """Rebuild docs."""
    logging.info("Rebuilding docs")
    logging.debug("Request body: %s", req.get_body())
    context = DataContext(context_root_dir=ROOT_FOLDER_PATH)
    context.build_data_docs()
    site = get_docs_site_urls(context)
    return func.HttpResponse(f"Docs (re)built: {site}")

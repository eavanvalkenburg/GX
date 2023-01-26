"""Main entrypoint of the Function."""
from __future__ import annotations

import logging

import azure.functions as func

from src.data import get_data_frame, FileFormat
from src.gx import run_checkpoint, get_context, get_docs_site_urls
from src.utils import get_checkpoint_from_filename, create_event_grid_event

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
async def gx_validate_blob(data: func.InputStream, output: func.Out[str]):
    """Process a file."""
    logging.info("Processing file: %s", data.name)
    assert data.name

    # set context
    context = get_context(data.name)

    # get checkpoint name
    checkpoint_name = get_checkpoint_from_filename(data.name)
    if not checkpoint_name:
        logging.warning("No checkpoint found for file: %s", data.name)
        return

    # get data
    data_frame = await get_data_frame(data.read(), file_format=FileFormat.CSV)

    # do the actual validation
    result, docs_url = run_checkpoint(context, data_frame, checkpoint_name)

    # setup outputs
    create_event_grid_event(data.name, result, docs_url)
    output.set(str(result.to_json_dict()))


@app.function_name(name="gx_build_docs")
@app.route(
    trigger_arg_name="req",
    methods=[func.HttpMethod.GET],
    route="build_docs",
)
async def gx_build_docs(req: func.HttpRequest) -> func.HttpResponse:
    """Rebuild docs."""
    logging.info("(Re)building docs")
    logging.debug("Request body: %s", req.get_body())
    context = get_context()
    context.build_data_docs()
    site = get_docs_site_urls(context)
    return func.HttpResponse(f"Docs (re)built: {site}")

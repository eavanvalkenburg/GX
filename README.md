# Great Expectations on Azure Functions

This repository contains a sample project that demonstrates how to use data validation with Great Expectations with Azure Functions.

It uses:
- Azure Functions
  - One function with a blob trigger that validates the file that triggers
  - One function that (re-)builds the data docs on static website hosting in Azure Storage based on a HTTP request
- Azure Storage
  - Blob storage for the data files
  - Static website hosting for the data docs
  - Blob storage for the functions app (can be the same as the data files)

## Setup

In the `great_expectations` folder you can find the Great Expectations project. The `great_expectations.yml` file contains the configuration for the project. The `great_expectations` folder is the root folder for the Great Expectations project. 

Within that folder the checkpoints and expectation_suites are stored, the expectations suites should be updated to suite your needs and extended for multiple types of files. The sample is one called taxi.json and is configured for the taxi data set from the gettings started sample here. The checkpoint creates the mapping to which expectation suite to use for which file type.

In the `utils.py` file a simple mapping is created that matches the file name to the checkpoint name. This should be adapted to your needs.

The main functions app is a python v2 function and has two functions:
- gx_validate_blob: triggers off new files in he `data` container of the `DATA_STORAGE` environment variable (connection string), it outputs to the same storage with the result json.
- gx_build_docs: this triggers the built of the data docs website on the `DATA_DOC_STORAGE` environment variable (connection string), it uses the static web app feature, so that needs to be turned on, and in the `utils.py` file a url rewrite function is used to go from the `blob.core.windows.net` url to the `web.core.windows.net` url, the exact website url should be updated there.


## Other notes
- This sample is built with CSV files, which are pulled from the trigger binding and with BytesIO parsed by the pandas package, this should be updated to fit your data files.
- There is already a sample output for a event_grid_event that can be used to output a event grid event, this includes a deeplink to the validation result website in the datadocs, which is very usefull for debugging purposes.

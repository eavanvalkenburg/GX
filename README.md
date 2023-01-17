# Great Expectations on Azure Functions

This repository contains a sample project that demonstrates how to use data validation with Great Expectations with Azure Functions.

It uses:
- Azure Functions
  - One function with a blob trigger that validates the file that triggers
  - One function that (re-)builds the data docs on static website hosting in Azure Storage based on a HTTP request
- Azure Storage
  - Blob storage for the data files
  - Blob storage for the functions app (can be the same as the data files)
  - File share for the great expectations config
  - Static website hosting for the data docs

## Setup

In Azure create the Azure Function app, based on Linux (otherwise the mount doesn't work) and either use the storage account that get's deployed as part of the function app or a seperate one and create the following containers and files shares:
1. `data` container
2. `output` container
3. `config` file share

Finally, turn on the static website feature, which creates the `$web` folder and set the index document name to `index.html`.

Deployment can also be done by using the `main.bicep` in the *bicep* folder. After that only the function app and the config files still have to be deployed.

### Great Expectations config
In the `great_expectations` folder you can find the Great Expectations project. The `great_expectations` folder is the root folder for the Great Expectations project, when doing local development for the function use the `ROOT_FOLDER_PATH` environment variable to point to this folder, in the deployed function mount a file share to your function, and upload the contents of that folder there, using [these steps](https://learn.microsoft.com/en-us/azure/azure-functions/scripts/functions-cli-mount-files-storage-linux). After this, any time the function is invoked online it will use the config from the file share and therefore that can then by updated by your CI/CD pipeline, without having to change the function. 

The `great_expectations.yml` file contains the configuration for the project and more details on that and the other config files can be found [here](https://docs.greatexpectations.io/docs/). The most important of which are the *checkpoints* and *expectation_suites*, the expectations suites should be updated to suite your needs and extended for multiple types of files. The sample expectations suite is called `taxi.json` and is configured for the taxi data set from the gettings started sample [here](https://docs.greatexpectations.io/docs/tutorials/getting_started/tutorial_setup/). The checkpoint creates the mapping to which expectation suite to use for which file type, the checkpoint also triggers an update of the data docs website, which relies on the validation results being stored, so make sure to keep at least those two actions in there. The data source is setup to just pass through whatever pandas dataframe it gets, so no need to change that, this comes from [this guide](https://docs.greatexpectations.io/docs/guides/validation/checkpoints/how_to_pass_an_in_memory_dataframe_to_a_checkpoint).

**The whole `great_expectations` folder should be uploaded to the config file share.**

### Function app

The main functions app is a python v2 function and has two functions:
- gx_validate_blob: triggers off new files in the `data` container of the `DATA_STORAGE` environment variable (connection string), it outputs to the same storage with the result json.
- gx_build_docs: this triggers the built of the data docs website on the `DATA_DOC_STORAGE` environment variable (connection string), it uses the static web app feature. 

In the `utils.py` file a simple mapping is created that matches the file name to the checkpoint name. This should be adapted to your needs and potentially should be moved into a seperate file in the config share that gets loaded dynamically so that the function does not have to be redeployed.
Also in the `utils.py` file a url rewrite function is used to go from the `blob.core.windows.net` url to the `web.core.windows.net` url, the exact website url should be updated there, in my case it was `<storagename>.z6.web...`. This is used both to create the deeplink to the validation run result on the website and to output the link to the whole website by the rebuild docs function.

The paths for the *triggers* and *outputs* should also be updated to match your needs. The outputs are not strictly necessary, since the data docs are also updated in the website, but they might be usefull for other purposes, the contents of the output is the json of the checkpoint run result.

After deploying the function, you can run the `gx_build_docs` function to create the initial version of the data_docs (and depending on if you have any validations stored in the uncommitted folder you will aready see those) and after that you can review the site, the url is returned when it was able to build.

And once you then start adding files to the data blob you will see the site being updated after each run.

### Other notes
- This sample is built with CSV files, the content of which are pulled from the trigger binding and with BytesIO parsed by the pandas package, this should be updated to fit your data files.
- There is already a sample output for a event_grid_event that can be used to output a event grid event, this includes a deeplink to the validation result website in the datadocs, which is very usefull for debugging purposes.

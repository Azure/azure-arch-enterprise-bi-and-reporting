# Setting up Incremental Loads

## Review the data load pipeline setup

* Ensure that you have completed the tasks listed in [step 6](./6-Prepare%20the%20infrastructure%20for%20your%20Data.md)
* Deploy the upload script you created as part of [step 7](./7-Configure%20Data%20Ingestion.md) to on-premise system.

## Extract and Upload Incremental Data
* Extract incremental data and put in the storage space where the on-premise system can access.
* Run the upload script to authenticate, retrieve blob location, upload file and then register with job manager. 
* Schedule the upload jobs for each Fact and Dimension you need to upload.

## Monitor SSAS partition refresh
* Once incremental data gets uploaded, there will be tasks created for partition builder. Once partition builder tasks are completed, you can check the partition builder machine to check the last refresh time for each table. You can also validate the refreshed data for accuracy and completeness.

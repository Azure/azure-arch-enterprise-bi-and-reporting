# Load historical data into the warehouse.

## Summary
This page lists ways you can load historical data into the SQL Datawarehouse

Loading of historical data will depend on the data size and retention policy on Azure Cloud. Depending on the size of the data, you can use either of following approaches

1. Use the Solution itself to upload Files and load the data.
2. Export the data and Upload using Blob Storage.
3. Use Microsoft Import/Export Service to transfer data to Storage.


## 1. Use the Solution itself to upload files and load the data.

In case your historical data size is small(GB to TB), you can use the following steps to load data.
* Export the data from your exisiting solution into on-premise storage as csv files.
* Setup the data Ingestion pipeline as indicated in [Configure Data Ingestion](./7-Configure%20Data%20Ingestion.md)
* Upload each data file as indicated in step 2 and let the solution ADF pipelines load into the SQL DW's

## 2. Export the data and Upload using Blob Storage

In case your data is in low GB's or TB's which can be transferred over the network, you can follow the steps below to load data.

* Export the historical data from your existing solution into on-premise storage as cvs files.
* Create a new Blob Storage account in your resource group and upload all the files 
* Follow the [ documentation link ](https://docs.microsoft.com/en-us/azure/sql-data-warehouse/sql-data-warehouse-get-started-load-with-polybase) to load data into both Reader and Loader SQL DW's.


## 3. Use Microsoft Import/Export Service to transfer data to Storage.

In case your data is very large and cannot be uploaded using the network, you can use the Microsoft Import/Export Service to transfer data. Once data is transferred you can use the steps mentioned above in Step 2 to load into SQL DW from Blob Storage account.

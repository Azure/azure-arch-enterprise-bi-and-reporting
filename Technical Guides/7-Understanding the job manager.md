# Understanding the Job Manager

The Job Manager is an ASP.NET Web application that is hosted on one of the Azure IaaS VM provisioned during the deployment. Its purpose is to track and manage TRI Data ingestion and SSAS tabular model building. Its state is persisted to an Azure SQL database and exposed via [OData](https://msdn.microsoft.com/en-us/library/hh525392(v=vs.103).aspx) REST APIs. This document discusses the functional areas of Job Manager and its APIs.

## Job Manager OData Client Schema
In order to access the Job Manager, please refer to the "OData API" section of the deployment summary page. It lists the URL for the Job Manager in the form of `https://<mydeployment>.adminui.<mydomain>:8081/odata`. You can see the client schema by appending `$metadata` to that URL.

## Data Ingestion
### Ephemeral Storage Accounts
(Epemenral Storage Accounts)[./1-Understanding%20ephemeral%20blobs.md] are managed by the Job Manager. At any point in time, clients can find currently active Epemeral Blob storage account and its SAS token by querying `/StorageAccounts` OData API.

### Data Warehouse Table Availability Ranges
TRI clients create `DWTableAvailabilityRange` entities to signal arrival of new data (see [Understanding Data Ingestion](2-Understanding%20data%20ingestion.md)). Clients can monitor the status of their data imports by querying `/DWTableAvailabilityRanges` OData API.

### Job Runtime Policy
The Job Manager imposes certain policies on Load jobs. Those policies can be fetched by calling `/RuntimePolicy` OData API. They can be modified by invoking `PUT` and `PATCH` requests to `/RuntimePolicy` OData APIs.

### Runtime Tasks
Once a `DWTableAvailabilityRange` is created, a background process running inside the Job Manager will create an Azure Data Factory pipeline to ingest the data from the Ephemeral Blob Storage account and into each of the Physical Data Warehouses. One `RuntimeTask` corresponds to one Azure Data Factory pipeline. Clients can monitor their status by querying `/RuntimeTasks` OData endpoint.

### Runtime Task Policy
Job Manager can enforce certain policies on the Runtime Tasks discussed above. Clients can query `/RuntimeTaskPolicy` OData API to see the default policies. The defaults can be changed by invoking `PUT` or `PATCH` requests to `/RuntimeTaskPolicy` OData API.

## Data Warehouse Tables and Dependencies
### Data Warehouse Tables

### Data Warehouse Table Dependencies

### Stored Procedures




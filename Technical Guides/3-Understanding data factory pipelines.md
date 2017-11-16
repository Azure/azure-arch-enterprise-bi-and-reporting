# Understanding Data Factory Pipelines

Enterprise BI and Reporting TRI relies on [Azure Data Factory](https://azure.microsoft.com/en-us/services/data-factory/) to ingest data from the Ephemeral Blob storage into SQL Data Warehouses.

When the Job Manager server initiates loading of a given file into a given physical Data Warehouse, the Job Manager will call Azure Data Factory APIs to create and start a one-time pipeline. This pipeline contains the following three activities:
1. Pre-load activity 
2. [Copy activity](https://docs.microsoft.com/en-us/azure/data-factory/copy-activity-overview) ingests data from a given Ephemeral Blob storage file (source) into the given SQL Datawarehouse table (sink).
3. Post-load activity runs a specified Stored Procedure to produce aggregate facts after dependent tables have been ingested.

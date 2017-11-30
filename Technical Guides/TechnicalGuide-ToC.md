# Technical Guides for Enterprise BI and Reporting

The following documents describe the technical details of the various operational components of the TRI after it has been successfully deployed.

1. [Understanding Ephemeral Storage Accounts](./1-Understanding%20ephemeral%20blobs.md) - Explains ephemeral blobs as the intermediary stage between data upload and ingestion.

2. [Understanding data ingestion](./2-Understanding%20data%20ingestion.md) - Explains the checks for valid data slices, and steps taken to load each data slice into physical data warehouses from blob storage.

3. [Understanding data factory pipelines](./3-Understanding%20data%20factory%20pipelines.md) - Explains how the pipeline created by Azure Data Factory moves data from the Ephemeral Blob to the Data Warehouse.

4. [Understanding Logical Data Warehouses](./4-Understanding%20logical%20datawarehouses.md) - Explains the purpose and requirements of logical groupings of data warehouses.

5. [Understanding Data Warehouse Flip](./5-Understanding%20data%20warehouse%20flip.md) - Explains the details of how the DWs coordinate between being in a loading state and queryable active state. 

6. [Understanding Tabular Model Refresh](./6-Understanding%20tabular%20model%20refresh.md) - Explains how the TRI operationalizes and manages tabular models in Analysis Services for interactive BI.

7. [Understanding the job manager](./7-Understanding%20the%20job%20manager.md)

8. [Understanding how to scale](./8-Understanding%20how%20to%20scale.md)

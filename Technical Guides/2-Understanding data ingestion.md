# Understanding Data Ingestion

Once the data is uploaded to the Ephemeral Blob storage (see [Understanding Ephemeral Blobs](./1-Understanding%20ephemeral%20blobs.md)), the clients must call a Job Manager API to create a `DWTableAvailabilityRange` entity. The table below summarizes the contract for `DWTableAvailabilityRange`.

| Name | Description |
| ---- | -------- |
| `DWTableName` | The name of the table in SQL Datawarehouse to which the data will be ingested |
| `StorageAccountName` | The name of the Ephemeral Blob storage where the file was uploaded |
| `FileUri` | The URI to the file in the Ephemeral Blob storage above |
| `StartDate` | StartDate for the slice  |
| `EndDate` | EndDate for the slice |
| `ColumnDelimiter` | Delimiter for the column (i.e. ',') |
| `FileType` | Type of file (i.e. 'CSV') |

Note that `StartDate` - `EndDate` ranges for `DWTableAvailabilityRange` entities sharing the same `DWTableName` must not overlap. Job Manager will throw an exception at the time of creation if an overlapping `DWTableAvailabilityRange` is detected.

Upon creation, the Job Manager will create a separate instance of `DWTableAvailabilityRange` for each physical data warehouse and return `200 - OK` status code. For data ingestion code sample, please refer to [Configuring Data Ingestion](../User%20Guides/7-Configure%20Data%20Ingestion.md#1-modify-the-code-provided-in-the-tri-to-ingest-your-data).

A Job Manager background process continuously looks for `DWTableAvailabilityRange` entities that belong to physical data warehouses in `Load` state. Once such entity is found, an Azure Data Factory pipeline is created to ingest data into the physical data warehouse (see [Understanding Data Factory Pipelines](./3-Understanding%20data%20factory%20pipelines.md)). Therefore, the data is loaded into physical data warehouses in `Load` state as soon as corresponding `DWTableAvailabilityRange` is created. The remaining Physical Data Warehouses will have the data ingested after the next flip operation is performed (see [Understanding data warehouse flip](./5-Understanding%20data%20warehouse%20flip.md)).

# Understanding the Job Manager

The Job Manager is an ASP.NET Web application hosted on one of the Azure IaaS VMs provisioned during the deployment. Its purpose is to track and manage TRI Data ingestion and Analysis Services tabular model building. Its state is persisted to an Azure SQL database and exposed via [OData](https://msdn.microsoft.com/en-us/library/hh525392(v=vs.103).aspx) REST APIs. 

Job Manager's responsibilities fall into three broad categories: data ingestion coordination, Logical and Physical Data Warehouse state management (i.e. `Standby`, `Active` and `Load`), and coordination of Analysis Services tabular model building. This document discusses each of the categories in the context of Job Manager APIs.

## Job Manager OData Client Schema
In order to access the Job Manager, please refer to the "OData API" section of the Cortana Intelligence Quick Start deployment summary page. It lists the URL for the Job Manager in the form of `https://<mydeployment>.adminui.<mydomain>:8081/odata`. You can see the service client schema by calling GET `/$metadata` API.

## Data Ingestion
### Ephemeral Storage Accounts
(Epemenral Storage Accounts)[./1-Understanding%20ephemeral%20blobs.md] are managed by the Job Manager. At any point in time, clients can fetch active Epemeral Blob storage account and its SAS token by calling `/StorageAccounts` OData API.

### Data Warehouse Table Availability Ranges
TRI clients create `DWTableAvailabilityRange` entities to signal arrival of new data (see [Understanding Data Ingestion](./2-Understanding%20data%20ingestion.md)). Clients can monitor the status of their data imports by querying `/DWTableAvailabilityRanges` OData API.

### Job Runtime Policy
The Job Manager imposes certain policies on Load jobs. Those policies can be fetched by calling `/RuntimePolicy` OData API. They can be modified by invoking `PUT` or `PATCH` requests to `/RuntimePolicy` OData API endpoint.

### Runtime Tasks
Once a `DWTableAvailabilityRange` entity is created, a background process running inside the Job Manager will create an Azure Data Factory pipeline to ingest the data from the Ephemeral Blob Storage account into each of the Physical Data Warehouses. One `RuntimeTask` corresponds to one Azure Data Factory pipeline. Clients can monitor their status by calling `/RuntimeTasks` OData API.

### Runtime Task Policy
The Job Manager can enforce certain policies on the Runtime Tasks above. Clients can query `/RuntimeTaskPolicy` OData API to see the default policies. The defaults can be changed by invoking `PUT` or `PATCH` requests to `/RuntimeTaskPolicy` OData API endpoint.

### Data Warehouse Tables
The Job Manager tracks references of Physical Data Warehouse tables. Clients can query `/DWTables` OData API to see the tables, table types (i.e. `Fact`, `Dimension` or `Aggregate`), etc. When a new table is created in the Physical Data Warehouse, clients must create a `DWTable` entity by sending a `POST` request to `/DWTable` OData API. Similarly, when a client drops a table in the Physical Data Warehouse, they must delete corresponding `DWTable` entity by sending `DELETE` request to `/DWTable` OData API endpoint.

### Data Warehouse Table Dependencies
The Job Manager enables clients to declare dependencies between Physical Data Warehouse tables. When a dependency is declared between two Data Warehouse tables, the Job Manager will ensure that the given table is loaded into the Physical Data Warehouse only after all of its dependencies are loaded for specified time interval. Clients can query dependencies by calling `/DWTableDependencies` OData API. Clients can declare dependencies by sending `POST` request to `/DWTableDependencies` OData API endpoint.

### Stored Procedures
In order to generate data for aggregate tables, `StoredProcedure` entities can be associated with fact tables. The Job Manager will ensure that once a given fact table is loaded, the stored procedure is invoked to generate data for the aggregate table. Note that the Job Manager only stores the mappings between stored procedure and Data Warehouse table. Users will need to create the stored procedures in each Physical Data Warehouse.

Clients can query existing stored procedures by calling `/StoredProcedures` OData API. After the stored procedure is creating in each Physical Data Warehouse, clients can create a `StoredProcedure` entity by seding `POST` request to `/StoredProcedures` OData API endpoint.

## Logical and Physical Data Warehouse state management
As discussed in [Understanding Logical Data Warehouses](./4-Understanding%20logical%20datawarehouses.md) and [Understanding Data Warehouse Flip](./5-Understanding%20data%20warehouse%20flip.md), the Job Manager is responsible for maintaining the mapping between Logical and Physical Data Warehouses, as well as their states.

### Logical to Physical Data Warehouse mappings
Clients can find out the mapping between Logical and Physical Data Warehouses by calling `/LDWPDWMappings` OData API. 

### Logical Data Warehouse state history
Clients can audit Logical and Physical Data Warehouse state transition history by calling `/DWStatesHistory` OData API.

### Data Warehouse flip intervals
As discussed in [Understanding Data Warehouse Flip](./5-Understanding%20data%20warehouse%20flip.md), a series of operations is required to be performed during the Data Warehouse flip. While the `/DWStatesHistory` OData API lists the times and the statuses of each Logical and Physical Data Warehouse state transition, `/LDWExpectedStates` API lists the flip intervals for each of the Logical Data Warehouses. I.e. what state a given Logical Data Warehouse should be in at a given time.

## Analysis Services tabular model building
### Analysis Services Direct Query node to Physical Data Warehouse mapping
As discussed in [Understanding Data Warehouse Flip](./5-Understanding%20data%20warehouse%20flip.md), Analysis Services Direct Query nodes run a daemon which ensures that the nodes are always connected to the Data Warehouse in `Active` state. During the Data Warehouse Flip, the daemons will update to point to the Logical Data Warehouse in `Active` state and call a Job Manager API to report which Physical Data Warehouse the node is connected to.

Clients can see which Physical Data Warehouse each of the Direct Query nodes is connected by calling `/PdwAliasNodeStates` OData API.

### Analysis Services tabular models
As discussed in [Understanding Tabular Model Refresh](./6-Understanding%20tabular%20model%20refresh.md#tabular-model-partition-state-transition), Analysis Services Partition Builder nodes build tabular models to be consumed by the Analysis Services Read-only nodes. 

Clients can call `/TabularModels` OData API to fetch the list of tabular models with their server and database names. These server and database names are used by the partition builder for connecting to the data source.

### Analysis Services tabular model partitions and states
Clients can call `/TabularModelTablePartitions` and `/TabularModelTablePartitionStates` OData APIs to fetch the list of tabular model table partitions and their states. For an in-depth discussion on their meaning, please refer to [Tabular model configuration for continuous incremental refresh at scale](./6-Understanding%20tabular%20model%20refresh.md#tabular-model-configuration-for-continuous-incremental-refresh-at-scale).

### Analysis Services tabular model node assignments
Clients can call `/TabularModelNodeAssignments` OData API to find the latest partition for each tabular model table and each Analysis Services Read-only node.





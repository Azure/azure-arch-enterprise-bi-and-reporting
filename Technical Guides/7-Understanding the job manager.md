# Understanding the Job Manager

The Job Manager is an ASP.NET Web application hosted on one of the Azure IaaS VMs provisioned during the deployment. Its purpose is to track and manage TRI data ingestion and Analysis Services tabular model building. Its state is persisted to an Azure SQL database and exposed via [OData](https://msdn.microsoft.com/en-us/library/hh525392(v=vs.103).aspx) REST APIs. 

The Job Manager's responsibilities fall into three broad areas: data ingestion coordination, Logical and Physical Data Warehouse state management (i.e. `Standby`, `Active` and `Load`), and coordination of Analysis Services tabular model building. This document discusses these areas in the context of Job Manager APIs.

## Job Manager REST Endpoint and OData Client Schema
In order to access the Job Manager, please refer to the "OData API" section of the Cortana Intelligence Quick Start deployment summary page. It lists the URL for the Job Manager in the form of `https://<mydeployment>.adminui.<mydomain>:8081/odata`. You can see the service client schema by calling GET `/odata/$metadata` API.

## Data Ingestion
### Ephemeral Storage Accounts
This [Ephemeral Storage Account](./1-Understanding%20ephemeral%20blobs.md) are managed by the Job Manager. At any point in time, clients can fetch the active Epemeral Blob storage account and its SAS token by calling `/StorageAccounts` OData API.

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
The Job Manager enables clients to declare dependencies between Physical Data Warehouse tables. When a dependency is declared between two Data Warehouse tables, the Job Manager will ensure that the given table is loaded into the Physical Data Warehouse only after all of its dependencies are loaded for specified time interval. Clients can query dependencies by calling `/DWTableDependencies` OData API. Clients can declare a dependency by sending `POST` request to `/DWTableDependencies` OData API endpoint.

### Stored Procedures
In order to generate data for aggregate tables, `StoredProcedure` entities can be associated with fact tables. The Job Manager will ensure that once a given fact table is loaded, the stored procedure is invoked to generate data for the aggregate table. Note that the Job Manager only stores the mappings between stored procedures and Data Warehouse tables. Users will need to create stored procedures in each Physical Data Warehouse.

Clients can query existing stored procedures by calling `/StoredProcedures` OData API. After the stored procedure is creating in each Physical Data Warehouse, clients can create a `StoredProcedure` entity by sending `POST` request to `/StoredProcedures` OData API endpoint.

## Logical and Physical Data Warehouse state management
As discussed in [Understanding Logical Data Warehouses](./4-Understanding%20logical%20datawarehouses.md) and [Understanding Data Warehouse Flip](./5-Understanding%20data%20warehouse%20flip.md), the Job Manager is responsible for maintaining the mapping between Logical and Physical Data Warehouses, as well as their states.

### Logical to Physical Data Warehouse mappings
Clients can find out the mapping between Logical and Physical Data Warehouses by calling `/LDWPDWMappings` OData API. 

### Logical Data Warehouse state history
Clients can audit Logical and Physical Data Warehouse state transition history by calling `/DWStatesHistory` OData API.

### Data Warehouse flip intervals
As discussed in [Understanding Data Warehouse Flip](./5-Understanding%20data%20warehouse%20flip.md), a series of operations is required to be performed during the Data Warehouse flip. While the `/DWStatesHistory` OData API lists the times and the statuses of each Logical and Physical Data Warehouse state transition, `/LDWExpectedStates` API lists expected flip intervals for each of the Logical Data Warehouses; i.e. what state a given Logical Data Warehouse should be in at a given time.

## Analysis Service Direct Query node management
### Analysis Services Direct Query node to Physical Data Warehouse mapping
As discussed in [Understanding Data Warehouse Flip](./5-Understanding%20data%20warehouse%20flip.md), Analysis Services Direct Query nodes run a daemon which ensures that the nodes are always connected to the Data Warehouse currently set in the `Active` state. During the Data Warehouse Flip, the daemons will update to point to the Logical Data Warehouse in `Active` state and call a Job Manager API to report which Physical Data Warehouse the node is connected to.

This ensures that the Job Manager is always aware of which Physical Data Warehouses are connected to the Analysis Services Direct Query nodes and can perform data warehouse state transition accordingly.

Clients can see which Physical Data Warehouse each of the Direct Query nodes is connected by calling `/PdwAliasNodeStates` OData API.

## Analysis Services tabular model building
As discussed in [Understanding Tabular Model Refresh](./6-Understanding%20tabular%20model%20refresh.md#tabular-model-partition-state-transition), Analysis Services Partition Builder nodes build tabular models to be consumed by the Analysis Services Read-Only nodes. The Job Manager orchestrates tabular model building and Read-Only node refresh by exposing a set of OData APIs. A daemon running on the Analysis Services Partition Builder node calls a set of Job Manager APIs to query for and report on the progress of partition building.

### Analysis Services tabular models
Clients can call `/TabularModels` OData API to fetch the list of tabular models with their server and database names. Partition Builder uses these server and database names to connect to the data source.

### Analysis Services tabular model partitions
Clients can call `/TabularModelTablePartitions` OData API to fetch the list of tabular model table partitions. For an in-depth discussion on their meaning, please refer to [Tabular model configuration for continuous incremental refresh at scale](./6-Understanding%20tabular%20model%20refresh.md#tabular-model-configuration-for-continuous-incremental-refresh-at-scale).

### Analysis Services tabular model partition states
Clients can call `/TabularModelTablePartitionStates` OData API to fetch the status (i.e. `Queued`, `Dequeued`, `Processed`, `Ready`, `Purged`) of each of the tables in the tabular model. This API effectively shows the status of Analysis Services Partition Builder.

### Analysis Services tabular model node assignments
Once the Partion Builder finishes building tabular model table partitions, Analysis Services Read-Only nodes must refresh the models. Daemons running on Analysis Services Read-Only nodes will call the Job Manager APIs to check if updates are available. Upon updating the model, the daemon will call a Job Manager API to mark the node as updated.

Clients can call `/TabularModelNodeAssignments` OData API to find the latest partition for each tabular model table and each Analysis Services Read-only node.

# The Job Manager Properties and Miscellaneous APIs

## Job Manager Status API
Clients can use `/ServerStatus` OData API as an HTTP ping function to ensure that the Job Manager is up and serving requests. This could be useful for setting up external monitoring and HTTP probes.

## Job Manager Properties
Clients can query and update the Job Manager properties by calling `/ControlServerProperties` API. The table below summarizes the properties and their meaning.

| Property name | Description |
|:----------|:------------|
|**ComputeUnits_Active**| Compute Data Warehouse Units for Physical Data Warehouses in `Active` state. Note that the value must match one of the values listed under [SQL Data Warehouse pricing](https://azure.microsoft.com/en-us/pricing/details/sql-data-warehouse/elasticity/). See [Data Warehouse Units (DWUs) and compute Data Warehouse Units (cDWUs)](https://docs.microsoft.com/en-us/azure/sql-data-warehouse/what-is-a-data-warehouse-unit-dwu-cdwu) |
|**ComputeUnits_Load**| Compute Data Warehouse Units for Physical Data Warehouses in `Load` state. Note that the value must match one of the values listed under [SQL Data Warehouse pricing](https://azure.microsoft.com/en-us/pricing/details/sql-data-warehouse/elasticity/). |
|**ComputeUnits_Standby**| Compute Data Warehouse Units for Physical Data Warehouses in `Standby` state. Note that the value must match one of the values listed under [SQL Data Warehouse pricing](https://azure.microsoft.com/en-us/pricing/details/sql-data-warehouse/elasticity/). |
|**MinDQNodesNotInTransitionStateDuringFlip**| This parameter specifies the minimum number of Analysis Services Direct Query nodes that will serve traffic during the data warehouse flip. By default, it is set to 1. As a result, the Job Manager will guarantee that at least one DQ node will always be available to serve traffic, while the rest of the fleet is performing the flip. |
|**MinsAliasNodeDaemonGraceTime**| This parameter specifies the number of minutes that a Direct Query node will wait for the existing connections to be closed before the data warehouse flip is initiated. By default, it is set to 3. |
|**MinSSASROServersNotInTransition**| This parameter specifies the minimum number of Analysis Services Read-Only nodes that will serve traffic during the tabular model refresh. By default, it is set to 1. As a result, the Job Manager will ensure that at least on Read-Only node will be ready to serve traffic while the rest of the fleet is refreshing. |
|**MinsToWaitBeforeKillingAliasNodeDaemonGraceTime**| This parameter specifies the number of minutes that each Analysis Services Direct Query node is given to perform the flip. If that time is exceeded, the Job Manager will terminate the flip. It is set to 10 minutes. |





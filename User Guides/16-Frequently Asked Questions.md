# Frequently Asked Questions

### Why do the TRIs have multiple SQL Data Warehouses?

SQL DW does not currently support read isolation, i.e. loading and reading data at the same time. In addition, SQL Data Warehouse (DW) supports limited (currently 32, more upcoming) concurrent queries; limiting the number of jobs which can run in parallel. Large enterprises usually require a large number of concurrent queries. To support this requirement our design has two logical DWs; one for loading data and the other for reading. Each logical DW can have one or more physical DWs. After a loading cycle is finished, the logical DWs are switched from loader to reader and vice versa. For more information on the flip operation see the [technical guide](../Technical%20Guides/5-Understanding%20data%20warehouse%20flip.md).
 
### Why doesn’t the TRI use an ADF data source instead of rotating an ephemeral blob?
 
Enterprise customers have concerns of security of their data in the public cloud. At the time of inquiry, Blobs did not offer user keys for encryption. Keeping the blob ephemeral addresses this concern, and requires us to create one-time data load pipelines which can be deleted once the load is completed. For more information on the ephemeral blob see the [technical guide](../Technical%20Guides/1-Understanding%20ephemeral%20blobs.md).
 
### Why is a Job Manager required? Can’t we just use ADF?

To load data from ephemeral blob storage into logical DWs, we need to create dynamic Data Factory pipelines with changing source and destination sinks. In addition, ADF currently does not support the building of SSAS partitions. The piece required us to build custom code along with maintaining the state of data loads into SSAS. We also needed to keep track of which SQL DW is the loader and which is the reader, as well as maintain switching the SQL DW instances. These key requirements led us to build our own scheduler and metadata system (on SQL Server) to orchestrate the entire workflow. 
 
### Why is blob used to swap the partitions?

To solve for very large concurrent users, SSAS servers can be configured to host the same data with a load balancer in front. As the SSAS cache needs to be refreshed on all the servers without disrupting the users, the cache model is built by partition builder machine and copied to Blob storage. Each server then removes itself from the load balancer and updates the model from Blob before resuming user requests. 
 
### Why is there a separation between SSAS Read Only and SSAS for SSRS? What is the Queue limit, row security, query limit?
 
Enterprises typically have the need for interactive analytics as well as scheduled reporting needs. To address the interactive needs, we have SSAS cache models (SSAS Read Only) built which can be accessed using Power BI. Power BI allows users to interactively query the SSAS cache; providing instant results. To address the scheduled reporting needs we provide SSRS reports using SSAS Direct Query model ensuring that the same row level security is applied to both cache and Direct Query models. The limitations of the SSRS architecture is that report building has to be done by a limited set of users and multiple reports cannot be scheduled at the same time due to the 1024 query queue limit in SQL DW.
 
### Why use SSAS instead of Redis cache?

Redis is a completely different use case. It is not an interchangeable technology with SSAS which has a vertipaq engine allowing accessing relational data in a very low latency. Even if we use Redis, we are limited to cache hits of only 32 queries at a time. Any new query, even with minor syntactic changes, will require a new DW read. 
 
### Why does the TRI use Azure SQL DW? Why not Teradata? 

Azure DW is in the list of technologies that was recommended by all product teams as part of the TRI. It's a PaaS service which is T-SQL compliant and allows for scaling up and down including pausing the data warehouse when not in use. SQL DW provides automated backups along with geo backups and restores.  

### Can I configure the TRI to have only one logical SQL DW to play both Loader and Reader roles?

No, the system requires a minimum of two SQL DWs.

### Can I configure the TRI to replace SQL DW with SQL DB?

The TRI does not currently support the swapping of SQL DW with SQL DB.

### Can I configure the TRI to remove the SSAS cache components and have Power BI directly query SQL DW?

Although this is not a supported and tested scenario, removal of any node in the architecture should not effect the upstream nodes. As such, you can remove any nodes without seriously effecting the system. This will need to be performed manually in the [Azure portal](https://portal.azure.com) post deployment.

Keep in mind, the administration UI and other components are not configured to dynamically account for the removal of these nodes so you will still see the presence of these components even though they may not be functional.

### Can I configure the TRI to remove the SSRS scheduled reporting components?

Although this is not a supported and tested scenario, removal of any node in the architecture should not effect the upstream nodes. As such, you can remove any nodes without seriously effecting the system. This will need to be performed manually in the [Azure portal](https://portal.azure.com) post deployment.

Keep in mind, the administration UI and other components are not configured to dynamically account for the removal of these nodes so you will still see the presence of these components even though they may not be functional.

### Are the tabular models backed up?

All tabular model are backed up a storage blob. These can be found under your resource group with the name XXXpntrfsh.

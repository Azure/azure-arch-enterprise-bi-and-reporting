# Configuring Logical Data Warehouses
The TRI implements data load orchestration into multiple parallel data warehouses for redundancy and high availability.

![Architecture](../img/ConfiguringSQLDWforTRI.png)

## Data Availability and Orchestration features

The logical Data Warehouse architecture and orchestration address these requirements:

1. Each logical data warehouse (LDW) consists of a single physical data warehouse by default. More replicas per LDW can be configured for scalability and high availability. 
2. SQL DW data refresh cycle can be configured by the user - one option is to use 8 hours.This implies loading the physical data warehouses 3 times a day.
3. Adding new schemas and data files to the  SQL DW is a simple, scriptable process. The TRI assumes 100-500 data files being sent in every day, but this can vary day to day.
4. The job manager is both “table” aware and "data/time" aware to plan execution of a report until data has been applied representing a given period of time for that table.
5. Surrogate keys are not utilized and no surrogate key computation is applied during data upload.
6. All data files are expected to be applied using “INSERT” operations.  There is no support to upload “DELETE” datasets.  Datasets must be deleted by hand; no special accommodation is made in the architecture for DELETE or UPDATE.
7. All fact tables in the data warehouse (and the DIMENSION_HISTORY) tables are expected to follow the Kimball [Additive Accumulating Snapshot Fact Table](http://www.kimballgroup.com/2008/11/fact-tables/) approach.  A “reversal flag” approach is recommended, to indicate if a fact is to be removed, with offsetting numeric values.  For example, a cancelled order is stored with value of $100 on day 1 and reversal flag set to false; and stored with a value of -$100 on day 2 with a reversal flag set to true.
8.	All fact tables will have DW_ARCHIVAL_DATE column set so that out-of-time analysis and aggregation can be performed.  The values for the DW_ARCHIVAL_DATE will be set by the Data Generator that computes the change set for the LDW each local-timezone day.
9.	The job manager does not prioritize data loads, and provides only a minimal dependency tracking for golden dimensions and aggregates. “Golden Dimensions” are tables that must be loaded before other tables (dimension, fact or aggregate) into the physical EDWs.
10.	Dimension tables must be re-calculated and refreshed after every load of a dimension table with >0 records.  A stored procedure to re-create the current dimension table after a load of dimension table history records is sufficient.
11.	The Admin GUI provides DW load status.
12. Data availability can be controlled using manual overrides.

## Relationship with Tabular Models

The TRI also meets the following requirements for the tabular model generation in relation to the SQL DW:

1.	An optional stored procedure runs on tables to produce aggregate results after a load.  The aggregate tables will also be tracked in the job manager. A set of tabular model caches will be refreshed with the results of the incremental dataset changes.  
2.	Tabular model refreshes do not need to be applied synchronously with the logical data warehouse flip; however, there will be minimal (data volume dependent) delay between the tabular model refresh and the application of updates as viewed by a customer.
3.	Dependencies from the tabular model caches will be known to the Job Manager. Only the tabular model caches that are impacted by a dataset change will get re-evaluated and their read-only instances updated.
4.	The system is designed to refresh 10-100 tabular model caches 3 times daily, with each tabular model having size approximately 10Gb of data.

## Logical Data Warehouse Status and Availability
A set of control tables associate physical DWs to tables, schemas, and to time ranges and record dataset auditing information (start date, end date, row count, filesize, checksum) in a separate audit file.

The LDW load and read data sets iterate through three states:
- Load: The LDW set is processing uploaded data files to “catch-up” to the latest and greatest data.
- Load-Defer:The LDW is not processing updates nor serving customers; it is a hot-standby with “best available” data staleness for disaster recovery purposes. **TODO - Confirm if we have this state**
- Primary: The LDW is up-to-date and serving requests but not receiving any additional data loads.

It is recommended that the data files that are loaded into physical DW instances have the following naming structure:

- Data File: `startdatetime-enddatetime-schema.tablename.data.csv`
- Audit file: `startdatetime-enddatetime-schema.tablename.data.audit.json`

This will provide sufficient information to determine the intent of the file should it appear outside of the expected system paths.  The purpose of the audit file is to contain the rowcount, start/end date, filesize and checksum.  Audit files must appear next to their data files in the same working directory always.  Orphaned data or audit files should not be loaded.

## Advanced Topics

### Anatomy of a Logical SQL DW Flip

Here is an example schedule showing how the logical DW flips occur - with physical data warehouses located in different Azure availability regions. The DW control logic in the job manager performs the flip operation on the schedule only if the current time is past the time of the schedule and the conditions for safe and healthy operation of the scheduled event is fulfilled.

- Active - is the state when the LDW is active serving user queries.
- Load - is the state when the LDW is being loaded with data via data load jobs.
- Standby - is the state when the administrator has paused the LDW (i.e. the physical data warehouses in the LDW) for planned maintenance, if no data is available to be loaded, or other reasons.


| PST | EST | UTC | LDW 1 - US West | LDW 2 - US East | Data scenario |
|:----|:----|:----|:------|:------|:-------------------------|
|00:00 | 03:00 | 08:00 | Active | Load | Batch 1 is loaded into LDW 2 from BLOB via dynamic ADF pipelines |
|08:00 | 11:00 | 16:00 | Load | Active | Batch 2 data is loaded into LDW 1, while LDW 2 becomes the reader/primary (NOTE: Any incomplete ADF pipelines may continue to load LDW 2 until completion; Query connections and performance may be impacted in LDW2) |
|16:00 | 19:00 |24:00 | Active | Load | Batch 3 is loaded into LDW 2, while LDW 1 becomes the primary |
|20:00 | 23:00 |04:00 | Active | PAUSE | Admin pauses the Loader LDW 4 hours into the loading cycle |

# Data Warehouse Flip Operation
This transition of a LDW from Load to Active and vice versa a.k.a the "Flip Operation" is done every T hours where T is configurable by the user.
The flip operation is executed through the following steps
1. Once the current UTC time is past the end time of the current flip interval of T hours, a flip operation is initiated which needs to transition the currently Active LDW to Load status
and the next-to-be-Active Load LDW into Active status. If there are no LDWs in Load state then no flip will happen. If there are more than 1 LDW in Load state then the next LDW in sequence after the currently Active LDW is picked as the one to be flipped to Active state.
2. Once a flip operation is initiated the following conditions are checked before a Load LDW can be switched to Active state
    a. Each Load PDW in the Load LDW is transitioned to StopLoading state when no new load jobs for the PDW are started and the it waits for current load jobs to complete
    b. StopLoading PDW is transitioned to ScaleToActive state when current load jobs have completed and PDW's DWU capacity is being scaled up to higher capacity for servicing requests
    c. ScaleToActive PDW is transitioned to Active state when it can actively serve user queries
3. Once each PDW in the next-to-be-Active LDW are flipped to Active state, the direct query nodes pointing to the PDWs of the previously Active LDW are switched to point to the newly Active ones.
4. The above steps happen in a staggered manner such that Direct Query nodes don't change PDW connections all at once.This is to ensure that no existing user connections are dropped. A connection drain time is allowed when a Direct Query node stops accepting new requests but completes processing its existing requests before it can flip to the newly Active PDW.
5. Once all the PDWs have switched to Active state, the Active PDWs of the previously Active LDW are then transitioned into Load state after being scaled down to a lower DWU capacity.
6. A record is inserted in the database containing the timestamp when the next flip operation will be initiated and the all the above steps are repeated once the current UTC time is past that timestamp

**Importantly, are there any timing instructions for the Admin to restart the process**
The flip interval of T hours is a configurable property and can be set by the Admin by updating a ControlServer database property
When the next flip time comes around, this value will be used to set the next flip interval.
If the Admin wants to flip immediately then the end timestamp of the current flip interval will need to be updated to current UTC time in the LDWExpectedStates db table and flip operation should be initiated in the next couple of minutes.

**What other situations will require Admin intervention**
The flip operation requires a Load PDW to satisfy certain conditions before it can be made Active. These are explained in 2.a - 2.c of Data Warehouse Flip Operation. If load jobs get stuck or if scaling takes a long time, flip operation will be halted. If all the Direct Query nodes die, even then flip operation will not be triggered because currently ASDQ daemons initiate flip operation. Admin intervention will be required to address these.

**Explain what other steps the Admin should NOT do with the flip pattern**
Once a flip operation is started, Admin should not try to change the state of PDWs or LDWs by themselves. Since these states are maintained in the job manager's database, any mismatch between those and the real state will throw off the flip operation. If any of the PDWs die , Admin needs to get it back into the state as was last recorded in the database.

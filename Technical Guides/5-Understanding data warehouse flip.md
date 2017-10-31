# Data Warehouse Flip Operation 

The Logical Data Warehouse Sets( each set being a group of Physical Data Warehouses by availability region) iterate through "Load" and "Active" states when the system is running. A LDW can also be in "Standby" state if it is not being actively used in the data warehousing process. The 3 states are defined below
- Load: The LDW set is processing uploaded data files to "catch-up" to the latest and greatest data.
- Standby:The LDW is not processing updates nor serving customers; it is a hot-standby with “best available” data staleness for disaster recovery purposes.
- Active: The LDW is up-to-date and serving requests but not receiving any additional data loads.

### Anatomy of a Logical Data Warehouse Flip

This transition of a LDW from Load to Active and vice versa a.k.a the "Flip Operation" is done every T hours where T is configurable by the user.
The flip operation is triggered by daemons which run as scheduled task on each of the Analysis Server Direct Query (ASDQ) Nodes.


Every few minutes each daemon running on each ASDQ node queries the job manager if a LDW flip needs to happen.

1. The job manager maintains a database table "LDWExpectedStates" which stores the start and end times of the current flip interval. It consists of records that define which LDW is in Load state and which is in Active state and until what time they are supposed to be in those states.
2. On being queried by the ASDQ daemon, job manager queries this table and checks if its past the end time of the current flip interval else it responds with a No-Op. If the current UTC time is past the endtime, then flip operation needs to be executed and the following steps are executed.

    a. The LDW which needs to be Active in the next flip interval is determined and LDWExpectedStates table is populated with details regarding the start and end time of the next flip interval. The endtime stamp is determined by adding T hours to the start time which is the current UTC time. If there are no LDWs in Load state then no flip will happen. If there are more than 1 LDW in Load state then the next LDW in sequence after the currently Active LDW is picked as the one to be flipped to Active state.

    b. The state of the next-to-be-Active LDW is switched to Active state and the state transitions of its PDWs from Load to Active are initiated

3. PDW state transition from Load to Active goes through a couple of intermediate steps as follows
a. Load : The PDW is processing uploaded data files to "catch-up" to the latest and greatest data.
b. StopLoading : The PDW will not be accepting any new data load jobs but will wait till the current load jobs complete
c. ScaleUpToActive : State indicating that the PDW has completed all its assigned load jobs and is being scaled up to Active DWU capacity
d. Active - PDW is up-to-date and serving requests but not receiving any additional data loads.

4. Once a PDW is changed to Active state, job manager checks if there is at least 1 DQ node in the "DQ Alias group" which is still serving active queries. A "DQ Alias group" is the group of DQ nodes which point to the same PDW instance in an LDW. Multiple DQ nodes can point to the same PDW. This is ensure that we can increase the availability of DQs if we need to, assuming the PDW can support concurrent queries from all these DQs. Checking at least 1 DQ is in active state ensures new requests do not get dropped. If this check succeeds a "Transition" response is sent to the DQ node which stops accepting new connections from the DQ LoadBalancer and drains off the existing connections. Once the grace time is over, the DQ changes its connection string to point to the newly Active PDW and reports to job manager which then allows other ASDQs to start their transitions.

5. Once all the DQs in a "DQ Alias group" have flipped to a different PDW, the group's original PDW is transitioned to a Load state after scaling down its DWU capacity.
6. After all the Active PDWs of the previously Active LDW have been transitioned to Load state, the state of the LDW is changed to Load state. This marks the end of the flip operation.

Here is an example schedule showing how the Flip Operation occurs using the following configuration
2 LDWS : LDW01, LDW02
2 PDWS : PDW01-LDW01 (LDW01), PDW01-LDW02 (LDW02)
2 DQ Nodes : DQ01(points to PDW01-LDW01), DQ02(points to PDW01-LDW01)
ASDQ daemon schedule - 1 minute
Connection Time Drain - 10 minutes

| UTC | LDW01 | LDW02 | PDW01-LDW01 | PDW01-LDW02 | DQ01 | DQ02 |
|:----|:----|:----|:----|:----|:----|:----|
|00:00 | Active | Load | Active | Load | Normal : PDW01-LDW01 | Normal : PDW01-LDW01 |
|00:01 | Active | Load | Active | StopLoading | Normal : PDW01-LDW01 | Normal : PDW01-LDW01 |
|00:03 | Active | Load | Active | ScaleUpToActive | Normal : PDW01-LDW01 | Normal : PDW01-LDW01 |
|00:05 | Active | Active | Active | Active | Normal : PDW01-LDW01 | Normal : PDW01-LDW01 |
|00:06 | Active | Active | Active | Active | Transition : PDW01-LDW01 | Normal : PDW01-LDW01 |
|00:16 | Active | Active | Active | Active | ChangeCompleted : PDW01-LDW02 | Normal : PDW01-LDW01 |
|00:26 | Active | Active | Active | Active | ChangeCompleted : PDW01-LDW02 | Transition : PDW01-LDW01 |
|00:27 | Active | Active | ScaleDownToLoad | Active | Normal : PDW01-LDW02 | Normal : PDW02-LDW02 |
|00:29 | Load | Active | Load | Active | Normal : PDW01-LDW02 | Normal : PDW02-LDW02 |


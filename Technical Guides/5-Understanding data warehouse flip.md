# Anatomy of a Logical Data Warehouse Flip

> For a detailed description of the LDW transition states (`Active`, `Standby`, `Load`), please read [LDW States and Availability](./4-Understanding%20logical%20datawarehouses.md#logical-data-warehouse-status-and-availability)

The transition of a LDW from `Load` to `Active` and vice versa a.k.a the "Flip Operation" is done every T hours where T is configurable by the user.
The flip operation is triggered by daemons which run as scheduled tasks on each of the Analysis Server Direct Query (ASDQ) Nodes.

Every few minutes each daemon running on each ASDQ node queries the job manager if a LDW flip needs to happen.

## Step-by-Step

1. The Job Manager maintains a database table "LDWExpectedStates" which stores the start and end times of the current flip interval. It consists of records that define which LDW is in `Load` state and which is in `Active` state and until what time they are supposed to be in those states.
2. On being queried by the ASDQ daemon, job manager queries this table and checks if its past the end time of the current flip interval else it responds with a No-Op. If the current UTC time is past the endtime, then flip operation needs to be executed and the following steps are executed.
    * (a) The LDW which needs to be `Active` in the next flip interval is determined and `LDWExpectedStates` table is populated with details regarding the start and end time of the next flip interval. The endtime stamp is determined by adding T hours to the start time which is the current UTC time. If there are no LDWs in `Load` state then no flip will happen. If there are more than 1 LDW in `Load` state then the next LDW in sequence after the currently active LDW is picked as the one to be flipped to `Active` state.

    * (b) The state of the next-to-be-Active LDW is switched to `Active` state and the state transitions of its PDWs from `Load` to `Active` are initiated

3. PDW state transition from `Load` to `Active` goes through a couple of intermediate steps as follows
    * (a) `Load`: The PDW is processing uploaded data files to "catch-up" to the latest and greatest data.
    * (b) `StopLoading`: The PDW will not be accepting any new data load jobs but will wait till the current load jobs complete
    * (c) `ScaleUpToActive`: State indicating that the PDW has completed all its assigned load jobs and is being scaled up to Active DWU capacity
    * (d) `Active` - PDW is up-to-date and serving requests but not receiving any additional data loads.

4. Once a PDW is changed to `Active` state, job manager checks if there is at least 1 DQ node in the "DQ Alias group" which is still serving active queries. A "DQ Alias group" is the group of DQ nodes which point to the same PDW instance in an LDW. Multiple DQ nodes can point to the same PDW. This is to ensure that we can increase the availability of DQs if we need to, assuming the PDW can support concurrent queries from all these DQs. Checking at least 1 DQ is in `Active` state ensures new requests do not get dropped. If this check succeeds a "Transition" response is sent to the DQ node which stops accepting new connections from the DQ LoadBalancer and drains off the existing connections. Once the grace time is over, the DQ changes its connection string to point to the newly active PDW and reports to job manager which then allows other ASDQs to start their transitions.

5. Once all the DQs in a "DQ Alias group" have flipped to a different PDW, the group's original PDW is transitioned to a `Load` state after scaling down its DWU capacity.
6. After all of the Active PDWs of the previously Active LDW have been transitioned to `Load` state, the state of the LDW is changed to `Load` state. This marks the end of the flip operation.

## Example
Here is an example schedule showing how the Flip Operation occurs using the following configuration
* 2 LDWS: `LDW01`, `LDW02`
* 2 PDWS: `PDW01-LDW01` (LDW01), `PDW01-LDW02` (LDW02)
* 2 DQ Nodes: `DQ01` (points to PDW01-LDW01), `DQ02` (points to PDW01-LDW01)
* ASDQ daemon schedule: 1 minute
* Connection Time Drain: 10 minutes

| UTC | LDW01 | LDW02 | PDW01-LDW01 | PDW01-LDW02 | DQ01 | DQ02 |
|:----|:----|:----|:----|:----|:----|:----|
|00:00 | Active | Load | Active | Load | Normal : PDW01-LDW01 | Normal : PDW01-LDW01 |
|00:01 | Active | Load | Active | `StopLoading` | Normal : PDW01-LDW01 | Normal : PDW01-LDW01 |
|00:03 | Active | Load | Active | `ScaleUpToActive` | Normal : PDW01-LDW01 | Normal : PDW01-LDW01 |
|00:05 | Active | `Active` | Active | `Active` | Normal : PDW01-LDW01 | Normal : PDW01-LDW01 |
|00:06 | Active | Active | Active | Active | `Transition` : PDW01-LDW01 | Normal : PDW01-LDW01 |
|00:16 | Active | Active | Active | Active | `ChangeCompleted` : PDW01-LDW02 | Normal : PDW01-LDW01 |
|00:26 | Active | Active | Active | Active | ChangeCompleted : PDW01-LDW02 | `Transition` : PDW01-LDW01 |
|00:27 | Active | Active | `ScaleDownToLoad` | Active | `Normal` : PDW01-LDW02 | Normal : PDW02-LDW02 |
|00:29 | `Load` | Active | `Load` | Active | Normal : PDW01-LDW02 | Normal : PDW02-LDW02 |

## FAQ
**Are there any timing instructions for the Admin to restart the process?**  
The flip interval of T hours is a configurable property and can be set by the Admin by updating a ControlServer database property
When the next flip time comes around, this value will be used to set the next flip interval.
If the Admin wants to flip immediately then the end timestamp of the current flip interval will need to be updated to current UTC time in the LDWExpectedStates db table and flip operation should be initiated in the next couple of minutes.

**What other situations will require Admin intervention?**  
The flip operation requires a Load PDW to satisfy certain conditions before it can be made Active. These are explained in 2.a - 2.c of Data Warehouse Flip Operation. If load jobs get stuck or if scaling takes a long time, flip operation will be halted. If all the Direct Query nodes die, even then flip operation will not be triggered because currently ASDQ daemons initiate flip operation. Admin intervention will be required to address these.

**What other steps should the Admin NOT do with the flip pattern?**  
Once a flip operation is started, Admin should not try to change the state of PDWs or LDWs by themselves. Since these states are maintained in the job manager's database, any mismatch between those and the real state will throw off the flip operation. If any of the PDWs die , Admin needs to get it back into the state as was last recorded in the database.

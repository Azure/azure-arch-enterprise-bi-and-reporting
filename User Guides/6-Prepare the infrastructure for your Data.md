# Prepare the infrastructure for your Data

## Summary
This page lists the steps to prepare your deployment for ingesting your own data.

## 1. Install VPN Client

- Confirm that your client machine has the two certificates installed for VPN connectivity to the VM see [prerequisites](./1-Prerequisite%20Steps%20Before%20Deployment.md") for more details.
- Login to the [Azure portal](http://portal.azure.com) and find the Resource Group that corresponds to the VNet setup. Pick the **Virtual Network** resource, and then the **Virtual Network Gateway** in that resource.
- Click on **Point-to-site configuration**, and **Download the VPN client** to the client machine.
- Install the `64-bit (Amd64)` or `32-bit (x86)` version, depending on your local Windows operating system. The modal dialog that pops up after you launch the application may show up with a single **Don't run** button. Click on **More**, and choose **Run anyway**.
- Finally, choose the relevant VPN connection from **Network & Internet Settings**. This should set you up for the next step.


## 2. Stopping Data generation

The TRI deploys a dedicated VM for data generation, with a PowerShell script placed in the VM. The PowerShell script is scheduled to run every 3 hours. We need to login into the VM and disable the schedule.

* Get the IP address of your data generator VM: From the portal, open the resource group in which the TRI is deployed (this will be different than the VNET resource group) and look for a VM with the name ending in `dgvm00`. 
* Click the VM name.
* Click on the **Networking** tab for that specific VM and find the private IP address at the top of the blade.
* Connect to the VM: Use Remote Desktop to connect to the VM using its IP address and the admin username and password that you specified as part of the deployment parameters. *You must be connected to the VPN in order to connect to the VM*.
* Start the `Task Scheduler` app and disable the task named "Generate and upload data".


## 3. Drop AdventureWorks tables

As part of the initial deployment, the TRI installs AdventureWorks tables in the data warehouse. We need to drop the tables in all the physical data warehouse instances to create a clean schema for your organization.

* Login into the physical data warehouse:
  > As a pre-requisite, install either [SSMS](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms) or [SQLCMD](https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility) on your local computer, based on your personal preference.
  
  From the Azure Portal, get the list of SQL Data Warehouses (SQL DWs) installed in your resource group. Click on each server and ensure that the firewall setting in each DW allows your client machine to connect. Connect to the SQL DWs based on your client tool preference.
* Drop the tables: Once you log into the SQL DW database named "dw", you will be able to view the list of tables created in the dbo schema. Use the `Drop` command to drop all 29 AdventureWorks tables.

## 4. Size your data warehouse: 

As part of the initial deployment, the SQL DW physical instances are setup at DWU 100 to demonstrate the solution. Based on the data load volumes and query volumes, you will need to scale the SQL DW instances. Further details on sizing for scale are available [here](https://docs.microsoft.com/en-us/azure/sql-data-warehouse/sql-data-warehouse-manage-compute-overview).

Once you have determined the needed DWUs for your workload, the correct numbers must be updated in the Job Manager SQL Server instance. You can login into Azure portal and locate the ctrldb server in the solution resource group. Login into the SQL server instance and update the dbo.ControlServerProperties table. For example, if you determine that you need DWU 1000 for loading and 2000 for queries, run the following SQL.

```sql
/* Updating Reader to 2000 */

update dbo.ControlServerProperties
SET value = 2000
Where Name = 'ComputeUnits_Active'

/* Updating Loader to 1000 */

update dbo.ControlServerProperties
SET value = 1000
Where Name = 'ComputeUnits_Load'
```

## 5. Optionally override the initial setting for flip time

As part of the initial deployment, the data warehouses Reader and Loader are scheduled to *Flip* every 2 hours. This implies that you have a refresh cycle of 2 hours. Each organization will have different refresh cycles based on their business requirements. The flip time is controlled by a property in the ControlServerProperties table and can be changed as follows. 

```sql
/* Update the Flip time to 8 hours. */

update dbo.ControlServerProperties
SET value = 8
Where Name = 'FlipInterval'
```

The above command changes the Flip time to every 8 hours.

## 6. Create fact and dimension tables in all the physical data warehouses - both loader and reader.

You will need to create tables in both of the data warehouses (Loader and Reader). Since SQL DW is based on MPP technology, please read the [documentation](https://docs.microsoft.com/en-us/azure/sql-data-warehouse/sql-data-warehouse-tables-overview) on how to create tables.


#### Example Create Table Region

```sql
CREATE TABLE REGION (
r_regionkey integer not null,
r_name  char(25) not null,
r_comment   varchar(152) not null
)
WITH
    (
      DISTRIBUTION = round_robin,
      CLUSTERED COLUMNSTORE INDEX
    )
```

Create all the tables needed for your organization.



## 7. Insert entries in the mapping DW-Table in the Job Manager SQL Database.

Once the tables are created, the next step is to insert entries in Job Manager database so that, when a file is uploaded and registered with Job Manager, the correct data factory pipeline is created to load data into the SQL DW instances.

#### Example Entry for Region Table

```sql
insert into dbo.DWTables
(Name,Type,RunOrder,LoadUser,Id,CreationDate_UTC,createdby,LastUpdatedDate_UTC,lastupdatedby)
values
('dbo.regions','Fact',0,'edw_loader_mdrc',0,sysdatetime(),'admin',sysdatetime(),'admin');
```

Insert entries for all the tables you have created in Step 6.

Steps:
1. Stop all DataGen schedule
2. Drop AdventureWorks table in all the physical data warehouses - both loader and reader.
3. Size your data warehouse
4. Optionally override the initial setting for flip time
5. Create fact and dimension tables in all the physical data warehouses - both loader and reader.
6. Insert entries in the mapping DW-Table in the Job Manager SQL Database.


# Summary
This page lists the steps you need to take for preparing the installed Infrastructure for ingesting your own data


## 1. Stopping Data generation #

The TRI deploys a dedicated VM for data generation, with a Powershell script placed in the VM. The Powershell script is scheduled to run every X hours. We need to login into the VM and disable the schedule

* Get the IP address for data generator VM: From the portal, open the resource group in which the TRI is deployed (this will be different than the VNET resource group), and look for a VM with the string 'dgvm' in its name. 
* Choose (i.e. click on) the VM, click on **Networking** tab for that specific VM, and find the private IP address that you can remote to.
* Connect to the VM: Remote Desktop to the VM using the IP address with the admin account and password that you specified as part of the pre-deployment checklist. You need to make sure that you have the VPN'ed into the network.
* Start Task Scheduler and disable the task named "Generate and upload data"


## 2. Drop AdventureWorks tables

As part of the initial deployment, the TRI installs AdventureWorks tables in the Datawarehouse. We need to drop the tables in all the physical datawarehouse instances to create a Clean Schema for your organization.

* Login into the Physical Datawarehouse: As a pre-requisite, install SSMS or  SQLCMD based on your personal preference. From the Azure Portal , get the list of SQL Datawarehouse's installed into your resource group. Click on each server and ensure that the firewall setting in each DW allows your client machine to connect. Connect to the SQL DW's based on your preference of a client tool

* Drop the tables: Once you login into SQL DW database named "dw", you will be able to view the list of tables created in the dbo Schema. Use the Drop command to drop all the 29 AdventureWorks tables.

## 3. Size your datawarehouse: 

AS part of the initial deployment, the SQL DW physical instances are setup at DWU 100 to demonstrate the solution. Based on the data load volumes and query volumes , you will need to scale the SQL DW instances. Further details on sizing for scale are available [here](https://docs.microsoft.com/en-us/azure/sql-data-warehouse/sql-data-warehouse-manage-compute-overview)
Once you have determined the needed DWU's for your workload, the correct numbers have to update in the Job Manager  the Job Manager SQL Server instance. You can login into Azure portal and locate the ctrldb server in the solution resource group. Login into the SQL server instance and update the dbo.ControlServerProperties table. For E.g If you detemine that you need DWU 1000 for Load and 2000 for queries, run the following SQL.

Updating Reader to 2000

*update dbo.ControlServerProperties
SET value = 2000
Where Name = 'ComputeUnits_Active'*

Updating Loader to 1000

*update dbo.ControlServerProperties
SET value = 1000
Where Name = 'ComputeUnits_Load'*


## 4. Optionally override the initial setting for flip time

 As part of the initial deployment the datawarehouses Reader and Loader are scheduled to Flip every 2 hours. This implies that you have a refresh cycle of 2 hours. Each organization will have different refresh cycles based on the business requirement. The flip time is controlled by a property in the ControlServerProperties Table and can be changed. 

Update the Flip time to 8 hours.

*update dbo.ControlServerProperties
SET value = 8
Where Name = 'FlipInterval'*


## 5. Create fact and dimension tables in all the physical data warehouses - both loader and reader.
You will need to create tables in both the datawarehouses (Loader and Reader). Since SQL DW is based on MPP technology , please read the documentation [Link](https://docs.microsoft.com/en-us/azure/sql-data-warehouse/sql-data-warehouse-tables-overview) on how to create tables.

E.g Create table region

*CREATE TABLE REGION (
r_regionkey integer not null,
r_name  char(25) not null,
r_comment   varchar(152) not null
)
WITH
    (
      DISTRIBUTION = round_robin,
      CLUSTERED COLUMNSTORE INDEX
    )*


Create all the tables needed for your organization.


## 6. Insert entries in the mapping DW-Table in the Job Manager SQL Database.

Once the tables are created, next step is to insert entries in Job Manager Database , so that when a file is uploaded and registered with Job Manager , the correct ADF pipeline is created to load into SQL DW instances.

E.g Entry for Region Table

*insert into dbo.DWTables*
*(Name,Type,RunOrder,LoadUser,Id,CreationDate_UTC,createdby,LastUpdatedDate_UTC,lastupdatedby)*
*values*
*('dbo.regions','Fact',0,'edw_loader_mdrc',0,sysdatetime(),'admin',sysdatetime(),'admin');*


Insert entries for all the tables you have created in Step 5.








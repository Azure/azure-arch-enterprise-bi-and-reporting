# Load historical data into tabular models.

## Summary 

This file contains steps to refresh the SSAS Models with historical loads.

## 1. Data Model for SSAS.
Please ensure that you have created the SSAS models and configured them in the job Manager as indicated in [Configure SQL Server Analysis Services](./8-Configure%20SQL%20Server%20Analysis%20Services.md)

## 2. Locate the Partition Builder Machine.
* Login into Azure Portal and locate your resource group. In the list of resources search for partition builder Virtual Machine ssaspb
* Remote Desktop into the Machine using your credentials.
* Start SSMS and connect to Analysis Server.
* Process the Model for full refresh.


## 3. Copy database to SSAS RO nodes
There are multiple ways you can sync up the SSAS tabular model from Partition builder to SSAS RO nodes. One way is to backup the [database and restore](https://docs.microsoft.com/en-us/sql/analysis-services/multidimensional-models/backup-and-restore-of-analysis-services-databases) on each RO node. Another option is to use the following [link](https://docs.microsoft.com/en-us/sql/analysis-services/multidimensional-models/synchronize-analysis-services-databases)


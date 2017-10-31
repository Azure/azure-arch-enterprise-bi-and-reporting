# Load historical data into tabular models.

## Summary 

This file contains steps to refresh the SSAS Models with historical loads.

## 1. Data Model for SSAS.
Please ensure that you have created the SSAS models and configured them in the job Manager as indicated in [Configure SQL Server Analysis Services](./8-Configure%20SQL%20Server%20Analysis%20Services.md)

## 2. Locate the Partition Builder Machine.
* Login into Azure Portal and locate your resource group. In the list of resources search for Virtual Machine ssaspb
* Remote Desktop into the Machine using your credentials.
* Start SSMS and connect to Analysis Server.
* 
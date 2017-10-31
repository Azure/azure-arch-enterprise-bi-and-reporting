# User Guide for  for Enterprise BI and Reporting

The guide is organized along the sequence of steps that you need to follow to deploy and operationalize the TRI. You can return to specific sections once you have successfully deployed the TRI end to end (i.e. after you have completed all the steps until Step 15 below). If the deployment is blocked at any stage, consult the Get Help and Support section for mitigation and workarounds.

- Step 1 - It is assumed that you have an Azure subscription. If not, [obtain a subscription](https://azure.microsoft.com/en-us/free/?v=17.39a). Then implement these [prerequisite steps before deployment](./1-Prerequisite%20Steps%20Before%20Deployment.md)

- Step 2 - Next, [set up the deployment](./2-Set%20up%20Deployment.md), starting from either the GitHub repository, or the Cortana Gallery.

- Step 3 - Azure is a dynamic environment, and the TRI has several products in its architecture. Please monitor the deployment progress. If the deployment fails or stalls at a given step, you can [troubleshoot the deployment](./3-Troubleshoot%20the%20Deployment.md).

- Step 4 - Once the deployment completes with success, you can [manage the deployed infrastructure](./4-Manage%20the%20Deployed%20Infrastructure.md) from an Admin console that is provided as part of the TRI.

- Step 5 - You may also want to [monitor the deployed components](./5-Monitor%20the%20Deployed%20Components.md) individually - such as the SQL DW, SSAS, and SSRS servers, the VMs, load balancers, and other components, as part of monitoring the end to end system.

- Step 6 - Once the infrastructure has been deployed in the subscription, the next step is to [prepare the infrastructure to ingest your data](./6-Prepare%20the%20infrastructure%20for%20your%20Data.md). This includes optionally removing any demo data and models that are currently in SQL DW and the SSAS servers.

- Step 7 - The default data generator that is shipped with the TRI needs is programmed to load demo data files. So you need to modify this script to [configure the data ingestion](./7-Configure%20Data%20Ingestion.md) into the SQL Data Warehouse.

- Step 8 - Once SQL DW is configured for data ingestion, the next step is to [configure the SQL Server Analysis Services](./8-Configure%20SQL%20Server%20Analysis%20Services.md) for generation of analytical tabular models for interactive BI, and the models enabling direct query access for SSRS report generation.

- Step 9 - Next, [configure SQL Server Reporting Services](./9-Configure%20SQL%20Server%20Reporting%20Services.md) to generate and serve reports.

- Step 10 - To enable interactive BI against the SSAS cached models, [configure Power BI](./10-Configure%20Power%20BI.md) gateway to connect to the SSAS read-only servers through the front end load balancers, and the Power BI clients for dashboard access.

- Step 11 - Now that all the data engines are set up, your next step is to do an [one-time load of historical data into the SQL DW](./11-Load%20historical%20data%20into%20the%20warehouse.md). Skip this step if you have no historical data, and are starting your BI project from scratch.

- Step 12 - Follow this with an [one time load of all the historical tabular models](./12-Load%20historical%20tabular%20models.md).

- Step 13 - [Create and/or import dashboards and reports](./13-Create%20dashboards%20and%20reports.md) to confirm that your users are able to view the tabular model data through their PowerBI clients, and are able to receive reports.

- Step 14 - Given the reassurance that the end to end pipeline is working for data at rest, you can now confidently [set up incremental load](./14-Set%20up%20incremental%20loads.md) of data from your on-premise or cloud based data sources.

- Step 15 - Incremental data ingestion process is enabled by dynamic ADF pipelines that you may want to [monitor and troubleshoot](./15-Monitor%20and%20Troubleshoot%20Data%20Pipelines.md) as necessary.

- Step 16 - If you face any issues with the deployment, consult the [frequently asked questions](16-Frequently%20Asked%20Questions.md).

- Step 17 - [Get help and support](./17-Get%20Help%20and%20Support) for any of the above steps from the documentation and additional resources provided with the TRI.

- Step 18 - Finally, for any number of reasons, if you'd like to remove the deployed implementation from your subscription, you can follow these steps for [deleting the deployment](./18-Deleting%20a%20deployment).


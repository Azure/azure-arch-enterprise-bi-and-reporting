
# Technical Reference Implementation for Enterprise BI and Reporting

Azure offers a rich data and analytics platform for customers and ISVs seeking to build scalable BI and Reporting solutions. However, customers face pragmatic challenges in building the right infrastructure for enterprise-grade, production systems. They have to evaluate the various products for security, scale, performance and geo-availability requirements. They have to understand service features and their interoperability, and plan to address any perceived gaps with custom software. This takes time and effort, and many times, the end to end system architecture they design around thier product choices yields sub-optimal results. Consequently, the promise and expectations set during proof-of-concept (POC) stages do not translate to robust production systems in the expected time to market.

This TRI addresses this customer pain by providing a reference implementation that (a) is pre-built based on selected, stable Azure components proven to work in enterprise BI and reporting scenarios, (b) can be easily configured and deployed to an Azure subscription within a few hours, (c) is pre-built with software to handle all the operational essentials for a full fledged production system, and (d) is tested end to end against large workloads. Once deployed, the TRI can be used as-is, or customized to fit the application needs using the technical documentation that is provided with the TRI.

This liberates the customer to build the software that delivers the business goals based on a robust and functional foundational infrastructure.

# Audience
Business decision makers and evaluators can review the content in the **Solution Overview** folder that explain the benefits of using the TRI versus building a similar system from scratch.

For more information on how to tailor the TRI for your needs, **connect with one of our trained partners**.

It is recommended that the TRI is reviewed and deployed by a technical audience that is familiar with operational concepts in data warehousing, business intelligence, and analytics. Knowledge of Azure is a plus, but not mandatory. The technical guides provide pointers to Azure documentation for all the resources employed in this TRI.

# How to Deploy
The TRI can be deployed from http://gallery.cortanaintelligence.com/azure-arch-enterprise-bi-and-reporting
Click on the Deploy button on the right pane, and follow the instructions to fill in the input configuration parameters based on your application.

# Architecture

![Architecture](./img/azure-arch-enterprise-bi-and-reporting.png)

The TRI is designed with the initial premise that a customer desires to move data from an existing reporting and BI solution powered by a data warehouse into Azure. A key assumption is that the data ingested into the system is already ETL-processed to be loaded into a data warehouse.

The TRI has 4 stages: Ingestion, Processing, Analysis and Reporting, and Consumption.
1.	A data generator, provided in place of the customer's data source, queries the job manager for a staging [Azure Blob](https://docs.microsoft.com/en-us/azure/storage/) storage. The job manager returns the handle to an ephemeral BLOB, and the data generator pushes data files into this storage. [Configure the data ingestion](https://msdata.visualstudio.com/AlgorithmsAndDataScience/TRIEAD/_git/CIPatterns?_aConfiguringDataIngestion.md) module to load actual customer data.
2.	When the job manager detects fresh data in the Azure Blob, it creates a dynamic [ADF](https://docs.microsoft.com/en-us/azure/data-factory/v1/data-factory-introduction) pipeline to load the data from the Blob into a "logical" _Loader_ SQL DW, using [Polybase](https://docs.microsoft.com/en-us/sql/relational-databases/polybase/get-started-with-polybase). The logical DW is a scale-out and redundancy architecture to allow for multiple physical DW. It also enables a Loader-Reader pair of Data Warehouses to provide the required enterprise-grade scale for concurrent read-write operations.
operations. More details are provided in **[Configuring Logical Data Warehouse]**
3.	After a preconfigured duration, the job manager flips the Loader DW to become the _Reader_ SQL DW, ready to serve queries for report generation. The current Reader flips to become the Loader, and the job manager starts data load on the Loader. This Loader-Reader pair 
4.	Interactive BI is best served by cached analytical models in cubes that allow  fast drilldowns for summaries aggregated over various dimensions or pivots. This stage involves multiple steps to generate and serve these analytical models in a highly available manner.
    - The Analytical model cache consists of a [SSAS partition builder](https://docs.microsoft.com/en-us/sql/analysis-services/multidimensional-models-olap-logical-cube-objects/partitions-analysis-services-multidimensional-data), and an [availability-set of SSAS read-only servers](https://docs.microsoft.com/en-us/sql/analysis-services/instances/high-availability-and-scalability-in-analysis-services).
    - The job manager manages the mapping between the analytic (tabular) models stored in the cache and their source data tables in the data warehouse. As data arrives into tables in the _Loader_ SQL DW, the partition builder is instructed by the job manager to start rebuilding the tabular models by querying the relevant tables in data warehouse.
    - When the loader flips to become the reader, this flip event triggers the partition builder to _commit_ the completed tabular models into Blob storage.
    - When the job manager detects the availability of a tabular model, it coordinates a round robin refresh of the SSAS Read-Only nodes in the availability set, and the front end load balancer, as follows: (a) drain the existing connections to the SSAS-RO node (b) replace the tabular model in that node (c) open up the node for new interactive BI connections (d) move to the next one.
5. Power BI dashboards connect to the tabular models in SSAS RO nodes via a Power BI gateway that you can set up in your subscription, as explained [here](https://msdata.visualstudio.com/AlgorithmsAndDataScience/TRIEAD/_git/CIPatterns?_a=preview&path=%2Fdoc%2FConfiguringPowerBI.md).
6. For reporting, SSRS generates the report from data in the SQL DW via SSAS Direct Query. SSAS also offers row level security for the data fetched from SQL DW.
7. You can schedule report generation with SSRS using the Report Builder client tool. The generated reports are stored in SSRS servers. You can enable email based delivery of reports to users.

# How to Delete a Deployment
The TRI creates the end to end system in a dedicated resource group provided by you. Login to http://portal.azure.com, and delete this resource group from your subscription.

# Disclaimer

©2017 Microsoft Corporation. All rights reserved. This information is provided "as-is" and may change without notice. Microsoft makes no warranties, express or implied, with respect to the information provided here. Third party data was used to generate the solution. You are responsible for respecting the rights of others, including procuring and complying with relevant licenses in order to create similar datasets.
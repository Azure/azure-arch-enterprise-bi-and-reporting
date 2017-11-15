# Understanding Ephemeral Storage Accounts

Enterprise BI and Reporting TRI Job Manager maintains [Azure Blob](https://docs.microsoft.com/en-us/azure/storage/) accounts which serve as the staging area for the data to be ingested into TRI. The Job Manager will create a new Azure Blob account every 24 hours. After a new account is created, previously created accounts will be deleted once all the data uploaded to those accounts is successfully ingested. This ensures that one storage account contains no more than 24 hours worth of data. As a result, if one of the customer's data sources was compromised, no more than 24 hours worth of data could be impacted.

The Job Manager exposes an API to fetch the SAS URI for the currently active Storage Account. Therefore, when integrating on-prem data ingestion systems with this TRI, the first step is to always fetch the SAS URI for the currently active Azure Blob account.

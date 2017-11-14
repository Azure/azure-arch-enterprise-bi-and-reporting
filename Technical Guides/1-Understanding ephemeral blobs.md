# Understanding Ephemeral Storage Accounts

Enterprise BI and Reporting TRI Job Manager maintains Azure Storage accounts which serve as the landing spot for data to be ingested to TRI. The job manager will create a new storage account every 24 hours. After a new account is created, previously created accounts will be deleted once all the data uploaded to those accounts is successfully ingested. This ensures that one storage account contains no more than 24 hours worth of data. As a result, if one of the TRI's ingesting clients was compromised, no more than 24 hours worth of data could be impacted.

The Job Manager exposes an API to fetch the SAS URI for the currently active Storage Account. Therefore, when integrating on-prem data ingestion systems with this TRI, the first step is to always fetch the SAS URI for the currently active Storage Account.

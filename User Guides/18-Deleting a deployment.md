# Deleting the Deployment

Since the deployment provisions resources in your subscription, you will be billed for the usage. If you want to discard use of the deployment, we recommend deleting the resources that were provisioned so that you are not billed for the usage.
Since deleting the deployment will also remove the data in your physical data warehouses, please consider backing up your data before deleting the deployment.

In order to delete the deployment, please do the following:

## 1. Delete the resource group
1. Find your deployment resource group in the [Azure portal](https://portal.azure.com).
2. Click on 'Delete resource group' and follow the prompts to delete the resource group.
3. If you have locks that are preventing deletion of the resource group, you will have to find and delete them in the Locks pane for your resource group.

## 2. Delete the deployment in the Cortana Intelligence Solution Deployments
1. Find your [deployments on Cortana Intelligence Solutions](https://start.cortanaintelligence.com/Deployments/) and delete it.

## 3. Delete the Azure Active Directory applications
Since the Active Directory applications are provisioned as part of the tenant and not the subscription, they have to be deleted separately.

1. On the [Azure Portal](https://portal.azure.com), click on 'All Services' on the left menu and search for 'Azure Active Directory' to launch your Azure Active Directory Management UI.
2. Click on 'App Registrations' and enter the name of your deployment in the search bar which will show all the applications that were provisioned for this deployment.
3. Follow the prompt to open and then delete all of the applications.

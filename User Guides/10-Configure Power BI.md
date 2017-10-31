# Overview

[PowerBI](https://powerbi.microsoft.com/en-us/) is used to create live reports and dashboards that can be shared across your organization. This document describes the steps needed to create and share a PowerBI dashboard for your Enterprise Reporting and BI Technical Reference Implementation solution.

# Install PowerBI Data Gateway

## Log into the SQL Server VM

The [SQL Server Analysis Services (SSAS)](https://docs.microsoft.com/en-us/sql/analysis-services/analysis-services) installed as part of your solution is deployed in a private virtual network (VNET) on Azure. For PowerBI to access SSAS, you will need to install the [PowerBI Data Gateway](https://powerbi.microsoft.com/en-us/gateway/) on a virtual machine (VM) within this VNET.

To do this, first log into the SQL Server VM in your solution. Technically, the PowerBI Data Gateway could be installed on any of the VMs deployed as part of your solution, or even a new one, but the SQL Server VM is a good choice since it is not heavily used. You can find this VM by opening the [Azure portal](https://portal.azure.com/) and clicking **Resource groups**. Type in the name you gave for your solution, which is also used as the name of the resource group, to find your resource group. Click it, and sort the resources by type. Scroll down to the virtual machines and find the one ending in "sqlvm00". Click on this VM, then click the **Networking** link. The private IP listed is the IP address you will use to connect to the SQL Server VM.

> NOTE: Before you can connect, you must first ensure that your VPN client is running. Until it is running, you will not be able to connect.

Log in to the SQL Server VM using your preferred client, such as Remote Desktop, with the private IP address and the username and password you used for your deployment. If you are using Remote Desktop, select **More choices** > **Use a different account** to enter the username and password.

## Install the PowerBI on-premise Data Gateway

> TIP: Before downloading anything, you will want to disable the Enhanced Network Security on this VM. To do this, click **Server Manager** > **Local Server** and turn **IE Enhanced Security Configuration** to **Off** for both "Administrators" and "Users". Click **OK** to apply the changes and close **Server Manager**. This isn't required, but otherwise you will have to allow every individual download.

Using Internet Explorer on the VM (which comes pre-installed) browse to https://powerbi.microsoft.com/en-us/gateway, click **DOWNLOAD GATEWAY**, and click **Run** to begin the download. Click **Next** for all default options, accept the terms of agreement, and click **Install**. The installation takes a few minutes. Next, you need to register your gateway by entering an email address and clicking **Sign in**.

Now that you are signed in, click **Next** and give your on-premises data gateway a name and recovery key and click **Configure**. Your gateway is now ready.

# Create Dashboard using PowerBI Online

## Configure datasources

You are now ready to create a dashboard using the data in your deployment. The first thing to do is browse to  [PowerBI Online](https://powerbi.microsoft.com) and sign in. Then, click **settings** at the top and select **Manage gateways**. Click the gateway you just created the click **Add data sources to use the gateway**. Next, enter a new data source name and select **Analysis Services** for the type. For **Server** enter the SSAS load balancer's IP address. You can find this the same way you found the SQL Server VM's IP address, except this time scroll down to the load balancers and click the one ending in "ssasrolb" and clicking **Frontend IP configuration**. For **database** enter **AdventureWorks**(unless you've reconfigured your own database). For **Username** and **Password** enter the values you chose for your deployment.

> Note: **Username** here also requires the domain name which you specified during the deployment. So, **Username** should look like **DomainName** \ **Username**.

When ready, click **Add**.

## Add users to the datasource

Next you click **Users** and add all the people who can publish reports using this datasource by entering their email addresses and clicking **Add**. The email you entered in setting up the on-premises PowerBI data gateway is already used by default.

When ready, click **Map user names**. Enter the **Original name** (the user's email address) and the **New name** (the domain joined username from above) for all users. This will create mappings for each user's email id to the domain joined username for the SSAS Read Only VMs. Click [here](https://powerbi.microsoft.com/en-us/documentation/powerbi-gateway-enterprise-manage-ssas/#usernames-with-analysis-services) to learn more about usernames with Analysis Services.

When ready, click **OK**. You may need to wait a few minutes for the changes to take affect.

## Create an app workspace

Next you create a workspace. To do this, click **Workspaces** > **Create app workspace** and type a name for your workspace. If needed, edit it to be unique. You have a few options to set. If you choose Public, anyone in your organization can see what's in the workspace. Private, on the other hand, means only members of the workspace can see its contents.

> Note: You can't change the Public/Private setting after you've created the workspace.

You can also choose if members can edit or have view-only access. Add email addresses of people you want to have access to the workspace, and click **Add**. You can't add group aliases, just individuals. Decide whether each person is a member or an admin.

> Note: Admins can edit the workspace itself, including adding other members. Members can edit the content in the workspace, unless they have view-only access.

When ready, click **save**.

## Create a dataset

Now you are ready to create a report. Begin by clicking **Get Data**. Under **Databases** click **Get** > **SQL Server Analysis Services** > **Connect**. Scroll down and click on your newly created gateway. Click **AdventureWorks - Model** > **Connect**.

> TIP: You may have to click refresh on your browser to see your new dataset.

## Create a report

Under **Datasets**, click your new dataset. You can create whatever kind of report you want, but below are the steps for creating a three tabbed report showing some interesting data visualizations.

### Tab One

Under **Visualizations** select **Pie chart**. Under **Fields** expand **FactInternetSales** and drag **SalesAmount** into **Legend** and **CustomerKey** into **Values**. Under **Filters** select **SalesAmount**, enter **greater than 250000**, and click **Apply filter**.

Under **Visualizations** select **TreeMap**. Under **Fields** expand **FactInternetSales** and drag **SalesAmount** into **Values** and **OrderDate** into **Group**. Under **Filters** select **SalesAmount**, enter **greater than 250000**, and click **Apply filter**.

### Tab Two

Create a new tab. Under **Visualizations** click **Table**. Under **Fields** expand **FactInternetSales** and check all the fields. Click **Table** again, expand **FactProductInventory**, and check all fields. Click **Table** again, expand **FactResellerSales**, and check all fields. Click **Table** again, expand **FactSalesQuota**, and check all fields.

### Tab Three

Create a new tab. Under **Visualizations** click **Clustered column chart**. Under **Fields** expand **FactInternetSales** and drag **SalesAmount** to **Axis** and **CustomerKey** to **Value**. Click **CustomerKey** and select **Count (Distinct)**.

Under **Visualizations** select **Stacked column chart**. Under **Fields** expand **FactInternetSales** and drag **SalesAmount** to **Value** and **OrderDate** to **Axis**.

When ready, click **Save this report**, enter a name for your report, and click **Save**.

## Publish app

For your new workspace, click **Publish app** in the upper right to start the process of sharing all the content in that workspace. First, for **Details**, fill in the description to help people find the app. You can set a background color to personalize it. Next, for **Content**, you see the content that’s going to be published as part of the app – everything that’s in the workspace. You can also set the landing page (the dashboard or report people will see first when they go to your app) or none (in which case they’ll land on a list of all the content in the app). Last, for **Access**, decide who has access to the app: either everyone in your organization, or specific people or email distribution lists.
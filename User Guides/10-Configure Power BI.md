# Overview

[PowerBI](https://powerbi.microsoft.com/en-us/) is used to create live reports and dashboards that can be shared across your organization. This document describes the steps needed to create and share a PowerBI dashboard for your Enterprise Reporting and BI Technical Reference Implementation solution.

# Install PowerBI Data Gateway

The [SQL Server Analysis Services (SSAS)](https://docs.microsoft.com/en-us/sql/analysis-services/analysis-services) installed as part of your solution is deployed in a private virtual network (VNET) on Azure. For PowerBI to access SSAS, you will need to install the [PowerBI Data Gateway](https://powerbi.microsoft.com/en-us/gateway/) on a virtual machine (VM) within this VNET.

The following are the steps to install the PowerBI Data Gateway on your VM.

## Download the PowerBI Data Gateway installer locally

First, from your local environment, browse to https://powerbi.microsoft.com/en-us/gateway, click **DOWNLOAD GATEWAY**, and click **Save As** to download the installer executable to a folder in your local environment. You will next upload and run this installer executable on your SQL Server VM.

## Log into the SQL Server VM

Now, log into the SQL Server VM in your solution. Technically, the PowerBI Data Gateway could be installed on any of the VMs deployed as part of your solution, or even a new one, but the SQL Server VM is a good choice since it is not heavily used. You can find this VM by opening the [Azure portal](https://portal.azure.com/) and clicking **Resource groups**. Type in the name you gave for your solution, which is also used as the name of the resource group, to find your resource group. Click it, and sort the resources by type. Scroll down to the virtual machines and find the one ending in "sqlvm00". Click on this VM, then click the **Networking** link. The private IP listed is the IP address you will use to connect to the SQL Server VM.

> NOTE: Because your VM is running in a VNET, you must first ensure that your VPN client is running before you can connect to your VM. Until it is running, you will not be able to connect.

Log in to the SQL Server VM using your preferred client, such as Remote Desktop, with the private IP address and the username and password you used for your deployment. If you are using Remote Desktop, select **More choices** > **Use a different account** to enter the username and password.

## Upload the PowerBI Data Gateway installer and install

Copy the installer executable from your local environment onto the VM. If you are using Remote Desktop, you can do this by copying the file locally and pasting it onto the desktop of the VM.

Once there, double click it to begin the installation. Click **Next** for all default options, accept the terms of agreement, and click **Install**. The installation takes a few minutes. Next, you need to register your gateway by entering an email address and clicking **Sign in**.

Now that you are signed in, click **Next** and give your on-premises data gateway a name and recovery key and click **Configure**. Your gateway is now ready.

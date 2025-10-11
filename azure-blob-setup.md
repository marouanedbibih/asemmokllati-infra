# Azure Blob Storage Setup for Terraform State

## 1. Create Resource Group for Terraform State
az group create --name tfstate-rg --location westeurope

## 2. Create Storage Account (must be globally unique)
az storage account create --name mar1dbterraform --resource-group tfstate-rg --location westeurope --sku Standard_LRS

## 3. Create Blob Container
az storage container create --name tfstate --account-name mar1dbterraform

## 4. Get Storage Account Key
az storage account keys list --resource-group tfstate-rg --account-name mar1dbterraform

## 5. Configure Backend in Terraform
Add the following to your Terraform config:

```
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatemanagement"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
```

## 6. Initialize Backend
Run this in your Terraform project directory:

```
terraform init
```

Terraform will prompt you for the storage account key if needed.

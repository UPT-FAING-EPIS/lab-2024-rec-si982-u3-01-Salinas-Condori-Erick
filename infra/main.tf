terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0.0"
    }
  }
  required_version = ">= 0.14.9"
}

variable "suscription_id" {
    type = string
    description = "Azure subscription id"
}

variable "sqladmin_username" {
    type = string
    description = "Administrator username for server"
}

variable "sqladmin_password" {
    type = string
    description = "Administrator password for server"
}

provider "azurerm" {
  features {}
  subscription_id = var.suscription_id
}

# Generate a random integer to create a globally unique name
resource "random_integer" "ri" {
  min = 100
  max = 999
}

# Create the resource group
resource "azurerm_resource_group" "rg" {
  name     = "upt-arg-101"
  location = "centralus"
}

resource "azurerm_storage_account" "storageaccount" {
  name                     = "uptasa101"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create the Linux App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  name                = "upt-asp-101"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "azurefunction" {
  name                = "upt-afn-101"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  storage_account_name       = azurerm_storage_account.storageaccount.name
  storage_account_access_key = azurerm_storage_account.storageaccount.primary_access_key
  service_plan_id            = azurerm_service_plan.appserviceplan.id
  site_config {
    minimum_tls_version = "1.2"
    always_on = false
    application_stack {
      dotnet_version = "8.0"
      }
  }
}

resource "azurerm_static_web_app" "example" {
  name                = "upt-swa-101"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_mssql_server" "sqlsrv" {
  name                         = "upt-dbs-101"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sqladmin_username
  administrator_login_password = var.sqladmin_password
}

resource "azurerm_mssql_firewall_rule" "sqlaccessrule" {
  name             = "PublicAccess"
  server_id        = azurerm_mssql_server.sqlsrv.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

resource "azurerm_mssql_database" "sqldb" {
  name      = "shorten"
  server_id = azurerm_mssql_server.sqlsrv.id
  sku_name = "Free"
}
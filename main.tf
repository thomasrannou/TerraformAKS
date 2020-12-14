locals {
  tags = {
      projet      = "Demo"
      environment = "Dev"
    }
}

terraform {
  backend "azurerm" {
    resource_group_name   = "${var.backend-rg}"
    storage_account_name  = "${var.storage-account-name}"
    container_name        = "${var.container-name}"
    key                   = "${var.backend-name}"
  }
}

# ======================================================================================
# Resource Group
# ======================================================================================
 resource "azurerm_resource_group" "tf-rg" {
    name        = "${var.aks-resource-group-name}"
    location    = "${var.aks-resource-group-location}"
    tags        = "${local.tags}"
 }

# ======================================================================================
# Container Registry
# =======================================================================================
resource "azurerm_container_registry" "acr" {
  name                     = "${var.registry-name}"
  location                 = "${azurerm_resource_group.tf-rg.location}"
  resource_group_name      = "${azurerm_resource_group.tf-rg.name}"
  sku                      = "Basic"
  admin_enabled            = false
  depends_on               = [azurerm_resource_group.tf-rg] 
}

# ======================================================================================
# Cluster kubernetes
# ======================================================================================
resource "azurerm_kubernetes_cluster" "cluster-aks" {
  name                    = "${var.aks-cluster-name}"
  location                = "${azurerm_resource_group.tf-rg.location}"
  resource_group_name     = "${azurerm_resource_group.tf-rg.name}"   
  kubernetes_version      = "1.18.8"
  dns_prefix              = "${var.aks-cluster-name}-dns"
  tags                    = "${local.tags}"
   
  default_node_pool {
    name                  = "default"
    vm_size               = "Standard_D2_v2"
    enable_auto_scaling   = false
    node_count            = 1
    availability_zones    = ["1", "2", "3"]
    type                  = "VirtualMachineScaleSets"
  }

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }

  service_principal {
    client_id     = "${var.aks-cluster-sp-client-id}"
    client_secret = "${var.aks-cluster-sp-client-secret}"
  }
}

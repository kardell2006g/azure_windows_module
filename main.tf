provider "azurerm" {
  features {}
}

variable location {}
variable resource_group_name {}
variable subnet_name {}
variable subnet_RG {}
variable vnet_name {}
variable key_vault_name {}
variable key_vault_cert {}
variable key_vault_RG {}

data "azurerm_subnet" "example" {
  name                 = "subnet1"
  resource_group_name  = "AK-RG"
  virtual_network_name = "AK-example-network"
 }

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

data "azurerm_key_vault" "example" {
  name                = "akmodule5189221693"
  resource_group_name = "ak-module"
 }

data "azurerm_key_vault_certificate" "example" {
  name         = "example-kv-cert"
  key_vault_id = data.azurerm_key_vault.example.id
}


module "windowsservers" {
  source                        = "Azure/compute/azurerm"
  resource_group_name           = azurerm_resource_group.example.name
  vm_hostname                   = "mywinvm"
  is_windows_image              = true
  admin_password                = "ComplxP@ssw0rd!"
  allocation_method             = "Static"
  public_ip_sku                 = "Standard"
  public_ip_dns                 = ["winterravmip", "winterravmip1"]
  nb_public_ip                  = 2
  remote_port                   = "3389"
  nb_instances                  = 2
  vm_os_publisher               = "MicrosoftWindowsServer"
  vm_os_offer                   = "WindowsServer"
  vm_os_sku                     = "2012-R2-Datacenter"
  vm_size                       = "Standard_DS2_V2"
  #vnet_subnet_id                = module.network.vnet_subnets[0]
  vnet_subnet_id                = data.azurerm_subnet.example.id
  enable_accelerated_networking = true
  license_type                  = "Windows_Client"
  identity_type                 = "SystemAssigned" // can be empty, SystemAssigned or UserAssigned
  #vm_os_simple                  = "WindowsServer"

  extra_disks = [
    {
      size = 50
      name = "logs"
    },
    {
      size = 200
      name = "backup"
    }
  ]

  os_profile_secrets = [{
    source_vault_id   = data.azurerm_key_vault.example.id
    certificate_url   = data.azurerm_key_vault_certificate.example.secret_id
    certificate_store = "My"
  }]

  depends_on = [
    azurerm_resource_group.example
  ]
}

/*module "network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.example.name
  subnet_prefixes     = ["10.0.1.0/24"]
  subnet_names        = ["subnet1"]

  depends_on = [
    azurerm_resource_group.example
  ]
}
*/

output "windows_vm_public_name" {
  value = module.windowsservers.public_ip_dns_name
}

output "windows_vm_public_ip" {
  value = module.windowsservers.public_ip_address
}

output "windows_vm_private_ips" {
  value = module.windowsservers.network_interface_private_ip
}
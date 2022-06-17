provider "azurerm" {
  features {
     resource_group {
        prevent_deletion_if_contains_resources = false
   }
  }
}

variable location {}
variable resource_group_name {}
variable subnet_name {}
variable subnet_RG {}
variable vnet_name {}


data "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name  = var.subnet_RG
  virtual_network_name = var.vnet_name
 }

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

module "linuxservers" {
  source                           = "app.terraform.io/GAIG/linuxvm-cis/azurerm"
  resource_group_name              = azurerm_resource_group.example.name
  vm_hostname                      = "mylinuxvm"
  nb_public_ip                     = 0
  remote_port                      = "22"
  nb_instances                     = 2
  vm_os_publisher                  = "Canonical"
  vm_os_offer                      = "UbuntuServer"
  vm_os_sku                        = "18.04-LTS"
  # vm_os_publisher                  = "center-for-internet-security-inc"
  # vm_os_offer                      = "cis-oracle-linux-8-l1"
  # vm_os_sku                        = "cis-oracle8-l1-vw-po"
  vnet_subnet_id                   = data.azurerm_subnet.example.id
  boot_diagnostics                 = true
  delete_os_disk_on_termination    = true
  nb_data_disk                     = 2
  data_disk_size_gb                = 64
  data_sa_type                     = "Premium_LRS"
  enable_ssh_key                   = false
  ssh_key_values                   = ["ssh-rsa AAAAB3NzaC1",] #Takes entire public Key String
  vm_size                          = "Standard_D4s_v3"
  delete_data_disks_on_termination = true
  admin_password                   = "ComplxP@ssw0rd!"

  tags = {
    environment = "dev"
    costcenter  = "it"
  }

  enable_accelerated_networking = true

  depends_on = [
    azurerm_resource_group.example
  ]
}


output "linux_vm_private_ips" {
  value = module.linuxservers.network_interface_private_ip
}

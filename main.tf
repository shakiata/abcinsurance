#Azure terreform file for abc insurance


terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "abcinsurance"
  location = "eastus"
}

resource "azurerm_virtual_network" "abcnetwork" {
    name                = "abcnetwork"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.rg.name

   
    }
resource "azurerm_subnet" "abcsubnet" {
    name                 = "Subnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.abcnetwork.name
    address_prefixes       = ["10.0.2.0/24"]
}
resource "azurerm_public_ip" "abcpublicip" {
    name                         = "abcpublicip"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Static"
	sku  = "Standard"
}
   resource "azurerm_lb" "abclb" {
	 name                = "loadBalancer"
	 location            = azurerm_resource_group.rg.location
	 resource_group_name = azurerm_resource_group.rg.name
	 sku = "Standard"

	 frontend_ip_configuration {
	   name                 = "frontendip"
	   public_ip_address_id = azurerm_public_ip.abcpublicip.id
	 }
	}

	resource "azurerm_lb_backend_address_pool" "abclb" {
	 resource_group_name = azurerm_resource_group.rg.name
	 loadbalancer_id     = azurerm_lb.abclb.id
	 name                = "BackEndAddressPool"
	}
	

	resource "azurerm_network_security_group" "abcnsg" {
	    name                = "abcnetsec"
	    location            = "eastus"
	    resource_group_name = azurerm_resource_group.rg.name

	    security_rule {
	        name                       = "SSH"
	        priority                   = 1001
	        direction                  = "Inbound"
	        access                     = "Allow"
	        protocol                   = "Tcp"
	        source_port_range          = "*"
	        destination_port_range     = "22"
	        source_address_prefix      = "*"
	        destination_address_prefix = "*"
	    }

	}
	resource "azurerm_network_interface" "abcnic" {
	    count = 2
		name                        = "abcnic${count.index}"
	    location                    = "eastus"
	    resource_group_name         = azurerm_resource_group.rg.name

	    ip_configuration {
	        name                          = "abcnicconfig"
	        subnet_id                     = azurerm_subnet.abcsubnet.id
	        private_ip_address_allocation = "Dynamic"
	    }

	    
	}

	resource "random_id" "randomId" {
	    keepers = {
	        # Generate a new ID only when a new resource group is defined
	        resource_group = azurerm_resource_group.rg.name
	    }

	    byte_length = 8
	}
	
	resource "azurerm_storage_account" "abcstorage" {
	    name                        = "diag${random_id.randomId.hex}"
	    resource_group_name         = azurerm_resource_group.rg.name
	    location                    = "eastus"
	    account_replication_type    = "LRS"
	    account_tier                = "Standard"

	}
	
	

	resource "azurerm_managed_disk" "abcdisk" {
	 count                = 2
	 name                 = "datadisk_existing_${count.index}"
	 location             = azurerm_resource_group.rg.location
	 resource_group_name  = azurerm_resource_group.rg.name
	 storage_account_type = "Standard_LRS"
	 create_option        = "Empty"
	 disk_size_gb         = "1023"
	}



	resource "azurerm_virtual_machine" "abcvm" {
	 count                 = 2
	 name                  = "abcvm${count.index}"
	 location              = azurerm_resource_group.rg.location
	 resource_group_name   = azurerm_resource_group.rg.name
	 network_interface_ids = [element(azurerm_network_interface.abcnic.*.id, count.index)]
	 vm_size               = "Standard_DS1_v2"

	  #Uncomment this line to delete the OS disk automatically when deleting the VM
	  delete_os_disk_on_termination = true

	 # Uncomment this line to delete the data disks automatically when deleting the VM
	  delete_data_disks_on_termination = true

	 storage_image_reference {
	   publisher = "Canonical"
	   offer     = "UbuntuServer"
	   sku       = "16.04-LTS"
	   version   = "latest"
	 }

	 storage_os_disk {
	   name              = "myosdisk${count.index}"
	   caching           = "ReadWrite"
	   create_option     = "FromImage"
	   managed_disk_type = "Standard_LRS"
	 }

	 # Optional data disks
	 storage_data_disk {
	   name              = "datadisk_new_${count.index}"
	   managed_disk_type = "Standard_LRS"
	   create_option     = "Empty"
	   lun               = 0
	   disk_size_gb      = "1023"
	 }

	 storage_data_disk {
	   name            = element(azurerm_managed_disk.abcdisk.*.name, count.index)
	   managed_disk_id = element(azurerm_managed_disk.abcdisk.*.id, count.index)
	   create_option   = "Attach"
	   lun             = 1
	   disk_size_gb    = element(azurerm_managed_disk.abcdisk.*.disk_size_gb, count.index)
	 }

	 os_profile {
	   computer_name  = "hostname"
	   admin_username = "abcinsurance"
	   admin_password = "AbcInsurance123"
	 }

	 os_profile_linux_config {
	   disable_password_authentication = false
	 }
	}

	resource "azurerm_lb_backend_address_pool_address" "avcvm" {
  count = 2
  name                    = "abcvm${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.abclb.id 
  virtual_network_id      = azurerm_virtual_network.abcnetwork.id
    ip_address              = "10.0.0.2${count.index}"

}
resource "azurerm_lb_rule" "abclbrule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.abclb.id
  probe_id                       = azurerm_lb_probe.abcprobe.id  
  backend_address_pool_id        = azurerm_lb_backend_address_pool.abclb.id  
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.abclb.frontend_ip_configuration[0].name  
}

resource "azurerm_lb_probe" "abcprobe" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.abclb.id
  name                = "http-running-probe"
  port                = 80
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet_16"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet_66_24"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.66.0/24"]
}




## Create Network Security Group and rule
#resource "azurerm_network_security_group" "networksecuritygroup" {
#  name                = "networksecuritygroup"
#  location            = azurerm_resource_group.resourcegroup.location
#  resource_group_name = azurerm_resource_group.resourcegroup.name
#
#  security_rule {
#    name                       = "SSH"
#    priority                   = 1001
#    direction                  = "Inbound"
#    access                     = "Allow"
#    protocol                   = "Tcp"
#    source_port_range          = "*"
#    destination_port_range     = "22"
#    source_address_prefix      = "*"
#    destination_address_prefix = "*"
#  }
#}
## Connect the security group to the network interface
#resource "azurerm_network_interface_security_group_association" "nsg2nic" {
#  network_interface_id      = azurerm_network_interface.nic.id
#  network_security_group_id = azurerm_network_security_group.networksecuritygroup.id
#}


##################################################
# VM1
##################################################

# Create VM1 public IP
resource "azurerm_public_ip" "vm1publicip" {
  name                = "vm1pip"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Dynamic"
}

# Create network interface
resource "azurerm_network_interface" "vm1nic" {
  name                = "vm1nic"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    public_ip_address_id          = azurerm_public_ip.vm1publicip.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "${cidrhost("192.168.66.0/24", 102)}"
  }
}

# Create (and display) an SSH key
resource "tls_private_key" "vm1ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
output "tls_private_key_vm" { 
    value = tls_private_key.vm1ssh.private_key_pem 
    sensitive = true
}

# Create vm1 
resource "azurerm_linux_virtual_machine" "vm1vm" {
  name                  = "vm1"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.vm1nic.id]
  size                  = "Standard_DS3_v2"

  os_disk {
    name                 = "vmw1OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "vm1"
  admin_username                  = "azureuser"

 admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa_mentoring_vm1.pub")
  }

  connection {
    host = self.public_ip_address
    user = "azureuser"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa_mentoring_vm1")}"
  }

  provisioner "file" {
    source = "../docker-setup.sh"
    destination = "/tmp/docker-setup.sh"
  }

  provisioner "file" {
    source = "../jenkins-setup.sh"
    destination = "/tmp/jenkins-setup.sh"
  }

  provisioner "file" {
    source = "../sonarqube-setup.sh"
    destination = "/tmp/sonarqube-setup.sh"
  }

  provisioner "file" {
    source = "../owasp-zap-setup.sh"
    destination = "/tmp/owasp-zap-setup.sh"
  }

  provisioner "remote-exec" {
      inline = [
        "chmod +x /tmp/docker-setup.sh",
        "sudo /tmp/docker-setup.sh"
      ]
  }

  provisioner "remote-exec" {
      inline = [
        "chmod +x /tmp/jenkins-setup.sh",
        "sudo /tmp/jenkins-setup.sh"
      ]
  }

  provisioner "remote-exec" {
      inline = [
        "chmod +x /tmp/sonarqube-setup.sh",
        "sudo /tmp/sonarqube-setup.sh"
      ]
  }

  provisioner "remote-exec" {
      inline = [
        "chmod +x /tmp/owasp-zap-setup.sh",
        "sudo /tmp/owasp-zap-setup.sh"
      ]
  }

}

##################################################
# master
##################################################

# Create master public IP
resource "azurerm_public_ip" "masterpublicip" {
  name                = "masterpip"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Dynamic"
}

# Create network interface
resource "azurerm_network_interface" "masternic" {
  name                = "masternic"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    public_ip_address_id          = azurerm_public_ip.masterpublicip.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "${cidrhost("192.168.66.0/24", 100)}"
  }
}

# Create (and display) an SSH key
resource "tls_private_key" "masterssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
output "tls_private_key_master" { 
    value = tls_private_key.masterssh.private_key_pem 
    sensitive = true
}

# Create master 
resource "azurerm_linux_virtual_machine" "mastervm" {
  name                  = "master"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.masternic.id]
  size                  = "Standard_DS2_v2"

  os_disk {
    name                 = "masterOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "master"
  admin_username                  = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa_mentoring_master.pub")
  }

  connection {
    host = self.public_ip_address
    user = "azureuser"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa_mentoring_master")}"
  }

  provisioner "file" {
    source = "../k8s-setup.sh"
    destination = "/tmp/k8s-setup.sh"
  }

  provisioner "remote-exec" {
      inline = [
        "chmod +x /tmp/k8s-setup.sh",
        "sudo /tmp/k8s-setup.sh"
      ]
  }

}


##################################################
# worker1
##################################################

# Create worker1 public IP
resource "azurerm_public_ip" "worker1publicip" {
  name                = "workerpip"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Dynamic"
}

# Create network interface
resource "azurerm_network_interface" "worker1nic" {
  name                = "worker1nic"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    public_ip_address_id          = azurerm_public_ip.worker1publicip.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "${cidrhost("192.168.66.0/24", 101)}"
  }
}

# Create (and display) an SSH key
resource "tls_private_key" "worker1ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
output "tls_private_key_worker1" { 
    value = tls_private_key.worker1ssh.private_key_pem 
    sensitive = true
}

# Create worker1 
resource "azurerm_linux_virtual_machine" "worker1vm" {
  name                  = "worker1"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.worker1nic.id]
  size                  = "Standard_DS2_v2"

  os_disk {
    name                 = "worker1OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "worker1"
  admin_username                  = "azureuser"


  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa_mentoring_worker1.pub")
  }

  connection {
    host = self.public_ip_address
    user = "azureuser"
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa_mentoring_worker1")}"
  }

  provisioner "file" {
    source = "../k8s-setup.sh"
    destination = "/tmp/k8s-setup.sh"
  }

  provisioner "remote-exec" {
      inline = [
        "chmod +x /tmp/k8s-setup.sh",
        "sudo /tmp/k8s-setup.sh"
      ]
  }

}

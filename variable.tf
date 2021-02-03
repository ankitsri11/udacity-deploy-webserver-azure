
variable "prefix" {
  description = "The prefix which should be used for all resources in this project"
  default     = "udacity-project"
}

variable "location" {
  description = "Azure region to launch resources"
  default = "westus"
}

variable "vm_instance_count" {
  description = "virtual machine count"
  default = 4
}

variable "vm_size" {
	description = "Enter VM size needed"
	default = "Standard_D2s_v3"
}
variable "admin_username" {
	description = "Username for login"
	default = "admin-user"
}
variable "admin_password" {
	description = "Password for username"
	default = "SomePassword#1"
}

variable "image_resource_id" {
	description = "Resource information of image to be used"
	default = "/subscriptions/f217ab79-959d-4cb7-b24d-247612a7469f/resourceGroups/packer-rg/providers/Microsoft.Compute/images/myPackerImage"
}

variable "vnet_range" {
	description = "Vnet IP address range"
	default = ["10.0.0.0/22"]
}

variable "subnet_range" {
	description = "Subnet IP address range"
	default = ["10.0.1.0/24"]
}

variable "environment" {
	description = "Add value to environment tag key (e.g. production, stage, dev, test)"
    default     = "udacity"
}
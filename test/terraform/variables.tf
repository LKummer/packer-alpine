variable "proxmox_api_url" {
  description = "Proxmox VE API server URL."
  type        = string
}

variable "proxmox_target_node" {
  description = "Proxmox node the machine will be created on."
  type        = string
}

variable "proxmox_template" {
  description = "Proxmox template to clone."
  type        = string
}

variable "cloud_init_public_keys" {
  description = "SSH public keys to add with Cloud Init."
  type        = string
  default     = ""
}

variable "disk_size" {
  description = "Disk size when cloning, used to test disk resizing."
  type        = string
  default     = "15G"
}

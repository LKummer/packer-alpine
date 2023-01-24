module "machine" {
  source = "github.com/LKummer/terraform-proxmox//modules/machine?ref=1.0.0"

  proxmox_api_url     = var.proxmox_api_url
  proxmox_target_node = var.proxmox_target_node
  proxmox_template    = var.proxmox_template

  name                   = "packer-alpine-test"
  description            = "Created by packer-alpine automated testing suite."
  on_boot                = true
  memory                 = 2048
  cores                  = 2
  disk_pool              = "local-lvm"
  disk_size              = var.disk_size
  cloud_init_public_keys = var.cloud_init_public_keys
}

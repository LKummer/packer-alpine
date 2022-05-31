variable "proxmox_username" {
  type = string
}

variable "proxmox_password" {
  type = string
  sensitive = true
}

variable "proxmox_url" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "ssh_password" {
  type = string
  sensitive = true
}

variable "ssh_port" {
  type = string
  default = "2222"
}

variable "iso" {
  type = string
  default = "https://dl-cdn.alpinelinux.org/alpine/v3.16/releases/x86_64/alpine-virt-3.16.0-x86_64.iso"
}

variable "iso_checksum" {
  type = string
  default = "ba8007f74f9b54fbae3b2520da577831b4834778a498d732f091260c61aa7ca1"
}

variable "http_interface" {
  type = string
  default = null
}

variable "template_name" {
  type = string
  default = "Alpine-3.16.0"
}

variable "template_description" {
  type = string
  default = "Alpine Linux with QEMU guest agent and cloud-init."
}

source "proxmox-iso" "alpine" {
  proxmox_url = var.proxmox_url
  insecure_skip_tls_verify = true
  username = var.proxmox_username
  password = var.proxmox_password
  node = var.proxmox_node

  http_interface = var.http_interface

  iso_storage_pool = "local"
  iso_url = var.iso
  iso_checksum = var.iso_checksum

  template_name = var.template_name
  template_description = var.template_description

  unmount_iso = true

  scsi_controller = "virtio-scsi-pci"
  os = "l26"
  qemu_agent = true

  network_adapters {
    model = "virtio"
    bridge = "vmbr0"
  }

  disks {
    type = "scsi"
    disk_size = "10G"
    storage_pool = "local-lvm"
    storage_pool_type = "lvm-thin"
    format = "raw"
  }

  ssh_username = "root"
  ssh_password = var.ssh_password
  ssh_port = var.ssh_port
  ssh_timeout = "5m"

  http_directory = "http"
  
  boot_command = [
    "root<enter><wait>",
    "ifconfig 'eth0' up && udhcpc -i 'eth0'<enter><wait5>",
    "wget http://{{ .HTTPIP }}:{{ .HTTPPort }}/answers<enter><wait2>",
    "setup-alpine -f answers<enter><wait5>",
    "${var.ssh_password}<enter><wait>",
    "${var.ssh_password}<enter><wait5>",
    # Create non root user, default is no.
    "<enter>",
    # Enable password SSH authentication as it is used by Packer.
    "yes<enter>",
    # Do not add SSH keys for root.
    "<enter>",
    "<wait>y<enter><wait10>",
    "mount /dev/sda3 /mnt<enter>",
    "rc-service sshd stop<enter>",
    "echo 'PermitRootLogin yes' >> /mnt/etc/ssh/sshd_config<enter>",
    "echo 'Port ${var.ssh_port}' >> /mnt/etc/ssh/sshd_config<enter>",
    "reboot<enter><wait45>",
    "root<enter><wait>",
    "${var.ssh_password}<enter><wait>",
    "wget --quiet -O- http://{{ .HTTPIP }}:{{ .HTTPPort }}/qemu-setup | sh<enter><wait>"
  ]

  cloud_init = true
  cloud_init_storage_pool = "local-lvm"
}

build {
  sources = ["source.proxmox-iso.alpine"]

  provisioner "shell" {
    inline = [
      "apk add python3 py3-pip",
      "apk add sudo cloud-init",
      # Add default cloud-init user.
      "useradd alpine",
      "echo 'alpine ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers",
      # Clean up
      "sed -i '/PermitRootLogin yes/d' /etc/ssh/sshd_config",
      "setup-cloud-init",
    ]
  }
}

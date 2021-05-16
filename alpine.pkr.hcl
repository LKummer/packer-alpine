variable "proxmox_username" {
  type = string
  default = "root@pam"
}

variable "proxmox_password" {
  type = string
  sensitive = true
}

variable "ssh_password" {
  type = string
  default = "1234"
  sensitive = true
}

variable "iso" {
  type = string
  default = "https://dl-cdn.alpinelinux.org/alpine/v3.13/releases/x86_64/alpine-virt-3.13.5-x86_64.iso"
}

variable "iso_checksum" {
  type = string
  default = "e6bbcab275b704bc6521781f2342fff084700b458711fdf315a5816d9885943c"
}

variable "http_interface" {
  type = string
  default = null
}

variable "template_name" {
  type = string
  default = "alpine-3.13.5-cloud"
}

variable "template_description" {
  type = string
  default = "Alpine Linux with QEMU guest agent and cloud-init."
}

source "proxmox-iso" "pve" {
  proxmox_url = "https://pve.kummer.local:8006/api2/json"
  insecure_skip_tls_verify = true
  username = var.proxmox_username
  password = var.proxmox_password
  node = "pve"

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
  ssh_timeout = "5m"

  http_directory = "http"
  
  boot_command = [
    "root<enter><wait>",
    "ifconfig 'eth0' up && udhcpc -i 'eth0'<enter><wait>",
    "wget http://{{ .HTTPIP }}:{{ .HTTPPort }}/answers<enter><wait>",
    "setup-alpine -f answers<enter><wait>",
    "${var.ssh_password}<enter><wait>",
    "${var.ssh_password}<enter><wait5>",
    "<wait>y<enter><wait10>",
    "mount /dev/sda3 /mnt<enter>",
    "rc-service sshd stop<enter>",
    "echo 'PermitRootLogin yes' >> /mnt/etc/ssh/sshd_config<enter>",
    "reboot<enter><wait45>",
    "root<enter>",
    "${var.ssh_password}<enter><wait>",
    "wget --quiet -O- http://{{ .HTTPIP }}:{{ .HTTPPort }}/qemu-setup | sh<enter><wait>"
  ]

  cloud_init = true
  cloud_init_storage_pool = "local-lvm"
}

build {
  sources = ["source.proxmox-iso.pve"]

  provisioner "shell" {
    inline = [
      "apk add sudo cloud-init",
      # Add default cloud-init user.
      "useradd alpine",
      "echo 'alpine ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers",
      # Setup serial terminal.
      "sed -i 's/default_kernel_opts=\"\\(.*\\)\"/default_kernel_opts=\"console=tty1 console=ttyS0 \\1\"/' /etc/update-extlinux.conf",
      "update-extlinux",
      # Clean up
      "sed -i '/PermitRootLogin yes/d' /etc/ssh/sshd_config",
      "setup-cloud-init",
    ]
  }
}

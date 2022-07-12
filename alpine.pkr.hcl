variable "proxmox_node" {
  description = "Proxmox node ID to create the template on."
  type = string
}

variable "ssh_password" {
  description = "Root user password."
  type = string
  sensitive = true
}

variable "ssh_port" {
  description = "SSH port to configure the template to use."
  type = string
  default = "2222"
}
variable "template_name" {
  description = "Name of the created template."
  type = string
  default = "Alpine-3.16.0"
}

variable "template_name_suffix" {
  description = "Suffix added to template_name, used to add Git commit hash or tag to template name."
  type = string
  default = ""
}

variable "template_description" {
  description = "Description of the created template."
  type = string
  default = <<EOF
Alpine Linux cloud image with QEMU guest agent, cloud-init and Python.
https://git.houseofkummer.com/homelab/devops/packer-alpine
EOF
}

source "proxmox-iso" "alpine" {
  insecure_skip_tls_verify = true
  node = var.proxmox_node

  iso_storage_pool = "local"
  iso_url = "https://dl-cdn.alpinelinux.org/alpine/v3.16/releases/x86_64/alpine-virt-3.16.0-x86_64.iso"
  iso_checksum = "ba8007f74f9b54fbae3b2520da577831b4834778a498d732f091260c61aa7ca1"

  template_name = "${var.template_name}${var.template_name_suffix}"
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

  # Python, sudo and Cloud Init setup.
  provisioner "shell" {
    inline = [
      "apk add python3 py3-pip sudo",
      # e2fsprogs-extra is required by Cloud Init for creating/resizing filesystems.
      # See https://git.alpinelinux.org/aports/tree/community/cloud-init/README.Alpine.
      "apk add cloud-init e2fsprogs-extra",
      "setup-cloud-init",
    ]
  }

  # Cleanup.
  provisioner "shell" {
    inline = [
      # Password SSH login is already disabled by Cloud Init.
      "sed -i '/PermitRootLogin yes/d' /etc/ssh/sshd_config",
      "passwd --lock root",
      # Remove command history and authorized keys.
      "rm -rf /root/.ash_history"
    ]
  }
}

# Packer Alpine

Packer setup for creating Alpine Linux images on Proxmox.
Builds images with Cloud Init, QEMU guest agent and Python 3 for easy provisioning with Ansible.

## Build Instructions

Ensure Packer is installed.

Create a variable file `secrets.pkr.hcl` for Proxmox credentials and other variables.
See `secrets.example.pkr.hcl` as an example.

Set `PROXMOX_URL`, `PROXMOX_USERNAME` and `PROXMOX_TOKEN` environment variables.
[See the Proxmox builder documentation](https://www.packer.io/plugins/builders/proxmox/iso) for more information.

It is recommended to use a `.env` file to manage credentials. For example:

```sh
export PROXMOX_URL='https://192.168.0.100:8006/api2/json'
export PROXMOX_USERNAME='user@pve!token'
export PROXMOX_TOKEN='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
```

Build with a template name suffix denoting the current commit, for example `2b1adb0`:

```s
$ packer build --var-file secrets.pkr.hcl --var template_name_suffix=-2b1adb0 alpine.pkr.hcl
```

## Troubleshooting

Set `PACKER_LOG=1` to enable logging for easier troubleshooting.

Avoid running Packer on Windows.
This repository, Packer and Alpine all assume you are running on Linux.

`answers` file for `setup-alpine` must use LF line endings.
This might cause issues when cloning on Windows.

## Useful Resources

* [Packer Proxmox builder from ISO docs](https://www.packer.io/docs/builders/proxmox/iso).
* [Proxmox docs on creating a custom cloud image](https://pve.proxmox.com/wiki/Cloud-Init_FAQ#Creating_a_custom_cloud_image).
* [Alpine cloud-init package readme](https://git.alpinelinux.org/aports/tree/community/cloud-init/README.Alpine).
* [sed introduction and tutorial](https://www.grymoire.com/Unix/Sed.html).
* [Alpine Linux downloads](https://www.alpinelinux.org/downloads/).

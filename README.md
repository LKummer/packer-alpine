# Packer Alpine

Packer configuration for building an Alpine Linux 'cloud image' Proxmox template.

Features:

* Includes Cloud Init for configuration when cloning.
* Includes Python for configuration with Ansible.
* Includes `sudo` and QEMU guest agent.
* Tested with Terratest.

## Development Guide

Required tools:

* Packer `v1.8.2`.
* Terraform `v1.2.4`.
* Go `1.18.2`.

For building only Packer is required.

### Build

Create a variable file `secrets.pkr.hcl` for Proxmox credentials and other variables.
See `secrets.example.pkr.hcl` as an example.

Set `PROXMOX_URL`, `PROXMOX_USERNAME` and `PROXMOX_TOKEN` environment variables.
[See the Proxmox builder documentation](https://www.packer.io/plugins/builders/proxmox/iso) for more information.

Build with a template name suffix denoting the current commit, for example `2b1adb0`:

```sh
packer build --var-file secrets.pkr.hcl --var template_name_suffix=-2b1adb0 alpine.pkr.hcl
```

### Test

Testing requires `PROXMOX_URL`, `PROXMOX_USERNAME`, `PROXMOX_TOKEN`, `PM_API_TOKEN_ID` and `PM_API_TOKEN_SECRET` environment variables set, as well as `secrets.pkr.hcl` (see `secrets.example.pkr.hcl`).

For testing and development it is recommended to use a `.env` file to manage credentials.
For example:

```sh
export PROXMOX_URL='https://192.168.0.100:8006/api2/json'
export PROXMOX_USERNAME='user@pve!token'
export PROXMOX_TOKEN='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
export PM_API_TOKEN_ID="$PROXMOX_USERNAME"
export PM_API_TOKEN_SECRET="$PROXMOX_TOKEN"
```

Navigate to the `test` folder and run the tests:

```sh
cd test
go test ./...
```

## Troubleshooting

Set `PACKER_LOG=1` to enable logging for easier troubleshooting.

Avoid running Packer on Windows.
This repository, Packer and Alpine all assume you are running on Linux.

`answers` file for `setup-alpine` must use LF line endings.
This might cause issues when cloning on Windows.

## Useful Resources

* [Packer Proxmox ISO builder documentation](https://www.packer.io/docs/builders/proxmox/iso).
* [Proxmox wiki on creating a custom cloud image](https://pve.proxmox.com/wiki/Cloud-Init_FAQ#Creating_a_custom_cloud_image).
* [cloud-init documentation](https://cloudinit.readthedocs.io/en/latest/index.html).
* [Alpine cloud-init package readme](https://git.alpinelinux.org/aports/tree/community/cloud-init/README.Alpine).
* [Alpine Linux downloads](https://www.alpinelinux.org/downloads/).
* [Setting up Proxmox role with permissions for Packer](https://github.com/hashicorp/packer/issues/8463#issuecomment-726844945).

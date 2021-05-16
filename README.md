# Packer Alpine

Packer setup for creating Alpine Linux images on Proxmox.
Builds images with QEMU guest agent and Cloud Init.

## Build Instructions

Ensure Packer is installed.

Create a variable file `secrets.pkr.hcl` for Proxmox credentials and other variables.
See `secrets.example.pkr.hcl` as an example.

Run the build command:

```s
$ packer build --var-file ./secrets.pkr.hcl alpine.pkr.hcl
```

## Notes

`answers` file for `setup-alpine` must use LF line endings.
This might cause issues when cloning on Windows.

## Useful Resources

* [Packer Proxmox builder from ISO docs](https://www.packer.io/docs/builders/proxmox/iso).
* [Proxmox docs on creating a custom cloud image](https://pve.proxmox.com/wiki/Cloud-Init_FAQ#Creating_a_custom_cloud_image).
* [Alpine cloud-init package readme](https://git.alpinelinux.org/aports/tree/community/cloud-init/README.Alpine).
* [sed introduction and tutorial](https://www.grymoire.com/Unix/Sed.html).
* [Alpine Linux downloads](https://www.alpinelinux.org/downloads/).

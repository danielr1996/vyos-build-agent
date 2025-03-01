# vyos-build-agent

[VyOS](https://vyos.io/use-cases) is a great open source routing platform, but since it's targeted at enterprise customers prebuilt qemu images
with cloud-init support are only available through a subscription.

Thankfully we can build such images ourselves. The documentation is a little bit vague on how to build custom images, but
I was finally able to piece together a build environment that allowed me to build my own cloud images for VyOS. 
This repo mainly serves as documentation for myself, as well as inspiration for others. 

# Do you have any problems with the instructions?
As these instructions are mainly used for my own documentation purposes I only summarize the needed steps and omit things
I take for granted, but if you have any troubles adapting these steps for yourself please feel free to open an issue.

# Design
The [official instructions](https://docs.vyos.io/en/latest/contributing/build-vyos.html) recommend setting up a distinct build vm. 
To automatically set up a build environment I use terraform to bootstrap a vm in proxmox and install the necessary dependencies, 
as well as install a few custom scripts to switch between versions and build-flavors.

# Requirements
- terraform
- api and ssh access to a proxmox server (see: [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest/docs))
- a storagepool with snippet support in proxmox (see https://www.thomas-krenn.com/de/wiki/Custom_Cloud_Init_Config_in_Proxmox_VE)
- debian bookworm qemu img loaded into proxmox

# Building the image
```shell
cat <<EOF > main.tf
module "vyos-build-agent" {
  source = "github.com/danielr1996/vyos-build-agent"
  proxmox_endpoint = ""
  proxmox_password = ""
  proxmox_ssh_private_key = "~/.ssh/id_ed25519"
  proxmox_ssh_public_key = "~/.ssh/id_ed25519.pub"
  proxmox_insecure = true
}

output "ip" {
  value = module.vyos-build-agent.ip
}
EOF
terraform apply
ssh debian@$(terraform output ip | sed -r 's/"//g')
# Install all the dependencies takes some time (around 2-5 minutes), you can check the status with
vyos-log

# When you see a line similiar to Cloud-init v. 22.4.2 finished at Sat, 01 Mar 2025 02:32:14 +0000. Datasource DataSourceNoCloud [seed=/dev/sr0][dsmode=net].  Up 795.92 seconds, you can start a build by running
vyos-build

# After the build finished (~15min) you can list built images with
ls -la dist/

# And access them from a webserver with
curl -LO https://$(terraform output ip | sed -r 's/"//g')

```

# Roadmap
- [x] support building the latest rolling release image
- [ ] support building LTS releases
- [ ] support building arbitrary commits
- [ ] support building different flavors
- [ ] cleanup the cloud-init config for the build vm

# Resources
- https://forum.vyos.io/t/build-for-qemu-or-vmware/15885/3
- https://docs.vyos.io/en/latest/contributing/build-vyos.html
- https://docs.vyos.io/en/latest/automation/cloud-init.html
- https://blog.vyos.io/introducing-the-image-build-flavor-system
- https://registry.terraform.io/providers/bpg/proxmox/latest/docs
resource "proxmox_virtual_environment_vm" "vyos-build-agent" {
  name      = "vyos-build-agent"
  node_name = var.proxmox_node_name
  agent { enabled = true }
  memory { dedicated = var.agent_memory }
  cpu { cores = var.agent_cores }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.vyos-build-user_data_cloud_config.id
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  disk {
    file_id     = var.debian_image
    interface   = "virtio0"
    iothread    = true
    discard     = "on"
    size        = var.disksize
    file_format = "raw"
  }
  serial_device {
    device = "socket"
  }

  network_device {
    bridge = var.bridge
  }
}

resource "proxmox_virtual_environment_file" "vyos-build-user_data_cloud_config" {
  content_type = "snippets"
  datastore_id = var.snippets_datastore
  node_name    = var.proxmox_node_name

  source_raw {
    data      = <<-EOF
    #cloud-config
    hostname: vyos-build
    packages:
      - nginx
    write_files:
      - content: |
          server {
            listen 80 default_server;
            listen [::]:80 default_server;
            root /vyos-build/dist;
            autoindex on;
          }
        path: /etc/nginx/sites-enabled/default
    users:
      - default
      - name: debian
        groups:
          - sudo
          - docker
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    runcmd:
        - echo "alias vyos-build='time docker run --rm -it --privileged -v /vyos-build:/vyos -v /dev:/dev -w /vyos vyos/vyos-build:current bash -c \"sudo ./build-vyos-image generic-qemu-cloud-init\" && cp /vyos-build/build/vyos*.{iso,qcow2,raw} dist/'" >> /home/debian/.bash_aliases
        - echo "alias vyos-log='tail -f /var/log/cloud-init-output.log'" >> /home/debian/.bash_aliases
        - apt update
        - apt -y install qemu-guest-agent net-tools sudo
        - systemctl enable qemu-guest-agent
        - systemctl start qemu-guest-agent
        - apt -y install ca-certificates curl gnupg
        - install -m 0755 -d /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - chmod a+r /etc/apt/keyrings/docker.gpg
        - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        - apt-get update
        - apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        - git clone -b current --single-branch https://github.com/vyos/vyos-build
        - mkdir /vyos-build/dist
        - chown -R debian:debian /vyos-build/
        - docker pull vyos/vyos-build:current
        - echo "cd /vyos-build" >> /home/debian/.bashrc
        - curl -L https://raw.githubusercontent.com/danielr1996/vyos-community-flavors/refs/heads/main/generic-qemu-cloud-init.toml -o /vyos-build/data/build-flavors/generic-qemu-cloud-init.toml
        EOF
    file_name = "vyos-build-agent-user-data-cloud-config.yaml"
  }
}

output "ip" {
  value = proxmox_virtual_environment_vm.vyos-build-agent.ipv4_addresses[1][0]
}
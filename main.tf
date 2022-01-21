terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      version = "1.25.1"
    }
  }
}

variable api_token {}
variable root_pswd {
  default = "SomeStrongPassword"
}

# Configure the Linode Provider
provider "linode" {
  token = var.api_token
}

data "linode_profile" "me" {}

resource "linode_firewall" "jenkins_firewall" {
  label = "jenkins_firewall"

  inbound {
    label    = "http"
    action = "ACCEPT"
    protocol  = "TCP"
    ports     = "80"
    ipv4 = ["0.0.0.0/0"]
  }

  inbound {
    label    = "ssh"
    action = "ACCEPT"
    protocol  = "TCP"
    ports     = "22"
    ipv4 = ["0.0.0.0/0"] ## Для тестов открыто всё, поменять на свои IP
  }

  inbound_policy = "DROP"
  outbound_policy = "ACCEPT"
}


resource "linode_instance" "jenkins" {
    label = "jenkins_server"
    image = "linode/ubuntu21.10"
    region = "eu-central"
    type = "g6-standard-2"
    authorized_users = [ data.linode_profile.me.username ]
    root_pass = var.root_pswd

    group = "terraform"
    tags = [ "terraform" ]
}

resource "linode_firewall_device" "my_device" {
  firewall_id = linode_firewall.jenkins_firewall.id
  entity_id = linode_instance.jenkins.id
}

resource "null_resource" "jenkins_setup" {
    triggers = {
        ip = linode_instance.jenkins.ip_address
    }
    provisioner "local-exec" {
        command = "ansible-playbook --inventory ${linode_instance.jenkins.ip_address}, jenkins.yaml"
    }
}

output "ip" {
    value = linode_instance.jenkins.ip_address
}
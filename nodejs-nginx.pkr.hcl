packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}
source "amazon-ebs" "ubuntu" {
  ami_name      = "packer-ubuntu-aws-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}
source "azure-arm" "ubuntu" {
  client_id                         = "XXXX"
  client_secret                     = "XXXX"
  managed_image_resource_group_name = "packer_images" #  resource group to save the images
  managed_image_name                = "packer-ubuntu-azure-{{timestamp}}"
  subscription_id                   = "XXXX"
  tenant_id                         = "XXXX"

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "UbuntuServer"
  image_sku       = "16.04-LTS"

  azure_tags = {
    Created-by = "Packer"
    OS_Version = "Ubuntu 16.04"
    Release    = "Latest"
  }

  location = "East US"
  vm_size  = "Standard_A2"
}
build {
  name = "ubuntu"
  sources = [
    "source.amazon-ebs.ubuntu",
    //"source.azure-arm.ubuntu",
  ]

  provisioner "file" {
    source      = "./files/"
    destination = "/tmp"
  }

  provisioner "shell" {
    inline = [
      //"sudo adduser egarcia",
      //"sudo usermod -aG sudo egarcia",
      //"sudo rsync --archive --chown=egarcia:egarcia ~/.ssh /home/egarcia",
      "sudo rm -r /var/lib/apt/lists/*",
      "sudo apt-get update -y",
      //"sudo apt-get install --yes dialog",
      "sudo echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections",
      "sudo apt-get install -y nginx",
      //"sudo ufw allow OpenSSH",
      //"sudo ufw allow 'Nginx HTTP'",
      "sudo chmod -R 755 /var/www/html",
      "sudo cp /tmp/index.html /var/www/html/index.html",
      "sudo cp /tmp/nodejs /etc/nginx/sites-available/nodejs"
    ]
  }
  provisioner "shell" {
    inline = [
      "sudo ln -s /etc/nginx/sites-available/nodejs /etc/nginx/sites-enabled/",
      "sudo systemctl restart nginx",
      //"sudo ufw --force enable",
      "cd ~",
      "curl -sL https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh",
      "sudo bash nodesource_setup.sh",
      "sudo echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections",
      "sudo apt-get install nodejs -y",
      "sudo echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections",
      "sudo apt-get install build-essential -y",
      "sudo cp /tmp/hello.js /home/ubuntu/hello.js"
    ]
  }



  provisioner "shell" {
    inline = [
      "sudo npm install -y pm2@latest -g",
      "sudo pm2 start hello.js",
      "sudo pm2 startup systemd",
      "sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu",
      "sudo pm2 save",
      "sudo systemctl start pm2-ubuntu"
    ]
  }

  provisioner "shell" {
    only   = ["source.azure-arm.ubuntu"]
    inline = ["sudo apt-get install azure-cli"]
  }

  post-processor "manifest" {}

}


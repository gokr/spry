# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.provider "virtualbox" do |vb|
     vb.memory = "4096"
  end
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    sudo apt-get update && sudo apt-get upgrade
    sudo apt-get install -y git build-essential unzip gcc

    # Install latest Nim and bootstrap it
    curl https://nim-lang.org/choosenim/init.sh -sSf > init.sh
    sh init.sh -y
    export PATH="$HOME/.nimble/bin:$PATH"
    echo 'export PATH="$HOME/.nimble/bin:$PATH"' >> ~/.profile

    # Let it refresh the package list
    nimble refresh

    # Use nimble to install spry
    nimble install spry
  SHELL
end

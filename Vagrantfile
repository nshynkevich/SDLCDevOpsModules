
Vagrant.configure("2") do |config|
  
  config.vm.box = "hashicorp/bionic64"
  config.vm.define "master" do | w |
    w.vm.hostname = "master"
    w.vm.network "private_network", ip: "192.168.66.100"
    w.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "master"
    end
    w.vm.provision "k8smastersetup", :privileged => true, :type => "shell", :path => "k8s-setup.sh"
  end

  config.vm.box = "hashicorp/bionic64"
  config.vm.define "worker-1" do | w |
    w.vm.hostname = "worker-1"
    w.vm.network "private_network", ip: "192.168.66.101"

    w.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "worker-1"
    end
    w.vm.provision "k8sworkersetup", :privileged => true, :type => "shell", :path => "k8s-setup.sh"
  end

  config.vm.box = "hashicorp/bionic64"
  config.vm.define "VM1" do | w |
    w.vm.hostname = "VM1"
    w.vm.network "private_network", ip: "192.168.66.222"

    w.vm.provider "virtualbox" do |vb|
      vb.memory = "3072"
      vb.cpus = 2
      vb.name = "VM1"
    end
    w.vm.provision "dockersetup", :privileged => true, :type => "shell", :path => "docker-setup.sh"
    w.vm.provision "jenkinssetup", :privileged => true, :type => "shell", :path => "jenkins-setup.sh"
    w.vm.provision "sonarqubesetup", :privileged => true, :type => "shell", :path => "sonarqube-setup.sh"
  end

end

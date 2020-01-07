#!/bin/bash

# Installation script for Cuckoo Sandbox setup
# This setup uses Virtualbox as a virtualization platform and
# Vagrant for provisioning VMs
# Compatible with Ubuntu 18.04 x64
# Please execute this script with sudo

# [NOTE] This script is only to setup the environment. If the machine is rebooted,
# you will need to manually start up a Virtualbox VM so that the "vboxnet0" virtual
# interface is started.

[ $# -eq 0 ] && { echo "Usage: $0 <all|ubuntu|windows7>"; exit 1; }

# Preparation phase
cd ~
sudo apt-get update

# Step 1: Install Virtualbox
sudo apt-get -y install debconf-utils
echo virtualbox-ext-pack virtualbox-ext-pack/license boolean true | sudo debconf-set-selections
sudo apt-get -y install virtualbox virtualbox-ext-pack

# Step 2: Install Cuckoo Dependencies
sudo apt-get -y install python python-pip python-dev libffi-dev libssl-dev
sudo apt-get -y install python-virtualenv python-setuptools
sudo apt-get -y install libjpeg-dev zlib1g-dev swig
sudo apt-get -y install mongodb
sudo apt-get -y install postgresql postgresql-contrib libpq-dev
sudo apt-get -y install tcpdump apparmor-utils
sudo apt-get -y install volatility
sudo apt-get -y install libguac-client-rdp0 libguac-client-vnc0 libguac-client-ssh0 guacd

sudo adduser --disabled-password --gecos "" cuckoo
sudo groupadd pcap
sudo usermod -a -G pcap cuckoo
sudo usermod -a -G vboxusers cuckoo
sudo aa-disable /usr/sbin/tcpdump
sudo chgrp pcap /usr/sbin/tcpdump
sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

sudo -u postgres psql postgres -c "CREATE DATABASE cuckoo;"
sudo -u postgres psql postgres -c "CREATE USER cuckoo WITH ENCRYPTED PASSWORD 'password'; GRANT ALL PRIVILEGES ON DATABASE cuckoo TO cuckoo;"

# Step 3: Create and Prepare Virtualenv for Cuckoo
cd ~
virtualenv cuckoo_env
source cuckoo_env/bin/activate
pip install -U pip setuptools
pip install -U m2crypto
pip install -U psycopg2
pip install -U cuckoo
pip install -U supervisor
cuckoo -d
cuckoo community
deactivate

# Step 4: Configure Cuckoo
sed -i 's/ignore_vulnerabilities = .*/ignore_vulnerabilities = yes/' ~/.cuckoo/conf/cuckoo.conf
sed -i 's/machinery = .*/machinery = virtualbox/' ~/.cuckoo/conf/cuckoo.conf
sed -i 's/ip = .*/ip = 192.168.101.1/' ~/.cuckoo/conf/cuckoo.conf
sed -i 's/port = .*/port = 2042/' ~/.cuckoo/conf/cuckoo.conf
sed -i 's/connection = .*/connection = postgresql:\/\/cuckoo:password@localhost\/cuckoo/' ~/.cuckoo/conf/cuckoo.conf
sed -i '/\[mongodb\]/!b;n;cenabled = yes' ~/.cuckoo/conf/reporting.conf

# Step 5: Install Vagrant
# To install newer versions of Vagrant, change the download link and filename
wget https://releases.hashicorp.com/vagrant/2.2.6/vagrant_2.2.6_x86_64.deb
sudo dpkg -i vagrant_2.2.6_x86_64.deb
sudo apt-get install -f
# should the apt-get be on another line? else it will not be executed as SUDO, thus will fail
vagrant plugin install vagrant-disksize

# Step 6: Download Vagrant Boxes
# Step 7: Create Vagrant Projects
# Step 8: Configure Vagrant Projects
# This will download an Ubuntu 18.04 x86_64 box and/or a Windows 7 x86 box
if [ $1 == "all" ] || [ $1 == "ubuntu" ]; then
    vagrant box add ubuntu/bionic64
    cd ~; mkdir cuckoo_ubuntu; cd cuckoo_ubuntu; vagrant init ubuntu/bionic64
    cp ~/.cuckoo/agent/agent.py ~/cuckoo_ubuntu
    cd ~/cuckoo_ubuntu;
    echo -e "Vagrant.configure(\"2\") do |config|" > Vagrantfile
    echo -e "\tconfig.vm.box = \"ubuntu/bionic64\"" >> Vagrantfile
    echo -e "\tconfig.disksize.size = \"20GB\"" >> Vagrantfile
    echo -e "\tconfig.vm.network \"forwarded_port\", guest: 80, host:8080" >> Vagrantfile
    echo -e "\tconfig.vm.network \"private_network\", ip: \"192.168.101.10\"" >> Vagrantfile
    echo -e "\tconfig.vm.provider \"virtualbox\" do |vb|" >> Vagrantfile
    echo -e "\t\tvb.name = \"cuckoo_ubuntu\"" >> Vagrantfile
    echo -e "\t\tvb.memory = \"2048\"" >> Vagrantfile
    echo -e "\tend" >> Vagrantfile
    echo -e "\tconfig.vm.provision \"shell\", inline: <<-SHELL" >> Vagrantfile
    echo -e "\t\tcp /vagrant/agent.py /home/vagrant/agent.py" >> Vagrantfile
    echo -e "\t\tchmod +x /home/vagrant/agent.py" >> Vagrantfile
    echo -e "\t\t(crontab -l 2>/dev/null; echo \"@reboot python /home/vagrant/agent.py\") | crontab -" >> Vagrantfile
    echo -e "\t\texport DEBIAN_FRONTEND=noninteractive" >> Vagrantfile
    echo -e "\t\tapt-get update" >> Vagrantfile
    echo -e "\t\tapt-get install -y systemtap gcc patch linux-headers-\$(uname -r) python" >> Vagrantfile
    echo -e "\t\tapt-key adv --keyserver keyserver.ubuntu.com --recv-keys C8CAB6595FDFF622" >> Vagrantfile
    echo -e "\t\tcodename=\$(lsb_release -cs)" >> Vagrantfile
    echo -e "\t\techo \"deb http://ddebs.ubuntu.com/ \${codename}          main restricted universe multiverse\" > /etc/apt/sources.list.d/ddebs.list" >> Vagrantfile
    echo -e "\t\techo \"#deb http://ddebs.ubuntu.com/ \${codename}-security main restricted universe multiverse\" >> /etc/apt/sources.list.d/ddebs.list" >> Vagrantfile
    echo -e "\t\techo \"deb http://ddebs.ubuntu.com/ \${codename}-updates  main restricted universe multiverse\" >> /etc/apt/sources.list.d/ddebs.list" >> Vagrantfile
    echo -e "\t\techo \"deb http://ddebs.ubuntu.com/ \${codename}-proposed main restricted universe multiverse\" >> /etc/apt/sources.list.d/ddebs.list" >> Vagrantfile
    echo -e "\t\tapt-get update" >> Vagrantfile
    echo -e "\t\tapt-get -y install linux-image-\$(uname -r)-dbgsym" >> Vagrantfile
    echo -e "\t\twget https://raw.githubusercontent.com/cuckoosandbox/cuckoo/master/stuff/systemtap/expand_execve_envp.patch" >> Vagrantfile
    echo -e "\t\twget https://raw.githubusercontent.com/cuckoosandbox/cuckoo/master/stuff/systemtap/escape_delimiters.patch" >> Vagrantfile
    echo -e "\t\tpatch /usr/share/systemtap/tapset/linux/sysc_execve.stp < expand_execve_envp.patch" >> Vagrantfile
    echo -e "\t\tpatch /usr/share/systemtap/tapset/uconversions.stp < escape_delimiters.patch" >> Vagrantfile
    echo -e "\t\twget https://raw.githubusercontent.com/cuckoosandbox/cuckoo/master/stuff/systemtap/strace.stp" >> Vagrantfile
    echo -e "\t\tstap -p4 -r \$(uname -r) strace.stp -m stap_ -v" >> Vagrantfile
    echo -e "\t\tmkdir /root/.cuckoo" >> Vagrantfile
    echo -e "\t\tmv stap_.ko /root/.cuckoo/" >> Vagrantfile
    echo -e "\t\tufw disable" >> Vagrantfile
    echo -e "\t\ttimedatectl set-ntp off" >> Vagrantfile
    echo -e "\t\tapt-get purge update-notifier update-manager update-manager-core ubuntu-release-upgrader-core" >> Vagrantfile
    echo -e "\t\tapt-get purge whoopsie ntpdate cups-daemon avahi-autoipd avahi-daemon avahi-utils" >> Vagrantfile
    echo -e "\t\tapt-get purge account-plugin-salut libnss-mdns telepathy-salut" >> Vagrantfile
    echo -e "\t\tsed -i 's/ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config" >> Vagrantfile
    echo -e "\t\treboot" >> Vagrantfile
    echo -e "\tSHELL" >> Vagrantfile
    echo -e "end" >> Vagrantfile
    vagrant up
fi
if [ $1 == "all" ] || [ $1 == "windows7" ]; then
    vagrant box add datacastle/windows7
    cd ~; mkdir cuckoo_windows7; cd cuckoo_windows7; vagrant init datacastle/windows7
    cp ~/.cuckoo/agent/agent.py ~/cuckoo_windows7
    cd ~/cuckoo_windows7
    echo -e "\$pyInstallPath = \"C:\Python27\"" > install-python.ps1
    echo -e "if (-not (Test-Path \$pyInstallPath))" >> install-python.ps1
    echo -e "{" >> install-python.ps1
    echo -e "\t[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12" >> install-python.ps1
    echo -e "\tInvoke-WebRequest -OutFile \"C:\\python-2.7.17.msi\" -Uri \"https://npm.taobao.org/mirrors/python/2.7.17/python-2.7.17.msi\"" >> install-python.ps1
    echo -e "\tC:\\python-2.7.17.msi /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 TargetDir=C:\\Python27" >> install-python.ps1
    echo -e "\t[Environment]::SetEnvironmentVariable(\"Path\", \$env:Path + \";C:\\Python27;C:\\Python27\\Scripts\", \"Machine\")" >> install-python.ps1
    echo -e "}" >> install-python.ps1
    echo -e "else" >> install-python.ps1
    echo -e "{" >> install-python.ps1
    echo -e "\tWrite-Host \"Python 2 has been installed\"" >> install-python.ps1
    echo -e "}" >> install-python.ps1
    echo -e "Vagrant.configure(\"2\") do |config|" > Vagrantfile
    echo -e "\tconfig.vm.box = \"datacastle/windows7\"" >> Vagrantfile
    echo -e "\tconfig.vm.network \"private_network\", ip: \"192.168.101.20\"" >> Vagrantfile
    echo -e "\tconfig.vm.provider \"virtualbox\" do |vb|" >> Vagrantfile
    echo -e "\t\tvb.name = \"cuckoo_windows7\"" >> Vagrantfile
    echo -e "\t\tvb.memory = \"2048\"" >> Vagrantfile
    echo -e "\tend" >> Vagrantfile
    echo -e '\tconfig.vm.provision "file", source: "~/cuckoo_windows7/agent.py", destination: "C:\\\\Users\\\\vagrant\\\\agent.pyw"' >> Vagrantfile
    echo -e '\tconfig.vm.provision "shell", path: "install-python.ps1"' >> Vagrantfile
    echo -e '\tconfig.vm.provision "shell", inline: "REG add \"HKLM\\\\SYSTEM\\\\CurrentControlSet\\\\services\\\\sppsvc\" /v Start /t REG_DWORD /d 4 /f"' >> Vagrantfile
    echo -e '\tconfig.vm.provision "shell", inline: "REG add \"HKLM\\\\SOFTWARE\\\\Microsoft\\\\Windows NT\\\\CurrentVersion\\\\Winlogon\" /v DefaultUserName /t REG_SZ /d vagrant /f"' >> Vagrantfile
    echo -e '\tconfig.vm.provision "shell", inline: "REG add \"HKLM\\\\SOFTWARE\\\\Microsoft\\\\Windows NT\\\\CurrentVersion\\\\Winlogon\" /v DefaultPassword /t REG_SZ /d vagrant /f"' >> Vagrantfile
    echo -e '\tconfig.vm.provision "shell", inline: "REG add \"HKLM\\\\SOFTWARE\\\\Microsoft\\\\Windows NT\\\\CurrentVersion\\\\Winlogon\" /v AutoAdminLogon /t REG_SZ /d 1 /f"' >> Vagrantfile
    echo -e '\tconfig.vm.provision "shell", inline: "Start-Sleep -s 30"' >> Vagrantfile
    echo -e '\tconfig.vm.provision "shell", inline: "Start-Process -NoNewWindow -FilePath \"C:\\\\Python27\\\\Scripts\\\\pip.exe\" -ArgumentList \"install\",\"Pillow\""' >> Vagrantfile
    echo -e '\tconfig.vm.provision "shell", inline: "schtasks.exe /create /sc ONSTART /tn \"RunCuckooAgent\" /ru \"SYSTEM\" /tr \"C:\\\\Python27\\\\python.exe C:\\\\Users\\\\vagrant\\\\agent.pyw\""' >> Vagrantfile
    echo -e "end" >> Vagrantfile
    vagrant up
fi

# Step 9: Disconnect NAT Interfaces on VMs
# Step 10: Create Snapshots of Configured VMs
if [ $1 == "all" ] || [ $1 == "ubuntu" ]; then
    cd ~/cuckoo_ubuntu
    vagrant halt
    vboxmanage modifyvm cuckoo_ubuntu --cableconnected1 off
    vboxmanage startvm cuckoo_ubuntu --type headless
    sleep 70
    vboxmanage snapshot cuckoo_ubuntu take cuckoo_snapshot --pause
    vboxmanage controlvm cuckoo_ubuntu poweroff
    vboxmanage snapshot cuckoo_ubuntu restorecurrent
fi
if [ $1 == "all" ] || [ $1 == "windows7" ]; then
    cd ~/cuckoo_windows7
    vagrant halt
    vboxmanage modifyvm cuckoo_windows7 --cableconnected1 off
    vboxmanage startvm cuckoo_windows7 --type headless
    sleep 90
    vboxmanage snapshot cuckoo_windows7 take cuckoo_snapshot --pause
    vboxmanage controlvm cuckoo_windows7 poweroff
    vboxmanage snapshot cuckoo_windows7 restorecurrent
fi

# Step 11: Remove default Cuckoo analysis machine and add our own
cd ~
source cuckoo_env/bin/activate
cuckoo machine --delete cuckoo1
if [ $1 == "all" ] || [ $1 == "ubuntu" ]; then
cuckoo machine --add cuckoo_ubuntu 192.168.101.10 --platform linux --snapshot cuckoo_snapshot
fi
if [ $1 == "all" ] || [ $1 == "windows7" ]; then
cuckoo machine --add cuckoo_windows7 192.168.101.20 --platform windows --snapshot cuckoo_snapshot
fi

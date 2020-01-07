## Cuckoo Automated Installation and Configuration

### What is Cuckoo?

[Cuckoo](https://cuckoo.readthedocs.io/en/latest/) is an open source automated malware analysis system.

It’s used to automatically run and analyze files and collect comprehensive analysis results that outline what the malware does while running inside an isolated operating system.

It can retrieve the following type of results:

- Traces of calls performed by all processes spawned by the malware.
- Files being created, deleted and downloaded by the malware during its execution.
- Memory dumps of the malware processes.
- Network traffic trace in PCAP format.
- Screenshots taken during the execution of the malware.
- Full memory dumps of the machines.


### Cuckoo Installation

This script provides instructions to start and configure a sandbox environment using Cuckoo and [Vagrant](https://www.vagrantup.com/) with [VirtualBox](https://www.virtualbox.org/wiki/VirtualBox) as VM Hypervisor. Before starting, ensure that Internet access has been granted for the node to be used as the host.

Please follow the instructions here closely as some of them are crucial steps that are not provided in the official Cuckoo documentation. It is highly recommended that you use Ubuntu-16.04 with GUI as the operating system for your node.

An automated installation script [INSTALL.sh](INSTALL.sh) is provided that will give you a basic working setup. To use this:

```
user@node:~$ sudo ./INSTALL.sh <all|ubuntu|windows7>
```

"Ubuntu" option to install Ubuntu VM for Malware Testing.

"Windows" option to install Windows7 VM for Malware Testing.

"All" option to install both VMs.

### Starting Cuckoo Controller
It is recommended to use Cuckoo in a virtual environment to prevent version conflicts as Cuckoo does not use the latest versions of some packages that it depends on. Both a global and a virtual environment installation are provided on the sample VM.

To start Cuckoo in a virtual environment, start the sample virtual environment $HOME/cuckoo_env. Other Cuckoo instances can be run by pointing the $CWD to the location of the respective instances.

```$xslt
user@node:~$ cd ~
user@node:~$ . cuckoo_env/bin/activate
(cuckoo_env) user@node:~$ cuckoo --cwd ~/.cuckoo
```

It is recommended to run Cuckoo in the background using supervisor:

```$xslt
user@node:~$ cd ~
user@node:~$ . cuckoo_env/bin/activate
(cuckoo_env) user@node:~$ cd .cuckoo
(cuckoo_env) user@node:~$ sudo ~/cuckoo_env/bin/supervisorctl start all -c supervisord.conf
```

Check the status using supervisor control:

```$xslt
(cuckoo_env) user@node:~$ ~/cuckoo_env/bin/supervisorctl status
```


### Starting Cuckoo Web Interface
Cuckoo provides a graphical web interface that is more intuitive to use. This can be started with:

```$xslt
user@node:~$ cd ~
user@node:~$ . cuckoo_env/bin/activate
(cuckoo_env) user@node:~$ cuckoo web runserver 0.0.0.0:<PORT>
```

The web interface can be used through VNC on the node using the NCL website. Malware and URL submissions can be made through the web interface, and the subsequent reports can also be viewed there.

### Submitting Malware for Analysis
Malware can be submitted through the command line or the web interface. For ease of use, the web interface is recommended. To do so, access localhost:<PORT> on a browser on your experiment node using the user interface. Please check the [user guide](Doc/NCL%20Cuckoo%20Manual.pdf) for the detail.

### Stopping Cuckoo
A running Cuckoo instance can be terminated by simply issuing a CTRL-C command.
If using supervisord, Cuckoo can be stopped by:

```$xslt
user@node:~$ cd ~
user@node:~$ . cuckoo_env/bin/activate
(cuckoo_env) user@node:~$ cd .cuckoo
(cuckoo_env) user@node:~$ sudo ~/cuckoo_env/bin/supervisorctl stop all
cuckoo:
```

### Clear All Previous Records

To clear all the previous analysis results and binaries, run the following:

```$xslt
user@node:~$ cd ~
user@node:~$ . cuckoo_env/bin/activate
(cuckoo_env) user@node:~$ cuckoo clear
```
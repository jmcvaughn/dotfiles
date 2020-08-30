# home-server branch
The documentation and scripts in this branch were copied and modified from my old [server_setup](https://github.com/jmcvaughn/server_setup) repository. For these components, this branch can be considered a continuation of that repository.

## Installation
For my configuration, most working data is stored in separate ZFS file systems. As a result, the boot disk partitioning scheme doesn't matter too much; an ESP partition and a root partition is sufficient. If a disaster occurs, the installation can be rebuilt with minimal effort.

As of Subiquity 20.04.2, the creation of multiple ESPs is supported. However, this functionality is only supported if booting newer installers; updating doesn't work. Therefore, you must use the Ubuntu Server 20.04.1 LTS live disk image or newer. To set up multiple ESPs, at the *Guided storage configuration* page, select *Custom storage layout*. Under the *Storage configuration* page, select *Use As Boot Device* and *Add As Another Boot Device* for your primary and backup devices respectively.

At the *SSH Setup* screen, remember to select *Install OpenSSH server*.

There is no requirement to install any snaps at the *Featured Server Snaps* screen; those required are installed by the scripts in this repository.

## System setup
Prior to running `setup.sh`:
- Install the ZFS utilities:
```
$ sudo apt-get update && sudo apt-get -y install zfsutils-linux
```

- Manually import and mount/create ZFS pools and datasets as required.

After running `setup.sh`, enable [Canonical Livepatch](https://ubuntu.com/livepatch).

## OpenStack
All virtualisation requirements are met by OpenStack, running on LXD. `setup.sh` configures LXD and Juju as required, while `openstack.sh` adds the model, configures its profile, and deploys the openstack.yaml bundle.

glance-simplestreams-sync is used to manage Ubuntu images; these do not need to be added manually.

Note all of this is performed under Juju's "admin" user; see the [Add the OpenStack cloud as Juju](#optional-add-the-openstack-cloud-to-juju) section for recommended Juju usage.

### Post-deployment setup
The commands in this section are examples; modify as appropriate.

#### Set the timezone
By default, all the LXD containers will be using the Etc/UTC timezone. Correct this as follows:
```
$ for i in $(ju machines | awk '!/Machine/ { print $1 }'); do ju ssh $i sudo timedatectl set-timezone Europe/London; done
```

While it is possible to do this using `juju run --all` and appears to work without issue, `action cancelled` errors seem to (falsely) appear.

#### Obtain the admin OpenStack RC file
Obtain the admin user's password:
```
$ juju run --unit keystone/0 leader-get admin_passwd
```

Obtain the OpenStack Dashboard IP address:
```
$ juju status | grep openstack-dashboard
```

Log in to the OpenStack Dashboard at http://<DASHBOARD_IP>/horizon/ using the "admin_domain" domain, the "admin" user and the password obtained above. Once logged in, download the OpenStack RC file from the top-right menu.

#### Create provider network and subnet
```
$ openstack network create --share --external --provider-network-type flat --provider-physical-network physnet1 provider
$ openstack subnet create --network provider --allocation-pool start=10.188.1.1,end=10.188.1.254 --dns-nameserver 10.188.0.1 --gateway 10.188.0.1 --subnet-range 10.188.0.0/16 provider-subnet
```

#### Create flavours
```
$ openstack flavor create --public --ram 1024 --disk 20 --vcpus 1 xs
$ openstack flavor create --public --ram 2048 --disk 20 --vcpus 1 s
$ openstack flavor create --public --ram 4096 --disk 40 --vcpus 2 m
$ openstack flavor create --public --ram 8192 --disk 60 --vcpus 4 l
$ openstack flavor create --public --ram 16384 --disk 80 --vcpus 8 xl
$ openstack flavor create --public --ram 32768 --disk 80 --vcpus 8 xxl
$ openstack flavor create --public --ram 65536 --disk 80 --vcpus 8 xxxl
$ openstack flavor create --public --ram 98304 --disk 80 --vcpus 8 xxxxl
$ openstack flavor create --public --ram 2048 --disk 20 --vcpus 1 --ephemeral-disk 5 s5  # Mainly for Ceph testing
```

#### Set up users and domains
Much like you wouldn't use the "root" user for day-to-day work on a personal machine, don't use the "admin" user and the "admin_domain" domain for your workloads.

As from the command line the following tasks at minimum require changing domain/project contexts or using IDs, these tasks are most quickly performed in the OpenStack Dashboard.

Log in to the OpenStack Dashboard as "admin" as detailed in [Obtain the admin OpenStack RC file](#obtain-the-admin-openstack-rc-file). Under the Identity tab, repeat the following tasks for each required domain:
- Create a domain, then click "Set Domain Context" to manage it
- Create users
- Create projects
- Set users as domain Admins/Members
- Assign memberships and primary projects to users
- Set project quotas - remember that in addition to increasing instance quotas you will need to increase other quotas accordingly, e.g. network ports, security groups and rules, among others.

As a user:
- Import an SSH public key (per user)
- Add ingress rules for ICMP and SSH to the default security group (per project)
- Create a network and subnet, and a router to connect to the provider network (per project)
- Download the OpenStack RC file

## Juju
`openstack.sh` deploys OpenStack to the local LXD cloud using Juju, so it may seem strange to place this section after the [OpenStack](#openstack) section. There are two reasons for doing this:

- Juju can be set up to use this OpenStack installation as another cloud, with the steps needing to be performed after the OpenStack deployment.
- For normal workloads, users should not use Juju's "admin" user. However, it is less hassle to keep the OpenStack deployment under the root user.

The ideal interaction between Juju, OpenStack, and users can be summarised as follows:
- The OpenStack cloud is added to the Juju controller
- Users have accounts on both the Juju controller and OpenStack
- Users login to and interact with the Juju controller from their `juju` command line client, whether remotely (e.g. laptop), locally, or both
- Users add the cloud to their client, and add credentials for their accounts on the OpenStack cloud to use Juju in their own project

The following sections will run through the full setup process as per my requirements; refer to the [Juju documentation](https://juju.is/docs) as a definitive resource.

### OpenStack setup
Juju can only use the primary OpenStack project for a user. If a separate project is desired:
- Create a new project
- Create a dedicated Juju user with the new project as its default
- Add your normal user to the project as an Admin/Member as required for easier management outside of Juju

The following changes will need to be made to the project:
- Project quotas will need to be set
- A network named "juju-default" (or another arbitrary name), a subnet within and a router to connect this to the provider network will need to be created

Juju will automatically create SSH keys and manage security groups and rules.

### Creating juju.yaml
Copy [juju_template.yaml](juju_template.yaml) and modify it as required. This file will be used to configure both the controller and the client. It is presumed this will be located at /tmp/juju.yaml.

### Add the OpenStack cloud to the controller
Run the following command:
```
$ juju add-cloud --controller "$(hostname -s)" openstack /tmp/juju.yaml
```
The `credentials` section will be ignored; ignore the warning.

Set defaults for OpenStack models:
```
$ juju model-defaults openstack network=juju-default use-floating-ip=true  # Replace with network created previously
```
These can be overridden on a per-model basis. A couple of things to note:
- `network=juju-default` does not refer to a specific network. As before, Juju can only use the primary project for the OpenStack user as per the credential currently in use, so "juju-default" is the name of a network that exists in this project.
- Floating IPs are required to SSH into instances.

### Create a user account on the Juju controller and logging in
Create your user and grant access to the OpenStack cloud:
```
$ juju add-user jamesvaughn
$ juju grant-cloud jamesvaughn add-model openstack
```

`juju add-user` will generate a `juju register` command to setup your client. Copy this command and run it on your client:
```
~ % juju register <HASH>
Since Juju 2 is being run for the first time, downloading latest cloud information.
Fetching latest public cloud list...
This client's list of public clouds is up to date, see `juju clouds --client-only`.
Enter a new password:
Confirm password:
Enter a name for this controller [jvaughnserver]:
Initial password successfully set for jamesvaughn.

Welcome, jamesvaughn. You are now logged into "jvaughnserver".

There are no models available. You can add models with
"juju add-model", or you can ask an administrator or owner
of a model to grant access to that model with "juju grant".
```

### Add the OpenStack cloud to the client
Copy /tmp/juju.yaml to the client machine, and run:
```
$ juju add-cloud --client openstack /tmp/juju.yaml
$ juju add-credential --controller jvaughnserver --client -f /tmp/juju.yaml openstack
```

Then set the default region for convenience:
```
$ juju default-region openstack RegionOne
```

### Change Juju "admin" user password and logout
For security and safety purposes—again, largely to prevent accidental modification to the OpenStack cloud—it is best to log out of the "admin" account on the server. However, to do this, the password must be changed. On the server, run:
```
$ juju change-user-password
```

Then log out:
```
$ juju logout
```

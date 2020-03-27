# Motivation.

Systemd-nspawn provides a simple wrapper to handle light-weight containers. Due
to technical debt, OpenXT requires the build host environment to include some
tools unlikely to be desirable in the host. Systemd-nspawn offers a chroot
capability with benefits, is readily available and integrates in systemd
swiftly.

If Docker is more to your liking, this repository also provides Dockerfiles.

# Create a systemd-nspawn environment.

## Install Debian 10.3 (buster)

Most distribution use /var/lib/machines for systemd-nspawn containers rootfs by
default, so the following will use that.
```sh
# mkdir /var/lib/machines/deb10-3-base
# debootstrap --include=systemd-container stable /var/lib/machines/deb10-3-base/
```

## Install Debian 8.11 (jessie)

```sh
# mkdir /var/lib/machines/deb10-3-base
# debootstrap --include=dbus stable /var/lib/machines/deb8-11-base/
```

`machinectl shell` was introduced in v225, so you will have to `machinectl
login` to a Debian 8.11 container. Amend or remove `/etc/securetty` if you plan
to login as root. Alternatively, you can run OpenSSH inside the container and
ssh to it.

## BTRFS snapshot (optional)

```sh
# btrfs subvol list /var/lib/machines/
ID 258 gen 25249 top level 5 path deb10-3-base
# cd /var/lib/machines
# btrfs subvol snapshot deb10-3-base deb10-3-openxt
```

## Setup the build host environment

Convenience setup scripts are provided in this directory.
```sh
# cp ./mkdeb10-3-openxt.sh /var/lib/machines/deb10-3-openxt/root/
# systemd-nspawn -D /var/lib/machines/deb10-3-openxt
# ./mkdeb10-3-openxt.sh
[...]5-10 minutes[...]
```

## Setup the container for manual builds.

Because OpenXT uses a lot of storage space to build, it might be preferable to
bind a directory from the host in the namespace. This unfortunately requires to
turn off user namespaces (PrivateUsers) and, provided a host user will use the
built sources and build output, will necessitate to align a user/group IDs
between the container and the host.

```sh
user@host $ echo $UID:$GROUPS
1000:1000
user@host $ su -
root@host # systemd-nspawn -U -D /var/lib/machines/deb10-3-openxt/
root@deb10-3-openxt # useradd -u 1000 -g 1000 -m -s /bin/bash user
```
To change an existing user, also `chown` the user's files and other files it
possesses:
```sh
root@deb10-3-openxt # groupmod -g 1000 user
root@deb10-3-openxt # usermod -u 1000 user
root@deb10-3-openxt # chown -R user:user /home/user
```

```sh
root@host # systemd-nspawn -U -u user -D /var/lib/machines/deb10-3-openxt --bind /var/builds/openxt:/var/builds/openxt
```

Setting up a Virtual Ethernet is preferred for internet access from the
container:
```sh
root@host # cat /etc/systemd/nspawn/deb10-3-openxt.nspawn
[Exec]
PrivateUsers=0

[Network]
VirtualEthernet=yes

[Files]
Bind=/var/builds/openxt:/var/builds/openxt
```

This should be enough to let `machinectl` handle that container. Setup the
network daemons in the container.
```sh
root@host # machinectl start deb10-3-openxt
root@host # machinectl shell deb10-3-openxt
root@deb10-3-openxt # systemctl start systemd-networkd.service
root@deb10-3-openxt # systemctl enable systemd-networkd.service
root@deb10-3-openxt # ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
root@deb10-3-openxt # systemctl start systemd-resolved.service
root@deb10-3-openxt # systemctl enable systemd-resolved.service
```

If you use `iptables`, you need to let the containers negotiate an IP with the
host (the following allows all containers veth) and access the network:
```sh
root@host # iptables -A FORWARD -i ve-+ -o eth0 -j ACCEPT
root@host # iptables -A FORWARD -i eth0 -o ve-+ -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
root@host # iptables -A UDP -i ve-+ -p udp -m udp --dport 5355 -m comment --comment LLMNR-systemd-resolve -j ACCEPT
root@host # iptables -A UDP -i ve-+ -p udp -m udp --dport 67 -m comment --comment DHCP -j ACCEPT
```

You can start the container in background, then request a shell in it to build OpenXT.
```sh
root@host # machinectl start deb10-3-openxt
root@host # machinectl shell user@deb10-3-openxt
user@deb10-3-openxt $ mkdir /var/builds/openxt/tree
user@deb10-3-openxt $ cd /var/builds/openxt/tree
user@deb10-3-openxt $ repo init -u https://github.com/apertussolutions/openxt-manifest.git
user@deb10-3-openxt $ repo sync
user@deb10-3-openxt $ export PATH="${PATH}:$(pwd)/openxt/bordel"
user@deb10-3-openxt $ bordel config -i 0
user@deb10-3-openxt $ bordel build
```

Note: You might want to run `repo init` outside the container if you plan to
use your host user configuration.

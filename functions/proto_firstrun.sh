proto_firstrun ()
{
    RR_CMD=$(cat rr_cmd)
    cat > firstboot <<EOF
set -e
cd /root
LOG_FILE=/root/proto_firstboot.log
if ! grep "clean_requirements_on_remove=1" /etc/yum.conf
then
    echo "clean_requirements_on_remove=1" >> /etc/yum.conf
fi
systemctl stop NetowrkManager | tee -a \$LOG_FILE
systemctl disable NetworkManager | tee -a \$LOG_FILE
yum remove -y cloud-init* NetworkManager* *bigswitch* | tee -a \$LOG_FILE

dhclient eth0 | tee -a \$LOG_FILE

if [ -r files.tar ]
then
    tar xf files.tar
    rpm -Uvh *rpm --nodeps | tee -a \$LOG_FILE
fi

rm -rf /etc/yum.repos.d/* /var/cache/yum/*
rhos-release $RR_CMD

# Updating the system.
yum update -y | tee -a \$LOG_FILE
yum groups mark convert | tee -a \$LOG_FILE

# Installing packagaes I like having.
yum install -y acpid ahc-tools createproto crudini device-mapper-multipath \
dosfstools elinks gdb gdisk genisoimage git gpm hdparm ipmitool \
iscsi-initiator-utils keepalived libvirt lsof mc mlocate net-tools ntp \
plotnetcfg psmisc python-setuptools screen setroubleshoot sos sshpass \
sysstat telnet tmux traceroute tree vim wget | tee -a \$LOG_FILE

# Installing development packages.
yum group install -y "Development Tools" | tee -a \$LOG_FILE

# Installing OpenStack stuff.
yum install -y python-tripleoclient openstack-aodh-common \
openstack-ceilometer-common openstack-gnocchi-common openstack-heat-common \
openstack-ironic-common openstack-mistral-common openstack-neutron-common \
openstack-nova-common openstack-panko-common | tee -a \$LOG_FILE

if ls *.conf 2> /dev/null
then
    for conf in $(ls *.conf)
    do
        cp $conf /etc
    done
fi

# creating a SWAP file and compresssing it.
if [ $undercloud_SWP -gt 100 ]
then
    dd if=/dev/zero of=/swap bs=1M count=$undercloud_SWP | tee -a \$LOG_FILE
    chmod 600 /swap | tee -a \$LOG_FILE
    mkswap /swap | tee -a \$LOG_FILE
    echo /swap none swap defaults 0 0 >> /etc/fstab
fi

# cleaning up and some tweaks
rm -rf /etc/yum.repos.d/* /var/cache/yum/*
echo "Some VIM settings" | tee -a \$LOG_FILE
cat > /etc/vimrc <<END
syntax on
set background=dark
set backspace=2
set colorcolumn=78
set completeopt=menuone,longest,preview
set encoding=utf8
set expandtab
set fileformats=unix
set hlsearch
set laststatus=2
set linebreak
set matchpairs+=(:)
set matchpairs+=<:>
set matchpairs+=[:]
set matchpairs+={:}
set nocompatible
set nonu
set nowrap
set numberwidth=1
set omnifunc=syntaxcomplete#Complete
set ruler
set shiftwidth=4
set showmatch
set softtabstop=4
set tabstop=4

filetype plugin on
filetype indent on

highlight Pmenu ctermfg=cyan ctermbg=blue
highlight PmenuSel ctermfg=black ctermbg=cyan
highlight ColorColumn ctermbg=0
END

echo "Enabling some needed services." | tee -a \$LOG_FILE
systemctl enable gpm | tee -a \$LOG_FILE
systemctl enable acpid | tee -a \$LOG_FILE
systemctl start acpid | tee -a \$LOG_FILE

echo "Enabling tty-less sudo use." | tee -a \$LOG_FILE
sed -i '/requiretty/d' /etc/sudoers

echo "Setting Selinux." | tee -a \$LOG_FILE
sed -i "s/SELINUX=.*/SELINUX=$OVER_SEL/" /etc/selinux/config
grep "SELINUX=" /etc/selinux/config | tee -a \$LOG_FILE

echo "Setting time."
timedatectl set-timezone $GUEST_TZ | tee -a \$LOG_FILE
if [ ! -d /root/.ssh ]
then
    mkdir /root/.ssh
    chmod 0700 /root/.ssh
fi

echo "Setting prompt." | tee -a \$LOG_FILE
sed -i '/PS1/d' /root/.bashrc
echo "PS1='\[\033[01;31m\]\u@\h\] \w \$\[\033[00m\] '" >> /root/.bashrc

echo "Updating locate db and adding it to cron." | tee -a \$LOG_FILE
updatedb
ln -s /usr/bin/updatedb /etc/cron.hourly

echo "Allowing a more comfortable SSH connections." | tee -a \$LOG_FILE
cat > /etc/ssh/ssh_config <<END
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    CheckHostIp no
END

ln -s /dev/null /root/.ssh/known_hosts

echo "Adding user stack." | tee -a \$LOG_FILE
useradd stack | tee -a \$LOG_FILE
echo stack | passwd stack --stdin
echo "stack ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack

echo "Shutting down now." | tee -a \$LOG_FILE
shutdown -hP -t 0 now | tee -a \$LOG_FILE

EOF
    chmod +x firstboot
    try virt-customize $CUST_ARGS -a $VIRT_IMG/proto.qcow2 --firstboot ./firstboot || failure
}

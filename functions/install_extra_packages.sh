install_extra_packages ()
{
    install_from_epel ()
    {
        echo "Downloading $1"
        try wget -q -nv -r -nd -np ${EPEL}/${1:0:1}/ -A "${1}*rpm" || failure
        if rpm -qa | grep $1 &> /dev/null
        then
            echo "$1 is already installed, skipping."
        else
            echo "Installing $1"
            try rpm -Uvh ${1}*rpm || failure
        fi
    }

    try wget -q -nv $LATEST_RR || failure
    try wget -q -nv $RHEL_GUEST || failure
    
    for package in "python-psutil" "nethogs" "htop" "glances" "sshpass"
    do
        install_from_epel $package
    done

    tar cf files.tar *.rpm *.conf
    rm -rf *.rpm
}

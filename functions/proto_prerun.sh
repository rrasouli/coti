proto_prerun ()
{
    try virt-customize $CUST_ARGS -a $VIRT_IMG/proto.qcow2 --selinux-relabel --root-password password:${ROOT_PASS} || failure
    try virt-sysprep -q -a $VIRT_IMG/proto.qcow2 --upload $WORK_DIR/files.tar:/root || failure
}

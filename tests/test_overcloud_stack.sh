# Test parameters.
NAME="Test overcloud stack status"
DESCRIPTION="Testing that the overcloud stack status is CREATE_COMPLETE."
TAG="overcloud"

# Source the environment and the project's configuration.                     
source /home/stack/stackrc 2> /dev/null                                       
source /home/stack/tests/env 2> /dev/null                                     
                                                                              
# Exit on the first error.                                                    
set -e

# Test starts here.
openstack stack list | grep -e overcloud.*CREATE_COMPLETE &> /dev/null

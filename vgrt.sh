#!/bin/bash

help() {
   # Display Help
   echo "Up/Destroy VMs with vagrant."
   echo
   echo "Syntax: $0 [-s|d|h]"
   echo "options:"
   echo "s     Setup."
   echo "d     Destroy."
   echo "h     Print this Help."
   echo
}

chkexit() {
  code="$1"
  msg="$2"

  if [ $code -eq 0 ]; then
    echo " $msg .. OK "
  else
    echo " $msg .. FAIL "
    exit 1

  fi
}

setup() {
	echo "Vagrant setup .. "
	# initial VM setup
	vagrant up

	# Run some other tasks on running VM (e.g. backup in this example)
	vagrant provision --provision-with jenkins
}

destroy() {
	echo "Vagrant destroy .. "
	vagrant destroy -f
}

while getopts ":hsd" option; do
   case $option in
      h) # display Help
		help
        exit 0
        ;;
      s) 
		setup
		chkexit $? "setup is "
		;;
      d) 
		destroy
		chkexit $? "destroy is"
		;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit 1
         ;;
   esac
done

#!/bin/bash

end_of_file=0
while [[ $end_of_file == 0 ]]
do
  read -r line
  # the last exit status is the 
  # flag of the end of file
  end_of_file=$?
  echo $line
  git clone http://git.openstack.org/openstack/$line /etc/puppet/modules/
done < "openstack_modules.txt"

end_of_file=0
while [[ $end_of_file == 0 ]]
do
  read -r line
  # the last exit status is the 
  # flag of the end of file
  end_of_file=$?
  echo $line
  puppet module install $line
done < "external_modules.txt"

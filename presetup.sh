#!/bin/bash

while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "$line"
    git clone http://git.openstack.org/openstack/puppet-$line /etc/puppet/modules/$line
done < "openstack_modules.txt"

while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "$line"
    puppet module install $line
done < "external_modules.txt"

mkdir /etc/puppet/modules/openstack
cp manifests /etc/puppet/modules/openstack -r

if $::osfamily == 'RedHat' {
    
  include openstack_extras::repo::redhat::redhat

} elsif $::osfamily == 'Debian' {
  if $::operatingsystem == 'ubuntu' {
     include openstack_extras::repo::debian::ubuntu
  }

}

include ::openstack
include ::openstack::rabbitmq
include ::openstack::mysql
include ::openstack::keystone
include ::openstack::glance
include ::openstack::neutron
include ::openstack::nova
include ::openstack::cinder
include ::openstack::horizon
#include ::openstack::provision

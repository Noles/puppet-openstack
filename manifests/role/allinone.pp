class openstack::role::allinone inherits ::openstack::role {
  class { '::openstack::rabbitmq': }
  class { '::openstack::mysql': }
  class { '::openstack::keystone': }
  class { '::openstack::glance': }
  class { '::openstack::neutron': }
  class { '::openstack::nova': }
  class { '::openstack::cinder': }
  class { '::openstack::horizon': }
  #class { '::openstack::provision': }
}

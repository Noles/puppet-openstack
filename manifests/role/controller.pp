class openstack::role::controller inherits ::openstack::role {
  class { '::openstack::rabbitmq': }
  class { '::openstack::mysql': }
  class { '::openstack::keystone': }
 
  class { '::openstack::glance': }
  class { '::openstack::resource::neutron::server': } ->
  class { '::openstack::resource::neutron::network': }
  class { '::openstack::resource::nova::compute': }
  class { '::openstack::resource::cinder::api': }
  
  class { '::openstack::horizon': }
  #class { '::openstack::provision': }
}

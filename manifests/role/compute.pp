class openstack::role::compute inherits ::openstack::role {
  class { '::openstack::resource::neutron::agent': }
  class { '::openstack::resource::nova::compute': }
  
  class { '::openstack::resource::cinder::volume': }
}

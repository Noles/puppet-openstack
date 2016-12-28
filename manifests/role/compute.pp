class openstack::role::compute inherits ::openstack::role {
  class { '::openstack::neutron::agent': }
  class { '::openstack::nova::compute': }
}

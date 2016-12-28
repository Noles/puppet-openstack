class openstack::resource::cinder::volume {

  include ::openstack::config
  include ::openstack::params  
  include ::openstack::resource::cinder
  
  class { '::cinder::volume':
    volume_clear => 'none',
  }
}

class openstack::resource::cinder {

  class { '::cinder':
    default_transport_url => os_transport_url({
      'transport' => 'rabbit',
      'host'      => $::openstack::config::host,
      'port'      => $::openstack::config::rabbit_port,
      'username'  => 'cinder',
      'password'  => 'an_even_bigger_secret',
    }),
    database_connection   => 'mysql+pymysql://cinder:cinder@127.0.0.1/cinder?charset=utf8',
    rabbit_use_ssl        => $::openstack::config::ssl,
    debug                 => true,
  }

  class { '::cinder::glance':
    glance_api_servers => "${::openstack::config::base_url}:9292",
  }
}

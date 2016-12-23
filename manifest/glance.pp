# Configure the Glance service
#
# [*backend*]
#   (optional) Glance backend to use.
#   Can be 'file', 'swift' or 'rbd'.
#   Defaults to 'file'.
#
class openstack::glance (
  $backend = 'file',
) {

  include ::openstack::config
  include ::openstack::params

  if $::openstack::config::ssl {
    openstack_integration::ssl_key { 'glance':
      notify => [Service['glance-api'], Service['glance-registry']],
    }
    Package<| tag == 'glance-package' |> -> File['/etc/glance/ssl']
    $key_file  = "/etc/glance/ssl/private/${::fqdn}.pem"
    $crt_file = $::openstack::params::cert_path
    Exec['update-ca-certificates'] ~> Service['glance-api']
    Exec['update-ca-certificates'] ~> Service['glance-registry']
  } else {
    $key_file = undef
    $crt_file  = undef
  }

  rabbitmq_user { 'glance':
    admin    => true,
    password => 'an_even_bigger_secret',
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq'],
  }
  rabbitmq_user_permissions { 'glance@/':
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => Class['::rabbitmq'],
  }

  class { '::glance::db::mysql':
    password => 'glance',
  }
  include ::glance
  include ::glance::client
  class { '::glance::keystone::auth':
    public_url   => "${::openstack::config::base_url}:9292",
    internal_url => "${::openstack::config::base_url}:9292",
    admin_url    => "${::openstack::config::base_url}:9292",
    password     => 'a_big_secret',
  }
  class { '::glance::api::authtoken':
    password            => 'a_big_secret',
    user_domain_name    => 'Default',
    project_domain_name => 'Default',
    auth_url            => $::openstack::config::keystone_admin_uri,
    auth_uri            => $::openstack::config::keystone_auth_uri,
    memcached_servers   => $::openstack::config::memcached_servers,
  }
  class { '::glance::registry::authtoken':
    password            => 'a_big_secret',
    user_domain_name    => 'Default',
    project_domain_name => 'Default',
    auth_url            => $::openstack::config::keystone_admin_uri,
    auth_uri            => $::openstack::config::keystone_auth_uri,
    memcached_servers   => $::openstack::config::memcached_servers,
  }
  case $backend {
    'file': {
      include ::glance::backend::file
      $backend_store = ['file']
    }
    'rbd': {
      class { '::glance::backend::rbd':
        rbd_store_user => 'openstack',
        rbd_store_pool => 'glance',
      }
      $backend_store = ['rbd']
      # make sure ceph pool exists before running Glance API
      Exec['create-glance'] -> Service['glance-api']
    }
    'swift': {
      $backend_store = ['swift']
      class { '::glance::backend::swift':
        swift_store_user                    => 'services:glance',
        swift_store_key                     => 'a_big_secret',
        swift_store_create_container_on_put => 'True',
        swift_store_auth_address            => "${::openstack_integration::config::keystone_auth_uri}/v3",
        swift_store_auth_version            => '3',
      }
    }
    default: {
      fail("Unsupported backend (${backend})")
    }
  }
  $http_store = ['http']
  $glance_stores = concat($http_store, $backend_store)
  class { '::glance::api':
    debug                     => true,
    database_connection       => 'mysql+pymysql://glance:glance@127.0.0.1/glance?charset=utf8',
    workers                   => 2,
    stores                    => $glance_stores,
    default_store             => $backend,
    bind_host                 => $::openstack::config::host,
    registry_client_protocol  => $::openstack::config::proto,
    registry_client_cert_file => $crt_file,
    registry_client_key_file  => $key_file,
    registry_host             => $::openstack::config::host,
    cert_file                 => $crt_file,
    key_file                  => $key_file,
  }
  class { '::glance::registry':
    debug               => true,
    database_connection => 'mysql+pymysql://glance:glance@127.0.0.1/glance?charset=utf8',
    bind_host           => $::openstack::config::host,
    workers             => 2,
    cert_file           => $crt_file,
    key_file            => $key_file,
  }
  class { '::glance::notify::rabbitmq':
    default_transport_url => os_transport_url({
      'transport' => 'rabbit',
      'host'      => $::openstack::config::host,
      'port'      => $::openstack::config::rabbit_port,
      'username'  => 'glance',
      'password'  => 'an_even_bigger_secret',
    }),
    notification_driver   => 'messagingv2',
    rabbit_use_ssl        => $::openstack::config::ssl,
  }

}

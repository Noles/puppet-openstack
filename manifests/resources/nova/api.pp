# Configure the Nova service
class openstack::resource::nova::api {

  include ::openstack::config
  include ::openstack::params 

  if $::openstack::config::ssl {
    openstack::ssl_key { 'nova':
      notify  => Service['httpd'],
      require => Package['nova-common'],
    }
    Exec['update-ca-certificates'] ~> Service['httpd']
  }

  $transport_url = os_transport_url({
    'transport' => 'rabbit',
    'host'      => $::openstack::config::host,
    'port'      => $::openstack::config::rabbit_port,
    'username'  => 'nova',
    'password'  => 'an_even_bigger_secret',
  })

  rabbitmq_user { 'nova':
    admin    => true,
    password => 'an_even_bigger_secret',
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq'],
  }
  rabbitmq_user_permissions { 'nova@/':
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => Class['::rabbitmq'],
  }
  Rabbitmq_user_permissions['nova@/'] -> Service<| tag == 'nova-service' |>

  class { '::nova::db::mysql':
    password => 'nova',
  }
  class { '::nova::db::mysql_api':
    password    => 'nova',
    #TODO(aschultz): remove this once it becomes default
    setup_cell0 => true,
  }
  class { '::nova::db::sync_cell_v2':
    transport_url => $transport_url,
  }
  class { '::nova::keystone::auth':
    public_url   => "${::openstack::config::base_url}:8774/v2.1",
    internal_url => "${::openstack::config::base_url}:8774/v2.1",
    admin_url    => "${::openstack::config::base_url}:8774/v2.1",
    password     => 'a_big_secret',
  }
  class { '::nova::keystone::authtoken':
    password            => 'a_big_secret',
    user_domain_name    => 'Default',
    project_domain_name => 'Default',
    auth_url            => $::openstack::config::keystone_admin_uri,
    auth_uri            => $::openstack::config::keystone_auth_uri,
    memcached_servers   => $::openstack::config::memcached_servers,
  }

  include ::openstack::resource::nova

  class { '::nova::api':
    api_bind_address                     => $::openstack::config::host,
    neutron_metadata_proxy_shared_secret => 'a_big_secret',
    metadata_workers                     => 2,
    default_floating_pool                => 'public',
    sync_db_api                          => true,
    service_name                         => 'httpd',
  }
  include ::apache
  class { '::nova::wsgi::apache':
    bind_host => $::openstack::config::ip_for_url,
    ssl_key   => "/etc/nova/ssl/private/${::fqdn}.pem",
    ssl_cert  => $::openstack::params::cert_path,
    ssl       => $::openstack::config::ssl,
    workers   => '2',
  }
  class { '::nova::client': }
  class { '::nova::conductor': }
  class { '::nova::consoleauth': }
  class { '::nova::cron::archive_deleted_rows': }
  
  class { '::nova::scheduler': }
  class { '::nova::scheduler::filter': }
  class { '::nova::vncproxy': }
}

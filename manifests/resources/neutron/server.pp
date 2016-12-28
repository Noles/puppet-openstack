class openstack::resource::neutron::server {
  include ::openstack::config
  include ::openstack::params

  if $::openstack::config::ssl {
    openstack::ssl_key { 'neutron':
      notify  => Service['neutron-server'],
      require => Package['neutron'],
    }
    Exec['update-ca-certificates'] ~> Service['neutron-server']
  }

  rabbitmq_user { 'neutron':
    admin    => true,
    password => 'an_even_bigger_secret',
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq'],
  }
  rabbitmq_user_permissions { 'neutron@/':
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => Class['::rabbitmq'],
  }
  Rabbitmq_user_permissions['neutron@/'] -> Service<| tag == 'neutron-service' |>
  
  class { '::neutron::db::mysql':
    password => 'neutron',
  }

  class { '::neutron::client': }
  class { '::neutron::keystone::authtoken':
    password            => 'a_big_secret',
    user_domain_name    => 'Default',
    project_domain_name => 'Default',
    auth_url            => $::openstack::config::keystone_admin_uri,
    auth_uri            => $::openstack::config::keystone_auth_uri,
    memcached_servers   => $::openstack::config::memcached_servers,
  }
  class { '::neutron::server':
    database_connection => 'mysql+pymysql://neutron:neutron@127.0.0.1/neutron?charset=utf8',
    sync_db             => true,
    api_workers         => 2,
    rpc_workers         => 2,
    service_providers   => ['LOADBALANCER:Haproxy:neutron_lbaas.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default',
                            'LOADBALANCERV2:Haproxy:neutron_lbaas.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default',
                            'FIREWALL:Iptables:neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver:default'],
  }
  class { '::neutron::plugins::ml2':
    type_drivers         => ['vxlan', 'flat'],
    tenant_network_types => ['vxlan', 'flat'],
    mechanism_drivers    => $driver,
    firewall_driver      => $firewall_driver,
  }
  class { '::neutron::server::notifications':
    auth_url => $::openstack::config::keystone_admin_uri,
    password => 'a_big_secret',
  }
}

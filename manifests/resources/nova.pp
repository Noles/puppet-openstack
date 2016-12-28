class openstack::resource::nova {

  $transport_url = os_transport_url({
    'transport' => 'rabbit',
    'host'      => $::openstack::config::host,
    'port'      => $::openstack::config::rabbit_port,
    'username'  => 'nova',
    'password'  => 'an_even_bigger_secret',
  })

  class { '::nova':
    default_transport_url   => $transport_url,
    database_connection     => 'mysql+pymysql://nova:nova@127.0.0.1/nova?charset=utf8',
    api_database_connection => 'mysql+pymysql://nova_api:nova@127.0.0.1/nova_api?charset=utf8',
    rabbit_use_ssl          => $::openstack::config::ssl,
    use_ipv6                => $::openstack::config::ipv6,
    glance_api_servers      => "${::openstack::config::base_url}:9292",
    debug                   => true,
    notification_driver     => 'messagingv2',
    notify_on_state_change  => 'vm_and_task_state',
  }
  
  class { '::nova::network::neutron':
    neutron_auth_url => "${::openstack::config::keystone_admin_uri}/v3",
    neutron_url      => "${::openstack::config::base_url}:9696",
    neutron_password => 'a_big_secret',
  }
}

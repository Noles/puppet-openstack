class openstack::resource::neutron {

  class { '::neutron':
    default_transport_url => os_transport_url({
      'transport' => 'rabbit',
      'host'      => $::openstack::config::host,
      'port'      => $::openstack::config::rabbit_port,
      'username'  => 'neutron',
      'password'  => 'an_even_bigger_secret',
    }),
    rabbit_use_ssl        => $::openstack::config::ssl,
    allow_overlapping_ips => true,
    core_plugin           => 'ml2',
    service_plugins       => ['router', 'metering', 'firewall', 'lbaasv2'],
    debug                 => true,
    bind_host             => $::openstack::config::host,
    use_ssl               => $::openstack::config::ssl,
    cert_file             => $::openstack::params::cert_path,
    key_file              => "/etc/neutron/ssl/private/${::fqdn}.pem",
  }
}

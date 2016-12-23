class openstack::rabbitmq {

  include ::openstack::params
  include ::openstack::config

  if $::openstack::config::ssl {
    file { '/etc/rabbitmq/ssl/private':
      ensure                  => directory,
      owner                   => 'root',
      mode                    => '0755',
      selinux_ignore_defaults => true,
      before                  => File["/etc/rabbitmq/ssl/private/${::fqdn}.pem"],
    }
    openstack::ssl_key { 'rabbitmq':
      key_path => "/etc/rabbitmq/ssl/private/${::fqdn}.pem",
      require  => File['/etc/rabbitmq/ssl/private'],
      notify   => Service['rabbitmq-server'],
    }
    class { '::rabbitmq':
      package_provider      => $::package_provider,
      delete_guest_user     => true,
      ssl                   => true,
      ssl_only              => true,
      ssl_cacert            => $::openstack::params::ca_bundle_cert_path,
      ssl_cert              => $::openstack::params::cert_path,
      ssl_key               => "/etc/rabbitmq/ssl/private/${::fqdn}.pem",
      environment_variables => $::openstack::config::rabbit_env,
      repos_ensure          => false,
    }
  } else {
    class { '::rabbitmq':
      package_provider      => $::package_provider,
      delete_guest_user     => true,
      environment_variables => $::openstack::config::rabbit_env,
      repos_ensure          => false,
    }
  }
  rabbitmq_vhost { '/':
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq'],
  }

}

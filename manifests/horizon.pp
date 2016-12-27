class openstack::horizon {

  include ::openstack::config
  include ::openstack::params

  if $::openstack::config::ssl {
    file { '/etc/openstack-dashboard/ssl':
      ensure                  => directory,
      owner                   => 'root',
      mode                    => '0755',
      selinux_ignore_defaults => true,
      require                 => Package['horizon'],
    }
    file { '/etc/openstack-dashboard/ssl/private':
      ensure                  => directory,
      owner                   => 'root',
      mode                    => '0755',
      selinux_ignore_defaults => true,
      require                 => File['/etc/openstack-dashboard/ssl'],
      before                  => File["/etc/openstack-dashboard/ssl/private/${::fqdn}.pem"],
    }
    openstack::ssl_key { 'horizon':
      key_path  => "/etc/openstack-dashboard/ssl/private/${::fqdn}.pem",
      key_owner => 'root',
      require   => File['/etc/openstack-dashboard/ssl/private'],
      notify    => Service['httpd'],
    }
    Exec['update-ca-certificates'] ~> Service['httpd']
  }

  class { '::horizon':
    secret_key       => 'big_secret',
    allowed_hosts    => $::fqdn,
    listen_ssl       => $::openstack::config::ssl,
    ssl_redirect     => $::openstack::config::ssl,
    horizon_cert     => $::openstack::params::cert_path,
    horizon_key      => "/etc/openstack-dashboard/ssl/private/${::fqdn}.pem",
    horizon_ca       => $::openstack::params::ca_bundle_cert_path,
    keystone_url     => "$::openstack::config::keystone_auth_uri/v2.0",
    keystone_default_role => 'Member'
    # need to disable offline compression due to
    # https://bugs.launchpad.net/ubuntu/+source/horizon/+bug/1424042
    compress_offline => false,
  }

}

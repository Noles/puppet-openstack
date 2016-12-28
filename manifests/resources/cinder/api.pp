class openstack::resource::cinder::api {

  include ::openstack::config
  include ::openstack::params
  
  rabbitmq_user { 'cinder':
    admin    => true,
    password => 'an_even_bigger_secret',
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq'],
  }
  rabbitmq_user_permissions { 'cinder@/':
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => Class['::rabbitmq'],
  }

  if $::openstack::config::ssl {
    openstack::ssl_key { 'cinder':
      notify  => Service['httpd'],
      require => Package['cinder'],
    }
    Exec['update-ca-certificates'] ~> Service['httpd']
  }
  class { '::cinder::db::mysql':
    password => 'cinder',
  }
  class { '::cinder::keystone::auth':
    public_url      => "${::openstack::config::base_url}:8776/v1/%(tenant_id)s",
    internal_url    => "${::openstack::config::base_url}:8776/v1/%(tenant_id)s",
    admin_url       => "${::openstack::config::base_url}:8776/v1/%(tenant_id)s",
    public_url_v2   => "${::openstack::config::base_url}:8776/v2/%(tenant_id)s",
    internal_url_v2 => "${::openstack::config::base_url}:8776/v2/%(tenant_id)s",
    admin_url_v2    => "${::openstack::config::base_url}:8776/v2/%(tenant_id)s",
    public_url_v3   => "${::openstack::config::base_url}:8776/v3/%(tenant_id)s",
    internal_url_v3 => "${::openstack::config::base_url}:8776/v3/%(tenant_id)s",
    admin_url_v3    => "${::openstack::config::base_url}:8776/v3/%(tenant_id)s",
    password        => 'a_big_secret',
  }
  
  include ::openstack::resource::cinder
  
  class { '::cinder::keystone::authtoken':
    password            => 'a_big_secret',
    user_domain_name    => 'Default',
    project_domain_name => 'Default',
    auth_url            => $::openstack::config::keystone_admin_uri,
    auth_uri            => $::openstack::config::keystone_auth_uri,
    memcached_servers   => $::openstack::config::memcached_servers,
  }
  class { '::cinder::api':
    default_volume_type        => 'BACKEND_1',
    public_endpoint            => "${::openstack::config::base_url}:8776",
    service_name               => 'httpd',
    keymgr_api_class           => $keymgr_api_class,
    keymgr_encryption_api_url  => $keymgr_encryption_api_url,
    keymgr_encryption_auth_url => $keymgr_encryption_auth_url,
  }
  include ::apache
  class { '::cinder::wsgi::apache':
    bind_host => $::openstack::config::ip_for_url,
    ssl       => $::openstack::config::ssl,
    ssl_key   => "/etc/cinder/ssl/private/${::fqdn}.pem",
    ssl_cert  => $::openstack::params::cert_path,
    workers   => 2,
  }
  class { '::cinder::quota': }
  class { '::cinder::scheduler': }
  class { '::cinder::scheduler::filter': }  
  class { '::cinder::cron::db_purge': }
  
  case $backend {
    'iscsi': {
      class { '::cinder::setup_test_volume':
        size => '15G',
      }
      cinder::backend::iscsi { 'BACKEND_1':
        iscsi_ip_address   => '127.0.0.1',
        manage_volume_type => true,
      }
    }
    'rbd': {
      cinder::backend::rbd { 'BACKEND_1':
        rbd_user           => 'openstack',
        rbd_pool           => 'cinder',
        rbd_secret_uuid    => '7200aea0-2ddd-4a32-aa2a-d49f66ab554c',
        manage_volume_type => true,
      }
      # make sure ceph pool exists before running Cinder API & Volume
      Exec['create-cinder'] -> Service['httpd']
      Exec['create-cinder'] -> Service['cinder-volume']
    }
    default: {
      fail("Unsupported backend (${backend})")
    }
  }
  class { '::cinder::backends':
    enabled_backends => ['BACKEND_1'],
  }

  if $cinder_backup == swift {
    include ::cinder::backup
    class { '::cinder::backup::swift':
      backup_swift_user_domain    => 'Default',
      backup_swift_project_domain => 'Default',
      backup_swift_project        => 'Default',
    }
  }
}

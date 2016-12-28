# Configure the Nova service
#
# [*libvirt_rbd*]
#   (optional) Boolean to configure or not Nova
#   to use Libvirt RBD backend.
#   Defaults to false.
#
# [*libvirt_virt_type*]
#   (optional) Libvirt domain type. Options are: kvm, lxc, qemu, uml, xen
#   Defaults to 'qemu'
#
# [*libvirt_cpu_mode*]
#   (optional) The libvirt CPU mode to configure.
#   Possible values include custom, host-model, none, host-passthrough.
#   Defaults to 'none'
#
# [*volume_encryption*]
#   (optional) Boolean to configure or not volume encryption
#   Defaults to false.
#
class openstack::resource::nova::compute (
  $libvirt_rbd       = false,
  $libvirt_virt_type = 'qemu',
  $libvirt_cpu_mode  = 'none',
  $volume_encryption = false,
) {

  include ::openstack::config
  include ::openstack::params

  if $volume_encryption {
    $keymgr_api_class     = 'castellan.key_manager.barbican_key_manager.BarbicanKeyManager'
    $keymgr_auth_endpoint = "${::openstack::config::keystone_auth_uri}/v3"
    $barbican_endpoint    = "${::openstack::config::base_url}:9311"
  } else {
    $keymgr_api_class     = undef
    $keymgr_auth_endpoint = undef
    $barbican_endpoint    = undef
  }
  class { '::nova::compute':
    vnc_enabled                 => true,
    instance_usage_audit        => true,
    instance_usage_audit_period => 'hour',
    keymgr_api_class            => $keymgr_api_class,
    barbican_auth_endpoint      => $keymgr_auth_endpoint,
    barbican_endpoint           => $barbican_endpoint,
  }
  class { '::nova::compute::libvirt':
    libvirt_virt_type => $libvirt_virt_type,
    libvirt_cpu_mode  => $libvirt_cpu_mode,
    migration_support => true,
    vncserver_listen  => '0.0.0.0',
  }
  if $libvirt_rbd {
    class { '::nova::compute::rbd':
      libvirt_rbd_user        => 'openstack',
      libvirt_rbd_secret_uuid => '7200aea0-2ddd-4a32-aa2a-d49f66ab554c',
      libvirt_rbd_secret_key  => 'AQD7kyJQQGoOBhAAqrPAqSopSwPrrfMMomzVdw==',
      libvirt_images_rbd_pool => 'nova',
      rbd_keyring             => 'client.openstack',
      # ceph packaging is already managed by puppet-ceph
      manage_ceph_client      => false,
    }
    # make sure ceph pool exists before running nova-compute
    Exec['create-nova'] -> Service['nova-compute']
  }
}

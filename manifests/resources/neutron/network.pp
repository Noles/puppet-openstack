# Configure the Neutron service
#
# [*driver*]
#   (optional) Neutron Driver to test
#   Can be: openvswitch or linuxbridge.
#   Defaults to 'openvswitch'.
#
class openstack::resource::neutron::network (
  $driver = 'openvswitch',
) {
  include ::openstack::config
  include ::openstack::params
  include ::openstack::resource::nova

  case $driver {
    'openvswitch': {
      include ::vswitch::ovs
      # Functional test for Open-vSwitch:
      # create dummy loopback interface to exercise adding a port to a bridge
      vs_bridge { 'br-ex':
        ensure => present,
        notify => Exec['create_loop1_port'],
      }
      exec { 'create_loop1_port':
        path        => '/usr/bin:/bin:/usr/sbin:/sbin',
        provider    => shell,
        command     => 'ip link add name loop1 type dummy && ip addr add 127.2.0.1/24 dev loop1',
        refreshonly => true,
      } ->
      vs_port { 'loop1':
        ensure => present,
        bridge => 'br-ex',
        notify => Exec['create_br-ex_vif'],
      }
      # creates br-ex virtual interface to reach floating-ip network
      exec { 'create_br-ex_vif':
        path        => '/usr/bin:/bin:/usr/sbin:/sbin',
        provider    => shell,
        command     => 'ip addr add 172.24.5.1/24 dev br-ex && ip link set br-ex up',
        refreshonly => true,
      }
      class { '::neutron::agents::ml2::ovs':
        local_ip        => '127.0.0.1',
        tunnel_types    => ['vxlan'],
        bridge_mappings => ['external:br-ex'],
        manage_vswitch  => false,
      }
      $firewall_driver  = 'iptables_hybrid'
    }
    'linuxbridge': {
      exec { 'create_dummy_iface':
        path     => '/usr/bin:/bin:/usr/sbin:/sbin',
        provider => shell,
        unless   => 'ip l show loop0',
        command  => 'ip link add name loop0 type dummy && ip addr add 172.24.5.1/24 dev loop0 && ip link set loop0 up',
      }
      class { '::neutron::agents::ml2::linuxbridge':
        local_ip                    => $::ipaddress,
        tunnel_types                => ['vxlan'],
        physical_interface_mappings => ['external:loop0'],
      }
      $external_network_bridge = ''
      $firewall_driver         = 'iptables'
    }
    default: {
      fail("Unsupported neutron driver (${driver})")
    }
  }
  
  class { '::neutron::services::lbaas': }
  class { '::neutron::agents::metadata':
    debug            => true,
    shared_secret    => 'a_big_secret',
    metadata_workers => 2,
  }
  class { '::neutron::agents::lbaas':
    interface_driver => $driver,
    debug            => true,
  }
  class { '::neutron::agents::l3':
    interface_driver        => $driver,
    debug                   => true,
    extensions              => 'fwaas',
    # This parameter is deprecated but we need it for linuxbridge
    # It will be dropped in a future release.
    external_network_bridge => $external_network_bridge,
  }
  class { '::neutron::agents::dhcp':
    interface_driver => $driver,
    debug            => true,
  }
  class { '::neutron::agents::metering':
    interface_driver => $driver,
    debug            => true,
  }
  class { '::neutron::services::fwaas':
    enabled       => true,
    agent_version => 'v1',
    driver        => 'neutron_fwaas.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver',

  }
}

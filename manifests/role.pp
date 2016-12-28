class openstack::role {

  Exec { logoutput => 'on_failure' }

  if $::osfamily == 'RedHat' {
    include openstack_extras::repo::redhat::redhat
    
    package { 'openstack-selinux':
        ensure => 'latest'
    }
    # Some packages provided by RDO are virtual
    # allow_virtual is false in Puppet 3 and will be true
    # in Puppet 4. So let's set it to True.
    # We still support Puppet 3 until distros ship Puppet 4 by default.
    Package<| tag == 'openstack' |> { allow_virtual => true }
  } elsif $::osfamily == 'Debian' {
    if $::operatingsystem == 'ubuntu' {
      include openstack_extras::repo::debian::ubuntu
    }
  }
  
}

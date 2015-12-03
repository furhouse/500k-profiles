class profiles::foremanproxy {

  ## SSL and CA configuration
  # Open read permissions to private keys to puppet group for foreman, proxy etc.

  contain '::puppet'

  file { "${::puppet_vardir}/ssl":
    ensure => directory,
    owner  => $puppet::server_user,
    group  => $puppet::server_group,
    mode   => '0750',
  }

  file { "${::puppet_vardir}/ssl/private_keys":
    ensure => directory,
    owner  => $puppet::server_user,
    group  => $puppet::server_group,
    mode   => '0750',
  }

  file { "${::puppet_vardir}/ssl/private_keys/${::fqdn}.pem":
    owner => $puppet::server_user,
    group => $puppet::server_group,
    mode  => '0640',
  }

}

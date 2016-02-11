class profiles::apache {

  $mod_status_enable   = hiera('profiles::apache::mod_status_enable', false)
  $allow_from          = hiera('profiles::apache::allow_from', [])
  $mod_remoteip_enable = hiera('profiles::apache::mod_remoteip_enable', false)
  $trusted_ips         = hiera('profiles::apache::trusted_ips', [])

  # class { '::apache':
    # mpm_module => 'prefork',
  # }

  # class { '::apache::mod::php': }

  if ($mod_status_enable) {
    class { '::apache::mod::status':
      allow_from => $allow_from,
    }
  }

  if ($mod_remoteip_enable) {
    class { '::apache::mod::remoteip':
      trusted_proxy_ips => $trusted_ips,
      proxy_ips         => [],
    }
  }

  $apachevhost = hiera_hash('profiles::apache::vhosts')

  # $defaults_ssl_cert = {
      # 'ssl_cert' => '/etc/ssl/apache.crt',
      # 'ssl_key'  => '/etc/ssl/apache.key',
    # }

  # create_resources(apache::vhost, $apachevhost, $defaults_ssl_cert)
  create_resources(apache::vhost, $apachevhost)

}

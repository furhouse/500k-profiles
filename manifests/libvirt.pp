class profiles::libvirt {

  $vnc_address = hiera('profiles::libvirt::vnc_address', '127.0.0.1')
  $auth_tcp    = hiera('profiles::libvirt::auth_tcp', 'none')
  $listen_tls  = hiera('profiles::libvirt::listen_tls', false)
  $listen_tcp  = hiera('profiles::libvirt::listen_tcp', false)
  $deb_default = hiera('profiles::libvirt::deb_default')
  $pool        = hiera('profiles::libvirt::pool')

  class { '::libvirt':
    mdns_adv        => false,
    qemu_vnc_listen => $vnc_address,
    auth_tcp        => $auth_tcp,
    listen_tls      => $listen_tls,
    listen_tcp      => $listen_tcp,
    deb_default     => $deb_default,
  }

  create_resources('libvirt::pool', $pool)

  if $pool {
    file { 'libvirt_pool':
      ensure => directory,
      path   => '/data',
    }
  }

}

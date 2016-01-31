class profiles::libvirt {

  $pool  = hiera('profiles::libvirt::pool')

  contain '::libvirt'

  create_resources('libvirt::pool', $pool)

  if $pool {
    file { 'libvirt_pool':
      ensure => directory,
      path   => $pool,
    }
  }

}

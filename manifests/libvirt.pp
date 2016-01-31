class profiles::libvirt {

  $pool  = hiera('profiles::libvirt::pool')

  contain '::libvirt'

  create_resources('libvirt::pool', $pool)

}

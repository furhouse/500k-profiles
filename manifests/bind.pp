class profiles::bind {

  $bindkey  = hiera('profiles::bind::bindkey')
  $bindacl  = hiera('profiles::bind::bindacl')
  $bindzone = hiera('profiles::bind::bindzone')
  $bindview = hiera('profiles::bind::bindview')
  $bindrr   = hiera('profiles::bind::bindrr')

  contain '::bind'

  create_resources('bind::key', $bindkey)
  create_resources('bind::acl', $bindacl)
  create_resources('bind::zone', $bindzone)
  create_resources('bind::view', $bindview)
  create_resources('resource_record', $bindrr)

}

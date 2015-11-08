class profiles::bind {

  $bindacl = hiera('profiles::bind::bindacl')

  contain '::bind'

  create_resources('dns::acl', $bindacl)

  # create_resources('dns::zone', $dnszone)
  # create_resources('dns::zone', $dnszone)
  # create_resources('dns::zone', $dnszone)

}


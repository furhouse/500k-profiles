class profiles::dns {

  $dnszone = hiera('profiles::dns::dnszone')

  contain '::dns'

  create_resources('dns::zone', $dnszone)

}

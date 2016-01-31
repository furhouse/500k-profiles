class profiles::samba {

  # $server  = hiera('profiles::samba::server')

  $share      = hiera('profiles::samba::share')
  $interfaces = hiera('profiles::samba::interfaces')

  class { 'samba::server':
    workgroup     => '500k.lan',
    server_string => '500k.lan Samba',
    interfaces    => $interfaces,
    security      => 'user',
    printing      => 'bsd',
    printcap_name => '/dev/null',
  }

  create_resources(samba::server::share, $share)

}

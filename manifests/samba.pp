class profiles::samba {

  # $server  = hiera('profiles::samba::server')

  $share  = hiera('profiles::samba::share')

  class { 'samba::server':
    workgroup     => '500k.lan',
    server_string => '500k.lan Samba',
    interfaces    => 'br0 virbr0',
    security      => 'share',
  }

  create_resources(samba::server::share, $share)

}

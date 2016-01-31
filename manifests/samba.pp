class profiles::samba {

  $share         = hiera('profiles::samba::share')
  $workgroup     = hiera('profiles::samba::workgroup')
  $server_string = hiera('profiles::samba::server_string')
  $interfaces    = hiera('profiles::samba::interfaces')

  class { 'samba::server':
    workgroup     => $workgroup,
    server_string => $server_string,
    interfaces    => $interfaces,
    security      => 'user',
    printing      => 'bsd',
    printcap_name => '/dev/null',
  }

  create_resources(samba::server::share, $share)

}

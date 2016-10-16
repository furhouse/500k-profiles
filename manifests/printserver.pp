class profiles::printserver {

  class { '::cups':
    default_queue => hiera('cups_default_queue', undef),
  }

  class { '::cups::server': }

  $printers = hiera_hash('printers', {})
  create_resources('cups_queue', $printers)

  package { 'cups-bsd':
    ensure => present,
  }

  class { '::samba::server':
    workgroup     => hiera('smb_workgroup', undef),
    server_string => hiera('smb_server_name', undef),
    security      => hiera('smb_security', undef),
    printing      => 'cups',
  }

}

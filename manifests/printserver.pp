class profiles::printserver {

  class { '::cups':
    default_queue => hiera('profiles::printserver::cups_default_queue', undef),
  }

  class { '::cups::server':
    port =>  631,
  }

  $printers = hiera_hash('profiles::printserver::printers', {})
  create_resources('cups_queue', $printers)

  package { 'cups-bsd':
    ensure => present,
  }

  class { '::samba::server':
    workgroup     => hiera('profiles::printserver::smb_workgroup', undef),
    server_string => hiera('profiles::printserver::smb_server_name', undef),
    security      => hiera('profiles::printserver::smb_security', undef),
    printing      => 'cups',
  }

}

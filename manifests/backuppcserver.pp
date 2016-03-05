class profiles::backuppcserver {

  $serverpass = hiera('profiles::apache::serverpass')

  class { '::apache': } ->

  package { 'apache2-utils':
    ensure  => present,
  } ->

  class { '::backuppc::server':
    backuppc_password => $serverpass,
    notify            => Service['apache2'],
  }

  class { '::backuppc::client':
    system_account    => 'backuppc',
    backuppc_hostname => $::fqdn,
    xfer_method       => 'tar',
    tar_share_name    => ['/home', '/etc', '/var/log'],
    tar_client_cmd    => '/usr/bin/sudo $tarPath -c -v -f - -C $shareName --totals',
    tar_full_args     => '$fileList',
    tar_incr_args     => '--newer=$incrDate $fileList',
  }

}

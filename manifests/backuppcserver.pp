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
    backuppc_hostname => $::fqdn,
    xfer_method       => 'tar',
    tar_share_name    => ['/home', '/etc', '/var/log'],
    tar_client_cmd    => '/usr/bin/sudo $tarPath -c -v -f - -C $shareName --totals',
    tar_full_args     => '$fileList',
    tar_incr_args     => '--newer=$incrDate $fileList',
  }

  file { '/etc/sudoers.d/backuppc_localhost':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => "backuppc ALL=(ALL:ALL) NOEXEC:NOPASSWD: /bin/tar\n",
  }
}

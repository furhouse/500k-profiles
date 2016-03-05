class profiles::backuppcserver {

  $serverpass = hiera('profiles::apache::serverpass')

  class { '::apache': }

  apache::vhost { "${::fqdn}":
    docroot     => '/usr/share/backuppc/cgi-bin',
    directories => [
      { path           => '/usr/share/backuppc/cgi-bin',
        directoryindex => 'index.cgi',
        options        => ['ExecCGI','FollowSymLinks'],
        addhandlers    => [
          { handler  => 'cgi-script',
          extensions => ['.cgi']}],
        auth_user_file => '/etc/backuppc/htpasswd',
        auth_type      => 'basic',
        auth_name      => 'BackupPC admin',
        auth_require   => 'valid-user',
      },
    ],
  } ->

  package { 'apache2-utils':
    ensure  => present,
  } ->

  class { '::backuppc::server':
    backuppc_password    => $serverpass,
    apache_configuration => false,
    notify               => Service['apache2'],
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

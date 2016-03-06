class profiles::backuppcserver inherits ::backuppc::params {

  $serverpass = hiera('profiles::backuppcserver::serverpass', '')

  class { '::apache': default_vhost => false }

  apache::vhost { $::fqdn:
    docroot        => $::backuppc::params::cgi_directory,
    manage_docroot => false,
    port           => '80',
    aliases        => [ { alias => '/backuppc', path => $::backuppc::params::cgi_directory, }, ],
    directories    => [
      { path           => $::backuppc::params::cgi_directory,
        directoryindex => 'index.cgi',
        options        => ['ExecCGI','FollowSymLinks'],
        addhandlers    => [ { handler => 'cgi-script', extensions => ['.cgi'] }, ],
        auth_user_file => $::backuppc::params::htpasswd_apache,
        auth_type      => 'basic',
        auth_name      => 'BackupPC admin',
        auth_require   => 'valid-user',
      },
    ],
  }

  package { 'apache2-utils':
    ensure  => present,
  }

  class { '::backuppc::client':
    backuppc_hostname => $::fqdn,
    xfer_method       => 'tar',
    tar_share_name    => ['/home', '/etc', '/var/log'],
    tar_client_cmd    => '/usr/bin/sudo $tarPath -c -v -f - -C $shareName --totals',
    tar_full_args     => '$fileList',
    tar_incr_args     => '--newer=$incrDate $fileList',
  }

  backuppc::server::user { 'backuppc':
    password => $serverpass,
    require  => Package['apache2-utils'],
  }

  class { '::backuppc::server':
    backuppc_password    => $serverpass,
    apache_configuration => false,
  } ->

  exec { 'remove-localhost-hosts':
    command => "/bin/sed -i '/localhost/ d' ${::backuppc::params::hosts}",
    onlyif  => "/bin/grep localhost ${::backuppc::params::hosts}",
  }

  file { 'remove-localhost-config':
    ensure => absent,
    path   => "${::backuppc::params::config_directory}/localhost.pl",
  }

  file { '/etc/sudoers.d/backuppc_localhost':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => "backuppc ALL=(ALL:ALL) NOEXEC:NOPASSWD: /bin/tar\n",
  }

}

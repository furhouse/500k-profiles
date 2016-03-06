class profiles::backuppcserver inherits ::backuppc::params {

  $serverpass = hiera('profiles::backuppcserver::serverpass', '')

  class { '::apache': default_vhost => false }

  class { '::apache::mod::rewrite': }
  class { '::apache::mod::wsgi': }
  class { '::apache::mod::ssl': }

  apache::vhost { 'backuppc':
    servername     => $::fqdn,
    manage_docroot => false,
    port           => '80',
    docroot        => $::backuppc::params::cgi_directory,
    rewrites       => [
      {
        comment      => 'redirect to https',
        rewrite_cond => ['%{HTTPS} off'],
        rewrite_rule => ['(.*) https://%{HTTP_HOST}:443%{REQUEST_URI}'],
      },
    ],
  }

  apache::vhost{'backuppc-ssl':
    servername      => $::fqdn,
    manage_docroot  => false,
    ip              => '*',
    port            => '443',
    docroot         => $::backuppc::params::cgi_directory,
    default_vhost   => true,
    ssl             => true,
    ssl_cert        => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key         => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain       => undef,
    error_log_file  => 'backuppc_error.log',
    access_log_file => 'access.log',
    docroot_owner   => 'www-data',
    docroot_group   => 'www-data',
    directories     => [
      {
        path           => $::backuppc::params::cgi_directory,
        allow_override => ['None'],
        options        => ['+ExecCGI', '-MultiViews', '+FollowSymLinks'],
        addhandlers    => [ {
                            handler    => 'cgi-script',
                            extensions => ['.cgi']
                            }
                          ],
        directoryindex => 'index.cgi',
        auth_user_file => $::backuppc::params::htpasswd_apache,
        auth_type      => 'Basic',
        auth_name      => 'BackupPC',
        auth_require   => 'valid-user',
      },
    ],
    aliases         => [
      {
        alias => '/backuppc',
        path  => $::backuppc::params::cgi_directory
      },
    ],
  }

  package { 'apache2-utils':
    ensure  => present,
  }

  # class { '::backuppc::client':
    # backuppc_hostname => $::fqdn,
    # xfer_method       => 'tar',
    # tar_share_name    => ['/home', '/etc', '/var/log'],
    # tar_client_cmd    => '/usr/bin/sudo $tarPath -c -v -f - -C $shareName --totals',
    # tar_full_args     => '$fileList',
    # tar_incr_args     => '--newer=$incrDate $fileList',
  # }

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

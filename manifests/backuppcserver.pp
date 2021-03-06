class profiles::backuppcserver inherits ::backuppc::params {

  $adminpass = hiera('bpc_adminpass', undef)

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
        rewrite_rule => ['(.*) https://%{HTTP_HOST}%{REQUEST_URI}'],
      },
    ],
  }

  apache::vhost{'backuppc-ssl':
    servername     => $::fqdn,
    manage_docroot => false,
    ip             => '*',
    port           => '443',
    docroot        => $::backuppc::params::cgi_directory,
    default_vhost  => true,
    ssl            => true,
    ssl_cert       => "${::settings::ssldir}/certs/${::clientcert}.pem",
    ssl_key        => "${::settings::ssldir}/private_keys/${::clientcert}.pem",
    ssl_chain      => undef,
    docroot_owner  => 'www-data',
    docroot_group  => 'www-data',
    directories    => [
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
    aliases        => [
      {
        alias => '/backuppc',
        path  => $::backuppc::params::cgi_directory
      },
    ],
  }

  package { 'nfs-common':
    ensure  => present,
  }

  package { 'apache2-utils':
    ensure  => present,
  }

  backuppc::server::user { 'backuppc':
    password => $adminpass,
    require  => Package['apache2-utils'],
  }

  class { '::backuppc::server':
    backuppc_password     => $adminpass,
    apache_configuration  => false,
    ping_max_msec         => 30,
    email_admin_user_name => hiera('bpc_mailto', undef)
  }

  exec { 'remove-localhost-hosts':
    command => "/bin/sed -i '/localhost/ d' ${::backuppc::params::hosts}",
    onlyif  => "/bin/grep localhost ${::backuppc::params::hosts}",
    require => Class['::backuppc::server'],
  }

  file { 'remove-localhost-config':
    ensure  => absent,
    path    => "${::backuppc::params::config_directory}/localhost.pl",
    require => Class['::backuppc::server'],
  }

  file { '/etc/sudoers.d/backuppc_localhost':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => "backuppc ALL=(ALL:ALL) NOEXEC:NOPASSWD: /bin/tar\n",
  }

}

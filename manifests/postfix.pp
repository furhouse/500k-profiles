# Almost completely sets up postfixadmin 2.93.
# Todo:
# - generate superpassword hash with profile
# - curl https://${::fqdn}/setup.php & verify
# - add admin with profile

class profiles::postfix {

  Exec {
    path => '/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin',
  }

  class { '::mysql::server':
    root_password           => 'password',
    remove_default_accounts => true,
    package_name            => 'mysql-server-5.6',
  }

  mysql_database { 'postfix':
    ensure => 'present',
  }

  mysql_user { 'postfix_admin@localhost':
    ensure        => 'present',
    password_hash => '*9D3B5B8CAC5F6EEF085657AF20D0723FC5816F81',
    require       => Mysql_database['postfix'],
  }

  mysql_user { 'postfix@localhost':
    ensure        => 'present',
    password_hash => '*33E0762B574AF0FEB01F6B5410648D3C62C6C017',
    require       => Mysql_database['postfix'],
  }

  mysql_grant { 'postfix_admin@localhost/postfix.*':
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE', 'ALTER'],
    table      => 'postfix.*',
    user       => 'postfix_admin@localhost',
    require    => Mysql_database['postfix'],
  }

  mysql_grant { 'postfix@localhost/postfix.*':
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['SELECT'],
    table      => 'postfix.*',
    user       => 'postfix@localhost',
    require    => Mysql_database['postfix'],
  }

  include '::postfix'
  postfix::config {
    'smtp_tls_mandatory_ciphers':       value => 'high';
    'smtp_tls_security_level':          value => 'secure';
    'smtp_tls_CAfile':                  value => '/etc/ssl/certs/ca-certificates.crt';
    'smtp_tls_session_cache_database':  value => 'btree:${data_directory}/smtp_tls_session_cache';
    'inet_protocols':                   value => 'ipv4';
    'relay_domains':                    value => '*';
    'mydestination':                    value => '*';
    'smtpd_recipient_restrictions':     value => 'permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination';
    'disable_vrfy_command':             value => 'yes';
  }

  include '::staging'
  staging::deploy { 'postfixadmin-2.93.tar.gz':
    source => "puppet:///modules/${module_name}/postfixadmin-2.93.tar.gz",
    target => '/usr/share',
    user   => 'root',
    group  => 'root',
  }

  define postfixadmin::config (
    $configured     = true,
    $setup_password = hiera('postfixadmin::setup_pass', 'undef'),
    $pfadb_type     = 'mysqli',
    $pfadb_host     = 'localhost',
    $pfadb_user     = 'postfix_admin',
    $pfadb_passwd   = 'postfixadmin',
    $pfadb_name     = 'postfix',
    $db_host        = 'localhost',
    $db_user        = 'postfix',
    $db_passwd      = 'postfixadmin',
    $db_name        = 'postfix',
  ) {
    file { 'postfixadmin-config' :
      ensure  => file,
      path    => '/usr/share/postfixadmin-2.93/config.inc.php',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/postfixadmin-2.93_config.inc.php.erb"),
      require => Staging::Deploy['postfixadmin-2.93.tar.gz'],
    }
    file { 'postfixadmin-config-symlink' :
      ensure  => link,
      path    => '/etc/postfixadmin.conf',
      target  => '/usr/share/postfixadmin-2.93/config.inc.php',
      owner   => 'root',
      group   => 'root',
      require => Staging::Deploy['postfixadmin-2.93.tar.gz'],
    }
    file { 'postfixadmin-templates_c' :
      ensure  => directory,
      path    => '/usr/share/postfixadmin-2.93/templates_c',
      owner   => 'root',
      group   => 'www-data',
      mode    => '0775',
      require => Staging::Deploy['postfixadmin-2.93.tar.gz'],
    }
    file { 'mysql_virtual_alias_maps' :
      ensure  => file,
      path    => '/etc/postfix/mysql_virtual_alias_maps.cf',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/postfix/mysql_virtual_alias_maps.cf.erb"),
      require => Class['::postfix'],
    }
    file { 'mysql_virtual_domains_maps' :
      ensure  => file,
      path    => '/etc/postfix/mysql_virtual_domains_maps.cf',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/postfix/mysql_virtual_domains_maps.cf.erb"),
      require => Class['::postfix'],
    }
    file { 'mysql_virtual_mailbox_maps' :
      ensure  => file,
      path    => '/etc/postfix/mysql_virtual_mailbox_maps.cf',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/postfix/mysql_virtual_mailbox_maps.cf.erb"),
      require => Class['::postfix'],
    }
  }

  class { '::apache':
    default_vhost => false,
    mpm_module    => 'prefork',
  }

  class { '::apache::mod::php': }
  class { '::apache::mod::rewrite': }
  class { '::apache::mod::ssl': }

  $phppackages = [ 'php5-mysql', 'php5-imap' ]

  package { $phppackages:
    ensure => installed,
  }

  exec { 'enable-php5-imap':
    command => 'php5enmod imap',
    require => [ Package['php5-imap'], Class['::apache::mod::php'] ],
    unless  => 'php -m | grep imap',
  }

  apache::vhost { 'postfixadmin':
    servername     => $::fqdn,
    manage_docroot => false,
    port           => '80',
    docroot        => '/usr/share/postfixadmin-2.93',
    rewrites       => [
      {
        comment      => 'redirect to https',
        rewrite_cond => ['%{HTTPS} off'],
        rewrite_rule => ['(.*) https://%{HTTP_HOST}:443%{REQUEST_URI}'],
      },
    ],
  }

  apache::vhost { 'postfixadmin-ssl':
    servername      => $::fqdn,
    manage_docroot  => false,
    ip              => '*',
    port            => '443',
    docroot         => '/usr/share/postfixadmin-2.93',
    default_vhost   => true,
    ssl             => true,
    ssl_cert        => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key         => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain       => undef,
    error_log_file  => 'postfixadmin_error.log',
    access_log_file => 'access.log',
  }

  postfixadmin::config { "postfixadmin-config-${fqdn}": }

}

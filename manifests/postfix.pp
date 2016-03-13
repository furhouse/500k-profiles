class profiles::postfix {

  Exec {
    path => '/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin',
  }

  class { '::mysql::server':
    root_password           => 'password',
    remove_default_accounts => true,
  }

  mysql_database { 'postfix':
    ensure => 'present',
  }

  mysql_user { 'postfix_admin@localhost':
    ensure  => 'present',
    require => Mysql_database['postfix'],
  }

  mysql_user { 'postfix@localhost':
    ensure  => 'present',
    require => Mysql_database['postfix'],
  }

  mysql_grant { 'postfix_admin@localhost/postfix.*':
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE', 'ALTER'],
    table      => 'postfix.*',
    user       => 'postfix@localhost',
    require    => Mysql_database['postfix'],
  }

  mysql_grant { 'postfix@localhost/postfix.*':
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['SELECT'],
    table      => 'postfix.*',
    user       => 'postfix_admin@localhost',
    require    => Mysql_database['postfix'],
  }

  include '::postfix'
  postfix::config {
    'smtp_tls_mandatory_ciphers':       value => 'high';
    'smtp_tls_security_level':          value => 'secure';
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
    $pfadb_type   = 'mysqli',
    $pfadb_host   = 'localhost',
    $pfadb_user   = 'postfix_admin',
    $pfadb_passwd = 'postfixadmin',
    $pfadb_name   = 'postfix',
    $db_host      = 'localhost',
    $db_user      = 'postfix',
    $db_passwd    = 'postfixadmin',
    $db_name      = 'postfix',
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
  }

  class { '::apache::mod::rewrite': }
  class { '::apache::mod::ssl': }

  apache::vhost { 'postfixadmin':
    servername     => $::fqdn,
    manage_docroot => false,
    port           => '80',
    docroot        => '/usr/share/postfixadmin-2.93/config.inc.php',
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
    docroot         => '/usr/share/postfixadmin-2.93/config.inc.php',
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

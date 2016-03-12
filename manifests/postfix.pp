class profiles::postfix {

  Exec {
    path => '/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin',
  }

  include ::postfix
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

  include ::staging
  staging::deploy { 'postfixadmin-2.93.tar.gz':
    source => "puppet:///modules/${module_name}/postfixadmin-2.93.tar.gz",
    target => '/usr/share',
  }

  define postfixadmin::config (
    $db_type   = 'mysqli',
    $db_host   = 'localhost',
    $db_user   = 'postfix',
    $db_passwd = 'postfixadmin',
    $db_name   = 'postfix'
  ) {
    file { 'postfixadmin-config' :
      ensure  => file,
      path    => '/usr/share/postfixadmin-2.93/config.inc.php',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/postfixadmin-2.93_config.inc.php.erb"),
      require => Class['staging::deploy'],
    }
  }

  postfixadmin::config { "postfixadmin-config-${fqdn}": }

}

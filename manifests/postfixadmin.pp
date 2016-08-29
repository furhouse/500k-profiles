class profiles::postfixadmin {

  include '::staging'

  staging::deploy { 'postfixadmin-2.93.tar.gz':
    source => "puppet:///modules/${module_name}/postfixadmin-2.93.tar.gz",
    target => '/usr/share',
    user   => 'root',
    group  => 'root',
  }

  define postfixadmin::config (
    $configured     = true,
    $setup_password = hiera('postfixadmin::pfasetup_pass', 'undef'),
    $pfadb_type     = 'mysqli',
    $pfadb_host     = hiera('postfixadmin::pfadb_host', 'undef'),
    $pfadb_user     = hiera('postfixadmin::pfadb_user', 'undef'),
    $pfadb_passwd   = hiera('postfixadmin::pfadb_passwd', 'undef'),
    $pfadb_name     = hiera('postfixadmin::pfadb_name', 'undef'),
    $db_host        = hiera('postfix::db_host', 'undef'),
    $db_user        = hiera('postfix::db_user', 'undef'),
    $db_passwd      = hiera('postfix::db_passwd', 'undef'),
    $db_name        = hiera('postfix::db_name', 'undef'),
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
    }
    file { 'mysql_virtual_domains_maps' :
      ensure  => file,
      path    => '/etc/postfix/mysql_virtual_domains_maps.cf',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/postfix/mysql_virtual_domains_maps.cf.erb"),
    }
    file { 'mysql_virtual_mailbox_maps' :
      ensure  => file,
      path    => '/etc/postfix/mysql_virtual_mailbox_maps.cf',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/postfix/mysql_virtual_mailbox_maps.cf.erb"),
    }
  }

  postfixadmin::config { "postfixadmin-config-${fqdn}": }

}

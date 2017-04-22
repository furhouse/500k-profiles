class profiles::zabbixsrv {

  class { '::apache':
    mpm_module => 'prefork',
  }

  include ::apache::mod::php

  class { '::apache::mod::status':
    allow_from => hiera_array('apachestatus::from', []),
  }

  class { '::mysql::server':
    root_password           => hiera('zabbixsrv::mysql_rootpass'),
    remove_default_accounts => true,
  }

  class { '::zabbix':
    zabbix_url       => "${::fqdn}",
    zabbix_version   => '3.2',
    database_type    => 'mysql',
    default_vhost    => true,
    apache_use_ssl   => true,
    apache_ssl_cert  => "${::settings::ssldir}/certs/${::clientcert}.pem",
    apache_ssl_key   => "${::settings::ssldir}/private_keys/${::clientcert}.pem",
    startdiscoverers => '10',
  }

  $userparameters = hiera_hash('profiles::zabbixsrv::userparameters', {})
  create_resources('::zabbix::userparameters', $userparameters)

  file { 'zbx_homedir':
    ensure => directory,
    path   => '/var/lib/zabbix',
    owner  => 'zabbix',
    group  => 'zabbix',
  }

  file { 'zbx_sql_spy':
    ensure => directory,
    path   => '/var/lib/zabbix/.my.cnf',
    source => "puppet:///modules/files/zbx_sql_spy.my.cnf",
    owner  => 'zabbix',
    group  => 'zabbix',
    mode   => '0600',
  }

  mysql_user { 'zbx_sql_spy@localhost':
    ensure        => 'present',
    password_hash => hiera('zbx_sql_spy::passhash', undef)
  }

  mysql_grant { 'zbx_sql_spy@localhost/*.*':
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['USAGE'],
    table      => '*.*',
    user       => 'zbx_sql_spy@localhost',
  }

}

class profiles::zabbixsrv {

  class { '::apache':
    mpm_module => 'prefork',
  }

  include ::apache::mod::php

  class { '::mysql::server':
    root_password           => hiera('zabbixsrv::mysql_rootpass'),
    remove_default_accounts => true,
  }

  class { '::zabbix':
    zabbix_url     => "${::fqdn}",
    database_type  => 'mysql',
    default_vhost  => true,
    apache_use_ssl => true,
  }

}

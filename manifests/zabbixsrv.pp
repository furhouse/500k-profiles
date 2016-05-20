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
    zabbix_url    => "zabbix.${::fqdn}",
    database_type => 'mysql',
  }

}

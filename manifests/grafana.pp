class profiles::grafana {

  class { '::grafana':
    version  => '4.2.0',
    cfg      => {
      app_mode    => 'production',
      server      => {
        http_port => 8080,
      },
      database    => {
        type     => 'mysql',
        host     => '127.0.0.1:3306',
        name     => hiera('profiles::grafana::db_name', undef),
        user     => hiera('profiles::grafana::db_username', undef),
        password => hiera('profiles::grafana::db_password', undef),
      },
      users       => {
        allow_sign_up    => false,
        allow_org_create => false,
      },
      snapshots   => {
        external_enabled => false,
      },
      analytics   => {
        reporting_enabled => false,
      },
      smtp        => {
        enabled      => true,
        host         => 'localhost:25',
        from_address => "admin@${::fqdn}",
        from_name    => 'Dashboard Admin'
      },
      'auth.ldap' => {
        enabled     => true,
        config_file => '/etc/grafana/ldap.toml',
      },
    },
    ldap_cfg => {
      servers => [
        { host            => 'xxx',
          use_ssl         => true,
          search_filter   => '(sAMAccountName=%s)',
          search_base_dns => [ 'xxx' ],
          bind_dn         => 'xxx',
          bind_password   => 'xxx',
          port            => 3269+0,
        },
      ],
      'servers.attributes' => {
        name      => 'givenName',
        surname   => 'sn',
        username  => 'sAMAccountName',
        member_of => 'memberOf',
        email     => 'mail',
      },
      'servers.group_mappings' => [
        { group_dn => 'xxx',
          org_role => 'Viewers',
        },
      ],
    }
  }

  exec { 'install_zabbix_plugin':
    path    => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'  ],
    command => 'grafana-cli plugins install vonage-status-panel',
    unless  => 'grafana-cli plugins ls | grep vonage-status-panel',
    notify  => Class['::grafana::service'],
    require => Class['::grafana::install'],
  }

}

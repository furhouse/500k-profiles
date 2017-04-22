class profiles::grafana {

  $packages = [ 'apt-transport-https' ]

  package { $packages:
    ensure  => installed,
  }

  class { '::grafana':
    version  => hiera('profiles::grafana::version', 'installed'),
    cfg      => hiera_hash('profiles::grafana::cfg', {}),
    ldap_cfg => hiera_hash('profiles::grafana::ldap_cfg', {}),
    require  => Package[$packages],
  }

  exec { 'install_zabbix_plugin':
    path    => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ],
    command => 'grafana-cli plugins install alexanderzobnin-zabbix-app',
    unless  => 'grafana-cli plugins ls | grep alexanderzobnin-zabbix-app',
    notify  => Class['::grafana::service'],
    require => Class['::grafana::install'],
  }

  exec { 'install_clock_plugin':
    path    => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ],
    command => 'grafana-cli plugins install grafana-clock-panel',
    unless  => 'grafana-cli plugins ls | grep grafana-clock-panel',
    notify  => Class['::grafana::service'],
    require => Class['::grafana::install'],
  }

}

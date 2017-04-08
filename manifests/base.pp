class profiles::base {

  $imageuser = hiera('profiles::base::imageuser', undef)

  class { '::users': }

  group { $imageuser:
    ensure => absent,
  }

  user { $imageuser:
    ensure => absent,
  }

  # Not absent yet to be able to check bootstrap logs
  file { "/home/${imageuser}":
    ensure  => present,
  }

  User[$imageuser] -> Group[$imageuser] -> File["/home/${imageuser}"] -> Class['::users']

  $packages = hiera_array('profiles::base::packages')

  package { $packages:
    ensure => latest,
  }

  group { 'sudo':
    ensure  => present,
    gid     => '27',
    require => Class['::sudo'],
  }

  $satellite = hiera('profiles::base::satellite_mail', true)
  if $satellite {

    class { '::postfix':
      master_smtp         => 'smtp inet n - n - - smtpd',
      myorigin            => hiera('profiles::base::satellite_origin', undef),
      root_mail_recipient => hiera('profiles::base::satellite_root_rcpt', undef),
    }

    postfix::config {
      'relayhost':                      value => hiera('profiles::base::satellite_relay', undef);
      'smtp_sasl_auth_enable':          value => 'yes';
      'smtp_sasl_password_maps':        value => 'hash:/etc/postfix/smtp_auth';
      'smtp_sasl_security_options':     value => 'noanonymous';
      'smtp_sasl_tls_security_options': value => 'noanonymous';
    }

    postfix::hash { '/etc/postfix/smtp_auth':
      ensure  => 'present',
      content => hiera('profiles::base::satellite_serv_creds', undef),
    }
  }

  class { '::vim': }
  class { '::git': }

  class { '::sudo': }
  $sudo_cfg = hiera('profiles::base::sudo_configs', {})
  create_resources('::sudo::conf', $sudo_cfg)

  class { '::timezone':
    region   => hiera('profiles::base::tz_region', undef),
    locality => hiera('profiles::base::tz_locality', undef),
  }

  class { '::locales':
    default_locale => hiera('profiles::base::loc_default_locale', undef),
    locales        => hiera_array('profiles::base::loc_locales', []),
  }

  class { '::ntp':
    restrict => hiera_array('profiles::base::ntp_restrict', []),
    servers  => hiera_array('profiles::base::ntp_servers', []),
  }

  class { '::ssh':
    server_options => hiera_hash('profiles::base::ssh_server_options', {})
  }

  class { '::zabbix::agent':
    server       => hiera('profiles::base::zbx_agent_server', undef),
    serveractive => hiera('profiles::base::zbx_agent_serveractive', undef),
    hostnameitem => hiera('profiles::base::zbx_agent_hostnameitem', undef),
  }

  class { '::gcs':
    server_url      => hiera('profiles::base::gcs_url', undef),
    update_interval => hiera('profiles::base::gcs_interval', 30),
    tls_skip_verify => hiera('profiles::base::gcs_tls_skip_verify', true),
    tags            => hiera_array('profiles::base::gcs_tags', []),
  }

  $bpc_server = hiera('bpc_server', false)

  if !$bpc_server {

    class { '::backuppc::client':
      backuppc_hostname    => hiera('profiles::base::bpc_host', undef),
      rsync_share_name     => hiera_array('profiles::base::bpc_rsync_shares', []),
      backup_files_exclude => lookup('profiles::base::bpc_excludes', {}),
    }
  }

  else {

    class { '::backuppc::client':
      backuppc_hostname => $::fqdn,
      xfer_method       => 'tar',
      tar_share_name    => [ '/home', '/etc', '/var/log'],
      tar_client_cmd    => '/usr/bin/sudo $tarPath -c -v -f - -C $shareName --totals',
      tar_full_args     => '$fileList',
      tar_incr_args     => '--newer=$incrDate $fileList',
    }
  }

}

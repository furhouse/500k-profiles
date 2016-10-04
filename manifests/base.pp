class profiles::base {

  $packages = hiera_array('profiles::base::packages')

  Package { ensure  => latest, }

  package { $packages: }

  group { 'sudo':
    ensure  => present,
    gid     => '27',
    require => Class['::sudo'],
  }

  $bpc_server = hiera('bpc_server', false)

  if !$bpc_server {

    class { '::backuppc::client':
      backuppc_hostname    => hiera('bpc_host', undef),
      rsync_share_name     => hiera_array('bpc_rsync_shares', []),
      backup_files_exclude => hiera_hash('bpc_excludes', {}),
    }
  }

  else {

    class { '::backuppc::client':
      backuppc_hostname => "${::fqdn}",
      xfer_method       => 'tar',
      tar_share_name    => [ '/home', '/etc', '/var/log'],
      tar_client_cmd    => '/usr/bin/sudo $tarPath -c -v -f - -C $shareName --totals',
      tar_full_args     => '$fileList',
      tar_incr_args     => '--newer=$incrDate $fileList',
    }
  }

}

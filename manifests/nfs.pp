class profiles::nfs {

  $export                     = hiera('profiles::nfs::export')
  $nfs_v4                     = hiera('profiles::nfs::nfs_v4')
  $nfs_v4_export_root         = hiera('profiles::nfs::nfs_v4_export_root')
  $nfs_v4_export_root_clients = hiera('profiles::nfs::nfs_v4_export_root_clients')
  $nfs_v4_idmap_domain        = hiera('profiles::nfs::nfs_v4_idmap_domain')
  $nfs_v4_mount_root          = hiera('profiles::nfs::nfs_v4_mount_root')

  class { 'nfs::server':
    nfs_v4                     => $nfs_v4,
    nfs_v4_export_root         => $nfs_v4_export_root,
    nfs_v4_export_root_clients => $nfs_v4_export_root_clients,
    nfs_v4_idmap_domain        => $nfs_v4_idmap_domain,
  }

  class { 'nfs::params':
    nfs_v4_mount_root => $nfs_v4_mount_root,
  }

  create_resources(nfs::server::export, $export)

}

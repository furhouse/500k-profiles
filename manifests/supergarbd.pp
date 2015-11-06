class profiles::supergarbd {

  $garbd_package      = hiera('profiles::supergarbd::garbd_package')
  $garbd_ensure       = hiera('profiles::supergarbd::garbd_ensure')
  $spvprograms        = hiera('profiles::supergarbd::spvprograms')
  $spvpackageprovider = hiera('profiles::supergarbd::spvpackageprovider')
  $spvexecutable      = hiera('profiles::supergarbd::spvexecutable')
  $spvexecutablectl   = hiera('profiles::supergarbd::spvexecutablectl')

  apt::source { 'percona-trusty':
    comment    => 'percona-trusty',
    location   => 'http://repo.percona.com/apt/',
    repos      => 'main',
    key        => '430BDF5C56E7C94E848EE60C1C4CBDCDCD2EFD2A',
    key_server => 'keys.gnupg.net',
    include    => {
      'src' => false,
      'deb' => true,
    },
  }

  class { '::supervisord':
    package_provider => $spvpackageprovider,
    executable       => $spvexecutable,
    executable_ctl   => $spvexecutablectl,
  }

  package { "$garbd_package":
    ensure  => $garbd_ensure,
    require => Apt::Source['percona-trusty'],
    notify  => Exec['apt_update'],
  }

  contain '::supervisord'

  create_resources('supervisord::program', $spvprograms)

}

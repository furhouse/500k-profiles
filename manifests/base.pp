class profiles::base {

  $packages = hiera('profiles::base::packages')

  Package { ensure  => latest, }

  package { $packages: }

  group { 'sudo':
    ensure  => present,
    gid     => '27',
    require => Class['::sudo'],
  }

}

class profiles::base {

  $packages = hiera('profiles::base::packages')

  Package { ensure  => latest, }

  package { $packages: }

  class { 'apt':
    update => {
      frequency => 'daily',
    },
  }

}

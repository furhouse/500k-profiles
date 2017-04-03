# mopidy.conf is NOT being managed ... yet
class profiles::mopidy {

  ::apt::ppa { 'ppa:chris-lea/python-tornado':
    package_manage => true,
  }

  ::apt::ppa { 'ppa:chris-lea/python-pycares':
    package_manage => true,
  }

  ::apt::source { 'mopidy':
    location => 'http://apt.mopidy.com',
    release  => 'jessie',
    repos    => 'main contrib non-free',
    key      => {
      id     => '9E36464A7C030945EEB7632878FD980E271D2943',
      source => 'https://apt.mopidy.com/mopidy.gpg',
    },
    require  => [ ::Apt::Ppa['ppa:chris-lea/python-tornado'], ::Apt::Ppa['ppa:chris-lea/python-pycares'] ],
  }

  $packages = [ 'mpc', 'ncmpcpp', 'mopidy', 'mopidy-spotify', 'mopidy-scrobbler' ]

  package { $packages:
    ensure  => installed,
    require => [ ::Apt::Source['mopidy'], Class['::apt::update'] ],
  }

  class { '::python': }

  package { 'Mopidy-Qsaver':
    ensure   => '0.1.0',
    provider => 'pip',
    require  => [ Class['::python'], Package[$packages] ],
  }

  package { 'Mopidy-Mopify':
    ensure   => present,
    provider => 'pip',
    require  => [ Class['::python'], Package[$packages] ],
  }

  package { 'Mopidy-Iris':
    ensure   => present,
    provider => 'pip',
    require  => [ Class['::python'], Package[$packages] ],
  }

  package { 'Mopidy-Local-SQLite':
    ensure   => present,
    provider => 'pip',
    require  => [ Class['::python'], Package[$packages] ],
  }

  exec { 'start_mopidy_boot':
    path    => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'  ],
    command => 'echo "mopidy mopidy/daemon boolean true" | debconf-set-selections',
    unless  => 'debconf-get-selections | grep "mopidy/daemon" | grep true',
    require => Package[$packages],
  }
}

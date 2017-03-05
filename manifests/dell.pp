class profiles::dell {

  ::apt::source { 'dell_openmanage':
    location => 'http://linux.dell.com/repo/community/ubuntu',
    repos    => 'openmanage',
    key      => {
      id     => '42550ABD1E80D7C1BC0BAD851285491434D8786F',
      server => 'pool.sks-keyservers.net',
    },
  }

  $packages = [ 'dcism', ]

  package { $packages:
    ensure  => installed,
    require => ::Apt::Source['dell_openmanage'],
  }

}

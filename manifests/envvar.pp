class profiles::envvar {

  shellvar { 'TERM':
    ensure => present,
    target => '/etc/environment',
    value  =>  'xterm',
  }

}

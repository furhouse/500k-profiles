class profiles::termvar {

  shellvar { 'TERM':
    ensure => present,
    target => '/etc/environment',
    value  =>  'xterm',
  }

}

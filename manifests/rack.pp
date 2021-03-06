class profiles::rack {

  include ::lm_sensors

  class { '::ipmi':
    ipmievd_service_ensure => 'running',
  }

  augeas { 'ipmievd':
    context => '/files/etc/default/ipmievd',
    changes => [
      'set ENABLED true',
    ],
    require => Class['::ipmi'],
  }

}

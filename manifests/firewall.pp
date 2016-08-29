class profiles::firewall {
  class { '::firewall': }
  resources { 'firewall':
    purge => false,
  }

  Firewall {
    before        => Class['profiles::firewall::post'],
    require       => Class['profiles::firewall::pre'],
  }

  class { ['profiles::firewall::pre', 'profiles::firewall::post']: }

  $rules = hiera_hash('fwrules', {})

  create_resources('firewall', $rules)
}

class profiles::sssd {

  class { '::sssd':
    config => hiera_hash('profiles::sssd::cfg', {})
  }

}

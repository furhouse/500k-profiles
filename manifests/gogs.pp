class profiles::gogs {

  class { '::gogs':
    app_ini          => hiera_hash('profiles::gogs::app_ini', {}),
    app_ini_sections => hiera_hash('profiles::gogs::app_ini_sections', {}),
    manage_packages  => false,
  }

}

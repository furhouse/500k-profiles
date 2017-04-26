class profiles::foreman {

  class { '::foreman':
    admin_password        => hiera('profiles::foreman::admin_pass', undef),
    db_password           => hiera('profiles::foreman::db_pass', undef),
    db_type               => hiera('profiles::foreman::db_type', 'postgresql'),
    oauth_consumer_key    => hiera('profiles::foreman::oauth_consumer_key', undef),
    oauth_consumer_secret => hiera('profiles::foreman::oauth_consumer_secret', undef),
    logging_level         => hiera('profiles::foreman::logging_level', 'info'),
    loggers               => hiera_hash('profiles::foreman::loggers', {}),
    custom_repo           => false,
  }

}

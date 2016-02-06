class profiles::backuppc {

  class { 'backuppc::server':
    backuppc_password => 'somesecret'
  }

}

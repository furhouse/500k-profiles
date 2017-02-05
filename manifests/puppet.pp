class profiles::puppet {

  $is_puppetmaster = hiera('is_puppetmaster', false)

  if !$is_puppetmaster {

    class { '::puppet':
      puppetmaster => hiera('puppetmaster', undef),
      show_diff    => true,
      listen       => true,
    }
  }

  else {

    class { '::hiera':
      datadir        => '/etc/puppetlabs/code/hieradata/%{::environment}',
      merge_behavior => 'deeper',
      hierarchy      => [
        'nodes/%{::fqdn}',
        'common',
      ],
    }

    class { '::r10k':
      version           => '1.5.1',
      manage_modulepath => false,
      sources           => {
        'hiera4' => {
          'remote'  => hiera('modules_remote', undef),
          'basedir' => "${::settings::codedir}/environments",
          'prefix'  => false,
        },
        'hiera3'  => {
          'remote'  => hiera('hiera_remote', undef),
          'basedir' => "${::settings::codedir}/hieradata",
          'prefix'  => false,
        }
      },
    }

    tidy { '/var/lib/puppet/reports':
      age     => '4w',
      matches => "*.yaml",
      recurse => true,
      rmdirs  => false,
      type    => ctime,
    }

  }

}

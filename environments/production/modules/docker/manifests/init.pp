# == Class: docker
#
# Install and maintain the Docker Service. Support for Ubuntu OS.
# Uses latest packages from docker.com.
#
# === Parameters
# [*docker_opts*]
#   Array of options to be passed to the docker daemon.
#   docker_opts => [ '--dns=8.8.8.8', '--insecure-registry=myreg.example.com' ]
#
# [*version*]
# pass version to lxc-docker package.
# Default is installed. Can be version like '1.3.1' or 'latest'
# Older versions may not be avalible in the docker.com repo :(
# === Variables
#
# === Examples
#
#  class { 'docker':
#   docker_opts => [ '--dns=8.8.8.8', '--insecure-registry=myreg.example.com' ],
#  }
#
# === Authors
#
# Jason Greathouse <jgreat@jgreat.me>
#
# === Copyright
#
# Copyright 2014 Jason Greathouse
#
class docker (
  $docker_opts = [],
  $version = 'installed',
){

  validate_array($docker_opts)
  validate_string($version)
  $docker_options = join($docker_opts, ' ')

  case $::operatingsystem {
    'Ubuntu': {
      exec { 'docker-apt-get-update':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
      }

      # Use new dockerproject repo and docker-engine package.
      apt::source { 'dockerproject':
        ensure => absent,
      }

      apt::source { 'docker':
        location => 'https://apt.dockerproject.org/repo',
        release  => "ubuntu-${::os['distro']['codename']}",
        repos    => 'main',
        key      => {
          'id'     => '58118E89F3A912897C070ADBF76221572C52609D',
          'server' => 'keyserver.ubuntu.com',
        },
        include  => {
          'src' => false,
        },
        notify   => Exec['docker-apt-get-update']
      }

      case $::os['distro']['codename'] {
        'trusty': {
          file_line { 'default_docker':
            path   => '/etc/default/docker',
            line   => "DOCKER_OPTS=\"${docker_options}\"",
            match  => '^DOCKER_OPTS=.*',
            notify => Service['docker'],
          }
        }
        'xenial': {
          exec { 'docker-systemd-daemon-reload':
            command     => '/bin/systemctl daemon-reload',
            refreshonly => true,
            notify      => Service['docker'],
          }
          file { '/etc/systemd/system/docker.service.d':
            ensure => directory,
          }
          file { '/etc/systemd/system/docker.service.d/docker.conf':
            content => template("${module_name}/etc/systemd/system/docker.service.d/docker.conf.erb"),
            notify  => Exec['docker-systemd-daemon-reload'],
          }
        }
      }
      package { 'docker-engine':
        ensure  => $version,
        require => Exec['docker-apt-get-update'],
        notify  => Service['docker'],
      }


    }
    'RedHat': {
    }
    default: {
    }
  }

  service { 'docker':
    ensure => running,
    enable => true,
    notify => Exec['wait-for-docker'],
  }
  exec { 'wait-for-docker':
    command     => '/usr/bin/docker info',
    refreshonly => true,
    tries       => 30,
    try_sleep   => 1,
  }
}

# Used to define/realize users on Puppet-managed systems
#
class accounts {
  file_line { 'default_useradd':
    ensure => present,
    path   => '/etc/default/useradd',
    match  => '^SHELL=',
    line   => 'SHELL=/bin/bash'
  }
}

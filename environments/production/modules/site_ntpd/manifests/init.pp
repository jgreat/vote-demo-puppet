#
class site_ntpd {
  package { 'ntp': }
  file { '/etc/ntp.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///modules/${module_name}/etc/ntp.conf",
    # require => Package['ntp'],
    notify => Service['ntp'],
  }
  service { 'ntp':
    ensure => running,
    enable => true,
    # require => File['/etc/ntp.conf'],
  }
}

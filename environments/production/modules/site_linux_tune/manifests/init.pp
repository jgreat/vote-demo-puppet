#
class site_linux_tune {
  # Ulimit
  file { '/etc/security/limits.d/lk.conf':
    mode   => '0644',
    source => "puppet:///modules/${module_name}/etc/security/limits.d/lk.conf",
  }
  # Sysctl - Network/Kernel
  file { '/etc/sysctl.d/09-lk.conf':
    mode   => '0644',
    source => "puppet:///modules/${module_name}/etc/sysctl.d/09-lk.conf",
    notify => Exec['sysctl-lk.conf'],
  }
  exec { 'sysctl-lk.conf':
    command     => '/sbin/sysctl --load=/etc/sysctl.d/09-lk.conf',
    refreshonly => true,
  }
  # Kernel
  exec { 'disable_transparent_hugepage':
    command => '/bin/echo never > /sys/kernel/mm/transparent_hugepage/enabled',
    unless  => '/bin/grep -c \'\[never\]\' /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null',
  }
  # Disk
  $::disks.each |$d_key, $d_value| {
    if $d_key =~ /^(sd|xvd)/ {
      exec { "nr_requests.${d_key}":
        command => "/bin/echo 1024 >/sys/block/${d_key}/queue/nr_requests",
        unless  => "/bin/cat /sys/block/${d_key}/queue/nr_requests | /bin/grep 1024",
      }
    }
  }
}

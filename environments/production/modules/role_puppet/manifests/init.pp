# Class: role_puppet
# ===========================
#
class role_puppet {
  # Make sure puppetmaster starts on boot
  service { 'puppetserver':
    ensure => running,
    enable => true,
  }
}

#
class site_resolv {
  file_line { 'resolv.conf':
    path  => '/etc/resolv.conf',
    line  => "search ${::networking['domain']}",
    match => '^search .*',
  }
}

# Apply to all Ubuntu servers
class { 'site_linux_tune': }
class { 'site_python': }
class { 'site_accounts': }
class { 'site_ntpd': }
class { 'site_resolv': }
class { 'site_docker': }

# role base modules
class { "role_${::lk['role']}": }

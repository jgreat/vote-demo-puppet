#
class site_python {
  # Remove crappy ubuntu version
  # Add setuptools (easy_install)
  package { 'python-pip':
    ensure => latest,
  }
  package { 'python-dev':
    ensure => latest,
  }

  # Why did we need these packages?
  package { 'libffi-dev': }
  package { 'libssl-dev': }
  package { 'ndg-httpsclient':
    ensure   => 'latest',
    provider => 'pip',
  }
}

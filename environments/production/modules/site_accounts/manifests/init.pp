#
class site_accounts {
  class { 'accounts': }

  file { '/etc/sudoers.d/devops':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => '%devops ALL=(ALL) NOPASSWD:ALL',
  }

  $users = keys(hiera_hash('accounts'))
  @accounts::users { [ $users ] : }

  # Admin Accounts - All Servers
  Accounts::Users <|title == 'jason.greathouse'|>
}

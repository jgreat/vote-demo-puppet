# Defined type for creating virtual user accounts
#
define accounts::users (
    $remove = false,
    $groups = undef
) {
  $users = hiera_hash('accounts')
  $uid = $users[$title]['uid']
  $realname = $users[$title]['realname']
  if ($groups) {
    $userGroups = $groups
  } else {
    $userGroups = $users[$title]['groups']
  }
  $github_user = $users[$title]['github_user']

  if $remove {
    $date = strftime('%Y%m%d-%H%M%S')
    exec { "/bin/tar cvfz /home/${title}-${date}.tar.gz /home/${title}":
      onlyif  => "/usr/bin/test -d /home/${title}",
      creates => "/home/${title}-${date}.tar.gz",
    }
    file { "/home/${title}":
      ensure  => absent,
      recurse => true,
      force   => true,
      purge   => true,
      require => Exec["/bin/tar cvfz /home/${title}-${date}.tar.gz /home/${title}"],
    }
    user { $title:
      ensure  => absent,
      require => File["/home/${title}"],
    }
    group { $title:
      ensure  => absent,
      require => [
        File["/home/${title}"],
        User[$title],
      ],
    }
  }
  else {
    if ($userGroups) {
      user { $title:
        ensure     => present,
        uid        => $uid,
        home       => "/home/${title}",
        comment    => $realname,
        managehome => true,
        groups     => $userGroups,
        shell      => '/bin/bash',
        require    => File_line['default_useradd']
      }
    }
    else {
      user { $title:
        ensure     => present,
        uid        => $uid,
        home       => "/home/${title}",
        comment    => $realname,
        managehome => true,
        shell      => '/bin/bash',
        require    => File_line['default_useradd']
      }
    }
    group { $title:
      gid     => $uid,
      require => User[ $title ]
    }
    file { "/home/${title}":
      ensure  => directory,
      owner   => $title,
      group   => $title,
      mode    => '0755',
      require => [
        User[$title],
        Group[$title],
      ],
    }
    file { "/home/${title}/.ssh":
      ensure  =>  directory,
      owner   =>  $title,
      group   =>  $title,
      mode    =>  '0700',
      require =>  File["/home/${title}"],
    }
    file { "/home/${title}/.ssh/authorized_keys":
      owner   => $title,
      group   => $title,
      mode    => '0600',
      content => generate('/usr/bin/curl', '-Ss', "https://github.com/${github_user}.keys"),
      require => File["/home/${title}/.ssh"],
    }
  }
}

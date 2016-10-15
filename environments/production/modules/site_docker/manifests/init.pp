# Class: role_puppet
# ===========================
#
class site_docker {
  #Class for base docker config


  # Login creds for docker - leankitbuildmonkey
  file { '/var/lib/docker':
    ensure => directory,
  }

  case $::os['distro']['codename'] {
    'trusty': {
      $vg = 'docker'
      $lv = 'data01'
      $opts = [
        '--tlsverify',
        "--tlscacert=${::ssldir}/certs/ca.pem",
        "--tlscert=${::ssldir}/certs/${::fqdn}.pem",
        "--tlskey=${::ssldir}/private_keys/${::fqdn}.pem",
        '--host=tcp://0.0.0.0:2376',
        '--host=unix:///var/run/docker.sock',
        '--storage-driver=overlay'
      ]

      # Create thinpool for Docker
      package { 'lvm2': }
      $::disks.each |$d, $v| {
        if ($d =~ /^sd[c-z]+/) {
          # Create pv if not a pv
          exec { "/sbin/pvcreate /dev/${d}":
            unless => "/sbin/pvs --noheadings /dev/${d}",
          }
          # Create VG if not exists
          exec { "/sbin/vgcreate ${vg} /dev/${d}":
            unless => "/sbin/vgs ${vg}",
          }
          # Add disk if not in the vg
          exec { "/sbin/vgextend ${vg} /dev/${d}":
            unless => "/sbin/pvs --noheadings -o vg_name /dev/${d} | /bin/grep ${vg}",
          }
        }
      }
      # create volume if it doesn't exist
      exec { "/sbin/lvcreate --extents 100%FREE -n ${lv} ${vg}":
        unless  => "/sbin/lvs ${vg}/${lv}",
      }
      # Create ext4 filesystem
      exec { "/sbin/mkfs.ext4 -j -b 4096 /dev/${vg}/${lv}":
        unless  => "/sbin/blkid /dev/${vg}/${lv} | /bin/grep 'TYPE=\"ext4\"'",
        require => Exec["/sbin/lvcreate --extents 100%FREE -n ${lv} ${vg}"],
      }
      # extend volume if room in data vg
      exec { "/sbin/lvextend --extents +100%FREE ${vg}/${lv}":
        unless => "/sbin/vgs --noheadings -o vg_free ${vg} | /bin/grep -P '^\\s+0\\s$'"
      }
      mount { '/var/lib/docker':
        ensure  => 'mounted',
        atboot  => true,
        device  => "/dev/${vg}/${lv}",
        fstype  => 'ext4',
        options => 'defaults,nobootwait,nobarrier',
        dump    => '0',
        pass    => '2',
        require => [
          File['/var/lib/docker'],
          Exec["/sbin/mkfs.ext4 -j -b 4096 /dev/${vg}/${lv}"],
        ]
      }
      class { 'docker':
        docker_opts => $opts,
        version     => "1.10.3-0~${::os['distro']['codename']}",
        require     => Mount['/var/lib/docker'],
      }
    }
    'xenial': {
      $zpool = 'zpool-docker'
      $opts = [
        '--tlsverify',
        "--tlscacert=${::ssldir}/certs/ca.pem",
        "--tlscert=${::ssldir}/certs/${::fqdn}.pem",
        "--tlskey=${::ssldir}/private_keys/${::fqdn}.pem",
        '--host=tcp://0.0.0.0:2376',
        '--host=unix:///var/run/docker.sock',
        '--storage-driver=zfs'
      ]
      package { 'zfsutils-linux': }

      # we want to add luns 0-7 for the sdc controller
      $sdc_controller = $::scsi_by_device['sdc']['controller']

      $::scsi_by_device.each |$d, $v| {
        if ($v['controller'] == $sdc_controller) {
          if ($v['lun'] =~ /[0-7]/){
            # Create pool if not exists
            exec { "/sbin/zpool create -f ${zpool} /dev/${d}":
              unless => "/sbin/zpool list -H ${zpool}",
            }
            # Add more devices
            exec { "/sbin/zpool add -f ${zpool} /dev/${d}":
              unless => "/sbin/zpool status ${zpool} | /bin/grep ${d}",
            }
          }
        }
      }

      exec { "/sbin/zfs create -o mountpoint=/var/lib/docker -o dedup=off ${zpool}/docker":
        unless => "/sbin/zfs list ${zpool}/docker",
      }

      class { 'docker':
        docker_opts => $opts,
        version     => "1.11.2-0~${::os['distro']['codename']}",
        require     => Exec["/sbin/zfs create -o mountpoint=/var/lib/docker -o dedup=off ${zpool}/docker"],
      }
    }
  }
}

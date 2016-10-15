# Definition: docker::image
#
# This class installs or removes docker images.
#
# Requires docker version >=1.3.1
#
# Parameters:
# Option parameters:
# ensure => "latest" - pull a docker image
# ensure => "0.1.1" - tag version docker image
# ensure => "absent" - remove docker image
# tag => '0.1.1' - pull/remove a specific tag for the repo default is 'latest'
# image => 'myrepo.jgreat.me:port/myimage'
#
# Requires:
# - docker class
#
# Sample Usage:
#    require docker
#
#    docker::image { 'ubuntu':
#      tag => '14.04'
#    }
#
define docker::image (
    $ensure = 'latest',
    $image_tag = undef,
    $image = $title,
) {
  validate_string($ensure)
  validate_string($image_tag)
  validate_string($image)

  if (!$image_tag) {
    $i_tag = $ensure
  } else {
    $i_tag = $image_tag
  }

  # if ensure == absent and tag not defined, tag = latest
  if (($ensure == 'absent') and ($i_tag == 'absent')) {
    $i_tag = 'latest'
  }

  if ($ensure == 'absent') {
    #remove images if they exist
    exec { "/usr/bin/docker rmi ${image}:${i_tag}":
      onlyif  => "/usr/bin/docker images -q ${image} | /usr/bin/awk '{print \$2}' | /bin/grep ${i_tag}",
      require => Exec['wait-for-docker']
    }
  } else {
    exec { "/usr/bin/docker pull ${image}:${i_tag}":
      unless  => "/usr/bin/docker images ${image} | /usr/bin/awk '{print \$2}' | /bin/grep ${i_tag}",
      require => Exec['wait-for-docker']
    }
  }
}

#
# define that wraps sudoers functionality of sudores
#
define sudo::defaults(
  $ensure,
  $parameters,
  $comment = '',
  $target = '/etc/sudoers'
) {

  sudoers { $name:
    type       => 'default',
    ensure     => $ensure,
    parameters => $parameters,
    comment    => $comment,
    target     => $target,
  }
}

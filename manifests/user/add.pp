# this should eventaully be a native type 
define rabbitmq::user::add (
  $password,
  $path = '/usr/sbin/'
) {
  $line_filter = "grep -v '\.\.\.'"
  exec { "${path}/rabbitmqctl add_user ${title} ${password}":
    unless  => "${path}/rabbitmqctl list_users | /bin/grep -v '\.\.\.' | /usr/bin/cut -f 1 | /bin/grep ${title}" 
  }
}

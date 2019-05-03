# @summary
#   This class handles the RabbitMQ guest user.
#
# @api private
#
class rabbitmq::management {

  assert_private()

  if $rabbitmq::delete_guest_user {
    rabbitmq_user { 'guest':
      ensure   => absent,
      provider => 'rabbitmqctl',
    }
  }
}

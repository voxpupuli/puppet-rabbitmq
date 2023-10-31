# install first the puppet/erlang module. See README.md
include erlang

Class['erlang'] -> Class['rabbitmq']

# Fact to get the ssl path for the erlang distribution in the current
# system as described in the RabbitMQ docs [1].
#
# [1] https://www.rabbitmq.com/clustering-ssl.html
Facter.add('erl_ssl_path') do
  setcode do
    data = false
    if Facter::Util::Resolution.which('erl')
      Facter::Util::Resolution.with_env('HOME' => '/root') do
        data = Facter::Core::Execution.execute("erl -eval 'io:format(\"~p\", [code:lib_dir(ssl, ebin)]),halt().' -noshell")
      end
    end
    # erl returns the string with quotes, strip them off
    data.gsub!(%r{\A"|"\Z}, '')
  end
end

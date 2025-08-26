# rubocop:disable Style/FrozenStringLiteralComment

require 'spec_helper'

describe Facter::Util::Fact do
  before { Facter.clear }

  describe 'erl_ssl_path' do
    context 'with valid value' do
      it do
        allow(Facter::Util::Resolution).to receive(:which).with('erl').and_return(true)
        allow(Facter::Core::Execution).to receive(:execute).with("erl -eval 'io:format(\"~p\", [code:lib_dir(ssl, ebin)]),halt().' -noshell").and_return('"/usr/lib64/erlang/lib/ssl-5.3.3/ebin"')
        expect(Facter.fact(:erl_ssl_path).value).to eq('/usr/lib64/erlang/lib/ssl-5.3.3/ebin')
      end
    end

    context 'with error message' do
      it do
        allow(Facter::Util::Resolution).to receive(:which).with('erl').and_return(true)
        allow(Facter::Core::Execution).to receive(:execute).with("erl -eval 'io:format(\"~p\", [code:lib_dir(ssl, ebin)]),halt().' -noshell").and_return('{error,bad_name}')
        expect(Facter.fact(:erl_ssl_path).value).to be_nil
      end
    end

    context 'with erl not present' do
      it do
        allow(Facter::Util::Resolution).to receive(:which).with('erl').and_return(false)
        expect(Facter.fact(:erl_ssl_path).value).to be_nil
      end
    end
  end
end

# rubocop:enable Style/FrozenStringLiteralComment

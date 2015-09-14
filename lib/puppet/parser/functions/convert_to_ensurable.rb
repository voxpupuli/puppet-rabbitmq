#
# convert_to_ensurable.rb
#
# Simple converter function to map boolean values into their 'ensurable' counterparts, :present & :absent
#
module Puppet::Parser::Functions
  newfunction(:convert_to_ensurable, :type => :rvalue, :doc => <<-EOS
Simple converter function to map a boolean value into its 'ensurable' counterpart
    EOS
  ) do |arguments|
    raise(Puppet::ParseError, "convert_to_ensurable(): Expected one argument") if arguments.size < 1
    case arguments[0]
      when false then return :absent
      when true  then return :present
      else raise(Puppet::ParseError, 'convert_to_ensurable(): Expected boolean argument')
    end
  end
end

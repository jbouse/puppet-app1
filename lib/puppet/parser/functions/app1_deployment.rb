module Puppet::Parser::Functions

  newfunction(:app1_deployment, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    Load a YAML file containing a deployment configuration, and return the data
    in the corresponding native data type.

    For example:

        $myhash = app1_deployment('/etc/puppet/data/myhash.yaml')

        or

        $myhash = app1_deployment('http://localhost/data/myhash.yaml')
    ENDHEREDOC

    unless args.length == 1
      raise Puppet::ParseError, ("app1_deployment(): wrong number of arguments (#{args.length}; must be 1)")
    end

    require 'open-uri'

    YAML.load(open(args[0]))

  end

end

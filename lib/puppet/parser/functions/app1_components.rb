module Puppet::Parser::Functions

  newfunction(:app1_components, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    Given an array of hashs containing a site deployment accumulate an array of
    the unique component/version combination required by the sites listed within
    the deployment.

    Example:

        $sites_hash = [{"siteA" => {"components" => [{"comp1" => "3"}, {"comp2" => "4"}], "version" => "5"}}]
        $components = app1_components($sites_hash)
        # The resulting array is equivalent to:
        # $components = ["comp1/3", "comp2/4"]

    ENDHEREDOC

    compkey = 'components'

    unless args.length == 1
      raise Puppet::ParseError, "app1_components(): wrong number of arguments (#{args.length}; must be 1)"
    end
    unless args.is_a?(Array)
      raise Puppet::ParseError, "app1_components(): expects the argument to be an array, got #{args.inspect} which is of type #{args.class}"
    end

    # The array we accumulate into
    accumulator = Array.new
    # Merge into the accumulator all site 'components' arrays
    args.each do |site|
      site.each do |opt, val|
        if val.has_key?(compkey)
          val[compkey].each { |a| a.each { |k,v| accumulator << "#{k}/#{v}" } }
        end
      end 
    end
    accumulator.uniq!
  end
end

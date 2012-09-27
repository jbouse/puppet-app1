module Puppet::Parser::Functions

  newfunction(:app1_site_components, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    Given an array of hashs containing a site deployment accumulate an array of
    the unique component/version combination required by the sites listed within
    the deployment.

    Example:

        $site = "siteA"
        $components = ["components" => [{"comp1" => "3"}, {"comp2" => "4"}], "version" => "5"}]
        $site_components = app1_site_components($site, $components)
        # The resulting array is equivalent to:
        # $site_components = ["siteA/comp1/3", "siteA/comp2/4"]

    ENDHEREDOC

    compkey = 'components'

    unless args.length == 2
      raise Puppet::ParseError, "app1_site_components(): wrong number of arguments (#{args.length}; must be 2)"
    end
    unless args[0].is_a?(String)
      raise Puppet::ParseError, "app1_site_components(): expects the first argument to be a string, got #{args[0].inspect} which is of type #{args[0].class}"
    end
    unless args[1].is_a?(Array)
      raise Puppet::ParseError, "app1_site_components(): expects the second argument to be an array, got #{args.inspect} which is of type #{args.class}"
    end

    site = args[0]
    # The array we accumulate into
    accumulator = Hash.new
    # Merge into the accumulator all site 'components' arrays
    args[1].each do |c|
        c.each { |k,v| accumulator["#{site}/#{k}"] = { 'version' => "#{v}" } }
    end
    accumulator
  end
end

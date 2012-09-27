define app1::manage_components(
    $version    = undef,
    $sitedir    = undef,
) {
    $component = regsubst($name, '^(\w+)/(\w+)', '\2')
    debug("Deploy ${component} component version ${version} to ${sitedir}")
    
    file {
        "${sitedir}/${component}":
            ensure  => symlink,
            notify  => Service['httpd'],
            target  => "${app1::rootdir}/components/${component}/${version}",
            require => App1::Component["${component}/${version}"];
    }
}

define app1::component(
    $ensure  = 'present',
) {
    # Validate our inputs from the end user using a "best effort" strategy
    # ensure
    validate_re($ensure, '^present$|^absent$')

    $component = regsubst($name, '^(\w+)/(\d+)', '\1')
    $version = regsubst($name, '^(\w+)/(\d+)', '\2')

    $componentroot = inline_template("<%= File.join('${app1::componentsdir}', '${component}') %>")
    $componentdir = inline_template("<%= File.join('${componentroot}', '${version}') %>")

    $tarball = "${component}_${version}.tgz"
    $sourceurl = s3geturl($app1::software, "components/${tarball}", 1800)

    debug("Deploy ${component} component version ${version}")

    file {
        $componentdir:
            ensure  => $ensure ? {
                default => directory,
                absent  => $ensure,
            },
            force   => true,
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            backup  => false,
            require => File[$componentroot];
    }

    common::archive::tar-gz {
        "${componentdir}/.installed":
            ensure  => $ensure,
            source  => $sourceurl,
            target  => $componentdir,
            require => File[$componentdir];
    }
}

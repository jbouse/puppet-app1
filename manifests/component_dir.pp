define app1::component_dir(
    $ensure  = 'present',
) {
    # Validate our inputs from the end user using a "best effort" strategy
    # ensure
    validate_re($ensure, '^present$|^absent$')

    $componentroot = inline_template("<%= File.join('${app1::componentsdir}', '${name}') %>")

    file {
        $componentroot:
            ensure  => $ensure ? {
                default => directory,
                absent  => $ensure,
            },
            force        => true,
            recurse      => true,
            purge        => true,
            recurselimit => 2,
            mode         => '0755',
            owner        => 'root',
            group        => 'root',
            backup       => false,
            require      => File[$app1::componentsdir];
    }
}

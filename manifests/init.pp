class app1 inherits app1::params {
    class { 'apache::php': }

    debug("App1 ${environment} Environment (${deployment})")

    $sitesdir = inline_template("<%= File.join('${rootdir}', 'sites') %>")
    $componentsdir = inline_template("<%= File.join('${rootdir}', 'components') %>")
    $assetsdir = inline_template("<%= File.join('${rootdir}', 'assets') %>")
    $logsdir = inline_template("<%= File.join('${rootdir}', 'logs') %>")

    apache::mod {
        [
            'expires',
            'rewrite',
        ]: }

    apache::mod { 'rpaf': package => 'libapache2-mod-rpaf'; }

    apache::vhost {
        "default":
            ensure             => present,
            priority           => '000',
            configure_firewall => false,
            ssl                => false,
            port               => '80',
            docroot            => '/var/www';
    }

    file {
        $rootdir:
            ensure => directory,
            mode   => '0755',
            owner  => 'root',
            group  => 'root';

        $sitesdir:
            ensure  => directory,
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            require => File[$rootdir];

        $componentsdir:
            ensure  => directory,
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            require => File[$rootdir];

        $assetsdir:
            ensure  => directory,
            mode    => '0755',
            owner   => 'www-data',
            group   => 'www-data',
            require => File[$rootdir];

        $logsdir:
            ensure  => directory,
            mode    => '0755',
            owner   => 'www-data',
            group   => 'www-data',
            require => File[$rootdir];
    }

    package {
       [
            "php5-imagick",
            "php5-mysql",
            "php5-memcache",
            "php5-gd",
            "php5-curl",
            "php-apc"
        ]:
            ensure => latest,
            notify => Service["apache2"];
    }

    # Load the hash data from YAML
    # The file containing the end user defines data in.
    $sites_hash_file = s3geturl($software, "deployments/${deployment}", 1800)
    # Load the files and validate the basic data types.
    $sites_hash = app1_deployment($sites_hash_file)
    validate_hash($sites_hash)

    $components_hash = app1_components($sites_hash)
    validate_array($components_hash)
    $componentdirs_hash = app1_component_dirs($sites_hash)
    validate_array($componentdirs_hash)

    app1::component_dir { $componentdirs_hash: }
    app1::component { $components_hash: }
    create_resources('app1::site', $sites_hash)

    if $loadBalancer {
        elbRegisterInstance($loadBalancer)
    }
}

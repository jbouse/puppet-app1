define app1::site(
    $ensure = 'present',
    $version = undef,
    $main = undef,
    $admin = undef,
    $aliases = [],
    $cookie = undef,
    $fb_app_id = undef,
    $fb_secret = undef,
    $aws_bucket = undef,
    $twitter = 'absent',
    $components = []
) {
    # Validate our inputs from the end user using a "best effort" strategy
    # ensure
    validate_re($ensure, '^present$|^absent$')
    # version number
    if $version != undef {
        validate_re($version, '^\d+$')
    }
    # main vhost name
    if $main != undef {
        validate_string($main)
        $app1_main_vhost = $main
    } else {
        $app1_main_vhost = "${name}.v2.${app1::domain}"
    }
    # admin vhost name
    if $admin != undef {
        validate_string($admin)
        $app1_admin_vhost = $admin
    } else {
        $app1_admin_vhost = "admin.${app1_main_vhost}"
    }
    # aliases for site
    if $aliases != [] {
        validate_array($aliases)
        $app1_aliases = $aliases
    } else {
	$app1_aliases = ["www.${app1_main_vhost}",]
    }
    # cookie domain
    if $cookie != undef {
        validate_string($cookie)
        $app1_cookie_domain = $cookie
    } else {
        $app1_cookie_domain = $app1_main_vhost
    }
    # facebook application id
    if $fb_app_id != undef {
        validate_re($fb_app_id, '^\d+$')
        $app1_fb_app = $fb_app_id
        debug("Facebook Application ID ${app1_fb_app}")
    }
    # facebook secret
    if $fb_secret != undef {
        validate_string($fb_secret)
        $app1_fb_secret = $fb_secret
    }
    # twitter
    validate_re($twitter, '^present$|^absent$')
    # components
    if $components != [] {
        validate_array($components)
    }

    $siteroot = inline_template("<%= File.join('${app1::sitesdir}', '${name}') %>")
    $sitedir = inline_template("<%= File.join('${siteroot}', '${version}') %>")
    $currentdir = inline_template("<%= File.join('${siteroot}', 'current') %>")

    $config_file = "config/defines_infrastructure.php"

    $tarball = "${name}_${version}.tgz"
    $sourceurl = s3geturl($app1::software, "sites/${tarball}", 1800)

    debug("Deploy ${name} site version ${version}")
    if $components != [] {
        $site_components = app1_site_components($name, $components)
        $defaults = { 'sitedir' => $sitedir }
        create_resources('app1::manage_components', $site_components, $defaults)
    }

    file {
        $siteroot:
            ensure  => $ensure ? {
                default => directory,
                absent  => $ensure,
            },
            force   => true,
            recurse => true,
            purge   => true,
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            backup  => false,
            require => File[$app1::sitesdir];

        $sitedir:
            ensure  => $ensure ? {
                default => directory,
                absent  => $ensure,
            },
            force   => true,
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            backup  => false,
            require => File[$siteroot];

        $currentdir:
            ensure  => $ensure ? {
                default => symlink,
                absent  => $ensure,
            },
            target  => $sitedir,
            owner   => 'root',
            group   => 'root',
            backup  => false,
            notify  => Service['httpd'],
            require => [
                    File[$sitedir],
                    File["${sitedir}/website/${config_file}"],
                    File["${sitedir}/admin/${config_file}"],
                ];
    }

    file {
        "${sitedir}/website/htdocs/cache":
            ensure  => $ensure ? {
                default => directory,
                absent  => $ensure,
            },
            force   => true,
            mode    => '0755',
            owner   => 'www-data',
            group   => 'www-data',
            backup  => false,
            require => Common::Archive::Tar-gz["${sitedir}/.installed"];

        "${sitedir}/admin/htdocs/cache":
            ensure  => $ensure ? {
                default => directory,
                absent  => $ensure,
            },
            force   => true,
            mode    => '0755',
            owner   => 'www-data',
            group   => 'www-data',
            backup  => false,
            require => Common::Archive::Tar-gz["${sitedir}/.installed"];

        "${sitedir}/admin/htdocs/tiny_mce":
            ensure  => $ensure ? {
                default => symlink,
                absent  => $ensure,
            },
            target  => "${sitedir}/tinymce",
            owner   => 'root',
            group   => 'root',
            backup  => false,
            require => Common::Archive::Tar-gz["${sitedir}/.installed"];

        "${sitedir}/website/${config_file}":
            ensure  => $ensure,
            content => template('app1/infrastructure-defines.php.erb'),
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            notify  => Service['httpd'],
            require => Common::Archive::Tar-gz["${sitedir}/.installed"];

        "${sitedir}/admin/${config_file}":
            ensure  => $ensure,
            content => template('app1/infrastructure-defines.php.erb'),
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            notify  => Service['httpd'],
            require => Common::Archive::Tar-gz["${sitedir}/.installed"];
    }

    apache::vhost {
        "${name}_website":
            ensure             => $ensure,
            priority           => '10',
            configure_firewall => false,
            ssl                => false,
            template           => 'app1/app1-vhost.conf.erb',
            servername         => $app1_main_vhost,
            port               => '80',
            docroot            => "${currentdir}/website/htdocs",
            serveraliases      => $app1_aliases;

        "${name}_admin":
            ensure             => $ensure,
            priority           => '15',
            configure_firewall => false,
            ssl                => false,
            template           => 'app1/app1-vhost.conf.erb',
            servername         => $app1_admin_vhost,
            port               => '80',
            docroot            => "${currentdir}/admin/htdocs";
    }

    common::archive::tar-gz {
        "${sitedir}/.installed":
            ensure  => $ensure,
            source  => $sourceurl,
            target  => $sitedir,
            require => File[$sitedir];
    }

    cron::crontab {
        "${name} twitter feed":
            ensure  => $twitter,
            user    => 'www-data',
            command => "cd ${currentdir}/common/bin; SITE_HOME=${currentdir}/website php process_twitter_feeds.php --log",
            minute  => "*/15";
    }
}

class app1::params {

    if $::app1_env {
        $environment = $::app1_env
    } else {
        $environment = $::environment
    }

    if $::app1_software {
        $software = $::app1_software
    } else {
        $software = hiera('app1_software', undef)
    }

    if $::app1_deployment {
        $deployment = $::app1_deployment
    } else {
        $deployment = hiera('app1_deployment')
    }


    $awsAccessKeyId = hiera('aws_access_key_id', undef)
    $awsSecretKey   = hiera('aws_secret_key', undef)
    $dbServer       = hiera('db_server', undef)
    $dbUser         = hiera('db_username', undef)
    $dbPasswd       = hiera('db_password', undef)
    $dbName         = hiera('db_name', undef)
    $cacheCluster   = hiera('app1_cache_cluster', 'localhost')
    $rootdir        = hiera('app1_root_dir', undef)
    $domain         = hiera('app1_domain', 'example.com')
    $loadBalancer   = hiera('app1_elb', undef)
    $cacheHosts     = $environment ? {
        'production' => ecGetMembers($cacheCluster),
        default      => $cacheCluster,
    }
}

App1 Module
===========

This module is meant to deploy a custom PHP web application that is deployed consisting of
multiple tarballs for `sites` and `components`. A `site` will require various `components`
and each `site` could require different versions of a `component`.

The deployment is managed via a YAML file that follows the following structure:

```yaml
---
site1:
    version: '12345'
    aws_bucket: 'app1-site1'
    components:
    - comp1: '12345'
    - comp2: '23456'
    - comp3: '34567'

site2:
    version: '12346'
    main: 'www.example.net'
    admin: 'admin.example.net'
    cookie: 'example.net'
    aws_bucket: 'app1-site2'
    components:
    - comp1: '12345'
    - comp2: '23456'
    - comp3: '12345'
```

In this example case there will need to be 4 `components` installed as `site1` and `site2` make
use of 2 different versions of `comp3` but otherwise use the same version of `comp1` and `comp2`.

Problem
-------

Currently the module functions as expected and deploys the application properly; however, it has
on multiple occasions generated execution timeouts on the Puppet master side due to time to render
the catalog so there is a need to improve the rendering. I believe that removing the need for several
of the generated parser functions can accomplish that if the module can be refactored to handle the 
YAML deployment file better.

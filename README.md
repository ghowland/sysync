## sysync

sysync is a system configuration manager, like Puppet/Chef/Ansible/Salt, but different.

sysync is:

* Data defined.  There is no scripting or script-like data definition language.  It uses YAML (preferred for human readability) or JSON to define the configuration.  This also makes it ideal for generating or creating custom interfaces to manage the configuration data.
* Idempotent.  sysync will always perform the same commands, given a particular host and host-state, and they will always be performed in the same order.
* Deterministic.  sysync creates an ordered list of commands that must be run to complete the configuration.  In non-commit mode it will always return the exact commands that will be run in sequence.  This gives the best feedback in terms of what work it will perform.  No guessing what work will be performed is required.
* Planned.  A given host can only be in a single host-group.  A host-group only supplies a specific set of packages.  Those packages are always evaluated in order.  Each package contains data directives for configuration, and are evaluated in sequence.  This removes conflicts of whether a host may or may not get a package, or what order the package might be deployed in.  It is always done the same way, and can only happen in one way.  This makes changes to sysync less worrisome, even in large installations, because you get what you meant, and not any number of unintended side-effects.
* Run locally.  It can be pushed or pulled onto a system, and then it is run locally.  This allows for easy testing by using alternative storage location to test a different configuration.
* Only for system configuration management.  It does not stop or start services, run commands (unrelated to configuration) or do anything besides system configuration management.  This is difficult and dangerous enough without adding in many unrelated tasks for other automation events.  Do one thing, and do it well.

sysync has been managing a production and corporate server infrastructure (500+ machines) since 2012.

Command Line options:

```
  -h, -?, --help          This usage information
  -C, --commit            Commit changes.  No changes will be made, unless set.
  -b, --bootstrap         Boot Strap this host (assume no local configuration)
      --hostgroups[=path] Path to host groups (directory)
      --deploy[=path]     Path to deployment files (directory)
      --packages[=path]   Path to package files (directory)
      --handlers[=path]   Path to handler default yaml data (directory)
      --buildas[=group]   Manually specify Host Group, cannot be in one already

  -v, --verbose           Verbose output
  -o, --output            Output file
  -f, --format            Output format: pprint, json, yaml
```


To run from a config directory:

```[config/production]$ ../../sysync/sysync.py install```


### Host Groups

A host can only be in a single host group.


### Hosts

A host defines a specific machine to configure.

### Packages

Packages are lists of Configuration Handler Dictionary/Hash/Map/Associative-Array data.

A basic package that installs MySQL server would look like this:

```
- yum:
  - name: mysql-server
```

In this way there is a "List -> Dictionary -> List -> Dictionary" approach to layering data.

The first list is the sequence out from the package.  This package has 1 Configuration Handler section to process.  The Dictionary key is "yum" which specifies the Configuration Handler to be used.

The list inside the yum configuration data is the order of the command groups to be run.  One or many items may be put under the "yum" handler, such as:

```
- yum:
  - name: mysql-server
  - name: mysql-devel
```

This would install the "mysql-sever" and the "mysql-devel" yum packages.

Any number of sections can exist in the same Package file, and a "yum" handler could be created many times, like:

```
- yum:
  - name: bind

- files:
  - path: /etc/resolv.conf
    source path: files/etc/resolv.conf

- yum:
  - name: mysql-server
```

The above Package file would first install bind, then installed "files/etc/resolve.conf" in the "config/production" current working directory to /etc/resolv.conf, and finally it will install the "mysql-server" yum package.

This allows for absolute sequencing of how things will be installed in this package.

### The Final Configuration Specification

A host can only be in a single host-group.  A host-group contains a set list of packages, in sequence.  Each package contains a sequence of configuration handlers, and handler items to be applied to the Final Configuration Specification.

The Final Configuration Specification is a roll up of all the sequences of packages, handlers and items.  Later packages or package handler items can change the properties of earlier configuration properties.

Consider this.  A host-group with 2 packages, "first_package" and "second_package".

first_package:

```
- files:
  - path: /etc/resolv.conf
    source path: files/etc/resolv.conf
```

second_package:

```
- files:
  - path: /etc/resolv.conf
    remove: true
```

The first_package tells sysync to put the "./config/production/files/etc/resolv.conf" file in the "/etc/resolv.conf" location.  The second_package tells sysync to set the "remove = True" data parameter.

When sysync is dont with processing both of the packages, it will only remove the /etc/resolv.conf as a final command.

Why?  Because we first told it to create it with the file given, and then we told it to remove the file.  The final configuration section for the files "/etc/resolv.conf" ignores putting a file there if it's going to be removed.


### Configuration Handlers

sysync configurations are defined in Handler Sections of data.  Each configuration file is considered a Dictionary/Hash/Map/Associative-Array, and the top-level key is the Configuration Handler.

Currently these are the Configuration Handlers: files, groups, services, users, yum

Configuration Handlers can be added easily to the code, and a downloadable plug-in system will be developed in the future to support more architectures and package managers.

#### files

The Handler Key for "files" is the "path" key.  This key must exist, and all changes associated with this key will overwrite the defaults as each Package Configuration Handler Section Item is processed.

Default values:

```
path: null
source path: null
symlink path: null
remove: false
template: false

user: root
group: root
mode: 644
directory mode: 755

ignore directories: ['.svn']
ignore files: []

set base directory permissions: false

# If true, this file will not collapse into the normal order of import, so that they can happen at a later time than first encountered
ordered: false

# If this file is not a match for a given path.  This is the only exclusionary directive and is the compliment to "ordered", in that something done initially should not be re-done when the alter ordered function is run
if not match: null
```

#### groups

The Handler Key for "groups" is the "name" key.  This key must exist, and all changes associated with this key will overwrite the defaults as each Package Configuration Handler Section Item is processed.

Default values:

```
name: null
gid: null
remove: false
```

#### services

The Handler Key for "services" is the "name" key.  This key must exist, and all changes associated with this key will overwrite the defaults as each Package Configuration Handler Section Item is processed.

Default values:

```
name: null
levels: 2345
run: true
remove: false
```

#### users

The Handler Key for "users" is the "name" key.  This key must exist, and all changes associated with this key will overwrite the defaults as each Package Configuration Handler Section Item is processed.

Default values:

```
name: null
fullname: null
uid: null
groups: []
ssh key: null
shell: null
home: null
remove: false
```

#### yum

The Handler Key for "yum" is the "name" key.  This key must exist, and all changes associated with this key will overwrite the defaults as each Package Configuration Handler Section Item is processed.

Default values:

```
name: null
version: null
remove: false
```


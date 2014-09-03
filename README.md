## sysync

sysync is a system configuration manager, like Puppet/Chef/Ansible/Salt, but different.

sysync is:

* Data defined.  There is no scripting or script-like data definition language.  sysync uses YAML (preferred for human readability) or JSON to define the configuration.  This also makes it ideal for generating or creating custom interfaces to manage the configuration data.
* Idempotent.  sysync will always perform the same commands, given a particular host and host-state, and they will always be performed in the same order.  Work will never be done and undone, will never toggle, even during the configuration, leaving the system in the most stable state during configuration.
* Deterministic.  sysync creates an ordered list of commands that must be run to complete the configuration.  In non-commit mode it will always return the exact commands that will be run in sequence.  This gives the best feedback in terms of what work it will perform.  There is no guessing in what work will be performed.
* Planned.  A given host can only be in a single host-group.  A host-group only supplies a specific set of packages.  Those packages are always evaluated in order.  Each package contains data directives for configuration, and are evaluated in sequence.  This removes conflicts of whether a host may or may not get a package, or what order the package might be deployed in.  It is always done the same way, and can only happen in one way.  This makes changes to sysync less worrisome, even in large installations, because you get what you meant, and not any number of unintended side-effects.
* Run locally.  It can be pushed or pulled onto a system, and then it is run locally.  This allows for easy testing by using alternative storage location to test a different configuration.
* Only for system configuration management.  It does not stop or start services, run commands (unrelated to configuration) or do anything besides system configuration management.  This is difficult and dangerous enough without adding in many unrelated tasks for other automation events.  Do one thing, and do it well.  sysync is differentiated more by what it does not do, than by what it does do.

sysync has been managing a production and corporate server infrastructure (500+ machines) since 2012.

Command Line options:

```
  -h, -?, --help          This usage information
  -C, --commit            Commit changes.  No changes will be made, unless set.
  -b, --bootstrap         Boot Strap this host (assume no local configuration)
  
      --hostgroups[=path] Path to host groups (directory)
      --packages[=path]   Path to package files (directory)
      
      --buildas[=group]   Manually specify Host Group, cannot be in one already
      
      --deploy[=path]     Path to deployment files (directory)
      --handlers[=path]   Path to handler default yaml data (directory)

  -v, --verbose           Verbose output
  -o, --output            Output file
  -f, --format            Output format: pprint, json, yaml
```


To run from the git clone directory, as the "database" Host Group, specifying all paths on the command line:

```[sysync]$ ./sysync/sysync.py --hostgroups=example_config/test_database/host_groups/ --packages=example_config/test_database/packages/ --files=example_config/test_database/files/ --buildas=database```

This will output:

```
----NOT COMMITTED COMMAND LIST----
/bin/cp example_config/test_database/files/common/etc/resolv.conf /etc/resolv.conf
/usr/sbin/groupadd -g 2001 ops
/usr/sbin/groupadd -g 2002 eng
/usr/sbin/useradd --create-home -c 'Geoff Howland' -g 'ops' -u 2001 -s /bin/bash -d "/home/ghowland" geoff
/usr/sbin/usermod -G "eng" geoff
/bin/mkdir ~geoff/.ssh
/bin/chown geoff:ops ~geoff/.ssh
/bin/chmod 700 ~geoff/.ssh
echo ssh-dss AAAAB3NzaC1kc3MAAACBAOVUyfBV3ovrFQz6rVFt582Zp+HzvzZvd1fWRXWIb2OLYWBndWFg4XbwzF1Xf/X0WDtSgM/kRuO0c/GRaOAn5qwGwMdiRVCBnjW/UcywQ8xfk0pfI5LyNsaCJadq1M6xbGPNlV73tV7y3nIUAmEngceXufnBIP2n086ZvOjgQKR/AAAAFQDvuj7w1QksR9BK8L5K72ZTuUIo+wAAAIArchj87mcd3P8NrGFlPBz24OHIuXaEjiI/V37NeWTEM1+eWDOFF5xwFQ+ohekEraOBm+S0GmKGSLSNpDvdyQx8fZFLAU5KutEHRfi6qcRBfGI8fep6BaZajKp3YjfuiQSxNuHVQr9J5/j/91capZO+vh8HaaiW8moiovWVe2EbCQAAAIEAkg0glZS0mBRbRRZRuIdFD9CPS4cZ5dMta8jk38BUQmNmHcJXmlhOWwp8t8T8IPMqG4uNcx8Byh3zOl2sqya1KhZ3x2bZ/ypxVyM9TBDTuvSUDqTEEzGFaVVFFelplDT8KbBs2cenVe6DwloAnEgkFrqBido2fwigOJ23Sl6GlTI= ghowland@somewhere > ~geoff/.ssh/authorized_keys
/bin/chown geoff:ops ~geoff/.ssh/authorized_keys
/bin/chmod 600 ~geoff/.ssh/authorized_keys
/usr/sbin/useradd --create-home -c 'George Washington' -g 'eng' -u 2002 wash
/bin/mkdir ~wash/.ssh
/bin/chown wash:eng ~wash/.ssh
/bin/chmod 700 ~wash/.ssh
echo ssh-dss AAAAB3NzaC1kc3MAAACBAPTG0VLaD5Wstpl4EZ8NN0R2vmeMpGkJy0Epc7X2n9NZMLbMscy3lcuYqdwJ8ch8Nf/fk2Zm+v9hyHBL/XxqquTCGPJqLhi1Pf3+N0zzHwMAaiLa89o1dsJG6mjEfym4Y6dECgifqVMSJSYfagi2HfgFB75GYYjR4uKSHMqEMH2LAAAAFQCix7HT0Fb/qvgC8B3axxiTYxUk5wAAAIApXOsD3g9L4gYVFafHZrH9JaoH+9ATtXSXxPTPEcISF2eCwSbZL57+GLrT6SpPes8TmwEKD/tsucZl7m6vwG5V86ILUzQwsjh0BP8CCwhkqBNZhLfNtjJn0/bfYESUejDgoBSK2k/EEzDIqOfILEp2wLqrHPBq93dC4vP0OXn9kAAAAIBpooBr/Q4Je2D8EqYsD/hlNzqNawhjNTNTS2+AWLftseN+nszugGZ0utRA8cDEGMR/1n2p8MjAu/KThXpJzWfe8g54NYasYc3GxdoNqrI4trYglSQTP4aKEBL0GYmb71NSiUPf0J6ahRswpo1yQx8XHt+aaWItRupgyFnYN1aUVg== wash@somewhere > ~wash/.ssh/authorized_keys
/bin/chown wash:eng ~wash/.ssh/authorized_keys
/bin/chmod 600 ~wash/.ssh/authorized_keys
/usr/bin/yum -y mysql-server
/sbin/chkconfig --level 2 mysqld on
/sbin/chkconfig --level 3 mysqld on
/sbin/chkconfig --level 4 mysqld on
/sbin/chkconfig --level 5 mysqld on
----NOT COMMITTED COMMAND LIST----
validated: {'host_group': 'database'}
```

This shows every command, which were not run because -C/--commit was not specified, to configure the current running system as the "database" machine.

Note that the "--buildas" command will only work if the current host is not specified in any Host Groups.  This is for testing only.  If the current host is specified in a Host Group, "--buildas=hostgroup" will exit with an error.

### Host Groups

A Host Group contains 5 pieces of data:

* It's name/label.
* It's domain name, that will be appended to all of the machines.
* Any data associated with the host group for templating into files.
* All hosts that are to be built with this host group.
* All packages, in sequeunce, that will be applied to each host in this host group.

A host can only be in a single host group.  If a host is put into more than 1 host group, sysync will abort with an error.  This saves more headaches and problems than any clever uses that putting a host into more than one host group can ever yield, so do not subvert it.  Use a different configuration manager if you wish to apply conflict, non-deterministic, non-idempotent changes to your hosts.

Packages will be applied in sequence to each host.

sysync is run locally, so the host name should already be configured before sysync is run.  sysync is not a system image manager, so it expects that a system already has a bootable OS, and an IP address, and a working resolver, and a unique host name.  Once a host has these things, sysync will take care of the rest.

Example Host Group:

```
name: Databases

domain: prod.somewhere.com

hosts:
  - db-1

data:
  - host_type: db
  - backup_server: ["backup-1", "backup-2", "backup-3"]

packages:
  - common
  - users
  - groups
  - mysql
```

This is a "Database" host group, for machines of the domain "prod.somewhere.com".  If you have different domain names, make different Host Groups, as every host can only have a single Fully Qualified Domain Name, and sysync uses this as a key to determine what systems to configure.  This can be changed for testing purposes, of course.

There is 1 host in this Host Group: "db-1.prod.somewhere.com".

There is 2 pieces of templating data for this Host Group.  The first is "host-type: db", so if a "files" Handler item has "template: true" in it's configuration, then it will replace "%(host_type)s" with "db" throughout that file.

The second template data is "backup_server", and it is equal to a list.  This means that the values in the list will be selected by means of the number of items (3), and the position of the host in the host list (0).  The algorithm would then be:  0 % 3.  Zero modulus three equals zero (0), so the first item in the list is choosen: "backup-1" templates "%(backup_server)s" in files that have "template: true".

Finally, there is a list of "packages".  These will be applied in sequence, creating a [Final Configuration Specification](#the-final-configuration-specification), which can be applied to manage this host's configuration in an idempotent and deterministic manner.

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

The above Package file would first install "bind", then installed "files/etc/resolve.conf" in the "config/production" current working directory to /etc/resolv.conf, and finally it will install the "mysql-server" yum package.

This allows for absolute sequencing of how things will be installed in this package.

#### Note on Ordering of Packages in a Host Group

The order of Packages in a Host Group is very important, because this determined when a Handler item is first encountered, and when it is updated.

It is recommended that you start with more general configuration (ex: a "common" package), and then become more specific over time (ex: an "app" server package, or "mysql" package).

If you require updating a single file twice, for example starting with a common "/etc/resolv.conf" and then later updating to a specific "/etc/resolv.conf", to perhaps switch between general datacenter DNS resolution and specific app-server DNS resolution, you can create a general Package "common" and a final run Package such as "common_last_app" that is the last Package listed.

In this way you can perform general actions at the beginning of the configuration, and then override them with a very specific change later.  See the section below [Strict Ordering](#strict-ordering) for details.

### The Final Configuration Specification

A host can only be in a single host-group.  A host-group contains a set list of packages, in sequence.  Each package contains a sequence of configuration handlers, and handler items to be applied to the Final Configuration Specification.

The Final Configuration Specification is a roll up of all the sequences of packages, handlers and items.  Later packages or package handler items can change the properties of earlier configuration properties.

It is this rolling up of all sequential changes to the specification that gives sysync the propery of idempotency.  It compares the state of the host to the ideal state of the configuration, and only makes the changes necessary to correct the inconsistencies, without doing extraneous work such as putting a file there and then removing it later, even if the Handler items that describe the configuration appear in that order.

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

The Final Configuration Specification data will look like this:

```
- files:
  - path: /etc/resolv.conf
    source path: files/etc/resolv.conf
    remove: true
```

This will remove the file.  "source path" is ignored, because removal takes precidence.

##### Inspecting a Host Group's Final Configuration Specification

In order to inspect a Host Group's Final Configuration Specification, use the "inspect" command.  By default the command used with sysync is "install".  You can type it after the command line options, or it is assumed by default.

To run the inspect command from this Github clone, run:

```[sysync]$ ./sysync/sysync.py --hostgroups=example_config/test_database/host_groups/ --packages=example_config/test_database/packages/ --files=example_config/test_database/files/ inspect database```

This will inspect the "database" Host Group, and will print:

```
{'__key': '/etc/resolv.conf',
 'directory mode': 755,
 'group': 'root',
 'if not match': None,
 'ignore directories': ['.svn', '.git'],
 'ignore files': ['.gitignore'],
 'mode': 644,
 'ordered': False,
 'path': '/etc/resolv.conf',
 'remove': False,
 'set base directory permissions': False,
 'source path': 'example_config/test_database/files//common/etc/resolv.conf',
 'symlink path': None,
 'template': False,
 'user': 'root'}

{'__key': 'ops', 'gid': 2001, 'name': 'ops', 'remove': False}

{'__key': 'eng', 'gid': 2002, 'name': 'eng', 'remove': False}

{'__key': 'geoff',
 'crypt_password': None,
 'fullname': 'Geoff Howland',
 'groups': ['ops', 'eng'],
 'home': '/home/ghowland',
 'name': 'geoff',
 'remove': False,
 'shell': '/bin/bash',
 'ssh key': 'ssh-dss AAAAB3NzaC1kc3MAAACBAOVUyfBV3ovrFQz6rVFt582Zp+HzvzZvd1fWRXWIb2OLYWBndWFg4XbwzF1Xf/X0WDtSgM/kRuO0c/GRaOAn5qwGwMdiRVCBnjW/UcywQ8xfk0pfI5LyNsaCJadq1M6xbGPNlV73tV7y3nIUAmEngceXufnBIP2n086ZvOjgQKR/AAAAFQDvuj7w1QksR9BK8L5K72ZTuUIo+wAAAIArchj87mcd3P8NrGFlPBz24OHIuXaEjiI/V37NeWTEM1+eWDOFF5xwFQ+ohekEraOBm+S0GmKGSLSNpDvdyQx8fZFLAU5KutEHRfi6qcRBfGI8fep6BaZajKp3YjfuiQSxNuHVQr9J5/j/91capZO+vh8HaaiW8moiovWVe2EbCQAAAIEAkg0glZS0mBRbRRZRuIdFD9CPS4cZ5dMta8jk38BUQmNmHcJXmlhOWwp8t8T8IPMqG4uNcx8Byh3zOl2sqya1KhZ3x2bZ/ypxVyM9TBDTuvSUDqTEEzGFaVVFFelplDT8KbBs2cenVe6DwloAnEgkFrqBido2fwigOJ23Sl6GlTI= ghowland@somewhere',
 'uid': 2001}

{'__key': 'wash',
 'crypt_password': None,
 'fullname': 'George Washington',
 'groups': ['eng'],
 'home': None,
 'name': 'wash',
 'remove': False,
 'shell': None,
 'ssh key': 'ssh-dss AAAAB3NzaC1kc3MAAACBAPTG0VLaD5Wstpl4EZ8NN0R2vmeMpGkJy0Epc7X2n9NZMLbMscy3lcuYqdwJ8ch8Nf/fk2Zm+v9hyHBL/XxqquTCGPJqLhi1Pf3+N0zzHwMAaiLa89o1dsJG6mjEfym4Y6dECgifqVMSJSYfagi2HfgFB75GYYjR4uKSHMqEMH2LAAAAFQCix7HT0Fb/qvgC8B3axxiTYxUk5wAAAIApXOsD3g9L4gYVFafHZrH9JaoH+9ATtXSXxPTPEcISF2eCwSbZL57+GLrT6SpPes8TmwEKD/tsucZl7m6vwG5V86ILUzQwsjh0BP8CCwhkqBNZhLfNtjJn0/bfYESUejDgoBSK2k/EEzDIqOfILEp2wLqrHPBq93dC4vP0OXn9kAAAAIBpooBr/Q4Je2D8EqYsD/hlNzqNawhjNTNTS2+AWLftseN+nszugGZ0utRA8cDEGMR/1n2p8MjAu/KThXpJzWfe8g54NYasYc3GxdoNqrI4trYglSQTP4aKEBL0GYmb71NSiUPf0J6ahRswpo1yQx8XHt+aaWItRupgyFnYN1aUVg== wash@somewhere',
 'uid': 2002}

{'__key': 'mysql-server',
 'name': 'mysql-server',
 'remove': False,
 'version': None}

{'__key': 'mysqld',
 'levels': 2345,
 'name': 'mysqld',
 'remove': False,
 'run': True}
```

This shows all the Handler items in the sequence they will be processed during the configuration "install" with -C/--commit options.

This is all the parameters available, found in the "./sysync/handlers/defaults/" directory, for the given Configuration Handler, with any updated values found in the packages.

Note the "__key" parameter, which will map to "path" in a files Configuration, or "name" in a yum Configuration.  This is the unique identifier that allows sysync to act idempotently after processing all section items from all packages.  "__key" will only be seen more than once using the files "ordered" parameter, otherwise there will only be 1 instance of a given Configuration Handler "__key" in the inspect output.

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

ignore directories: ['.svn', '.git']
ignore files: ['.gitignore']

set base directory permissions: false

# If true, this file will not collapse into the normal order of import, so that they can happen at a later time than first encountered
ordered: false

# If this file is not a match for a given path.  This is the only exclusionary directive and is the compliment to "ordered", in that something done initially should not be re-done when the alter ordered function is run
if not match: null
```

###### "source path" and "symlink path"

"source path" and "symlink path" parameters are mutually exclusive, you will either use the "source path" to set a file to copy, or you will use a "symlink path" to create a symlink at "path" to "source path"

###### Templating

If the "template" parameter is true, then the file from "source path" is considered a template file, following Python dictionary formatting "%(key)s".

Template data comes from the Host Group "data" dictionary section, which is either a string or a list of strings.  If it is a list of strings, the string that is chosen is based on the index of the current host in the Host Group's host list, modulus (remainder of division) of the number of strings in the template list.

*Only Python string formatting is current supported: "%()s".  Other formats for floating point values, etc will be forthcoming.*

###### Strict Ordering

By default sysync will place an item of work in the sequence it first encountered the key of the Handler item.

If a Handler item key (files: path, yum: name) is found in the first package, and then updated in a second package, then it will be performed at the position of the first package.  The second package merely updates the data of the Handler item's paramaters.

If you need something to happen both at the first time it is encounter (example: early in the configuration, such as a "common" package), and you need something to happen later in the process as well, so that it actually performs two tasks on the same Handler item key (files: path, yum: name), then you need to use the "ordered: true" parameter.

When "ordered" is set to true, sysync will consider both operations to be separate.

The "if not match: true" parameter can be used with "ordered" to skip toggling between doing the first item of work, and the later "ordered" item of work.  This keeps sysync idempotent, even though it is told to do two different things with the same Handler item key (files: path).

###### "set base directory permissions"

"set base directory permissions" defaults to false, so that you can easily point files to be populate into a directory (like "/etc/") without changing that directory's mode (directory permissions).

If you want to set the base directories permissions as well, then set "set base directory permissions: true", and the "directory mode" parameter will be applied to the base directory.

If it is set to false, and the "path" value is a directory and not a file, then only the sub-directories which are managed under the files will have the "directory mode" applied to them.

#### yum

The Handler Key for "yum" is the "name" key.  This key must exist, and all changes associated with this key will overwrite the defaults as each Package Configuration Handler Section Item is processed.

Default values:

```
name: null
version: null
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

For use with chkconfig systems, such as RHEL, CentOS and Fedora.

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
crypt_password: null
remove: false
```

If no "uid" is specified, the useradd tool will choose the next available one, on each host.  It is recommended to set these yourself, but not required.

"shell" and "home" will also be defaulted by useradd.

"groups" is a list of strings, which are group names.  These should already exist on the system, so put "groups" Handler items before the "users" Handler items.

As a security point, if you use the "crypt_password" value, while the useradd process is running the crypted password will be visible in the process list.

#### groups

The Handler Key for "groups" is the "name" key.  This key must exist, and all changes associated with this key will overwrite the defaults as each Package Configuration Handler Section Item is processed.

Default values:

```
name: null
gid: null
remove: false
```

If no "gid" is specified, the groupadd tool will choose the next available one, on each host.  It is recommended to set these yourself, but not required.


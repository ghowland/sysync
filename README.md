## sysync

sysync is a system configuration manager, like Puppet/Chef/Ansible/Salt, but different.

sysync is:

* Data defined.  There is no scripting or script-like data definition language.  It uses YAML (preferred for human readability) or JSON to define the configuration.  This also makes it ideal for generating or creating custom interfaces to manage the configuration data.
* Idempotent.  sysync will always perform the same commands, given a particular host and host-state, and they will always be performed in the same order.
* Deterministic.  sysync creates an ordered list of commands that must be run to complete the configuration.  It will always return the exact commands that will be run in a non-commit mode.  This gives the best feedback in terms of what work it will perform.  No guessing required.
* Planned.  A given host can only be in a single host-group.  A host-group only supplies a specific set of packages.  Those packages are always evaluated in order.  Each package contains data directives for configuration, and are evaluated in sequence.  This reduces conflicts of whether a host may or may not get a package, or what order the package might be deployed in.  It is always done the same way, and can only happen in one way.  This makes changes to sysync less worrisome, because you get what you meant, not a number of unintended side-effects.
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


To run from a deployment directory:

> ../../sysync/sysync.py install



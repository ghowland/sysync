#!/usr/bin/env python

"""
sysync

System Synchronizer - Global system configuration enforcement

Requries Python 2.4 to 2.x
"""


__author__ = 'Geoff Howland <geoff@gmail.com>'


import sys
import os
import getopt

# sysync utility module
import utility
from utility.error import Error
from utility.format import FormatAndOuput
import handlers
import utility.log

# Possible commands that can be processed
COMMANDS = ['install', 'package']

# Output format types
OUTPUT_FORMATS = ['pprint', 'json', 'yaml']

# Default Configuration Paths
DEFAULT_HOST_GROUP_PATH = '/etc/sysync/host_groups/'
DEFAULT_PACKAGE_PATH = '/etc/sysync/packages/'
DEFAULT_HANDLER_DEFAULT_PATH = '/etc/sysync/handlers/defaults/'
DEFAULT_FILES_PATH = '/etc/sysync/files/'
DEFAULT_DEPLOY_PATH = '/etc/sysync/deploy/'
DEFAULT_DEPLOY_TEMP_PATH = '/tmp/sysync_tmp/'


def ProcessCommand(command, options, args):
  """Process the command: routes to specific command functions
  
  Args:
    command: string, command to process - routing rule
    options: dict of string/string, options for the command
    args: list of strings, args for the command
  """
  #print 'Process command: %s: %s: %s' % (command, options, args)
  
  # Install the local host
  if command == 'install':
    result = utility.install.InstallSystem(options, args)
  
  # # Package for remote hosts
  # elif command == 'package':
  #   #result = utility.package.Package(options, args)
  #   raise Excception('Not yet implemented: Packing for remote hosts')
  
  else:
    #NOTE(g): Running from CLI will test for this, so this is for API usage
    raise Exception('Unknown command: %s' % command)
  
  # Return whatever the result of the command was, so it can be used or formatted
  return result


def Usage(error=None):
  """Print usage information, any errors, and exit.  
  If errors, exit code = 1, otherwise 0.
  """
  if error:
    print '\nerror: %s' % error
    exit_code = 1
  else:
    exit_code = 0
  
  print
  print 'usage: %s [options] <command>' % os.path.basename(sys.argv[0])
  print
  print 'Commands:'
  print '  install                 Install the sysync deployment on this local host'
  #print '  package                 Package the sysync configuration for deployment'
  print
  print 'Options:'
  print
  print '  -h, -?, --help          This usage information'
  print '  -C, --commit            Commit changes.  No changes will be made, unless set.'
  print '  -b, --bootstrap         Boot Strap this host (assume no local configuration)'
  print
  print '      --hostgroups[=path] Path to host groups (directory)'
  print '      --packages[=path]   Path to package files (directory)'
  print '      --files[=path]      Path to installation files (directory)'
  print
  print '      --buildas[=group]   Manually specify Host Group, cannot be in one already'
  print
  print '      --deploy[=path]     Path to deployment files (directory)'
  print '      --handlers[=path]   Path to handler default yaml data (directory)'
  print
  print '  -v, --verbose           Verbose output'
  print '  -o, --output            Output file'
  print '  -f, --format            Output format: pprint, json, yaml'
  print
  
  sys.exit(exit_code)


def Main(args=None):
  if not args:
    args = []
  
  long_options = ['help', 'output=', 'format=', 'verbose', 'hostgroups=', 
      'deploy=', 'packages=', 'bootstrap', 'commit', 'handlers=',
      'buildas=', 'files=']
  
  try:
    (options, args) = getopt.getopt(args, '?hvo:f:bC', long_options)
  except getopt.GetoptError, e:
    Usage(e)
  
  # Dictionary of command options, with defaults
  command_options = {}
  command_options['commit'] = False
  command_options['bootstrap'] = False
  command_options['hostgroup_path'] = DEFAULT_HOST_GROUP_PATH
  command_options['package_path'] = DEFAULT_PACKAGE_PATH
  command_options['files_path'] = DEFAULT_FILES_PATH
  command_options['deploy_path'] = DEFAULT_DEPLOY_PATH
  command_options['deploy_temp_path'] = DEFAULT_DEPLOY_TEMP_PATH
  command_options['handler_data_path'] = DEFAULT_HANDLER_DEFAULT_PATH
  command_options['verbose'] = False
  command_options['build_as'] = None
  command_options['format'] = 'pprint'
  
  
  # Process out CLI options
  for (option, value) in options:
    # Help
    if option in ('-h', '-?', '--help'):
      Usage()
    
    # Verbose output information
    elif option in ('-v', '--verbose'):
      command_options['verbose'] = True
    
    # Commit changes for Install or Package
    #NOTE(g): If not set (False), no installation will be done, no packages
    #   will be created.  This will be a dry-run to test what would be 
    #   performed if commit=True
    elif option in ('-C', '--commit'):
      command_options['commit'] = True
    
    # Bootstrap this host?  Install "bootstrap packages" before "packages"
    elif option in ('-b', '--bootstrap'):
      command_options['bootstrap'] = True
    
    # Host Groups Path
    elif option in ('--hostgroups'):
      if os.path.isdir(value):
        command_options['hostgroup_path'] = value
      else:
        Error('Host Groups path specified is not a directory: %s' % value)
    
    # Deployment Path
    elif option in ('--deploy'):
      if os.path.isdir(value):
        command_options['deploy_path'] = value
      else:
        Error('Deployment path specified is not a directory: %s' % value)
    
    # Package Path
    elif option in ('--packages'):
      if os.path.isdir(value):
        command_options['package_path'] = value
      else:
        Error('Package path specified is not a directory: %s' % value)
    
    # Handlers Path
    elif option in ('--handlers'):
      if os.path.isdir(value):
        command_options['handler_data_path'] = value
      else:
        Error('Handler path specified is not a directory: %s' % value)
    
    # Files Path
    elif option in ('--files'):
      if os.path.isdir(value):
        command_options['files_path'] = value
      else:
        Error('Files path specified is not a directory: %s' % value)
    
    # Build As (Host Group)
    elif option in ('--buildas'):
      command_options['build_as'] = value
    
    # Output file
    elif option in ('-o', '--output'):
      command_options['output'] = value
    
    # Output format
    elif option in ('-f', '--format'):
      if value not in OUTPUT_FORMATS:
        Usage('Output format unknown: "%s".  Use good formats: %s' % (value, ', '.join(OUTPUT_FORMATS)))
      else:
        command_options['format'] = value
    
    # Invalid option
    else:
      Usage('Unknown option: %s' % option)
  
  
  # Store the command options for our logging
  utility.log.RUN_OPTIONS = command_options
  
  
  # Ensure we at least have a command, it's required
  if len(args) < 1:
    Usage('No command sepcified')
  
  # Get the command
  command = args[0]
  
  # If this is an unknown command, say so
  if command not in COMMANDS:
    Usage('Command "%s" unknown.  Commands: %s' % (command, ', '.join(COMMANDS)))
  
  # If there are any command args, get them
  command_args = args[1:]
  
  # Process the command
  if 1:
  #try:
    # Process the command and retrieve a result
    result = ProcessCommand(command, command_options, command_args)
    
    # Format and output the result (pprint/json/yaml to stdout/file)
    FormatAndOuput(result, command_options)
  
  #NOTE(g): Catch all exceptions, and return in properly formatted output
  #TODO(g): Implement stack trace in Exception handling so we dont lose where this
  #   exception came from, and can then wrap all runs and still get useful
  #   debugging information
  #except Exception, e:
  else:
    Error({'exception':str(e)}, command_options)


if __name__ == '__main__':
  #NOTE(g): Fixing the path here.  If you're calling this as a module, you have to 
  #   fix the utility/handlers module import problem yourself.
  sys.path.append(os.path.dirname(sys.argv[0]))
  
  Main(sys.argv[1:])


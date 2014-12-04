"""
sysync: utility: install

Methods for installing packages on a host
"""

import localhost
import configuration
import section_handler
from error import Error
from log import Log
import run


def InstallSystem(options, args):
  """Install the local host from the sysync deployment configuration files."""
  installed = {}
  
  Log('Options: %s' % options)
  
  # Determine what this host is
  hostname = localhost.GetHostname(options)
  
  if hostname == None:
    Error('Host name not found.')
  
  # Determine what host groups this host is in
  host_groups = configuration.GetHostInHostGroups(hostname, options)
  
  # If this host is in more than one host groups, fail
  if len(host_groups) > 1:
    Error('Host "%s" is in more than 1 host group: %s' % (hostname, host_groups), options)
  
  elif len(host_groups) == 0:
    if options['build_as'] != None and options['build_as'] in configuration.GetHostGroups(options):
      # Specify our host group, manually
      host_group = options['build_as']
    else:
      Error('Host "%s" is not in any host group.  Use --buildas=[hostgroup] to test a configuration.' % hostname, options)
  
  else:
    # If we are not trying to manually set the Host Group
    if options['build_as'] == None:
      # Specify our host group (it's the only one)
      host_group = host_groups[0]
    
    else:
      Error('Host "%s" is already in host group "%s", cannot be manually build as "%s"' % \
          (hostname, host_groups[0], options['build_as']), options)


  Log('Installing %s with host group: %s' % (hostname, host_group))
  installed['host_group'] = host_group
  
  # Create fresh temporary directory
  Log('Clearing temporary deployment path: %s' % options['deploy_temp_path'])
  run.Run('/bin/rm -rf %s' % options['deploy_temp_path'])
  run.Run('/bin/mkdir -p %s' % options['deploy_temp_path'])
  
  # Install the packages
  InstallPackagesLocally(hostname, host_group, options)
  
  if options['commit'] == True:
    result = {'installed': installed}
  else:
    result = {'validated': installed}
  
  return result


def InstallPackagesLocally(hostname, host_group, options):
  """Install the packages locally for the specified """
  # Get the data for this install, for templating
  host_data = configuration.GetHostData(hostname, host_group, options)
  
  # Get host group data
  host_groups = configuration.GetHostGroups(options)
  host_group_data = configuration.GetHostGroups(options)[host_group]
  host_data['host_group'] = host_group_data

  
  if options['verbose']:
    host_group_keys = list(host_groups.keys())
    host_group_keys.sort()
    Log('Available Host Groups: ' % ', '.join(host_group_keys))

  
  # If bootstrap=True, then install package
  if options.get('bootstrap', False):
    packages = host_group_data.get('bootstrap packages', [])
    Log('Bootstrap: Installing packages: %s' % packages)
    for package_name in packages:
      InstallPackage(package_name, host_data, options)
  
  # Get the packages
  packages = host_group_data.get('packages', [])
  Log('Packages List: %s' % packages)
  
  # Work List gives us sequence precidence for work, and Work Data has 
  #   finalized options for each area
  #NOTE(g): work_list is a sequence of keys for work_data, key format: 
  #   "handler:::key"
  #   example: "files:::/etc/resolv.conf"
  (work_list, work_data) = CreateMasterWorkListFromPackages(packages, options)
  
  
  # Process each work item via it's specified Section Handler, in sequence
  for work_key in work_list:
    # Get the item data
    item_data = work_data[work_key]
    
    # Take the Section Handler name from the work key
    section_handler_name = work_key.split(':::')[0]
    
    # Process this work item: registering what commands will be run on Commit
    ProcessWorkItem(section_handler_name, item_data, host_data, options)


  # If we want to commit this set of changes
  if options['commit'] == True:
    # Run each of the commands our handlers specified for commit, and handle any errors
    run.Commit_Commands(options)
  
  # Else, we can show what changes we would have committed
  else:
    print '----NOT COMMITTED COMMAND LIST----'
    for cmd_data in run.RUN_COMMIT_LIST:
      print cmd_data['cmd']
    print '----NOT COMMITTED COMMAND LIST----'


def ProcessWorkItem(section_handler_name, section_item, host_data, options):
  """Process each work item individually, registering all commands that should 
  be run on commit.
  """
  #print 'Work: %s: %s' % (section_handler_name, section_item)
  
  # Get the Section Handler python module
  handler_module = section_handler.GetModule(section_handler_name, options)
  
  # Register this Section Handler Work Item for Installation
  handler_module.Install(section_item, host_data, options)


def CreateMasterWorkListFromPackages(packages, options):
  """Returns (work_list, work_data).  
    work_list (list) is a sequence of keys for work_data (dict), key format:
      'handler:::key' example: 'files:::/etc/resolv.conf'
  """
  # Initialize our master Work List and Work Data containers
  work_list = []
  work_data = {}
  
  # Process all our of packages, to roll up all configuration specified into Work List and Work Data
  for package in packages:
    Log('Processing package: %s' % package)
    
    package_data = configuration.GetPackage(package, options)
    if type(package_data) not in (list, tuple):
      Error('Package data is incorrect formatted.  Package sections must be in the form of a List for determinism. type: %s' % type(package_data))

    # Process the package sections
    for section_count in range(0, len(package_data)):
      section = package_data[section_count]
    
      # Enforce we have list of dicts
      if type(section) != dict:
        Error('Package Section data is incorrect formatted.  Package Section Data must be in the form of a Dictionary to specify the Section Handler: section number: %s  type: %s' % (section_count, type(section)))
      # Enforce each dict has a single key, to specify the Section Handler
      if len(section.keys()) != 1:
        Error('Package Section data is incorrect formatted.  Package Section Data dictionary must have only 1 key, which specifies the Section Handler: section number: %s  keys: %s' % (section_count, section.keys()))
    
      # Get the section handler
      section_handler_name = section.keys()[0]
    
      # Get the list the Section Handler will process (in order)
      section_list = section[section_handler_name]
    
      # Enforce Section List is a list
      if type(section_list) not in (list, tuple):
        Error('The Package Section list is not in a List format.  Section Handlers process their items in a list, for determinism.  section number: %s  section handler: %s  type: %s' % (section_count, section_handler_name, type(section_list)))
      
      # Install each Package Section Item, via it's Section Handler
      for section_item in section_list:
        # Enforce the Section Item is a dictionary
        if type(section) != dict:
          Error('Section Item is not a dictionary: section number: %s  section handler: %s  type: %s' % (section_count, section_handler_name, type(section)))
        
        # Get the Section Handler python module
        handler_module = section_handler.GetModule(section_handler_name, options)
        
        # Layer section_item over defaults to get this item_data
        #NOTE(g): item_data will be the final data used.  The last update always trumps any 
        #   previous section item, because that is the only way data can retain integrity,
        #   as layering with previous data could create invalid specifications.  The 
        #   last update on a given handler:::key always wins.
        item_data = {}
        handler_defaults = section_handler.GetDefaults(section_handler_name, options)
        try:
          item_data.update(handler_defaults)
        except Exception, e:
          Error('Failed to update handler defaults, improper format (should be dict): %s' % handler_defaults, options)
          
        try:
          item_data.update(section_item)
        except Exception, e:
          Error('Failed to update section items, improper format (should be dict): %s' % section_item, options)
        
        # Get all the Section Handler keys that this section item refers to
        #NOTE(g): Many files could be effected by a singles "files" handler 
        #   section_item, but each file will get the same section_item data
        #   updated.  We want to specify each unit of work individually
        #   so that we have complete precision
        section_handler_keys = handler_module.GetKeys(item_data, options)
        
        # Process all Section Handler Keys
        for section_handler_key in section_handler_keys:
          # Make a new copy of the data for this specific key
          key_data = dict(item_data)
          
          # Create the Work Key, which we use to track data order in Work List, and data in Work Data
          work_key = '%s:::%s' % (section_handler_name, section_handler_key)
          
          # Always keep this accessible in the data.  The key may be needed to figure
          #   out where the work must be done, such as in the 'files' Section Handler
          #   which has data to find the keys, but often not the key itself, and so
          #   needs this specified here.
          key_data['__key'] = section_handler_key
          
          # If this is supposed to be ordered, and not layered
          if key_data.get('ordered', False):
            order_id = len(work_list) + 1
            ordered_work_key = '%s:::%s' % (work_key, order_id)
            work_data[ordered_work_key] = key_data
            work_list.append(ordered_work_key)
            #print 'Ordered: %s' % ordered_work_key
            
          # Else, If we havent seen this work_key before, or it is specified as Ordered, put section_item data over defaults
          elif work_key not in work_list:
            # Add to sequence and data pool
            work_list.append(work_key)
            work_data[work_key] = key_data
          
          # Else, we already have this work_key, so are just updating the item data
          else:
            work_data[work_key] = key_data
  
  #DEBUG
  # print work_list
  # import pprint
  # pprint.pprint(work_data)
  
  return (work_list, work_data)


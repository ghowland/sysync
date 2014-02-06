"""
sysync: utility: error

Deal with fatal errors
"""


import sys

import format


def Error(text, options, exit_code=1):
  """Fail with an error.  Options are required to deliver proper output."""
  output = {'error': text, 'exit_code':exit_code}
  
  # Format errors and output them, in the specified fashion
  format.FormatAndOuput(output, options)
  
  #TODO(g): Clean-up work we have done so far, so this system is not left in
  #   an unusable state
  pass#...
  
  # Exit
  sys.exit(exit_code)


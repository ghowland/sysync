"""
sysync: utility: localhost

Methods for inspecting and working on the local host.
"""


#import socket
from run import Run

def GetHostname():
  """Returns a string, the fully qualified domain name (FQDN) of this local host."""
  #return socket.getfqdn()
  
  (status, output) = Run('/bin/hostname -f')
  return output



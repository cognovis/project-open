#      Initializes datastrctures for the installer.

#      @creation-date 02 October 2000
#      @author Bryan Quinn
#      @cvs-id $Id: installer-init.tcl,v 1.3 2008/10/10 11:30:35 gustafn Exp $


# Create a mutex for the installer
nsv_set acs_installer mutex [ns_mutex create oacs:installer]

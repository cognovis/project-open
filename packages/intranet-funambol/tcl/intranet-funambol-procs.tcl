# /packages/intranet-funambol/tcl/intranet-funambol-procs.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_funambol_sync { } {
    Initiates a new synchronization.
    The PL/SQL code does everything.
} {
    # Make sure that only one thread is indexing at a time
    if {[nsv_incr intranet_funambol sync_p] > 1} {
	nsv_incr intranet_funambol sync_p -1
	ns_log Notice "intranet_funambol_sync: Aborting. There is another process running"
	return
    }

    catch {
	# Perform the sync.
	db_string funambol_sync "select fnbl_sync()" -default 0
    } errmsg	
	
    nsv_incr intranet_funambol sync_p -1
}


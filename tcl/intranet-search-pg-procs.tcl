# /packages/intranet-forum/tcl/intranet-forum.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Support for searching P/O Objects
	
    @author frank.bergmann@project-open.com
}



    set url "${url_stub}projects/view?project_id=$object_id"
    return $url
}


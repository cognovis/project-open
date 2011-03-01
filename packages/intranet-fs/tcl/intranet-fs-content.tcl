#
#  Copyright (C) 2001, 2002 MIT
#
#  This file is part of dotLRN.
#
#  dotLRN is free software; you can redistribute it and/or modify it under the
#  terms of the GNU General Public License as published by the Free Software
#  Foundation; either version 2 of the License, or (at your option) any later
#  version.
#
#  dotLRN is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
#  details.
#

ad_library {

    A portlet to show the _contents_ of a fs folder in a list. 
    Used for the "handouts", "assignments", etc. portlets 

    @author Arjun Sanyal (arjun@openforce.net)
    @version $Id: fs-contents-portlet-procs.tcl,v 1.3 2002/08/09 18:39:32 yon Exp $

}

namespace eval fs_contents_portlet {

    ad_proc -private my_package_key {
    } {
        return "fs-contents-portlet"
    }

    ad_proc -private get_my_name {
    } {
        return fs_contents_portlet
    }

    ad_proc -public get_pretty_name {
        We want the pretty_name to be passed in from the applet. 
    } {
        error
    }

    ad_proc -public link {
    } {
        return ""
    }

    ad_proc -public show {
         cf
    } {
        Note: we use the fs_portlet's pk here
    } {
        portal::show_proc_helper \
            -package_key [fs_portlet::my_package_key] \
            -config_list $cf \
            -template_src fs-contents-portlet
    }

}

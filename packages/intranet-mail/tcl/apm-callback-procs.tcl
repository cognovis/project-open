# packages/intranet-mail/tcl/intranet-mail-callback-procs.tcl

## Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
# 

ad_library {
    
    Callback procs for install and update
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-04-21
    @cvs-id $Id$
}

namespace eval intranet-mail {}

ad_proc -private intranet-mail::package_install {} {} {
    # Create the imap folder for each project
    db_foreach project "select project_id,project_nr,project_name from im_projects where project_type_id not in ('[im_project_type_task]', '[im_project_type_ticket]')" {
	intranet-mail::project_imap_folder_create -project_id $project_id
	ns_log Notice "Created IMAP Folder for $project_nr: $project_name"
    }
}

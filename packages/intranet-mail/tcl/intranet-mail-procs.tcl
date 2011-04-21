# packages/intranet-mail/tcl/intranet-mail-procs.tcl

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
    
    Procedures for intranet mail
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-04-21
    @cvs-id $Id$
}

namespace eval intranet-mail {}

ad_proc -public intranet-mail::extract_project_nrs { 
    {-subject:required}
} {
    Extract all project_nrs (2007_xxxx) from the subject of an E-Mail
    
    Returns a list of project_ids (object_ids), if any are found
} {
	set line [string tolower $subject]
	regsub -all {\<} $line " " line
	regsub -all {\>} $line " " line
	regsub -all {\"} $line " " line

	set tokens [split $line " "]
	set project_nrs [list]
    
	foreach token $tokens {
	    # Tokens must be built from aphanum plus "_" or "-".
	    if {![regexp {^[a-z0-9_\-]+$} $token match ]} { continue }
        
	    # Discard tokens purely from alphabetical
	    if {[regexp {^[a-z]+$} $token match ]} { continue }

	    lappend project_nrs $token
	}

    set ids [list]
	set condition "('[join [string tolower $project_nrs] "', '"]')"
    
	set sql "
		select	project_id
		from	im_projects
		where	lower(project_nr) in $condition
	"
    return [db_list emails_to_ids $sql]
    
}

ad_proc -public intranet-mail::extract_object_ids {
    {-subject:required}
} {
    Extract all possible object_ids
    
    An Object_id can either be given by "#object_id" or with a project_nr
} {
    
    set object_ids [intranet-mail::extract_project_nrs -subject $subject]

	set line [string tolower $subject]
	regsub -all {\<} $line " " line
	regsub -all {\>} $line " " line
	regsub -all {\"} $line " " line

	set tokens [split $line " "]
    
    foreach token $tokens {
        # Figure our if this is a valid object_id
        set number [string trimleft $token "#"]

	    if {![regexp {^[0-9]+$} $number match ]} { continue }        
        
        # Check if this is a valid object_id
        if {[db_string object_id_p "select 1 from acs_objects where object_id = :number and object_type in ([template::util::tcl_to_sql_list [intranet-mail::valid_object_types]])" -default 0]} {
            lappend object_ids $number
        }
        
    }
    return $object_ids
}

ad_proc -public intranet-mail::valid_object_types {
} {
    return a list of valid object_types
} {
    return [list im_project im_timesheet_task im_ticket]
}


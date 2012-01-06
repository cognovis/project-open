# packages/intranet-collmex/tcl/intranet-collmex-callback-procs.tcl

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
    
    Procedures for the callbacks where we hook into
    
    @author <yourname> (<your email>)
    @creation-date 2012-01-06
    @cvs-id $Id$
}


ad_proc -public -callback im_company_after_update -impl intranet-collmex_update_company {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
} {
    Update or create the company in Collmex
} {
    # Find out if this is a customer
    if {[lsearch [im_category_parents $type_id] 57]>=0 || $type_id eq 57} {
	ns_log Notice "Updating Collmex: [intranet_collmex::update_company -company_id $object_id -customer]"
    } else {
	ns_log Notice "Updating Collmex: [intranet_collmex::update_company -company_id $object_id]"
    }
}

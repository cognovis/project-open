# packages/intranet-cust-kolibri/tcl/intranet-cust-kolibri-procs.tcl

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
    
    Kolibri Custom Procs
    
    @author  (kolibri@ubuntu.localdomain)
    @creation-date 2011-10-07
    @cvs-id $Id$
}

ad_proc -public -callback im_invoice_before_update -impl kolibri_set_vars {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
} {
    Set the invoice variables needed by Kolibri
} {

    # ------------------------------------------------------------------
    # We need the quote number, the quote date and the delivery date
    # ------------------------------------------------------------------

    # Upvar two levels as there is the callback level in between
    upvar 2 quote_no quote_no
    upvar 2 quote_date quote_date
    upvar 2 delivery2_date delivery_date
    upvar 2 company_project_nr company_project_nr

    set project_id [db_string project_id "select project_id from im_costs where cost_id = :object_id" -default 0]
    if {$project_id} {
	db_0or1row quote_information "select company_project_nr,cost_nr, effective_date, end_date from im_costs c, im_projects p where p.project_id = :project_id and p.project_id = c.project_id and cost_type_id = 3702 order by effective_date desc limit 1"
	set quote_no $cost_nr
	set quote_date [lc_time_fmt $effective_date %q]
	set delivery_date [lc_time_fmt $end_date "%q"]
    }
} 
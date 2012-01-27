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

ad_proc -public -callback im_company_after_create -impl intranet-collmex_create_company {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
} {
    Create the company in Collmex
} {
    # Find out if this is a customer
    if {[lsearch [im_category_parents $type_id] 57]>=0 || $type_id eq 57} {
	ns_log Notice "Creating in Collmex: [intranet_collmex::update_company -company_id $object_id -customer]"
    } else {
	ns_log Notice "Creating in Collmex: [intranet_collmex::update_company -company_id $object_id]"
    }
}

ad_proc -public -callback im_invoice_after_update -impl intranet-collmex_invoice_handling {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
} {
    This is the complex handle all types of invoice changes function for collmex
} {

    if {[lsearch [im_category_children -super_category_id 3700] $type_id] >-1 || $type_id eq 3700} {
	# Customer Invoice
	ns_log Notice "Creating invoice in Collmex:: [intranet_collmex::update_customer_invoice -invoice_id $object_id]"
	return
    } 
    
    if {[lsearch [im_category_children -super_category_id 3704] $type_id] >-1 || $type_id eq 3704} {
	# Provider Bill
	ns_log Notice "Creating bill in Collmex:: [intranet_collmex::update_provider_bill -invoice_id $object_id]"
	return
    }
}

ad_proc -public -callback im_invoice_before_delete -impl intranet-collmex_invoice_handling {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
} {
    This is the complex handle all types of invoice changes function for collmex when they are deleted
} {
    
    if {[lsearch [im_category_children -super_category_id 3700] $type_id] >-1 || $type_id eq 3700} {
	# Customer Invoice
	ns_log Notice "Deleting invoice in Collmex:: [intranet_collmex::update_customer_invoice -invoice_id $object_id -storno]"
	return
    } 
    
    if {[lsearch [im_category_children -super_category_id 3704] $type_id] >-1 || $type_id eq 3704} {
	# Provider Bill
	ns_log Notice "Deleting bill in Collmex:: [intranet_collmex::update_provider_bill -invoice_id $object_id -storno]"
	return
    }
}

ad_page_contract {
    Set the display mode for the specific acs_object_type.
    Takes an arrray (all the radio-buttons from the page),
    compares it with the currently configured settings and
    changes those settings that are different.
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @cvs-id $Id: attribute-type-map-2.tcl,v 1.4 2009/07/02 11:53:22 po34demo Exp $
} {
    acs_object_type:notnull
    return_url:notnull
    attrib:array
}

# --------------------------------------------------------------
# Defaults & Security

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}


# --------------------------------------------------------------
# Get the information about the map and stuff it into a hash array
# for convenient matrix display.

switch $acs_object_type {
    im_project { set category_type "Intranet Project Type" }
    im_company { set category_type "Intranet Project Type" }
    im_office { set category_type "Intranet Office Type" }
    user { set category_type "Intranet Project Type" }
    im_freelance_rfq { set category_type "Intranet Freelance RFQ Type" }
    im_freelance_rfq_answer { set category_type "Intranet Freelance RFQ Answer Type" }
    default { set category_type "" }
}


set sql "
        select  m.attribute_id,
                m.object_type_id,
                m.display_mode
        from
                im_dynfield_type_attribute_map m,
                im_dynfield_attributes a,
                acs_attributes aa
        where
                m.attribute_id = a.attribute_id
                and a.acs_attribute_id = aa.attribute_id
                and aa.object_type = :acs_object_type
	order by
		aa.sort_order, aa.pretty_name
"
db_foreach attribute_table_map $sql {
    set key "$attribute_id.$object_type_id"
    set hash($key) $display_mode
}


# --------------------------------------------------------------
# Compare the information from "attrib" and "hash"

foreach key [array names attrib] {

    # New value from parameter
    set new_val $attrib($key)

    # Old value from database
    set old_val "none"
    set exists_p 0
    if {[info exists hash($key)]} { 
	set old_val $hash($key) 
	set exists_p 1
    }

    if {$new_val != $old_val} {

	if {[regexp {^([0-9]+)\.([0-9]+)$} $key match attribute_id object_type_id]} {

	    ns_log Notice "attribute-type-map-2: attribute_id=$attribute_id, object_type_id=$object_type_id, old_val=$old_val, new_val=$new_val"
	    
	    if {$exists_p} {

		# Existed beforehand - perform an update
		if {"none" == $new_val} {
		    
		    db_dml delete_dynfield_type_attribute_map "
			delete from im_dynfield_type_attribute_map
			where
				attribute_id = :attribute_id
				and object_type_id = :object_type_id

		    "
		    
		} else {
		    db_dml update_dynfield_type_attribute_map "
			update im_dynfield_type_attribute_map
			set display_mode = :new_val
			where
				attribute_id = :attribute_id
				and object_type_id = :object_type_id
		    "
		}

	    } else {

		# Didn't exist before - insert
		db_dml insert_dynfield_type_attribute_map "
			insert into im_dynfield_type_attribute_map (
				attribute_id, object_type_id, display_mode
			) values (
				:attribute_id, :object_type_id, :new_val
			)
		"
	    }

	}
    }
}


# --------------------------------------------------------------

# Remove all permission related entries in the system cache
im_permission_flush

ad_returnredirect $return_url




# packages/contacts/www/admin/attribute-list.tcl
ad_page_contract {

    Display a list of the available attributes to map to an specific
    search_id and also the default attributes set in the paramaters
    for each specific search_type.
    
    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
    @creation-date  2005-11-11
} {
    orderby:optional
    search_id:notnull
    page:optional
}

set search_for [db_string get_search_for { } -default ""]
set search_for_clause ""

# Get the var list of the search if type equals group
# so we can retrieve the default attributes of the group
# also.
set var_list [db_string get_var_list { } -default ""]

# We get the default attributes of persons, organizations or both and of the group
# if there is a condition for the gorup in the search (when var_list not null)
switch $search_for {
    person {
	if { ![empty_string_p $var_list] } {
	    # Default attributes for the group and persons
	    set group_id [lindex [split $var_list " "] 1]
	    set search_for_clause "and (l.list_name like '%__-2' or l.list_name like '%__$group_id') "
	} else {
	    # Default attributes for person only
	    set search_for_clause "and l.list_name like '%__-2' "
	}
	append search_for_clause "and l.object_type = 'person'"
	set default_extend_attributes [parameter::get -parameter "DefaultPersonAttributeExtension"]

    }
    organization {
	if { ![empty_string_p $var_list] } {
	    # Default attributes for the group and organizations
	    set group_id [lindex [split $var_list " "] 1]
	    set search_for_clause "and (l.list_name like '%__-2' or l.list_name like '%__$group_id') "
	} else {
	    # Default attributes for organization
	    set search_for_clause "and l.list_name like '%__-2' "
	}
	append search_for_clause "and l.object_type = 'organization'"
	set default_extend_attributes [parameter::get -parameter "DefaultOrganizationAttributeExtension"]

    }
    party {
	if { ![empty_string_p $var_list] } {
	    # Default attributes for the group, persons and organizations
	    set group_id [lindex [split $var_list " "] 1]
	    set search_for_clause "and (l.list_name like '%__-2' or l.list_name like '%__$group_id') "
	}
	set default_extend_attributes [parameter::get -parameter "DefaultPersonOrganAttributeExtension"]
    }
}


set default_names [list]
set attribute_values [list]
    
# We add the default attributes, first we take out all spaces
# and then split by ";"
regsub -all " " $default_extend_attributes "" default_extend_attributes
set default_extend_attributes [split $default_extend_attributes ";"]

foreach attr $default_extend_attributes {
    # Now we get the attribute_id
    set attr_id [attribute::id -object_type "person" -attribute_name "$attr"]
    if { [empty_string_p $attr_id] } {
	set attr_id [attribute::id -object_type "organization" -attribute_name "$attr"]
    }

    # We need to check if the attribute is not already present
    # in the list, otherwise we could have duplicated.
    if { ![empty_string_p $attr_id] } {
	lappend attribute_values $attr_id
	lappend default_names [attribute::pretty_name -attribute_id $attribute]
    }
}

set default_names [join $default_names ", "]
set extend_query ""
if { ![string equal [llength $attribute_values] 0] } {
    set extend_query "and a.attribute_id not in ([join $attribute_values ","])"
}

set bulk_actions [list "[_ intranet-contacts.Set_default]" set-default "[_ intranet-contacts.Set_default]" \
		      "[_ intranet-contacts.Remove_default]" remove-default "[_ intranet-contacts.Remove_default]"]

template::list::create \
    -name ams_options \
    -multirow ams_options \
    -key attribute_id \
    -page_size 15 \
    -page_flush_p 0 \
    -page_query_name get_ams_options_pagination \
    -bulk_action_method post \
    -bulk_actions $bulk_actions \
    -bulk_action_export_vars { search_id } \
    -elements {
	pretty_name {
	    label "[_ intranet-contacts.Attribute_Name]:"
	}
	default {
	    label ""
	}
    } -filters {
	search_id {}
    } -orderby {
	default_value pretty_name
	pretty_name {
	    label "[_ intranet-contacts.Attribute_Name]:"
	    orderby_asc "a.attribute_name asc"
	    orderby_desc "a.attribute_name desc"
	}
    }

db_multirow -extend { default } ams_options get_ams_options " " {
    set default ""
    set default_p [db_string get_default_p { } -default "0"]
    if { $default_p } {
	set default "[_ intranet-contacts.Default]"
    }
}


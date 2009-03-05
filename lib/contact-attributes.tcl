# packages/contacts/lib/contact-attributes.tcl
#
# Include for the contact attributes
#
# @author Malte Sussdorff (sussdorff@sussdorff.de)
# @creation-date 2005-06-21
# @arch-tag: 1df33468-0ff5-44e2-874a-5eec78747b8c
# @cvs-id $Id$

foreach required_param {party_id} {
    if {![info exists $required_param]} {
	return -code error "$required_param is a required parameter."
    }
}
foreach optional_param {package_id hidden_attributes} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

if {[empty_string_p $package_id]} {
    set package_id [contact::package_id -party_id $party_id]
}

set party [::im::dynfield::Class get_instance_from_db -id $party_id]
multirow create attributes section attribute value

set list_ids [$party list_ids]
foreach dynfield_id [::im::dynfield::Attribute dynfield_attributes -list_ids $list_ids -privilege "read"] {

    # Initialize the Attribute
    set element [im::dynfield::Element get_instance_from_db -id [lindex $dynfield_id 0] -list_id [lindex $dynfield_id 1]]
    set value [$party value [$element attribute_name]]
    if {[$element multiple_p] && $value ne ""} {
        set value "<ul><li>[join $value "</li><li>"]</li></ul>"
    }
    if {$value ne ""} {
        multirow append attributes [$element section_heading] [$element pretty_name] $value
    }
}

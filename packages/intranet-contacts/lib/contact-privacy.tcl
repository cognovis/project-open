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

if { ![exists_and_not_null package_id] } {
    set package_id [ad_conn package_id]
}

set email_p 1
set mail_p 1
set phone_p 1
set gone_p 0
if { [parameter::get -boolean -package_id $package_id -parameter "ContactPrivacyEnabledP" -default "0"] } {
    db_0or1row select_privacy_settings " select * from contact_privacy where party_id = :party_id "
    if { [string is true $gone_p] } {
	set object_type [util_memoize [list acs_object_type $party_id]]
    }
}


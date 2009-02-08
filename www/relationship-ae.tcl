ad_page_contract {
    Add a Relationship and Manage Relationship Details

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-05-21
    @cvs-id $Id$
} {
    {object_id_one:integer,notnull}
    {object_id_two:integer,notnull}
    {party_id:integer,notnull}
    {rel_type:notnull}
    {return_url ""}
} -validate {
    contact_one_exists -requires {object_id_one} {
	if { ![contact::exists_p -party_id $object_id_one] } {
	    ad_complain "[_ intranet-contacts.lt_The_first_contact_spe]"
	}
    }
    contact_two_exists -requires {object_id_two} {
	if { ![contact::exists_p -party_id $object_id_two] } {
	    ad_complain "[_ intranet-contacts.lt_The_second_contact_sp]"
	}
    }
    party_id_valid -requires {object_id_one object_id_two party_id} {
	if { $party_id != $object_id_one && $party_id != $object_id_two } {
	    ad_complain "[_ intranet-contacts.lt_The_contact_specified_1]"
	}
    }
}

contact::require_visiblity -party_id $object_id_one
contact::require_visiblity -party_id $object_id_two

set rel_id [relation::get_id -object_id_one $object_id_one -object_id_two $object_id_two -rel_type $rel_type]

if {$rel_id eq ""} {
    set class [::im::dynfield::Class object_type_to_class $rel_type]
    set relation [$class create "::${object_id_one}__${object_id_two}"]
    $relation set object_type $rel_type
    $relation set rel_type $rel_type
    $relation set object_id [db_nextval acs_object_id_seq]
    set new_p 1
    unset rel_id
} else {
    set relation [::im::dynfield::Class get_instance_from_db -id $rel_id]
    set new_p 0
}

set form_class [::im::dynfield::Form object_type_to_class $rel_type]
set form_exists 0

set list_ids [$relation list_ids]

set num_form_attr [db_string attributes "select count(*) from im_dynfield_type_attribute_map where object_type_id in ([template::util::tcl_to_sql_list $list_ids])" -default 0]


if {[$relation isclass $form_class] && $num_form_attr >0} {
    # A Form exists and we need to generate it.
    set form_exists 1

    set form [::im::dynfield::Form create ::${rel_type}_form -class "$form_class" -list_ids $list_ids -name "rel_form" -data $relation -key "rel_id" -submit_link "/intranet-contacts/${party_id}/relationships" -export [list [list object_id_one $object_id_one] [list object_id_two $object_id_two] [list party_id $party_id] [list rel_type $rel_type]] ]
    $form generate 
}

if {!$form_exists && $new_p} {
    # If the relation already exists and we do not update the form
    # Then what the hell are we doing here :-)
    # Therefore we only save if it is a new relation.

    #Save the relationship and directly skip ahead
    $relation set object_id_one $object_id_one
    $relation set object_id_two $object_id_two
    $relation save_new 
    
    ad_returnredirect $return_url
}
ad_return_template

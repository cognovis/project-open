ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id: list-attributes.tcl,v 1.1 2009/01/23 14:38:30 cvs Exp $

} {
    {attribute_id:integer,multiple}
    {list_id:integer,notnull}
    {command "map"}
}

# We get the lis info
set list [::im::dynfield::List get_instance_from_db -id $list_id]

set attribute_ids $attribute_id

# If it reachs this point it means that we can map all attributes.
foreach attribute_id $attribute_ids {
    im_dynfield::attribute::$command -list_id $list_id -attribute_id $attribute_id
    ::im::dynfield::Element flush -id $attribute_id -list_id $list_id
}


ad_returnredirect "[$list url]"
ad_script_abort

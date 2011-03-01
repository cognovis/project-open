ad_page_contract {
     
    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id: list-attributes-unmap.tcl,v 1.1 2009/01/23 14:38:29 cvs Exp $

} {
    {attribute_id:integer,multiple}
    {list_id:integer,notnull}
    {command "unmap"}
}

foreach attribute_id $attribute_id {
    im_dynfield::attribute::$command -list_id $list_id -attribute_id $attribute_id
    ::im::dynfield::Element flush -id $attribute_id -list_id $list_id
}

set list [::im::dynfield::List get_instance_from_db -id $list_id]

ad_returnredirect "[$list url]"
ad_script_abort

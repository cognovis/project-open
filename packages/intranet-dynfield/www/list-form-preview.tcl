ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id: list-form-preview.tcl,v 1.1 2009/01/23 14:38:30 cvs Exp $


} {
    list_id:integer,notnull
}


set list [::im::dynfield::List get_instance_from_db -id $list_id]
set pretty_name [$list pretty_name]

set title "[_ intranet-dynfield.Form_Preview]"
set context [list [list lists Lists] [list [$list url] $pretty_name] $title]
set class [::im::dynfield::Class object_type_to_class [$list object_type]]

set element [$class create ::element_${list_id}]
set form [::im::dynfield::Form create ::im_company_form -class "$class" -list_ids $list_id -name "form_preview" -data $element -submit_link [$list url]]
$form generate

ad_return_template

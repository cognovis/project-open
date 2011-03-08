ad_page_contract {

    @author yon@openforce.net
    @creation-date 2002-08-29
    @cvs-id $Id: toggle-approved.tcl,v 1.2 2002/09/10 22:22:22 jeffd Exp $

} -query {
    {object_id:integer,notnull}
    {item_id:integer,notnull}
    {approved_p ""}
    {return_url:notnull}
}

attachments::toggle_approved -object_id $object_id -item_id $item_id -approved_p $approved_p

ad_returnredirect $return_url

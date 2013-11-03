ad_page_contract {

    Attaches something to an object

    @author Arjun Sanyal (arjun@openforce.net)
    @author Ben Adida (ben@openforce.net)
    @cvs-id $Id$

} -query {
    {object_id:notnull}
    {item_id:notnull}
    {return_url:notnull}
}

# Perms
permission::require_permission -object_id $object_id -privilege write

if {[catch {
    # Perform the attachment
    attachments::attach -object_id $object_id -attachment_id $item_id
} errmsg]} {
    # Attachment already exists, just keep going
    ns_log Notice "Attachment $item_id to Object $object_id already exists"
}

ad_returnredirect $return_url

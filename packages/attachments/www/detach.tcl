# packages/attachments/www/detach.tcl

ad_page_contract {
    
    detaches an attached item from an object
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2006-07-13
    @cvs-id $Id$
} {
    object_id:notnull
    attachment_id:notnull
    {return_url ""}
} -properties {
} -validate {
} -errors {
}

set user_id [auth::require_login]

# require write
permission::require_permission -object_id $object_id -privilege write

set object_name [acs_object_name $object_id]
set attachment_name [acs_object_name $attachment_id]

set title "[_ attachments.Detach_file_from]"
set context "[_ attachments.Detach]"

ad_form \
    -name detach \
    -export { object_id attachment_id return_url } \
    -cancel_url $return_url \
    -form {
	{inform:text(inform) {label {}} {value "[_ attachments.Are_you_sure_detach]"}}
	{attachment_name:text(inform) {label "[_ attachments.Attachment]"}}
	{object_name:text(inform) {label "[_ attachments.on_Object]"}}
    }

set attached_to_other_objects_n [db_string get_other_object_count {
    select count(*)
    from attachments
    where item_id = :attachment_id
          and object_id <> :object_id
}]

set delete_options [list [list [_ acs-kernel.common_No] 0] [list [_ acs-kernel.common_Yes] 1]]

if {$attached_to_other_objects_n} {
    ad_form \
	-extend \
	-name detach \
	-form {
	    {count_info:text(inform) {label {}} {value "[_ attachments.Only_detach]"}}
	    {detach:text(submit) {label "[_ attachments.Detach]"}}
	}
} else {
    ad_form \
	-extend \
	-name detach \
	-form {
	    {count_info:text(inform) {label {}} {value "[_ attachments.Can_delete]"}}
	    {detach_button:text(submit) {label "[_ attachments.Detach]"}}
	    {delete_button:text(submit) {label "[_ attachments.delete_from_fs]"}}
	}
}

ad_form \
    -extend \
    -name detach \
    -form {
    } -on_request {
    } -on_submit {
	attachments::unattach -object_id $object_id -attachment_id $attachment_id
	if {[exists_and_not_null delete_button] && !$attached_to_other_objects_n} {
	    fs::delete_file -item_id $attachment_id		
	}
    } -after_submit {
	ad_returnredirect $return_url
    }
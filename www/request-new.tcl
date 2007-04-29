ad_page_contract {

    Request tracking for a package instance

    @author Nima Mazloumi (mazloumi@uni-mannheim.de)
    @creation-date 2005-05-31
    @cvs-id $Id$
} {
    object_id:integer,notnull
    return_url
}

set user_id [auth::require_login]

# Check that the object can be subcribed to
mail_tracking::security::require_notify_object -object_id $object_id

set instance_name [apm_instance_name_from_id $object_id]

set page_title "[_ mail-tracking.Request_mail_tracking_for_instance_name]"

set context [list "[_ mail-tracking.Request_mail_tracking_for_instance_name]"]

ad_form -name subscribe -export {object_id return_url} -form {} -on_submit {

    # Add the subscribe
    mail_tracking::request::new -object_id $object_id -user_id $user_id

    ad_returnredirect $return_url
    ad_script_abort
}

ad_return_template

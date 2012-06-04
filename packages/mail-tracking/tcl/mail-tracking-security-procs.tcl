ad_library {

    Mail Tracking Security Library

    Manage permissions for mail-tracking.

    @creation-date 2005-05-31
    @author Nima Mazloumi <mazloumi@uni-mannheim.de>
    @cvs-id $Id$

}

namespace eval mail_tracking::security {
    
    ad_proc -public can_admin_request_p {
	{-request_id:required}
    } {
	Checks if a user can manage a given tracking request. RIGHT NOW HACKED to 1.
    } {
	# hack
	return 1
    }
    
    ad_proc -public require_admin_request {
	{-request_id:required}
    } {
	Require the ability to admin a request
    } {
    }

    ad_proc -public require_notify_object {
        {-object_id:required}
    } {
        Require the ability to notify on an object.
    } {
    }

}

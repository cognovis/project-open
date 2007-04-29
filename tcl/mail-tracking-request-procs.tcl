ad_library {

    Mail Tracking Requests

    When a user wishes to track mails from a package,
    he issues a request. This request is recorded specifically.
    These procs help to manage such requests.

    @creation-date 2005-05-31
    @author Nima Mazloumi <mazloumi@uni-mannheim.de>
    @cvs-id $Id$

}

namespace eval mail_tracking::request {

    ad_proc -public new {
        {-request_id ""}
        {-user_id:required}
        {-object_id:required}
    } {
        create a new request for a given user and package.
    } {
        set request_id [get_request_id -object_id $object_id]

        if {[empty_string_p $request_id]} {
            # Create the request
            set request_id [db_nextval acs_object_id_seq]
            db_dml insert_request {}
        }

        return $request_id
    }

    ad_proc -public get_request_id {
        {-object_id:required}
    } {
        Checks if a particular tracking request exists, and if so return the request ID.
        Note that the primary key on notification requests is the object.
    } {
        return [db_string select_request_id {} -default {}]
    }

    ad_proc -public request_exists {
        {-object_id:required}
    } {
        returns true if one request exists for this object
    } {
        return [expr { [db_string request_count {}] > 0 }]
    }

    ad_proc -public delete {
        {-request_id:required}
    } {
        delete a request for tracking by request ID.
    } {
        # do the delete
        db_exec_plsql delete_request {}
    }

    ad_proc -public delete_all {} {
        remove all requests
    } {
        # Do it
        db_exec_plsql delete_all_requests {}
    }
}
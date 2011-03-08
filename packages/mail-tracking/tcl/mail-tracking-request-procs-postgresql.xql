<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>
    <fullquery name="mail_tracking::request::new.insert_request">
        <querytext>
            	insert into acs_mail_tracking_request
	    		(request_id, object_id, user_id)
	    	values
		(:request_id, :object_id, :user_id);
        </querytext>
    </fullquery>

    <fullquery name="mail_tracking::request::get_request_id.select_request_id">
        <querytext>
            select request_id from acs_mail_tracking_request where object_id = :object_id;
        </querytext>
    </fullquery>

    <fullquery name="mail_tracking::request::delete.delete_request">
        <querytext>
            select acs_mail_tracking_request__delete(:request_id);
        </querytext>
    </fullquery>

    <fullquery name="mail_tracking::request::delete_all.delete_all_requests">
        <querytext>
            select acs_mail_tracking_request__delete_all();
        </querytext>
    </fullquery>

</queryset>

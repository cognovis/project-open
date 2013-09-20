<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="event_insert">
    <querytext>
		SELECT im_event__new(
			:event_id,
			'im_event',
			now(),
			:current_user_id,
			'[ns_conn peeraddr]',
			null,

			:event_name,
			:event_nr,
			$event_start_date_sql,
			$event_end_date_sql,
			:event_status_id,
			:event_type_id
		);
    </querytext>
</fullquery>

<fullquery name="event_update_acs_object">
    <querytext>
		update acs_objects set
			last_modified = now()
		where object_id = :event_id
    </querytext>
</fullquery>


<fullquery name="event_update">
    <querytext>
	update im_events set
		event_name		= :event_name,
		event_nr		= :event_nr,
		event_type_id		= :event_type_id,
		event_status_id		= :event_status_id,
		event_material_id	= :event_material_id,
		event_location_id	= :event_location_id,
		event_start_date	= $event_start_date_sql,
		event_end_date		= $event_end_date
	where
		event_id = :event_id;
    </querytext>
</fullquery>


</queryset>

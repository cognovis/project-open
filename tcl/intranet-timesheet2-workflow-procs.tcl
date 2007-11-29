# /packages/intranet-timesheet2-workflow/tcl/intranet-timesheet-workflow-procs.tcl
#
# Copyright (C) 1998-2007 ]project-open[
# All rights reserved

ad_library {
    Definitions for the intranet timesheet workflow
    @author frank.bergmann@project-open.com
}

# ---------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------

ad_proc -public im_timesheet_conf_obj_type_default {} { return 17100 }

ad_proc -public im_timesheet_conf_obj_status_created {} { return 17000 }
ad_proc -public im_timesheet_conf_obj_status_unconfirmed {} { return 17010 }
ad_proc -public im_timesheet_conf_obj_status_confirmed {} { return 17080 }
ad_proc -public im_timesheet_conf_obj_status_deleted {} { return 17090 }


# ---------------------------------------------------------------------
# Create TS Confirmation Object
# ---------------------------------------------------------------------

ad_proc -public im_timesheet_conf_object_new {
    -project_id
    -user_id
    -start_date
    -end_date
    {-conf_status_id 0}
    {-conf_type_id 0}
} {
    Create a new confirmation object
} {
    if {0 == $conf_status_id} { set conf_status_id [im_timesheet_conf_obj_status_created] }
    if {0 == $conf_type_id} { set conf_type_id [im_timesheet_conf_obj_type_default] }

    if {0 == $project_id} {
	set project_list [db_list projects "
		select distinct
			project_id
		from
			im_hours
		where
			user_id = :user_id and
			day >= :start_date and
			day < :end_date
	"]
    } else {
	set project_list [list $project_id]
    }

    foreach project_id $project_list {
        set conf_oid [db_string create_conf_object "
	    select im_timesheet_conf_object__new (
		null,
		'im_timesheet_conf_object',
		now(),
		[ad_get_user_id],
		'[ad_conn peeraddr]',
		null,

		:project_id,
		:user_id,
		:start_date,
		:end_date,
		:conf_type_id,
		:conf_status_id
	    );
        "]
    }
    return $conf_oid
}


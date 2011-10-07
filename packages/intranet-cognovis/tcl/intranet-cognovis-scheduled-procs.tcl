# /intranet-cognovis/tcl/intranet-cognovis-init.tcl

ad_library {
    Scheduled procs for intranet-cognovis pkg

    @author Iuri Sampaio
    @creation-date 2011-04-06
}


set remind_members_p [db_string select_parameter {
    SELECT attr_value FROM apm_parameter_values WHERE parameter_id = (
        SELECT parameter_id FROM apm_parameters WHERE package_key = 'intranet-cognovis' AND parameter_name = 'RemindMembersToLogHoursP'
	);
}]

if {$remind_members_p} {
    ad_schedule_proc -thread t -schedule_proc ns_schedule_weekly [list 1 7 0] intranet_cognovis::remind_members
}

# That would work if we were not dealing with scheduled procs!
#if {[parameter::get_from_package_key -package_key "intranet-cognovis" -parameter "RemindMembersToLogHoursP" -default 0 ]} {}

#ad_schedule_proc -thread t 10 intranet_cognovis::remind_members
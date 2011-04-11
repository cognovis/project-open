# /intranet-cognovis/tcl/intranet-cognovis-init.tcl

ad_library {
    Scheduled procs for intranet-cognovis pkg

    @author Iuri Sampaio
    @creation-date 2011-04-06
}

if {[parameter::get_from_package_key -package_key "intranet-cognovis" -parameter "RemindMembersToLogHoursP" -default 0 ]} {
     ad_schedule_proc -thread t -schedule_proc ns_schedule_weekly [list 1 7 0] intranet_cognovis::remind_members
}
#ad_schedule_proc -thread t 10 intranet_cognovis::remind_members
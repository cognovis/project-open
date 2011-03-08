if [info exists user_id] {
    set maybe_restrict_to_user "and creation_user = :user_id"
} else {
    set maybe_restrict_to_user ""
}

db_multirow -extend { lastbuild_pretty } subscrs get_subscrs {} {
    if {![empty_string_p $lastbuild_ansi]} { 
        set lastbuild_ansi [lc_time_system_to_conn $lastbuild_ansi]
        set lastbuild_pretty [lc_time_fmt $lastbuild_ansi "%x %X"]
    } else { 
        set lastbuild_pretty "never built"
    }

    if [string equal $channel_title ""] {
	set channel_title "Subscription #$subscr_id"
    }
}

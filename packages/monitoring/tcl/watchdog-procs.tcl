ad_library {

     A complete rewrite of Watchdog
    
     This package provides a page that prints all errors from
     the system log. (/admin/errors).
    
     If you set the acs parameter for monitoring package :

        WatchDogFrequency=15
      
     then watchdog will check the error log every 15 minutes
     and sent any error messages to ad_system_owner.

    @author
    @author Andrew Piskorski (atp@piskorski.com)
    @creation-date Nov 28, 1999
    @cvs-id $Id: watchdog-procs.tcl,v 1.1.1.2 2006/08/24 14:41:37 alessandrol Exp $
}


ad_proc wd_errors {{
   -external_parser_p 0
   -num_minutes ""
   -num_bytes {1024000}
}} {
   TODO:  Docs...
} {
    set proc_name {wd_errors}

    set options ""
    if ![empty_string_p $num_minutes] {
        validate_integer "Minutes" "$num_minutes"
        set options "-${num_minutes}m "
    } else {
        validate_integer "Bytes" "$num_bytes"
        set options "-${num_bytes}b "
    }

    # TODO: Rather than using external_parser_p flag, my want to do the
    # external_parser_p stuff if the WatchDogParser parameter is empty
    # string.  --atp@piskorski.com, 2002/04/08 14:25 EDT

    if { $external_parser_p } {
        set default_command "[acs_package_root_dir monitoring]/bin/aolserver-errors.pl"
        set command [ad_parameter -package_id [monitoring_pkg_id] WatchDogParser monitoring $default_command]

        if { ![file exists $command] } {
            ns_log Error "Watchdog($proc_name): Can't find WatchDogParser: $command doesn't exist" 
        } else {
            # This has been changed from the previous version's concat
            # because it did not work.  Some quick testing
            # did not reveal an elegant solution, so we're going back
            # to the old less-elegant-but-functional solution

            if { [catch { set result [exec $command $options [ns_info log]] } err_msg] } {
                global errorInfo
                ns_log Error "Watchdog($proc_name): $errorInfo"
                return ""
            } else {
                return $result
            }
            
        }

    } else {
        return [wd_aolserver_errors -num_minutes $num_minutes -num_bytes $num_bytes [ns_info log]]
    }
}


ad_proc wd_email_frequency {} "" {
    # Frequency is in minutes.  First checks value from ad_parameter,
    # if no such parameter, uses value from AOLserver nsd.tcl config
    # file, if no such parameter, uses default of 15 minutes:
    # --atp@piskorski.com, 2002/04/08 12:49 EDT
    
    return [ad_parameter -package_id [monitoring_pkg_id] WatchDogFrequency monitoring \
            [ns_config "ns/server/[ns_info server]/acs/monitoring" WatchDogFrequency 15]]
}

ad_proc wd_people_to_notify {} "" {

    set people_to_notify [ad_parameter_all_values_as_list -package_id [monitoring_pkg_id] PersontoNotify monitoring]
    
    if [empty_string_p $people_to_notify] {
        return [ad_system_owner]
    } else {
        return $people_to_notify
    }
}

ad_proc wd_mail_errors {} "" {
    set proc_name {wd_mail_errors}
    
    set num_minutes [wd_email_frequency]   
    ns_log Debug "Watchdog($proc_name): Looking for errors..."
    set errors [wd_errors -num_minutes $num_minutes]
    
    if {[string length $errors] > 50} {
        ns_log Debug "Watchdog($proc_name): Errors found."
        # Let's put the url to this server in the email message
        # to make it crystal clear which server is having problems
        set message "
([ad_url])

$errors"
        wd_email_notify_list "Errors on [ad_system_name]" $message
    }
}


ad_proc wd_email_notify_list { subject message } {
    Sends the specified subject and message in an email to all people on the notify list.
} {
    set system_owner [ad_system_owner]
    foreach person [wd_people_to_notify] {
        ns_sendmail $person $system_owner $subject $message
    }
}


ad_proc wd_aolserver_errors {{
    -num_minutes {}
    -num_bytes   {1024000}
} log_file } {
    Tcl version of packages/monitoring/bin/aolserver-errors.pl, to run
    inside of AOLserver rather than forking a Perl script.
    <p>
    Saves its run-to-run state in $lastreadfile, so AOLserver must have
    write permission to the directory where $log_file is located.
    
    @author David Walker (openacs@grax.com)
    @author Andrew Piskorski (atp@piskorski.com)
} {
    
    if { ![empty_string_p $num_minutes] } {
        validate_integer {Minutes} $num_minutes
    } elseif { [empty_string_p $num_bytes] } {
        set num_bytes 0
    } else {
        validate_integer {Bytes} $num_bytes
    }
    
    set lastreadfile "${log_file}.lastread"
    
    if {[file exists $lastreadfile]} {
        source "${lastreadfile}"
        
        # That will set the lastread (which is bytes) and lastread_time
        # (which is a string like 'Tue Apr 09 18:44:49 2002') variables.
    }
    set log_file_size [file size $log_file]
    
    if { ![info exists lastread] || $lastread > $log_file_size } {
        set lastread 0
        set lastread_time "First Run"
        
        # If the log has been rolled, presumably it will now be smaller
        # in size than it was last time.  So in that case, always read
        # from the beginning of the file.
        #
        # TODO: But, it isn't GUARANTEED that it will always be smaller.
        # Is there any other way for us to detect if the log has been
        # rolled or otherwise fooled with?  Save the first line from the
        # log into our $lastreadfile, if the first line in the current
        # log is different, then we know the log has been rolled.
        # --atp@piskorski.com, 2002/04/09 13:13 EDT
    }
    
    # TODO: num_minutes is currently being ignored.  Change that.
    # --atp@piskorski.com, 2002/04/08 18:33 EDT
    
    # If the log grew by more than num_bytes since the last run, then
    # we review only the LAST num_bytes of the log, where the "end" of
    # the log is the point that WAS the end at the time we set
    # log_file_size, above.  To always read everything, set num_bytes
    # to 0:
    
    if { $num_bytes > 0 } {
        set sizediff [expr {$log_file_size - $lastread}]
        
        if { $sizediff > $num_bytes } {
            set lastread [expr {$log_file_size - $num_bytes}]
            append output "Log file grew by [expr {round(100.0 * [expr {$sizediff / 1024.0 / 1024.0}]) / 100.0}] megabytes.\nReporting on the last $num_bytes bytes of log:\n"
        } 
    }
    
    set fh [open $log_file]
    seek $fh $lastread
    
    set in_error_p 0
    set in_following_notice_p 0
    
    append output "Errors since $lastread_time\n";
    
    # Note that in the while loop below, if we simply read till EOF we
    # will have a race condition with the other threads writing to the
    # log - bad!  A stern chase is a long chase, so if the log is
    # growing like crazy because our server is, say, looping over and
    # over on an error (yes, I've seen it happen...), by the time this
    # thread catches up, we may easily end up trying to email 50+ MB of
    # error messages.  We avoid this race condition by checking our
    # position in the file with tell:
    #
    # --atp@piskorski.com, 2002/07/26 00:46 EDT
    
    while { ![eof $fh] && ([tell $fh] <= $log_file_size) } {
        gets $fh thisline
        
        # Each line in the AOLserver error (server) log looks like this:
        # [13/Jul/2002:00:43:29][2074.5][-sched-] Notice: Running scheduled proc wd_mail_errors...
        
        # Using non-greedy like this works: 
        #   {^\[(.*?)\]\[(.*?)\]\[(.*?)\](.*)$}
        # but let's use negated character classes instead:
        
        if { [regexp -expanded -- {
            ^\[([^\]]*)\]
            \[([^\]]*)\]
            \[([^\]]*)\]
            (.*)$
        } $thisline xxx var1 var2 var3 var4] } {
            set time $var1
            set message [string trim $var4]
            
            if {[string first "Error:" $message] == 0} {
                append output "\n$time\n    $message\n";
                set in_error_p 1
                set in_following_notice_p 0
            } elseif {[string first "Notice:" $message] == 0} {
                if { $in_error_p } {
                    set in_following_notice_p 1
                    append output "    $message\n"
                } else {
                    set in_following_notice_p 0
                }
                set in_error_p 0
            } else {
                set in_error_p 0
                set in_following_notice_p 0
            }
        } else {
            # The regexp didn't match, so whatever this line is, it's NOT
            # the start of a normal AOLserver ns_log message.
            
            if { $in_error_p || $in_following_notice_p } {
                append output "$thisline\n"
            }
        }
    }
    set file_read_size [tell $fh]
    close $fh
    
    set fh [open $lastreadfile w]
    puts $fh "set lastread \"${file_read_size}\""
    puts $fh "set lastread_time \"[ns_fmttime [clock seconds]]\""
    close $fh
    
    return $output
}

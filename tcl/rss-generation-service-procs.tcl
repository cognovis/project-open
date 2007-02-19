ad_library {
    RSS feed service procs

    @author jerry@theashergroup.com (jerry@theashergroup.com)
    @author aegrumet@alum.mit.edu

    @creation-date Fri Oct 26 11:43:26 2001
    @cvs-id $Id$
}

ad_proc -private rss_gen_service {} {

    ns_log Debug "rss_gen_service: starting"

    # Bind any unbound implementations
    rss_gen_bind

    set n 0

    db_foreach timed_out_subscriptions {} {
	set lastupdate [acs_sc_call RssGenerationSubscriber lastUpdated \
		$summary_context_id $impl_name]
	if { $lastupdate > $lastbuild } {
	    # Old report is stale.  Build a new one.
	    rss_gen_report $subscr_id
	    incr n
	}
    }

    ns_log Debug "rss_gen_service: built $n reports"

}

ad_proc -private rss_gen_report subscr_id {
    Build a report, write it out, log it.
} {
    set start [clock seconds]

    db_1row subscr_info {}

    set datasource [acs_sc_call RssGenerationSubscriber datasource \
	    $summary_context_id $impl_name]

    if { [empty_string_p $datasource] } {
        ns_log Error "Empty datasource returned from $impl_name for context $summary_context_id in rss_gen_report. Probably because the implementation hasn't been bound."
        return
    }
    ns_log notice "
DB --------------------------------------------------------------------------------
DB DAVE debugging procedure rss_gen_report
DB --------------------------------------------------------------------------------
DB datasource = '${datasource}' 
DB --------------------------------------------------------------------------------"
    set args ""
    foreach {name val} $datasource {
	regsub -all {[\]\[\{\}""\\$]} $val {\\&} val
	append args "-$name \"$val\" "
	if { [lsearch [list channel_link channel_title] $name] >= 0 } {
	    set $name $val
	}
    }
    set xml [apply rss_gen $args]

    # Write report.
    set report_file [rss_gen_report_file -summary_context_id $summary_context_id -impl_name $impl_name -assert]

    set fh [open $report_file w]
    puts $fh $xml
    close $fh

    # Copy some useful display information into the
    # subscriptions table.
    set extra_sql ""
    foreach col [list channel_title channel_link] {
	if [info exists $col] {
	    append extra_sql ", $col = :$col"
	}
    }

    set last_ttb [expr [clock seconds] - $start]
    db_dml update_timestamp {}
}

ad_proc -private rss_assert_dir path {
    Steps through path creating each new directory as needed.
    Accepts full path or relative path, but you probably want
    to specify the full path.
    <p>
    Makes no attempt to catch errors.
} {
    set running_path ""
    foreach dir [split $path /] {
	append running_path ${dir}/
	if ![file exists $running_path] {
	    ns_mkdir $running_path
	}
    }
}

ad_proc -private rss_gen_bind {} {
    Creates bindings for unbound implementations for RssGenerationSubscriber.
} {
    set contract_id [db_string get_contract_id {}]

    db_foreach get_unbound_impls {} {
	ns_log Debug "rss_gen_bind: binding impl $impl_id for contract $contract_id"
	# Don't ask me why, but bind variables don't appear to work
	# in this nested db operation.  
	if [catch {
	    db_exec_plsql bind_impl {}
	} errMsg] {
	    ns_log Warning "rss_gen_bind: error binding impl $impl_id for contract $contract_id: $errMsg"
	}
    }
}

ad_proc -private rss_gen_report_dir {
    -summary_context_id
    -impl_name
    -subscr_id
    -assert:boolean
} {
    Return a directory path, relative to the pageroot, for the rss
    subscription with subscr_id or impl_name + summary_context_id
    provided.  If the assert flag is set, create the directory.
} {
    if {!([info exists summary_context_id] && \
	    [info exists impl_name])} {
	if ![info exists subscr_id] {
	    error "rss_gen_report_dir needs either subscr_id or impl_id+summary_context_id"
	} else {
	    db_1row subscr_context_and_impl {}
	}
    }

    set report_dir [acs_root_dir]/[ad_parameter -package_id [rss_package_id] RssGenOutputDirectory rss-support rss]/$impl_name/${summary_context_id}

    if $assert_p {
	rss_assert_dir $report_dir
    }

    return $report_dir
}

ad_proc -public rss_gen_report_file {
    -summary_context_id
    -impl_name
    -subscr_id
    -assert:boolean
} {
    Return a file path for the rss subscription with subscr_id
    or impl_name + summary_context_id provided.
    If the -assert flag is set, the parent directory is created if
    it doesn't exist
    @return a Unix file path.  
} {
    if {!([info exists summary_context_id] && \
	    [info exists impl_name])} {
	if ![info exists subscr_id] {
	    error "rss_gen_report_file needs either subscr_id or impl_id+summary_context_id"
	} else {
	    db_1row subscr_context_and_impl {}
	}
    }

    if $assert_p {
	set report_dir [rss_gen_report_dir              \
		-summary_context_id $summary_context_id \
		-impl_name $impl_name                   \
		-assert] 
    } else {
	set report_dir [rss_gen_report_dir              \
		-summary_context_id $summary_context_id \
		-impl_name $impl_name]
    }

    set report_file $report_dir/rss.xml

    return $report_file
}

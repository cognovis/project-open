# /packages/intranet-sysconfig/www/install-fts.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Configures the system according to Wizard variables
} {

}

# ---------------------------------------------------------------
# Output headers
# Allows us to write out progress info during the execution
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set content_type "text/html"
set http_encoding "iso8859-1"

append content_type "; charset=$http_encoding"

set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"

util_WriteWithExtraOutputHeaders $all_the_headers
ns_startcontent -type $content_type

ns_write "[im_header] [im_navbar]"



# ---------------------------------------------------------------
# Install TSearch2
#
# TSearch2 installation depends on the PostgreSQL version:
#	7.4.x - No install (crashes Backup/Restore)
#	8.0.1 - tsearch2.801.tcl
#	8.0.8 - tsearch2.808.tcl
# ---------------------------------------------------------------

ns_write "<h2>Installing Full-Text Search</h2>\n"

set psql_version [im_database_version]
ns_write "<li>Found psql version '$psql_version'\n"


set pageroot [ns_info pageroot]
set serverroot [join [lrange [split $pageroot "/"] 0 end-1] "/"]
set search_sql_dir "$serverroot/packages/intranet-search-pg/sql/postgresql"

ns_write "<li>Found search_sql_dir: $search_sql_dir\n"


switch $psql_version {
    "8.0.1" - "8.0.8" {
	set install_package_p 1
	set sql_file "$search_sql_dir/tsearch2.$psql_version.sql"
	set result ""
	ns_write "<li>Sourcing $sql_file ...\n"
	catch { set result [db_source_sql_file -callback apm_ns_write_callback $sql_file] } err
	ns_write "done<br><pre>$err</pre>\n"
	ns_write "<li>Result: <br><pre>$result</pre>\n"
    }
    default {
	set install_package_p 0
	ns_write "<li>PostgreSQL Version $psql_version not supported.\n"
    }
}



if {$install_package_p} {

    # set the default configuration for TSearch2 (stemming etc...)
    ns_write "<li>Set the default locale for TSearch2  ...\n"
    set lc_messages [db_string lc_messages "show lc_messages"]
    db_dml pg_ts_cfg "update pg_ts_cfg set locale=:lc_messages where ts_name='default'"
    ns_write "done\n"

}


if {$install_package_p} {
    set enable_p 1
    set package_path "$serverroot/packages/intranet-search-pg"
    set callback "apm_ns_write_callback"
    set data_model_files [list "$search_sql_dir/intranet-search-pg-create.sql" data_model_create "intranet-search-pg"]
    set mount_path "intranet-search"
    set spec_file "$serverroot/packages/intranet-search-pg/intranet-search-pg.info"

    if {[catch {
	set version_id [apm_package_install \
		    -enable=$enable_p \
		    -package_path $package_path \
		    -callback $callback \
		    -load_data_model \
		    -data_model_files $data_model_files \
		    -mount_path $mount_path \
		    $spec_file \
        ]
    } err_msg]} {
	ns_write "<li>Error installing package: <pre>'$err_msg'</pre> \n"
    }
}




# ---------------------------------------------------------------
# Finish off page
# ---------------------------------------------------------------

# Remove all permission related entries in the system cache
util_memoize_flush_regexp ".*"
im_permission_flush


ns_write "[im_footer]\n"



# /packages/intranet-sysconfig/www/configure.tcl
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
    sector
    deptcomp 
    features 
    orgsize 
    prodtest 
}

# ---------------------------------------------------------------
# Output headers
# Allows us to write out progress info during the execution
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

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
# Enabling everything
# ---------------------------------------------------------------

ns_write "<h2>Resetting System to Default</h2>\n"

ns_write "<li>Enabling menus ... "
catch {db_dml enable_menus "update im_menus set enabled_p = 't'"}  err
ns_write "done<br><pre>$err</pre>\n"

ns_write "<li>Enabling categories ... "
catch {db_dml enable_categories "update im_categories set enabled_p = 't'"}  err
ns_write "done<br><pre>$err</pre>\n"

ns_write "<li>Enabling components ... "
catch {db_dml enable_components "update im_component_plugins set enabled_p = 't'"}  err
ns_write "done<br><pre>$err</pre>\n"

ns_write "<li>Enabling projects ... "
catch {db_dml enable_projects "update im_projects set project_status_id = [im_project_status_open] where project_status_id = [im_project_status_deleted]"}  err
ns_write "done<br><pre>$err</pre>\n"



# ---------------------------------------------------------------
# Sector Configuration
# ---------------------------------------------------------------

switch $sector {
    it_consulting - biz_consulting - advertizing - engineering {
	set install_pc 1
	set install_pt 0
    }
    translation {
	set install_pc 1
	set install_pt 1
    }
    default {
	set install_pc 1
	set install_pt 1
    }
}


set install_pc 1
set install_pt 1


# ---------------------------------------------------------------
# Disable Consulting Stuff

if {!$install_pc} {
    ns_write "<h2>Disabling 'Consulting' Components</h2>"

    # ToDo
    ns_write "<li>Disabling 'Consulting' Categories ... "
    set project_type_consulting_id [db_string t "select category_id from im_categories where category = 'Consulting Project'"]
    catch {db_dml disable_trans_cats "
	update im_categories 
	set enabled_p = 'f'
	where category_id in (
		select child_id
		from im_category_hierarchy
		where parent_id = :project_type_consulting_id
	    UNION
		select :project_type_consulting_id
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"
  
    ns_write "<li>Disabling 'Consulting' Projects ... "
    catch {db_dml disable_trans_cats "
	update im_projects
	set project_status_id = [im_project_status_deleted]
	where project_type_id in (
		select child_id
		from im_category_hierarchy
		where parent_id = :project_type_consulting_id
	    UNION
		select :project_type_consulting_id
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"

    ns_write "<li>Disabling 'Consulting' Menus ... "
    catch {db_dml disable_trans_cats "
	update im_menus
	set enabled_p = 'f'
	where menu_id in (
		select menu_id from im_menus where lower(name) like '%timesheet task%'
	UNION	select menu_id from im_menus where lower(name) like '%wiki%%'
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"

    ns_write "<li>Disabling 'Consulting' Components ... "
    catch {db_dml disable_trans_cats "
	update im_component_plugins
	set enabled_p = 'f'
	where plugin_id in (
		select plugin_id from im_component_plugins where package_name in (
			'timesheet2-invoices', 'intranet-timesheet2-tasks',
			'intranet-ganttproject', 'intranet-wiki'
		)
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"



}

# ---------------------------------------------------------------
# Disable Translation Stuff

if {!$install_pt} {
    ns_write "<h2>Disabling 'Translation' Components</h2>\n"

    ns_write "<li>Disabling 'Translation' Categories ... "
    set project_type_translation_id [db_string t "select category_id from im_categories where category = 'Translation Project'"]
    catch {db_dml disable_trans_cats "
	update im_categories 
	set enabled_p = 'f'
	where category_id in (
		select child_id
		from im_category_hierarchy
		where parent_id = :project_type_translation_id
	    UNION
		select :project_type_translation_id
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"


    ns_write "<li>Disabling 'Translation' Projects ... "
    catch {db_dml disable_trans_cats "
	update im_projects
	set project_status_id = [im_project_status_deleted]
	where project_type_id in (
		select child_id
		from im_category_hierarchy
		where parent_id = :project_type_translation_id
	    UNION
		select :project_type_translation_id
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"

    ns_write "<li>Disabling 'Translation' Menus ... "
    catch {db_dml disable_trans_cats "
	update im_menus
	set enabled_p = 'f'
	where menu_id in (
		select menu_id from im_menus where label like '%_trans_%'
	UNION	select menu_id from im_menus where lower(name) like '%trans%'
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"

    ns_write "<li>Disabling 'Translation' Components ... "
    catch {db_dml disable_trans_cats "
	update im_component_plugins
	set enabled_p = 'f'
	where plugin_id in (
		select plugin_id from im_component_plugins where package_name like '%trans%'
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"


}


# ---------------------------------------------------------------
# Feature Simplifications
# ---------------------------------------------------------------

set disable_workflow 0
set disable_bug_tracker 0
set disable_chat 0
set disable_amberjack 0
set disable_big_brother 0
set disable_crm 0
set disable_expenses 0
set disable_forum 0
set disable_filestorage 0
set disable_ganttproject 0
set disable_search_pg 0
set disable_simple_survey 0
set disable_timesheet 0
set disable_wiki 0

switch $features {
    minimum {

	set disable_workflow 1
	set disable_bug_tracker 1
	set disable_chat 1
	set disable_amberjack 1
	set disable_big_brother 1
	set disable_crm 1
	set disable_expenses 1
	set disable_forum 1
	set disable_filestorage 1
	set disable_ganttproject 0
	set disable_search_pg 0
	set disable_simple_survey 1
	set disable_timesheet 1
	set disable_wiki 1

    }
    frequently_used {

	set disable_bug_tracker 1
	set disable_chat 1
	set disable_big_brother 1
	set disable_crm 1
	set disable_forum 1
	set disable_filestorage 0
	set disable_ganttproject 0
	set disable_search_pg 0
	set disable_simple_survey 1
	set disable_timesheet 0
	set disable_wiki 1
    }
    other {

    }
}







# ---------------------------------------------------------------
# Finish off page
# ---------------------------------------------------------------

ns_write "[im_footer]\n"



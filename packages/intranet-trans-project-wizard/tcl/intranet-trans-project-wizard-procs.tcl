# /packages/intranet-trans-project-wizard/tcl/intranet-trans-project-wizard.tcl

ad_library {
    Component for translation project wizard

    @author frank.bergmann@project-open.com
    @creation-date 10 June 2006
}


# ------------------------------------------------------
# Main Wizard Component
# ------------------------------------------------------

ad_proc im_trans_project_wizard_component { 
    -project_id:required
} {
    Returns a formatted HTML table representing the status of the translation project
} {
    if {![im_project_has_type $project_id "Translation Project"]} { return "" }

    im_project_permissions [ad_get_user_id] $project_id view read write admin
    if {!$write} { return "" }

    set params [list \
		    [list project_id $project_id] \
    ]

    set result ""
    if {[catch {
    } err_msg]} {
	set result "Error in Translation Project Wizard:<p><pre>$err_msg</pre>"
    }

	set result [ad_parse_template -params $params "/packages/intranet-trans-project-wizard/www/trans-project-wizard"]

    return $result

}

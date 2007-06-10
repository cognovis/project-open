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
    -return_url:required
} {
    Returns a formatted HTML table representing the status of the translation project
} {
    set params [list \
		    [list project_id $project_id] \
    ]
    set result [ad_parse_template -params $params "/packages/intranet-trans-project-wizard-procs/www/trans-project-wizard"]
    return $result

}

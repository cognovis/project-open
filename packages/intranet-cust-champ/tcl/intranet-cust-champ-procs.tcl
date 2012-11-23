# /packages/intranet-cust-champ/tcl/intranet-cust-champ-procs.tcl
#

ad_library {
    Extensions CHAMP 
    @author klaus.hofeditz@project-open.com
}

# ---------------------------------------------------------------------
# Components  
# ---------------------------------------------------------------------

ad_proc -public assign_group_members_to_project_component {
    user_id 
    object_id 
    { return_url "" }
} {
    Returns a HTML component showing a multi-select of acs groups  
} {

    set params [list \
                    [list user_id $user_id] \
                    [list object_id $object_id] \
                    [list return_url $return_url] \
		    ]

    return [string trim [ad_parse_template -params $params "/packages/intranet-cust-champ/lib/assign-group-to-project-component"]]
}

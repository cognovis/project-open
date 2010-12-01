# /packages/intranet-sla-management/www/sla-parameter-action.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Takes commands from the /intranet-sla-management/index page or 
    the sla-parameter-indicator-component and perform the selected 
    action on the selected items
    @author frank.bergmann@project-open.com
} {
    action
    { param:multiple {}}
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------


set user_id [ad_maybe_redirect_for_registration]
if {"" == $param} { ad_returnredirect $return_url }

switch $action {
    new_indicator {
	# redirect to create a new indicator
	ad_returnredirect [export_vars -base "/intranet-reporting-indicators/new" {{return_url $return_url} {also_add_rel_to_objects $param} {also_add_rel_type "im_sla_param_indicator_rels"}}]
    }
    associate_indicator {
	ad_returnredirect [export_vars -base "/intranet-sla-management/related-objects-associate.tcl" {{return_url $return_url} {tid $param}}]
    }
    default {
	ad_return_complaint 1 "<li>Unknown action: '$action'"
    }
}

ad_returnredirect $return_url


ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$

} {
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set page_title "Widget Examples"
set context_bar [im_context_bar [list /intranet-dynfield/ "DynField"] $page_title]


set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

# ------------------------------------------------------------------
# Create Datasource
# ------------------------------------------------------------------

list::create \
    -name widgets \
    -multirow widgets \
    -key widget_name \
    -row_pretty_plural "Object Types" \
    -checkbox_name checkbox \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -pass_properties {
        variable
    } -actions {
    } -bulk_actions {
    } -elements {
        widget_name {
            display_col widget_name
            label "Widget Name"
        }
        pretty_name {
            display_col pretty_name
            label "Pretty Name"
        }
        pretty_plural {
            display_col pretty_plural
            label "Pretty Plural"
        }
        widget {
            display_col widget
            label "Widget"
        }
        datatype {
            display_col datatype
            label "Datatype"
        }
        parameters {
            display_col parameters
            label "Parameters"
        }
    } -filters {
        object_type {}
    } -groupby {
    } -orderby {
    } -formats {
        normal {
            label "Table"
            layout table
            row {
                widget_name {}
                pretty_name {}
                widget {}
                datatype {}
                parameters {}
            }
        }
    }


db_multirow widgets get_widgets {
	select	*,
		im_category_from_id(storage_type_id) as storage_type
	from	im_dynfield_widgets
	order by widget_name
} {
}

# Create the ad_form
ad_form -name widgets_form -form {} -on_submit {}



set cnt 0
template::multirow foreach widgets {

    ns_log Notice "widget-examples: widget_name=$widget_name"

#    if { [string equal $storage_type_id [im_dynfield_storage_type_id_multimap]] } {
#        append form_element { {options { {"Demo Example One" 1} {"Demo Example Two" 2} {"Demo Example Three" 3} {"Demo Example Four" 4} {"Demo Example Five" 5} {"Demo Example Six" 6} }}}
#    }
#    lappend form_element [list "label" "<p><strong>$widget_name</strong></p><p>$pretty_plural</p><p><small>widget: $widget<br>datatype: $acs_datatype<br>parameters: $parameters</small></p>"]

    im_dynfield::append_attribute_to_form \
	-widget $widget \
	-form_id widgets_form \
	-datatype $acs_datatype \
	-display_mode "edit" \
	-parameters $parameters \
	-attribute_name "${widget_name}_widget" \
	-pretty_name $widget_name \
	-required_p "f" \
	-help_text ""

    incr cnt
}




# ------------------------------------------------------------------
# Left Navigation Bar
# ------------------------------------------------------------------

set left_navbar_html "
            <div class=\"filter-block\">
                <div class=\"filter-title\">
                    [lang::message::lookup "" intranet-dynfield.DynField_Admin "DynField Admin"]
                </div>
		[im_dynfield::left_navbar]
            </div>
            <hr/>
"





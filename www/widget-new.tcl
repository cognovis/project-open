# /packages/intranet-dynfield/www/widget-new.tcl

ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-01-05
    @cvs-id $Id$
} {
    widget_id:optional
    { form_mode "display" }
    { return_url "widgets" }
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set title "Add/Modify Widget"
set context [list [list "/intranet-dynfield/" DynField] [list widgets Widgets] $title]

set action_url "widget-new"
set focus "menu.var_name"

if {![info exists menu_id]} { set form_mode "edit" }


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

# How should the widget's value be stored in the database?
#
# In the future 

set storage_options [list [list "Table Column" 10007] [list "Multi-Select Mapping Table" 10005] ]

set acs_datatype_options [list \
	[list "Integer" integer] \
	[list "String" string] \
	[list "Boolean" boolean] \
	[list "Date" date] \
	[list "Email" email] \
	[list "Text" text] \
	[list "Float" float] \
	[list "Number" number] \
	[list "File" file] \
	[list "Filename" filename] \
	[list "Keyword" keyword] \
	[list "Natural Number" naturalnum] \
]

set widget_options [list \
	[list "Checkbox" checkbox] \
	[list "Date" date] \
	[list "Multiselect" multiselect] \
	[list "Radio" radio] \
	[list "Rich Text" richtext] \
	[list "Select" select] \
	[list "Text" text] \
	[list "Textarea" textarea] \
	[list "P/O Category" im_category_tree] \
	[list "OpenACS Category" category_tree] \
	[list "Generic SQL" generic_sql] \
	[list "Hidden" hidden] \
]


set deref_options [list \
	[list "Generic Default (im_name_from_id)" "im_name_from_id"] \
	[list "Integer (im_integer_from_id)" "im_integer_from_id"] \
	[list "User Name (im_name_from_user_id)" "im_name_from_user_id"] \
	[list "User Email (im_email_from_user_id)" "im_email_from_user_id"] \
	[list "Traffic Light (im_traffic_light_from_id)" "im_traffic_light_from_id"] \
	[list "Cost Center Name (im_cost_center_name_from_id)" "im_cost_center_name_from_id"] \
]
#	[list "" ""] \



ad_form \
    -name widget \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {user_id return_url} \
    -form {
	widget_id:key
	{widget_name:text(text) {label "Widget Name"} {html {size 40}}}
	{pretty_name:text(text) {label "Pretty Name"} {html {size 40}}}
	{pretty_plural:text(text) {label "Pretty Plural"} {html {size 40}}}
	{storage_type_id:text(select) {label "Storage Type"} {options $storage_options} }
	{acs_datatype:text(select) {label "ACS Datatype"} {options $acs_datatype_options} }
	{sql_datatype:text(text) {label "SQL Datatype"} {html {size 60}} {help_text {Please specify the datatype for this attribute when we generate a new SQL column. Examples: <table><tr><td><li>integer<li>varchar(200)</td><td><li>number(12,2)<li>clob</td></tr></table>}} }
	{widget:text(select) {label "TCL Widget"} {options $widget_options} }
	{deref_plpgsql_function:text(select) {label "Dereferencing function"} {options $deref_options} {help_text {Select the function that converts an attribute of this widget into a printable/ searchable string.<br>Default is im_name_from_id which deals reasonably with most data.}} }
	{parameters:text(textarea),optional {label "Parameters"} {nospell} {html {cols 65 rows 8}}}
    }


ad_form -extend -name widget -on_request {
    # Populate elements from local variables

} -select_query {

	select	w.*
	from	im_dynfield_widgets w
	where	w.widget_id = :widget_id

} -new_data {

    db_exec_plsql create_widget ""

# } -validate {
#
#	{widget_name
#	    {![db_string unique_name_check "select count(*) from im_dynfield_widgets where widget_name = :widget_name"]}
#	    "Duplicate Widget Name. Please use a new name."
#	}


} -edit_data {

    db_dml widget_update "
	update im_dynfield_widgets set
		widget_name	= :widget_name,
		pretty_name	= :pretty_name,
		pretty_plural	= :pretty_plural,
		storage_type_id	= :storage_type_id,
		acs_datatype	= :acs_datatype,
		sql_datatype	= :sql_datatype,
		widget		= :widget,
		deref_plpgsql_function = :deref_plpgsql_function,
		parameters	= :parameters
	where
		widget_id = :widget_id
"
} -on_submit {

	ns_log Notice "widget-new: on_submit"


} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}


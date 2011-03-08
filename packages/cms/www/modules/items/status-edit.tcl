# Build an appropriate form to edit the publishing status for an item.
request create
request set_param item_id -datatype integer
request set_param mount_point -datatype keyword -value sitemap
request set_param parent_id -datatype integer -optional

## Create the form

form create publish_status

element create publish_status item_id \
  -datatype integer -widget hidden -value $item_id

element create publish_status is_live \
  -datatype keyword -widget hidden -optional -value "f"

if { [form is_request publish_status] } {

    # Determine whether the item has a live revision
    set live_revision [db_string get_live_revision ""]

    if { [template::util::is_nil live_revision] } {
        element set_value publish_status is_live f
    } else {
        element set_value publish_status is_live t
    }
}





# generate status options

# always show production
set options [list [list "Production" production]]

set is_publishable [db_string check_status ""]

set is_live [element get_value publish_status is_live] 

# show "Ready" and "Live" if a live revision exists and the item is 
#   publishable
#if { [string equal $is_live t] && [string equal $is_publishable t] } {
  lappend options [list "Ready" ready] [list "Live (publishes the item)" live]
#}

set is_published [db_string check_published ""]

# show "Expired" only if the item is currently published
if { [string equal $is_published t] } {
    lappend options [list Expired expired]
} 










element create publish_status publish_status \
    -datatype keyword -widget radio -label Status \
    -options $options

if { [llength $options] == 1 } {
    element set_properties publish_status publish_status -widget hidden

    element create publish_status publish_status_inform \
	    -datatype text \
	    -widget inform \
	    -value "Production" \
	    -label "Status"
}

element create publish_status start_when \
  -datatype date -widget date -minutes_interval { 0 59 1 } \
  -format {MONTH DD, YYYY HH24:MI} -optional -help -label {Start Date}

element create publish_status end_when \
  -datatype date -widget date -minutes_interval { 0 59 1 } \
  -format {MONTH DD, YYYY HH24:MI} -optional -help -label {End Date}

# Populate the form
if { [form is_request publish_status] } {

  # Get the current status
  db_1row get_info "" -column_array info

  form set_values publish_status info
}

# Process the form

if { [form is_valid publish_status] } {

  form get_values publish_status publish_status start_when end_when item_id

  db_transaction {
      publish::set_publish_status $item_id $publish_status

      set start_when [template::util::date get_property sql_date $start_when]
      set end_when [template::util::date get_property sql_date $end_when]

      db_exec_plsql set_release_period "begin 
                    content_item.set_release_period(
                      item_id => :item_id,
                      start_when => $start_when,
                      end_when => $end_when
                    );
                  end;"

  }
 
  template::forward index?item_id=$item_id
}

# If the item is in a production state, we may simply be marking
# the item as ready or deploying it.  

# If the item is ready, we may want to move it back to production,
# schedule it for publishing, or publish it immediately.

# If the item is live, we way want to expire it, move it back to  or edit the 

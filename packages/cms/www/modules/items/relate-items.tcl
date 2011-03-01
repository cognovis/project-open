# This form will list all currently marked content items
# and confirm that the user wishes to link them all to the current item
request create -params {
  item_id -datatype integer
  mount_point -datatype keyword -value sitemap
}

# Check permissions
content::check_access $item_id cm_relate \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index"

######################## BASIC PHASE: create default elements ###################

  # Get the item title and type
  db_1row get_item_info "" -column_array item_info

  set item_title $item_info(title)
  set item_type $item_info(content_type)
  set page_title "Relate Items to \"$item_title\""

  # get related items from the clipboard
  set clip [clipboard::parse_cookie]
  set items [clipboard::get_items $clip $mount_point]

  # If no items are clipped, abort
  if { [llength $items] < 1 } {
    set no_items_on_clipboard t
    return
  } else {
    set no_items_on_clipboard f
  }

  # Get all possible relation types
  set type_options [db_list_of_lists get_options ""]

  # Prepare the query
  set sql_items "('"
  append sql_items [join $items "','"]
  append sql_items "')"

  

  db_multirow clip_items get_clip_items ""

  if { ${clip_items:rowcount} < 1} {
    set no_valid_items t
    return
  } else {
    set no_valid_items f
  }

  # Process the query
  clipboard::ui::form_create rel_form

  # A short proc to add a row
  proc add_row { } {
    uplevel {
      upvar 0 "clip_items:[expr $j - 1]" prev_row
      clipboard::ui::add_row rel_form $mount_point $prev_row(related_id) $prev_row(title) -checked
      clipboard::ui::element_create rel_form path -datatype text -widget hidden \
	-value $prev_row(path)
      clipboard::ui::element_create rel_form relation_type -datatype keyword -widget select \
	-options $type_options
      clipboard::ui::element_create rel_form relation_tag -datatype text -widget select \
	-options $item_tags
      clipboard::ui::element_create rel_form order_n -datatype integer -widget text \
	-html { size 3 } -optional
    }
  }    

  for { set j 1 } { $j <= ${clip_items:rowcount}} {incr j} {
    upvar 0 "clip_items:$j" clip_row

    if { $j == 1 } {

      set prev_item $clip_row(related_id)
      set item_tags [list [list $clip_row(relation_tag) $clip_row(relation_tag)]]

    } elseif { $prev_item != $clip_row(related_id) && [llength $item_tags] > 0 } {

      # Apppend another row
      add_row

      set item_tags [list [list $clip_row(relation_tag) $clip_row(relation_tag)]]
      set prev_item $clip_row(related_id)

    } else {

      # Append a tag
      lappend item_tags [list $clip_row(relation_tag) $clip_row(relation_tag)]
    }

  }

  # Add the last row
  add_row

  # Add passthrough
  element create rel_form item_id -label "Item ID" \
    -datatype integer -widget hidden -param
  element create rel_form mount_point -label "Mount Point" \
    -datatype keyword -widget hidden -param -optional -value sitemap
  element create rel_form next_button -label "Next >>" \
    -widget submit -datatype text
  element create rel_form checked_rows -label "Checked Rows" \
    -widget hidden -datatype text -optional 
  element create rel_form phase -label "Phase" \
    -widget hidden -datatype keyword -value "basic"
  element create rel_form item_title -label "Item Title" \
    -widget hidden -datatype text -value $item_title
  element create rel_form item_type -label "Item Type" \
    -widget hidden -datatype keyword -value $item_type

  # See if any items were valid for relating
  if { ![info exists rel_form_data:rowcount] || ${rel_form_data:rowcount} < 1 } {
    set no_valid_items t
    return
  } else {
    set no_valid_items f
  }

  # Process the form - remember which rows were checked, prepare
  # hidden variables
  if { [form is_valid rel_form] } {
    set rel_list [list]
    set source_id $item_id

      db_transaction {
          clipboard::ui::process_form rel_form {
              if { $row(checked) } {

                  template::util::array_to_vars row

                  lappend rel_list [list $item_id $relation_tag $order_n $relation_type]
              }
          }
      }

    # If no rows are checked, we're done
    if { [llength $rel_list] < 1 } {
      template::forward "index?item_id=$source_id&mount_point=$mount_point"
      return
    } 

    # There are checked rows - create a custom form for each row
    template::forward "relate-items-2?item_id=$source_id&mount_point=$mount_point&rel_list=$rel_list&page_title=$page_title"
    
  }










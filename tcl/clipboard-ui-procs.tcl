#########################################
# Procedures to manipulate clipped items
#########################################

ad_proc -public clipboard::ui::form_create { form_name args } {

  Create a form for representing clipped items,
  also start a multirow datasource for the items
  The columns created for the multirow datasource by default are
  mount_point, item_id, title, checked, html
 
  row_code is the code to execute for each row that is added;
    will usually create
  element_names are the names of all the extra elements that will
    be created for each row of the form

} {
  
  set default_columns [list mount_point item_id title checked]

  # Take out the elements tag but leave the rest preserved
  template::util::get_opts $args
  if { [info exists opts(elements)] } {
    set elements $opts(elements)
    unset opts(elements)
  } else {
    set elements [list]
  }
  set v_args [template::util::list_opts]

  # Create the form and the datasource
  uplevel "
    template::multirow create ${form_name}_data $default_columns
    template::form create $form_name $v_args
  "
  # Remember the elements
  upvar "${form_name}:properties" form_properties
  set form_properties(is_closed) 0 
  set form_properties(row_elements) $elements
}

ad_proc -public clipboard::ui::add_row { form_name mount_point item_id title args} {

  Append a row to the multirow datasource
  If the -checked switch is specified, checks the box by default
  If the -eval switch is specified, executes the passed-in code

} {

  template::util::get_opts $args

  # Allocate a new row
  upvar "${form_name}_data:rowcount" rowcount
  incr rowcount
  upvar "${form_name}_data:$rowcount" row
  set row(rownum) $rowcount

  # Figure out if the row is checked
  if { [template::form is_submission $form_name] } {
    set row(checked) [template::util::nvl [lindex [ns_querygetall check_$rowcount] 0] 0]
  } else {
    if { [info exists opts(checked)] } {
      set row(checked) 1
    } else {
      set row(checked) 0
    }
  }

  # Create a form for the row
  uplevel "template::form create ${form_name}_${rowcount}"

  # Set defaults
  set row(html) ""
  set row(hidden) ""
  set row(elements) [list]

  # Create the checkbox
  set element_code [list check -datatype text -widget checkbox \
                      -label "." -options [list [list "" 1]] -optional]

  if { $row(checked) } {
    lappend element_code -values [list 1]
  }

  uplevel "
    upvar 0 \"${form_name}_data:$rowcount\" row
    clipboard::ui::element_create $form_name $element_code
  "

  set row(checked) [template::util::nvl $row(checked) 0]

  # Create the title inform widget
  set element_code [list title -datatype text -widget inform -label Title \
                      -value $title]
  uplevel "clipboard::ui::element_create $form_name $element_code"

  # Create the mount point, item_id hidden vars, remember their values
  # in the datasource. other hidden vars ?
  foreach varname {mount_point item_id} {
    set element_code [list $varname -datatype keyword -widget hidden \
                       -label $varname -value [set $varname]]
    set row($varname) [set $varname]
    uplevel "clipboard::ui::element_create $form_name $element_code"
  } 

}

ad_proc -public clipboard::ui::element_create { form_name element_name args } {

  A wrapper for element create which maintains the naming convention
  for the element. Appends the element to the multirow datasource
  and instantly renders the element, storing it in the html field
  of the datasource

} {
 
  # Get the variables
  set data_name "${form_name}_data"
  
  upvar "${data_name}:rowcount" rowcount
  upvar "${data_name}:$rowcount" row

  set indexed_name "${element_name}_$rowcount"
  
  # Create the element, take out the validate tag if the row is not checked
  template::util::get_opts $args
  if { ! $row(checked) &&  [info exists opts(validate)] } {
    unset opts(validate)
    if { ![info exists opts(optional)] } {
      set opts(optional) 1
    }
  }
  set v_args [template::util::list_opts]

  uplevel "
    template::element create $form_name $indexed_name $v_args -optional
  "

  # Store the element in the list of elements for the row
  lappend row(elements) $element_name
}


ad_proc -public clipboard::ui::process_row { form_name row_index row_dml } {

  Process a row of the table, executing whatever TCL code
  the user has passed in.
  Bind each element to its value (singular);
  Bind "${element}_values" to the values (plural).

} {

  # Bind variable names to values
  set code "upvar 0 \"${form_name}_data:${row_index}\" row\n" 
  upvar "${form_name}_data:${row_index}" row

  foreach element_name $row(elements) {
    set indexed_name "${element_name}_${row_index}"

    append code "
      set row($element_name) \\
        \[template::element get_value $form_name $indexed_name\]
      set row(${element_name}_values) \\
        \[template::element get_values $form_name $indexed_name\]
    "
  }

  # Execute the code
  append code $row_dml
  uplevel $code
}
 
ad_proc -public clipboard::ui::generate_form { form_name clip mount_point } {

  Assemble the entire datasource based on all items under some mount point

} {

  uplevel "
    set __form_name $form_name
    set __mount_point $mount_point
    upvar 0 $form_name:properties form_properties
    set __clip $clip
  "
 
  uplevel {
    set items [clipboard::get_items $__clip $__mount_point]
    cm::modules::${__mount_point}::getSortedPaths clip_rows $items
    for { set i 1 } { $i <= [template::multirow size clip_rows] } { incr i } {
      # Start the row
      template::multirow get clip_rows $i
      clipboard::ui::add_row $__form_name $__mount_point \
        $clip_rows(item_id) $clip_rows(item_path)
      # Append all elements
      upvar 0 ${__form_name}:$i row
      foreach element $form_properties(row_elements) {
        eval clipboard::ui::element_create $__form_name $element
      }
    }
  }
}

ad_proc -public clipboard::ui::generate_form_header { form_name {row_index 1}} {

  Generate the extra <th>...</th> tags based on the elements in some row

} {
  
  upvar "${form_name}_header" header
  upvar "${form_name}_data:${row_index}" row

  if { ![info exists row] } {
    ns_log notice "clipboard::ui::generate_form_header: No such row $row_index"
    return
  }

  set header [list]
  foreach element_name $row(elements) {
    upvar "${form_name}:${element_name}_${row_index}" element
    if { ![string equal $element(widget) hidden] } {
      lappend header $element(label)
    }
  }
}

ad_proc -public clipboard::ui::process_form { form_name row_dml } {

  Process the entire form, executing the same DML for each row
  If no DML is specified, uses the global dml

} {
  
  upvar "${form_name}_data:rowcount" rowcount
  for {set i 1} {$i <= $rowcount} {incr i} {
    uplevel "clipboard::ui::process_row $form_name $i \{$row_dml\}"
  }
}
  
    
    



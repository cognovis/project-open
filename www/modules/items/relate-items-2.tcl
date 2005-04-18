# Step 2 in the relate item wizard - presents a custom form
# for each relation

request create -params {
  item_id     -datatype integer
  mount_point -datatype keyword -value sitemap -optional
  rel_list    -datatype text
  page_title  -datatype text -optional -value "Relate Items"
}

# rel_list is a list of lists in form of
# {item_id relation_tag order_n relation_type}

# Check permissions
content::check_access $item_id cm_relate \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index"

# Create the basic form
form create rel_form_2

element create rel_form_2 item_id -label "Item Id" \
  -widget hidden -datatype integer -value $item_id
element create rel_form_2 mount_point -label "Mount Point" \
  -widget hidden -datatype keyword -value $mount_point -optional
element create rel_form_2 rel_list -label "Rel List" \
  -widget hidden -datatype text -value $rel_list
element create rel_form_2 page_title -label "Page Title" \
  -widget hidden -datatype text -value $page_title

# Create extra widgets; one widget for each relationship, and a
# multirow datasource that encompasses them all
upvar 0 "rel_attrs:rowcount" index
set index 0

set item_title [db_string get_title ""]

# Create the main multirow datasource

set form_complete 1

foreach rel $rel_list {
  incr index
  upvar 0 "rel_attrs:$index" rel_row
  set rel_row(rownum) $index

  set related_id [lindex $rel 0]
  set relation_tag [lindex $rel 1]
  set order_n [lindex $rel 2]
  set relation_type [lindex $rel 3]

  set rel_row(related_id) $related_id
  set rel_row(relation_tag) $relation_tag
  set rel_row(order_n) $order_n
  set rel_row(relation_type) $relation_type
  set rel_row(elements) [list] 
  set row(dmls) [list]

  # Get all elements, if any
  # FIXME: 
  set content_type $relation_type
  content::query_form_metadata params multirow {
    object_type <> 'cr_item_rel'
  }  

  if { ${params:rowcount} > 0 } {

    set form_complete 0

    # Get the header
    db_1row get_rel_info "" -column_array rel_info

    # Create the form section
    form section rel_form_2 \
      "$rel_info(pretty_name) : $rel_info(item_title) relates to $rel_info(related_title)"

    element create rel_form_2 tag_info_$index -label "Relation Tag" \
      -datatype text -widget inform -value $rel_row(relation_tag)

    # Create all the custom elements
    set j 1
    set last_table {}
    set element_list [list]
    while { 1 } {
      upvar 0 "params:$j" el_row
      template::util::array_to_vars el_row
      lappend rel_row(elements) $attribute_name

      set j [content::assemble_form_element params $attribute_name $j]
      ns_log notice "$j : $attribute_name, $code_params"
      eval "template::element create rel_form_2 ${attribute_name}_$index $code_params"

      if { $j > ${params:rowcount} } {
        break
      }

    }
  }
}



# Process the form
if { [form is_valid rel_form_2] || $form_complete } {
  
  # sort order_n for all related items for consistency
  form get_values rel_form_2 item_id
  cms_rel::sort_related_item_order $item_id  


  db_transaction { 

      unset row

      for { set i 1 } { $i <= ${rel_attrs:rowcount} } {incr i} {
          upvar 0 "rel_attrs:$i" row
          template::util::array_to_vars row

          # Insert the basic data
          
          # Insert at the end if no order
          if { [template::util::is_nil order_n] } {
              set order_n [db_string get_order ""]
          }

          # Perform the insertion
          set rel_id [db_exec_plsql relate "begin 
      :1 := content_item.relate (
          item_id       => :item_id,
          object_id     => :related_id,
          relation_tag  => :relation_tag,
          order_n       => :order_n,
          relation_type => :relation_type
      );
    end;"]

          # Insert any extra attributes
          if { [llength $elements] > 0 } {
              set attr_list [template::util::tcl_to_sql_list $elements]
              ns_log notice "$i : $attr_list"
              content::insert_element_data rel_form_2 $relation_type \
                  [list acs_object cr_item_rel] $rel_id "_$i" \
                  " attribute_name in ($attr_list)"
          }
      }
  }

  template::forward "index?item_id=$item_id&mount_point=$mount_point"
}
     
    



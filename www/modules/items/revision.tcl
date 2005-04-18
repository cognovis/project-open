# View a particular revision of the item.

request create -params {
  revision_id -datatype integer
  mount_point -datatype keyword -value sitemap
}

# flag indicating this is the live revision
set live_revision_p 0

db_1row get_revision "" -column_array one_revision
template::util::array_to_vars one_revision

# Check permissions - must have cm_examine on the item
content::check_access $item_id cm_examine \
	-mount_point $mount_point \
	-return_url "modules/sitemap/index" 


ns_log notice "user_permissions = [array get user_permissions]"
# validate revision
if { [template::util::is_nil item_id] } {
    template::request::error invalid_revision \
      "revision - Invalid revision - $revision_id"
    return
}


# check if the item is publishable (but does not need live revision)
set is_publishable [db_string get_status ""]

# get total number of revision for this item
set revision_count [db_string get_count ""]

set valid_revision_p "t"

# flag indicating whether the MIME type of the content is text
set is_text_mime_type f
set is_image_mime_type f
if { [regexp {text/} $mime_type] } {
    set is_text_mime_type t
    set content [db_string get_content ""]
  
    ns_log notice $content

    # HACK: special chars in the text confuse TCL
    if { [regexp {<|>|\[|\]|\{|\}|\$} $content match] } {
      set is_text_mime_type f
    }

} elseif { [regexp {image/} $mime_type] } {
    set is_image_mime_type t
}


# get item info
db_1row get_one_item ""
    
if { $live_revision_id == $revision_id } {
  set live_revision_p 1
}

################################################################
################################################################


# get the attribute types for a given revision item
# if attr.table_name is null, then use o.table_name
# if column_name is null, then use the attribute_name
# if id_column is null, then use 'attribute_id' and 'acs_attribute_values'

set meta_attributes [db_list_of_lists get_meta_attrs ""]

set attr_columns [list]
set attr_tables [list]
set column_id_cons [list]
set attr_display [list]

foreach meta $meta_attributes {
    set attribute_id   [lindex $meta 0]
    set pretty_name    [lindex $meta 1]
    set object_type    [lindex $meta 2]
    set attribute_name [lindex $meta 3]
    set table_name     [lindex $meta 4]
    set id_column      [lindex $meta 5]

    lappend attr_display [list $pretty_name $object_type]

    # add the column constraint and table to the query only if it
    #   isn't there already
    if { [lsearch -exact $attr_tables $table_name] == -1 } {
	lappend attr_tables $table_name
	lappend column_id_cons "$table_name.$id_column = :revision_id"
    }

    # the attribute value columns we want to fetch are either in
    #   acs_attribute_values (object_id,attribute_id) 
    #   or in $table_name ($id_column)
    if { ![string equal $attribute_name ""] && \
	    ![string equal $table_name ""] } {
	lappend attr_columns "$table_name.$attribute_name"
    } else {
	lappend attr_columns "acs_attribute_values.attr_value"

	if { [lsearch -exact $attr_tables "acs_attribute_values"] == -1 } {
	    lappend attr_tables "acs_attribute_values"
	    lappend column_id_cons \
		    "acs_attribute_values.attribute_id = $attribute_id
                     and acs_attribute_values.object_id = :revision_id"
	}
    }
}

if { ![string equal $attr_columns ""] } {

    set attribute_values [db_list_of_lists get_attr_values ""]

    # write the body of the attribute display table to $revision_attr_html
    set revision_attr_html ""
    set i 0
    set attribute_count [llength $attribute_values]
    foreach attr_value [lindex $attribute_values 0] {
	set pretty_name [lindex [lindex $attr_display $i] 0]
	set object_type [lindex [lindex $attr_display $i] 1]
	
	if { [expr [expr $i+1] % 2] == 0 } {
	    set bgcolor "#EEEEEE"
	} else {
	    set bgcolor "#ffffff"
	}
	if { [string equal $attr_value ""] } {
	    set attr_value "&nbsp"
	}

	append revision_attr_html "
        <tr bgcolor=\"$bgcolor\">
          <td>$pretty_name</td>
          <td>$object_type</td>
          <td>$attr_value</td>
        </tr>
        "
	incr i
      }
} else {
  set revision_attr_html ""
}

set page_title \
	"$title : Revision $revision_number of $revision_count for $name"


request create -params {
  template_id -datatype integer
}

if { ! [request is_valid] } { return }

set path [db_string get_path ""]

form create edit_template -html { enctype multipart/form-data }

element create edit_template return_url -datatype url -widget hidden

element create edit_template template_id -datatype integer \
    -value $template_id -widget hidden

element create edit_template revision_id -datatype integer -widget hidden

element create edit_template content -widget file -label Local File \
    -datatype text -html { size 50 }

if { [form is_request edit_template] } {
  
  element set_properties edit_template revision_id \
      -value [content::get_object_id]

  set return_url [ns_set iget [ns_conn headers] Referer]
  element set_properties edit_template return_url -value $return_url

} else {

  set return_url [element get_value edit_template return_url]
}

if { [string equal [ns_queryget action] "Cancel"] } {
  template::forward $return_url
}

if { [form is_valid edit_template] } {

  form get_values edit_template template_id revision_id

  set tmpfile [content::prepare_content_file edit_template]

  content::add_basic_revision $template_id $revision_id "Template" \
      -tmpfile $tmpfile

  template::forward $return_url
}
    


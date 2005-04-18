request create -params {
  template_id -datatype integer
  edit_revision -datatype integer -optional
}

if { ! [request is_valid] } { return }

if { [string equal $edit_revision {}] } {

    set edit_revision [content::get_latest_revision $template_id]
}

set text [content::get_content_value $edit_revision]

ns_return 200 text/plain $text

    


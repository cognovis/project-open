request create
request set_param form_title -datatype text

clipboard::ui::form_create clip_form -elements {{
     the_name -datatype text -widget text -value "fdfd" -optional -label "Name" \
     -validate { \
        {expr [string equal $value bob]} \
        {Name must be bob} \
      }
  }}

clipboard::ui::generate_form clip_form [clipboard::parse_cookie] sitemap

if { [form is_valid clip_form] } {
  clipboard::ui::process_form clip_form {
    if { $row(checked) } {
      ns_log notice "ROW: $row(rownum) CHECKED, name = $row(the_name)"
    }
  }
}

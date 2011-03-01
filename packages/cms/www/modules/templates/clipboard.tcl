set clipboard [clipboard::parse_cookie]

set cookie [clipboard::parse_cookie]

set in_list [join [clipboard::get_items $cookie templates] ","]

set template_count [llength $in_list]

if { $template_count > 0 } {

    db_multirow templates get_templates ""
}

set return_url [ns_set iget [ns_conn headers] Referer]

# /packages/intranet-workflow/www/panels/hello-world.tcl

# Show all available task information
set debug_html ""
foreach var [array names task] {
    set val $task($var)
    append debug_html "<tr><td>$var=</td><td>$val</td></tr>\n"
}

ad_return_template

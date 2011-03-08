# View a relationship

request create -params {
  rel_id -datatype integer
  mount_point -datatype keyword -value sitemap -optional
}

# Get misc info

db_1row get_rel_info ""

# Get extra attributes

db_multirow rel_attrs get_rel_attrs ""
 
# Get attribute values... inefficient !

for { set i 1 } { $i <= ${rel_attrs:rowcount} } { incr i } {
    upvar 0 "rel_attrs:$i" a_row

    if { [string equal $a_row(datatype) date] } {
        set what "to_char($a_row(attribute_name), 'Mon DD, YYYY HH24:MI') as value"
    } else {
        set what "$a_row(attribute_name) as value"
    }

    set value [db_string get_value ""]

    set a_row(value) $value

}






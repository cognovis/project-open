ad_page_contract {
    @author Neophytos Demetriou
} {
    {q ""}
    {num 0}
}

set package_id [ad_conn package_id]

if { $num == 0 } {
    set num [ad_parameter -package_id $package_id LimitDefault]
}

set page_title "Advanced Search"


set sql "
	select
		sot.object_type_id,
		aot.object_type,
		aot.pretty_name as object_type_pretty_name,
		aot.pretty_plural as object_type_pretty_plural
	from
		im_search_object_types sot,
		acs_object_types aot
	where
		sot.object_type = aot.object_type
"

set objects_html ""
db_foreach object_type $sql {
    append objects_html "
	<tr>
	  <td>
	    <input type=checkbox name=type value='$object_type' checked>
	  </td>
	  <td>
	    $object_type_pretty_plural
	  </td>
	</tr>
"
}

ad_return_template
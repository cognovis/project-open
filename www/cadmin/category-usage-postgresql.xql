<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="get_category_usages">
    <querytext>
      select n.object_id
      from category_object_map m, acs_named_objects n
      where acs_permission__permission_p(m.object_id, :user_id, 'read') = 't'
      and m.category_id = :category_id
      and n.object_id = m.object_id
    </querytext>
  </fullquery>

  <fullquery name="get_objects_using_category">
    <querytext>
      select n.object_id, n.object_name as object_name, o.creation_date,
	           t.pretty_name as package_type, n.package_id, p.instance_name
        from acs_objects o, acs_named_objects n, apm_packages p, apm_package_types t,
             category_object_map m
       where n.object_id = m.object_id
	 and o.object_id = n.object_id
	 and p.package_id = n.package_id
	 and t.package_key = p.package_key
	 and m.category_id = :category_id
	 and acs_permission__permission_p(m.object_id, :user_id, 'read') = 't'
             $order_by_clause
       limit $last_row offset $first_row -1
    </querytext>
  </fullquery>

</queryset>

<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="get_categorized_objects">
    <querytext>
      select n.object_id, n.object_name as object_name, o.creation_date,
                   t.pretty_name as package_type, n.package_id, p.instance_name
        from acs_objects o, acs_named_objects n, apm_packages p, apm_package_types t,
             ($subtree_sql) s
       where n.object_id = s.object_id
         and o.object_id = n.object_id
         and p.package_id = n.package_id
         and t.package_key = p.package_key
         and exists (select 1
                       from acs_object_party_privilege_map oppm
                      where oppm.object_id = n.object_id
                        and oppm.party_id = :user_id
                        and oppm.privilege = 'read')
             $letter_sql
             $package_sql
             $order_by_clause
       limit $last_row offset $first_row
    </querytext>
  </fullquery>

</queryset>

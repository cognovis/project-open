<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="get_categorized_objects">
    <querytext>
      select r.*
      from (select n.object_id, n.object_name as object_name, o.creation_date,
                   t.pretty_name as package_type, n.package_id, p.instance_name,
                   row_number() over ($order_by_clause) as row_number
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
            $order_by_clause) r
      where r.row_number between :first_row and :last_row
    </querytext>
  </fullquery>

</queryset>

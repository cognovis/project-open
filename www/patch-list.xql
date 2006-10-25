<?xml version="1.0"?>
<queryset>

<partialquery name="states_where_clause">
      <querytext>
                bt_patches.status = :status
      </querytext>
</partialquery>

<partialquery name="apply_to_version_where_clause">
      <querytext>
                bt_patches.apply_to_version = :apply_to_version
      </querytext>
</partialquery>

<partialquery name="apply_to_version_null_where_clause">
      <querytext>
                bt_patches.apply_to_version is null
      </querytext>
</partialquery>

<fullquery name="select_components">
      <querytext>

                select c.component_name,
                       c.component_id, 
                       s.count
                from   bt_components c,
                       (select p.component_id, count(*) as count
                        from   bt_patches p 
                        where  p.project_id = :package_id
			group by p.component_id
                       ) s
                where  s.component_id = c.component_id
                order  by lower(c.component_name)

      </querytext>
</fullquery>

<partialquery name="component_where_clause">
      <querytext>
                bt_patches.component_id = :component_id
      </querytext>
</partialquery>

<fullquery name="select_patches">
      <querytext>
    select bt_patches.patch_number,
           bt_patches.summary,
           bt_patches.status,
           to_char(acs_objects.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty,
           bt_components.component_name,
           (select atv.version_name 
            from   bt_versions atv 
            where  atv.version_id = bt_patches.apply_to_version
           ) as apply_to_version_name
    from   bt_patches,
           bt_components,
           acs_objects
    where  bt_patches.patch_id = acs_objects.object_id
    and    bt_patches.project_id = :package_id
    and    bt_components.component_id = bt_patches.component_id
           [list::filter_where_clauses -and -name "patches"]
    order  by acs_objects.creation_date desc
      </querytext>
</fullquery>


</queryset>

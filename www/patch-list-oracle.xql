<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_states">      
      <querytext>
                select distinct upper(substr(p.status, 1, 1)) || substr(p.status, 2),
                       p.status,
                       (select count(*) 
                        from   bt_patches p2
                        where  p2.project_id = p.project_id 
                        and    p2.status = p.status
                       ) as count,
                       decode(p.status, 'open', 1, 'accepted', 2, 'refused', 3, 4) as order_num
                from   bt_patches p
                where  p.project_id = :package_id
                order  by order_num

      </querytext>
</fullquery>

<fullquery name="select_versions">
      <querytext>

                select v.version_name,
                       p.apply_to_version,
                       count(p.patch_id) as num_patches
                from   bt_patches p, 
                       bt_versions v
                where  p.project_id = :package_id
                and    v.version_id (+) = p.apply_to_version
                group  by v.version_name, v.anticipated_freeze_date, p.apply_to_version
                order  by v.anticipated_freeze_date, v.version_name

      </querytext>
</fullquery>

</queryset>

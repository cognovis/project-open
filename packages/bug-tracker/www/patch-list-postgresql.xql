<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_states">      
      <querytext>
	select upper(substring(s.status from 1 for 1)) || substring(s.status from 2), status, count,
	       (case s.status when 'open' then 1 when 'accepted' then 2 when 'refused' then 3 else 4 end) as order_num
	from (select status, count(*) as count
	      from   bt_patches p
	      where  p.project_id = :package_id
	      group by p.status) s
	order by order_num
      </querytext>
</fullquery>

<fullquery name="select_versions">
      <querytext>

                select v.version_name,
                       v.version_id,
                       s.count
                from   bt_versions v,
                       (select p.apply_to_version, count(*) as count
                        from   bt_patches p 
                        where  p.project_id = :package_id 
			group by p.apply_to_version) s
                where  s.apply_to_version = v.version_id
                order  by v.version_name

      </querytext>
</fullquery>


</queryset>

<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">


<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>8.2</version>
  </rdbms>
  <fullquery name="default_material_id">
    <querytext>
  select material_id
from im_timesheet_tasks_view
group by material_id
order by count(*) DESC
limit 1
    </querytext>
  </fullquery>

  <fullquery name="insert_task">
    <querytext>
		insert into im_timesheet_tasks (
			task_id, material_id, uom_id, task_type_id
		) values (
			:task_id, :default_material_id, [im_uom_hour], :task_type_id
		)

    </querytext>
  </fullquery>
  <fullquery name="default_cost_center">
    <querytext>
	select cost_center_id 
	from im_timesheet_tasks_view 
	group by cost_center_id 
	order by count(*) DESC 
	limit 1
    </querytext>
  </fullquery>
  <fullquery name="select_members">
    <querytext>
		select	object_id_two as user_id,
			bom.object_role_id as role_id
		from	acs_rels r,
			im_biz_object_members bom
		where	r.rel_id = bom.rel_id and
			object_id_one = :parent_id
    </querytext>
  </fullquery>

</queryset>

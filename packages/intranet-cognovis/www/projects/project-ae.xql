<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">


<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>8.2</version>
  </rdbms>
  <fullquery name="project_exists">
    <querytext> 
      select count(*) 
      from im_projects 
      where project_id = :project_id
    </querytext>
  </fullquery>

  <fullquery name="projects_by_parent_id_query">
    <querytext>
	    select 
	    p.company_id, 
	    p.project_type_id, 
	    p.project_status_id
	    from
	    im_projects p
	    where 
	    p.project_id=:parent_id 
    </querytext>
  </fullquery>
  <fullquery name="project_update">
    <querytext>
update im_projects set
		project_name =	:project_name,
		project_path =	:project_path,
		project_nr =	:project_nr,
		project_type_id =:project_type_id,
		project_status_id =:project_status_id,
		project_lead_id =:project_lead_id,
		company_id =	:company_id,
		supervisor_id =	:project_lead_id,
		parent_id =	:parent_id,
		description =	:description,
		company_project_nr = :company_project_nr,
		requires_report_p =:requires_report_p,
		percent_completed = :percent_completed,
		on_track_status_id =:on_track_status_id,
		start_date =	$start_date,
		end_date =      $end_date
	where
		project_id = :project_id
    
    </querytext>
  </fullquery>
  <fullquery name="project_update_add_budget_hours">
    <querytext>
      update im_projects set
      project_budget_hours =:project_budget_hours
      where
      project_id = :project_id
    </querytext>
  </fullquery>

  <fullquery name="project_update_add_budget">
    <querytext>
      update im_projects set
      project_budget =:project_budget,
      project_budget_currency =:project_budget_currency
      where
      project_id = :project_id
    </querytext>
  </fullquery>
  

  <fullquery name="prev_ptype">
    <querytext>
      select project_type_id 
      from im_projects 
      where project_id = :project_id
    </querytext>
  </fullquery>
  
</queryset>

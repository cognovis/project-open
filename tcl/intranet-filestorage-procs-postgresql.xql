<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-filestorage/tcl/intranet-filestorage-procs-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-17 -->
<!-- @arch-tag ed418f75-646c-4548-912e-a371ae862384 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="im_filestorage_profiles.project_profiles">
    <querytext>
select distinct 
	p.profile_id,
	p.profile_gif,
	g.group_name as profile_name
from 
	((select
		p.profile_id
	from
		im_fs_folder_perms p,
		im_fs_folders f,
		im_profiles prof
	where
		f.folder_id = p.folder_id
		and f.object_id = :object_id
		and p.profile_id = prof.profile_id
	)
	UNION (select [im_customer_group_id] from dual)
	UNION (select [im_employee_group_id] from dual)
	UNION (select [im_freelance_group_id] from dual)
	UNION (select [im_wheel_group_id] from dual)
	) r
      LEFT JOIN
	groups g ON r.profile_id = g.group_id
      LEFT JOIN
	im_profiles p USING (profile_id)

    </querytext>
  </fullquery>

  <fullquery name="projects_info_query">
    <querytext>
select
	p.project_nr,
	p.project_path,
	p.project_name,
	c.company_path
from
	im_projects p
      LEFT JOIN
	im_companies c USING (company_id)
where
	p.project_id=:project_id

    </querytext>
  </fullquery>


  <fullquery name="im_filestorage_project_path_helper.projects_info_query">
    <querytext>
select
	p.project_nr,
	p.project_path,
	p.project_name,
	c.company_path
from
	im_projects p
      LEFT JOIN
	im_companies c USING (company_id)
where
	p.project_id=:project_id

    </querytext>
  </fullquery>


  <fullquery name="im_filestorage_project_sales_path_helper.projects_info_query">
    <querytext>
select
	p.project_nr,
	p.project_path,
	p.project_name,
	c.company_path
from
	im_projects p
      LEFT JOIN
	im_companies c USING (company_id)
where
	p.project_id=:project_id

    </querytext>
  </fullquery>

</queryset>

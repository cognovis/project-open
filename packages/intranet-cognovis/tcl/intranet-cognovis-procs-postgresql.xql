<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-forum/tcl/intranet-forum-procs-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-14 -->
<!-- @arch-tag 0765ad02-e9d6-4658-bfe1-5d9b62e1b620 -->
<!-- @cvs-id $Id: intranet-forum-procs-postgresql.xql,v 1.10 2010/01/28 15:31:56 moravia Exp $ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>8.2</version>
  </rdbms>


  <fullquery name="im_timesheet_task_get_info.select_task_info">
    <querytext>
      select t.*,
      p.parent_id as project_id,
      p.project_name as task_name,
      p.project_nr as task_nr,
      p.percent_completed,
      p.project_type_id as task_type_id,
      p.project_status_id as task_status_id,
      to_char(p.start_date,'YYYY-MM-DD') as start_date,
      to_char(p.end_date,'YYYY-MM-DD-HH24:MI') as end_date,
      p.reported_hours_cache,
      p.reported_hours_cache as reported_units_cache,
      p.note
      from
      im_projects p,
      im_timesheet_tasks t
      where
      t.task_id = :task_id
      and   p.project_id = :task_id
      
    </querytext>
  </fullquery>



</queryset>

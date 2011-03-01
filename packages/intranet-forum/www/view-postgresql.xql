<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-forum/www/view-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-14 -->
<!-- @arch-tag cf27eef4-1874-4aad-a32d-ec297cb40cf2 -->
<!-- @cvs-id $Id: view-postgresql.xql,v 1.3 2005/03/22 15:57:27 cvs Exp $ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="get_topic">
    <querytext>
select
	t.topic_id,
	t.parent_id,
	t.subject,
	t.message,
	t.topic_status_id,
	t.topic_type_id,
	t.owner_id,
	t.priority,
	t.scope,
	t.asignee_id,
	t.object_id,
	to_char(t.due_date, :date_format) as due_date,
	to_char(t.posting_date, :date_format) as posting_date,
	m.read_p,
	m.folder_id,
	m.receive_updates,
	im_category_from_id(t.topic_status_id) as topic_status,
	im_category_from_id(t.topic_type_id) as topic_type,
	im_name_from_user_id(t.owner_id) as owner_name,
	im_name_from_user_id(t.asignee_id) as asignee_name,
	acs_object__name(t.object_id) as object_name
from
	im_forum_topics t
      LEFT JOIN
        (select * from im_forum_topic_user_map where user_id=:user_id) m USING (topic_id)
where
	t.topic_id=:topic_id

    </querytext>
  </fullquery>
</queryset>

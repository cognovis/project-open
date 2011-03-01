<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-forum/www/assign-postgresql.xql -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-10-08 -->
<!-- @arch-tag a41695ea-3ad6-41b9-a1d1-d8a670854fb2 -->
<!-- @cvs-id $Id: assign-postgresql.xql,v 1.1 2004/10/08 09:36:20 cvs Exp $ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="get_topic">
    <querytext>
select
	t.*,
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

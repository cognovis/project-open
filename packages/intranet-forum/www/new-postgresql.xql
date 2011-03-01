<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-forum/www/new-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-15 -->
<!-- @arch-tag 86ee817c-2e29-48d8-8c43-120af2ab31f0 -->
<!-- @cvs-id $Id: new-postgresql.xql,v 1.1 2004/09/15 13:06:50 cvs Exp $ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>

  <fullquery name="get_topic_for_reply">
    <querytext>
select
        t.*,
        acs_object__name(t.object_id) as object_name
from
        im_forum_topics t
where
        topic_id=:parent_id
    </querytext>
  </fullquery>

  <fullquery name="get_object_name">
    <querytext>
      select acs_object__name(:object_id)
    </querytext>
  </fullquery>

  <fullquery name="get_topic">
    <querytext>
select
        t.*,
        m.read_p,
        m.folder_id,
        m.receive_updates,
        im_name_from_user_id(t.owner_id) as user_name,
        im_name_from_user_id(t.asignee_id) as asignee_name,
        acs_object__name(t.object_id) as object_name,
        ftc.category as topic_type,
        sc.category as topic_status
from
        im_forum_topics t
      LEFT JOIN
        (select * from im_forum_topic_user_map where user_id=:user_id) m ON t.topic_id=m.topic_id
      LEFT JOIN
        im_categories ftc ON t.topic_type_id=ftc.category_id
      LEFT JOIN
        im_categories sc ON t.topic_status_id=sc.category_id
where
        t.topic_id=:topic_id
      
    </querytext>
  </fullquery>
</queryset>

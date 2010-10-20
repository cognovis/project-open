<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">

<!-- @author Dave Bauer (dave@thedesignexperience.org) -->
<!-- @creation-date 2004-02-15 -->
<!-- @cvs-id $Id$ -->

<queryset>

  <fullquery name="get_folders">
    <querytext>
      select cf.folder_id,
             cf.label,
             sn.node_id,
             sn.enabled_p
      from cr_folders cf,
           dav_site_node_folder_map sn
      where cf.folder_id=sn.folder_id
      </querytext>
    </fullquery>
  
</queryset>
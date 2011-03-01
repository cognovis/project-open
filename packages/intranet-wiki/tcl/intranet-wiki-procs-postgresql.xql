<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-wiki/tcl/intranet-wiki-procs-postgresql.xql -->
<!-- @author  (frank.bergmann@project-open.com) -->
<!-- @creation-date 2005-04-09 -->
<!-- @arch-tag d600813f-9963-43e7-a2e1-05aed35c7910 -->
<!-- @cvs-id $Id: intranet-wiki-procs-postgresql.xql,v 1.2 2005/04/14 18:29:43 cvs Exp $ -->

<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="im_wiki_base_component.object_name_for_one_object_id">
    <querytext>select acs_object__name(:object_id) from dual</querytext>
  </fullquery>
</queryset>

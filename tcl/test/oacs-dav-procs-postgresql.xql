<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "xql.dtd">
<!-- @author Dave Bauer (dave@thedesignexperience.org) -->
<!-- @creation-date 2003-09-14 -->
<!-- @cvs-id $Id$ -->
<queryset>
  <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="_oacs-dav__oacs_dav_put.create_test_folder">
    <querytext>
      select content_folder__new (
      '__test_folder',
      '__test_folder',
      NULL,
      NULL
      )
    </querytext>
  </fullquery>
  <fullquery name="_oacs-dav__oacs_dav_put.register_content_type">
    <querytext>
      select
      content_folder__register_content_type(:folder_id,'content_revision','t')
    </querytext>
  </fullquery>
  
</queryset>
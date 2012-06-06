<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "xql.dtd">
<!-- @author Dave Bauer (dave@thedesignexperience.org) -->
<!-- @creation-date 2003-09-14 -->
<!-- @cvs-id $Id$ -->
<queryset>

  <fullquery name="_oacs-dav__oacs_dav_sc_create.get_dav_sc">
    <querytext>
      select * from acs_sc_contracts where contract_name='dav'
    </querytext>
  </fullquery>

  <fullquery name="_oacs-dav__oacs_dav_sc_create.get_dav_pt_sc">
    <querytext>
      select * from acs_sc_contracts where contract_name='dav_put_type'
    </querytext>
  </fullquery>

  
  <fullquery name="_oacs-dav__oacs_dav_sc_create.get_dav_ops">
    <querytext>
      select operation_name from acs_sc_operations where contract_name='dav'
    </querytext>
  </fullquery>

  <fullquery name="_oacs-dav__oacs_dav_sc_create.get_dav_pt_op">
    <querytext>
      select operation_name from acs_sc_operations where
      contract_name='dav_put_type'
      and operation_name='get_type'
    </querytext>
  </fullquery>
  
  <fullquery name="_oacs-dav__oacs_dav_put.item_exists">
    <querytext>
      select item_id from cr_items where name=:name
      and parent_id=:folder_id
    </querytext>
  </fullquery>

  <fullquery name="_oacs-dav__oacs_dav_put.revision_exists">
    <querytext>
      select revision_id from cr_revisions
      where item_id=:new_item_id
    </querytext>
  </fullquery>

  <fullquery name="_oacs-dav__oacs_dav_put.get_content_filename">
    <querytext>
      select content from cr_revisions where revision_id=:revision_id
    </querytext>
  </fullquery>

  <fullquery name="_oacs-dav__oacs_dav_put.item_exists">
    <querytext>
      select item_id from cr_items where name=:name
      and parent_id=:folder_id
    </querytext>
  </fullquery>

  <fullquery name="_oacs-dav__oacs_dav_mkcol.get_parent_folder">
    <querytext>
      select folder_id from cr_folders where package_id=:package_id
    </querytext>
  </fullquery>
  
  <fullquery name="_oacs-dav__oacs_dav_mkcol.folder_exists">
    <querytext>
      select item_id
      from cr_items
      where name=:fname
      and content_type='content_folder'
    </querytext>
  </fullquery>

</queryset>
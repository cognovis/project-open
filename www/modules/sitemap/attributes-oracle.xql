<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="content">      
      <querytext>

             begin
               content_folder.${subfolder_method}(:folder_resolved_id,'content_folder');
               content_folder.${symlink_method}(:folder_resolved_id,'content_symlink');
             end;

      </querytext>
</fullquery>

 
<fullquery name="get_options">      
      <querytext>
      
  select
    content_folder.is_registered(:folder_id,'content_folder') allow_subfolders,
    content_folder.is_registered(:folder_id,'content_symlink') allow_symlinks,
    content_folder.is_registered(:folder_id,'content_template') allow_templates
  from dual

      </querytext>
</fullquery>

 
</queryset>

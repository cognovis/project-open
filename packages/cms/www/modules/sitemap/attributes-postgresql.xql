<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="content">      
      <querytext>

             begin
               PERFORM content_folder__${subfolder_method}(:folder_resolved_id,'content_folder','f');
               PERFORM content_folder__${symlink_method}(:folder_resolved_id,'content_symlink','f');

               return null;
             end;

      </querytext>
</fullquery>

 
<fullquery name="get_options">      
      <querytext>
      
  select
    content_folder__is_registered(:folder_id,'content_folder','f') as allow_subfolders,
    content_folder__is_registered(:folder_id,'content_symlink','f') as allow_symlinks,
    content_folder__is_registered(:folder_id,'content_template','f') as allow_templates
  

      </querytext>
</fullquery>

 
</queryset>

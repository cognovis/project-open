<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="unregister">      
      <querytext>
      
         begin
           content_folder.unregister_content_type(
               folder_id        => :folder_id,
               content_type     => :type_key,
               include_subtypes => 'f' 
           );
         end;
      </querytext>
</fullquery>

 
</queryset>

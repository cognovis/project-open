<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="register_type">      
      <querytext>
      begin
           content_folder.register_content_type(
               folder_id        => :folder_id,
               content_type     => :type,
               include_subtypes => 'f'
           );
         end;
      </querytext>
</fullquery>

 
</queryset>

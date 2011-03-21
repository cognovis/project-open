<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="export_revision">      
      <querytext>
      
                             begin
                                 :1 := content_revision.export_xml(:revision_id);
                             end;
      </querytext>
</fullquery>

 
</queryset>

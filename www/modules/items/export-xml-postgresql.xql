<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="export_revision">      
      <querytext>

-- FIXME: need to modify xml related code to work with pg.

                 select content_revision__export_xml(:revision_id);
                            

      </querytext>
</fullquery>

 
</queryset>

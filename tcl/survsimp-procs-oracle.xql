<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_date">      
      <querytext>
      
            select to_char(creation_date, 'DD/MM/YYYY')
            from acs_objects
            where object_id = :response_id
        
      </querytext>
</fullquery>

 
</queryset>

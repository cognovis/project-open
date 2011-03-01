<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>                                                

<fullquery name="possible_guards">      
      <querytext>
      
select proname 
  from pg_proc 
 where proargtypes = '23 1043 1043 1043 1043 1043'::oidvector
   and prorettype = 16::oid

      </querytext>
</fullquery>

 
</queryset>

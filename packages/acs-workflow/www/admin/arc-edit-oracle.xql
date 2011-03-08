<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>                                                

<fullquery name="possible_guards">      
      <querytext>
      
    select a0.package_name || '.' || a0.object_name
    from   user_arguments a0
    where  position = 0
    and    argument_name is null
    and    data_type = 'CHAR'
    and    in_out = 'OUT'
    and    exists (select 1 from user_arguments a1 where a1.package_name=a0.package_name and a1.object_name=a0.object_name 
                   and a1.position=1 and a1.data_type='NUMBER' and a1.in_out='IN')
    and    exists (select 1 from user_arguments a2 where a2.package_name=a0.package_name and a2.object_name=a0.object_name 
                   and a2.position=2 and a2.data_type='VARCHAR2' and a2.in_out='IN')
    and    exists (select 1 from user_arguments a3 where a3.package_name=a0.package_name and a3.object_name=a0.object_name 
                   and a3.position=3 and a3.data_type='VARCHAR2' and a3.in_out='IN')
    and    exists (select 1 from user_arguments a4 where a4.package_name=a0.package_name and a4.object_name=a0.object_name 
                   and a4.position=4 and a4.data_type='VARCHAR2' and a4.in_out='IN')
    and    exists (select 1 from user_arguments a5 where a5.package_name=a0.package_name and a5.object_name=a0.object_name 
                   and a5.position=5 and a5.data_type='VARCHAR2' and a5.in_out='IN')
    and    exists (select 1 from user_arguments a6 where a6.package_name=a0.package_name and a6.object_name=a0.object_name 
                   and a6.position=6 and a6.data_type='VARCHAR2' and a6.in_out='IN')

      </querytext>
</fullquery>

 
</queryset>

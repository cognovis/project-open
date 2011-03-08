<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="new_group">      
      <querytext>


        select acs_group__new(
                        :group_id, 
                        'group',
                        now(),
                        :user_id, 
                        :ip,
                        :email,
                        :url,
                        :group_name, 
                        null,
                        null);

      </querytext>
</fullquery>

 
<fullquery name="new_rel">      
      <querytext>

        select composition_rel__new(
                        null,
                        'composition_rel',
                        :parent_id,
                        :group_id,
                        :user_id, 
                        :ip )
      </querytext>
</fullquery>

 
<fullquery name="get_group_id">      
      <querytext>
      
    select acs_object_id_seq.nextval 
  
      </querytext>
</fullquery>

 
</queryset>

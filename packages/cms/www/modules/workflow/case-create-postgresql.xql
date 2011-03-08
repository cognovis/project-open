<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="new_case">      
      <querytext>

        select  workflow_case__new(
	    :case_id,
	    'publishing_wf', 
	    NULL,
	    :item_id,
            now(),
	    :user_id, 
	    :creation_ip
        ); 
       
      </querytext>
</fullquery>


<fullquery name="add_assignment">      
      <querytext>

        select workflow_case__add_manual_assignment(
		      :case_id,
		      'authoring',
		      :value
		  );
		 
		
      </querytext>
</fullquery>

 
<fullquery name="add_new_assignment">      
      <querytext>

        select  workflow_case__add_manual_assignment(
		          :case_id,
	                  :transition,
	                  :new_value
		      );
		   
		    
      </querytext>
</fullquery>

 
<fullquery name="start_case">      
      <querytext>

        select workflow_case__start_case(
          :case_id,
          :user_id,
          :creation_ip,
          :msg
      );
     
    
      </querytext>
</fullquery>

 
<fullquery name="get_users">      
      <querytext>
      
  select 
    person__name(user_id) as name, user_id 
  from 
    users 
  where 
    user_id > 0 
  order by 
    name

      </querytext>
</fullquery>

 
<fullquery name="get_case_id">      
      <querytext>
      
          select acs_object_id_seq.nextval 
	
      </querytext>
</fullquery>

 
</queryset>




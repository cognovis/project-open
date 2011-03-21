<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="new_case">      
      <querytext>
      begin :1 := workflow_case.new(
	    workflow_key  => 'publishing_wf', 
	    context_key   => NULL,
	    object_id     => :item_id,
	    creation_user => :user_id, 
	    creation_ip   => :creation_ip,
	    case_id       => :case_id
        ); 
        end;
      </querytext>
</fullquery>

 
<fullquery name="add_assignment">      
      <querytext>
      
		  begin
		  workflow_case.add_manual_assignment(
		      case_id        => :case_id,
		      role_key 	     => 'authoring',
		      party_id       => :value
		  );
		  end;
		
      </querytext>
</fullquery>

 
<fullquery name="add_new_assignment">      
      <querytext>
      
		      begin
	    	      workflow_case.add_manual_assignment(
		          case_id         => :case_id,
	                  role_key        => :transition,
	                  party_id        => :new_value
		      );
		      end;
		    
      </querytext>
</fullquery>

 
<fullquery name="start_case">      
      <querytext>
      
      begin
      workflow_case.start_case(
          case_id       => :case_id,
          creation_user => :user_id,
          creation_ip   => :creation_ip,
          msg           => :msg
      );
      end;
    
      </querytext>
</fullquery>

 
<fullquery name="get_users">      
      <querytext>
      
  select 
    person.name(user_id) name, user_id 
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
      
          select acs_object_id_seq.nextval from dual
	
      </querytext>
</fullquery>

 
</queryset>

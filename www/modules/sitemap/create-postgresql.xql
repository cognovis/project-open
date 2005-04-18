<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="new_folder">      
      <querytext>
    
    select content_folder__new (
        :name, 
        :label, 
        :description,
        :create_parent_id, 
        null,
        null,
        now(),
        :user_id, 
        :ip ); 
    
      </querytext>
</fullquery>

 
<fullquery name="register_content_type">      
      <querytext>
	 
	  select content_folder__register_content_type(
	      :folder_id,
	      'content_template',
	      'f' 
	  );

	  
      </querytext>
</fullquery>

 
<fullquery name="get_path">      
      <querytext>
      
  select content_item__get_path(:create_parent_id, null) 

      </querytext>
</fullquery>

 
</queryset>

<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="create_survey">      
      <querytext>

	        select survsimp_survey__new (
                    :survey_id,
                    :name,
                    :name,
                    :description,
                    :description_html_p,
		    'f',
		    't',
		    'f',
                    :type,
                    :display_type,
		    :user_id,
                    :package_id
                )
        
      </querytext>
</fullquery>

 
<fullquery name="next_variable_id">      
      <querytext>
      select survsimp_variable_id_sequence.nextval 
      </querytext>
</fullquery>

 
<fullquery name="next_logic_id">      
      <querytext>
      select survsimp_logic_id_sequence.nextval 
      </querytext>
</fullquery>

<fullquery name="add_logic">
      <querytext>
      insert into survsimp_logic
      (logic_id, logic)
      values
      (:logic_id, :logic)
      </querytext>
</fullquery>

 
</queryset>

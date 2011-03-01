<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="create_survey">      
      <querytext>
      
	    begin
	        :1 := survsimp_survey.new (
                    survey_id => :survey_id,
                    name => :name,
                    short_name => :name,
                    description => :description,
                    description_html_p => :description_html_p,
                    type => :type,
                    display_type => :display_type,
                    context_id => :package_id,
                    package_id => :package_id,
		    creation_user => :user_id
                );
            end;
        
      </querytext>
</fullquery>

 
<fullquery name="next_variable_id">      
      <querytext>
      select survsimp_variable_id_sequence.nextval from dual
      </querytext>
</fullquery>

 
<fullquery name="next_logic_id">      
      <querytext>
      select survsimp_logic_id_sequence.nextval from dual
      </querytext>
</fullquery>

<fullquery name="add_logic">
      <querytext>
      insert into survsimp_logic
      (logic_id, logic)
      values
      (:logic_id, empty_clob()) returning logic into :1
      </querytext>
</fullquery>


 
</queryset>

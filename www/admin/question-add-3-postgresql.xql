<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="create_question">      
      <querytext>

	select survsimp_question__new (
		    :question_id,
		    :survey_id,
                    :sort_key,
                    :question_text, 
                    :abstract_data_type,
                    :required_p,
                    :active_p,
                    :presentation_type,
		    :presentation_options,
                    :presentation_alignment,
		    :user_id,
		    :survey_id
	)
	
      </querytext>
</fullquery>

 
<fullquery name="get_choice_id">      
      <querytext>
      select survsimp_choice_id_sequence.nextval as choice_id 
      </querytext>
</fullquery>

 
</queryset>

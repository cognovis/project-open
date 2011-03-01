<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="create_question">      
      <querytext>
      
	    begin
		:1 := survsimp_question.new (
		    question_id => :question_id,
		    survey_id => :survey_id,
                    sort_key => :sort_key,
                    question_text => empty_clob(),
                    abstract_data_type => :abstract_data_type,
                    presentation_type => :presentation_type,
                    presentation_alignment => :presentation_alignment,
                    active_p => :active_p,
                    required_p => :required_p,
		    context_id => :survey_id,
		    creation_user => :user_id
		);
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="get_choice_id">      
      <querytext>
      select survsimp_choice_id_sequence.nextval as choice_id from dual
      </querytext>
</fullquery>


</queryset>

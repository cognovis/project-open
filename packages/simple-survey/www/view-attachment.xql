<?xml version="1.0"?>
<queryset>

<fullquery name="get_file_type">      
      <querytext>
      select attachment_file_type
	    from survsimp_question_responses
	    where response_id = :response_id and question_id = :question_id
      </querytext>
</fullquery>

 
</queryset>

<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="return_attachment">      
      <querytext>
      select attachment_answer  
    from survsimp_question_responses
    where response_id = $response_id and question_id = $question_id

      </querytext>
</fullquery>

 
</queryset>

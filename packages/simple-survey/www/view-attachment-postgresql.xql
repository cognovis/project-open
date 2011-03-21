<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="return_attachment">      
      <querytext>
      FIX ME LOB
select attachment_answer  
    from survsimp_question_responses
    where response_id = $response_id and question_id = $question_id

      </querytext>
</fullquery>

 
</queryset>

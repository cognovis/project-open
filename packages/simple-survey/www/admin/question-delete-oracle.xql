<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="survsimp_delete_question">      
      <querytext>
      
	    begin
        	survsimp_question.del (:question_id);
	    end;
	
      </querytext>
</fullquery>

 
</queryset>

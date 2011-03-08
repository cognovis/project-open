<?xml version="1.0"?>
<queryset>

<fullquery name="survey_exists">      
      <querytext>
      
		select 1 from survsimp_surveys where survey_id = :survey_id
	    
      </querytext>
</fullquery>

 
<fullquery name="survey_info">      
      <querytext>
       select name, description
    from survsimp_surveys
    where survey_id = :survey_id

      </querytext>
</fullquery>

 
</queryset>

<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="update_logic">
      <querytext>
update survsimp_logic
set logic = :logic
where logic_id = :logic_id
      </querytext>
</fullquery>
 
</queryset>

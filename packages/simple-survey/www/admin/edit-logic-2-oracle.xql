<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="update_logic">
      <querytext>
update survsimp_logic
set logic = empty_clob()
where logic_id = :logic_id
returning logic into :1
      </querytext>
</fullquery>

</queryset>

<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_open_bugs">
      <querytext>
          select r.* 
          from (
              select rownum as r_rownum, q.*
              from (
                  select bt_bugs.bug_number,
                         bt_bugs.summary,
                         to_char(acs_objects.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty                
                  from   bt_bugs, acs_objects, workflow_cases cas, workflow_case_fsm cfsm
                  where  bt_bugs.bug_id = acs_objects.object_id
                  and    $sql_where_clause
                  order  by acs_objects.creation_date desc
              ) q
          ) r
          where r_rownum > $offset
          and   r_rownum <= $offset + $interval_size
      </querytext>
</fullquery>


</queryset>

<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="version_select">
  <querytext>
    
    select version_name,
           to_char(anticipated_release_date, 'YYYY MM DD HH24 MI') as anticipated_release_date, 
           to_char(coalesce(actual_release_date, now()), 'YYYY MM DD HH24 MI')  as actual_release_date
    from   bt_versions
    where  version_id = :version_id

  </querytext>
</fullquery>

</queryset>

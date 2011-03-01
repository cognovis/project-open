<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="bug_tracker::install::package_instantiate.create_project">      
      <querytext>

        select bt_project__new(:package_id);
    
      </querytext>
</fullquery>

 
</queryset>

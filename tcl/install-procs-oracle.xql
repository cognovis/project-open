<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="bug_tracker::install::package_instantiate.create_project">      
      <querytext>
        begin
            bt_project.new(:package_id);
        end;
      </querytext>
</fullquery>

 
</queryset>

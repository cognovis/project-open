<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_package_url">      
    <querytext>

        select site_node__url(s.node_id) as url
        from site_nodes s
        where s.object_id = :dev_support_id
        limit 1

    </querytext>
</fullquery>

 
</queryset>

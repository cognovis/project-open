<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_package_url">      
    <querytext>

        select site_node.url(s.node_id) as url
        from site_nodes s
        where s.object_id = :dev_support_id
        and rownum = 1

    </querytext>
</fullquery>

 
</queryset>

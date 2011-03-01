<?xml version="1.0"?>

<queryset>

  <fullquery name="rss_package_id.get_package_id">
    <querytext>
        select package_id from apm_packages where package_key = 'rss-support'
    </querytext>
  </fullquery>

  <fullquery name="rss_first_url_for_package_id_helper.first_node_id">
    <querytext>
        select node_id from site_nodes
        where object_id = :package_id
	order by node_id limit 1
    </querytext>
  </fullquery>

</queryset>

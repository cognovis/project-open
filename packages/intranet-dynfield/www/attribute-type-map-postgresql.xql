<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="attribute-type-map">
      <querytext>

	select
		*
	from
		im_dynfield_type_attribute_map m
	where
		m.object_type = :object_type
		and 

        select   v.version_id, v.package_key, t.pretty_name, v.version_name, v.enabled_p,
                 v.installed_p, v.distribution_uri,
            (select count(*) from apm_package_versions v2
             where v2.package_key = v.package_key
             and   v2.installed_p
             and   apm_package_version__sortable_version_name(v2.version_name) >
                   apm_package_version__sortable_version_name(v.version_name)) as  superseded_p,
             case
               when content_item__get_latest_revision(item_id) is null
               then 0
               else 1
             end as tarball_p
        from    apm_package_versions v, apm_package_types t
        where  t.package_key = v.package_key

        [ad_order_by_from_sort_spec $orderby $table_def]

      </querytext>
</fullquery>




</queryset>

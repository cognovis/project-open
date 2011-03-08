<?xml version="1.0"?>
<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="cms_folder::get_registered_types.get_name_type">
	<querytext>
    select
      o.pretty_name,
      m.content_type
    from
      acs_object_types o, cr_folder_type_map m
    where
      m.folder_id = :folder_id
    and
      m.content_type = o.object_type
    and
      content_item.is_subclass(o.object_type, 'content_revision') = 't'
    order by
      decode(o.object_type, 'content_revision', '----', o.pretty_name)
	</querytext>
</fullquery>

</queryset>
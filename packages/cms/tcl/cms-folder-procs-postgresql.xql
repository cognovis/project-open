<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

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
      content_item__is_subclass(o.object_type, 'content_revision') = 't'
    order by
      case when o.object_type = 'content_revision' then '----' else o.pretty_name end
	</querytext>
</fullquery>

</queryset>
<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="create_object">
  <querytext>
BEGIN
	:1 := acs_object.new (
                object_id =>		null,
                object_type =>		'im_dynfield_attribute',
                creation_date =>	sysdate,
                creation_user =>	'[ad_get_user_id]'
        );
END;
  </querytext>
</fullquery>

<fullquery name="create_object">
  <querytext>
BEGIN
        :1 := acs_object.new (
                object_id =>            null,
                object_type =>          'im_dynfield_attribute',
                creation_date =>        sysdate,
                creation_user =>        '[ad_get_user_id]'
        );
END;
  </querytext>
</fullquery>

</queryset>

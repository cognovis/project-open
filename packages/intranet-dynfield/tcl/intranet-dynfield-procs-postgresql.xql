<?xml version="1.0"?>
<queryset>

<fullquery name="im_dynfield::elements.select_elements">
  <querytext>
        select ida.attribute_id as dynfield_attribute_id,
               tam.required_p,
               tam.section_heading,
               aa.attribute_id,
               aa.attribute_name,
               aa.pretty_name,
               pos_y as sort_order,
               ida.widget_name as widget
       	  from im_dynfield_attributes ida,
               acs_attributes aa,
               im_dynfield_type_attribute_map tam,
               im_dynfield_layout idl
         where ida.acs_attribute_id = aa.attribute_id
               and tam.attribute_id = ida.attribute_id
               and ida.attribute_id = idl.attribute_id
               and tam.object_type_id in ($list_ids)
               order by sort_order
  </querytext>
</fullquery>

<fullquery name="im_dynfield::ad_form::elements.select_elements">
  <querytext>
        select im_dynfield_attribute_id, required_p
          from im_dynfield_list_attribute_map
         where list_id = :list_id
         order by sort_order
  </querytext>
</fullquery>

<fullquery name="im_dynfield_object_id_not_cached.select_im_dynfield_object_id">
  <querytext>
        select im_dynfield_object_id(:object_id)
  </querytext>
</fullquery>

<fullquery name="im_dynfield_object_id_not_cached.create_and_select_im_dynfield_object_id">
  <querytext>
        select im_dynfield_object__new(
                :object_id,
                :package_id,
                now(),
                :creation_user,
                :creation_ip
        );
  </querytext>
</fullquery>

<fullquery name="im_dynfield::option::new.im_dynfield_option_new">
  <querytext>
        select im_dynfield_option__new (:im_dynfield_attribute_id,:option,:sort_order)
  </querytext>
</fullquery>

<fullquery name="im_dynfield::option::delete.im_dynfield_option_delete">
  <querytext>
        select im_dynfield_option__delete (:option_id)
  </querytext>
</fullquery>


<fullquery name="im_dynfield::option::map.im_dynfield_option_map">
  <querytext>
        select im_dynfield_option__map (:option_map_id,:option_id)
  </querytext>
</fullquery>

<fullquery name="im_dynfield::attribute::get.select_attribute_info">
  <querytext>
        select intranet-dynfield.*,
               acs.attribute_name,
               acs.pretty_name,
               acs.pretty_plural,
               acs.object_type,
               aw.storage_type_id,
		im_category_from_id(aw.storage_type_id) as storage_type
          from im_dynfield_attributes intranet-dynfield,
               acs_attributes acs,
               im_dynfield_widgets aw
         where intranet-dynfield.im_dynfield_attribute_id = :im_dynfield_attribute_id
           and intranet-dynfield.attribute_id = acs.attribute_id
           and intranet-dynfield.widget_name = aw.widget_name
  </querytext>
</fullquery>

<fullquery name="im_dynfield::attribute::widget_not_cached.select_attribute">
  <querytext>
        select ac.attribute_name, 
               ac.pretty_name,
               ac.object_type,
               aw.widget,
               aw.acs_datatype as datatype,
               aw.parameters,
               aw.storage_type_id,
		im_category_from_id(aw.storage_type_id) as storage_type
          from im_dynfield_attributes aa,
               acs_attributes ac,
               im_dynfield_widgets aw
         where aa.attribute_id = :im_dynfield_attribute_id
           and aa.acs_attribute_id = ac.attribute_id
           and aa.widget_name = aw.widget_name
  </querytext>
</fullquery>

<fullquery name="im_dynfield::attribute::widget_not_cached.select_options">
  <querytext>
        select option, option_id
          from im_dynfield_options
         where im_dynfield_attribute_id = :im_dynfield_attribute_id
         order by sort_order 
  </querytext>
</fullquery>

<fullquery name="im_dynfield::attribute::exists_p.attribute_exists_p">
  <querytext>
        select '1' from acs_attributes where object_type = :object_type and attribute_name = :attribute_name
  </querytext>
</fullquery>

<fullquery name="im_dynfield::attribute::get_im_dynfield_attribute_id_not_cached.get_im_dynfield_attribute_id">
  <querytext>
        select intranet-dynfield.im_dynfield_attribute_id
          from im_dynfield_attributes intranet-dynfield, acs_attributes acs
         where acs.object_type = :object_type
           and acs.attribute_name = :attribute_name
           and acs.attribute_id = intranet-dynfield.attribute_id
  </querytext>
</fullquery>

<fullquery name="im_dynfield::attribute::name_not_cached.im_dynfield_attribute_name">
  <querytext>
        select im_dynfield_attribute__name (:im_dynfield_attribute_id)
  </querytext>
</fullquery>

<fullquery name="im_dynfield::attribute::storage_type_not_cached.im_dynfield_attribute_storage_type">
  <querytext>
        select aw.storage_type_id,
		im_category_from_id(aw.storage_type_id) as storage_type
          from im_dynfield_widgets aw, im_dynfield_attributes aa
         where aa.im_dynfield_attribute_id = :im_dynfield_attribute_id
           and aw.widget_name = aa.widget_name
  </querytext>
</fullquery>

<fullquery name="im_dynfield::attribute::delete.im_dynfield_attribute_delete">
  <querytext>
        select im_dynfield_attribute__delete (:im_dynfield_attribute_id)
  </querytext>
</fullquery>

<fullquery name="im_dynfield::object::attribute::values_batch_process.get_attr_values">
  <querytext>
        select aav.*, 
               ao.object_id,
               im_dynfield_attribute__options_string(option_map_id) as options_string,
               im_dynfield_attribute__postal_address_string(address_id) as address_string,
               im_dynfield_attribute__telecom_number_string(number_id) as telecom_number_string
          from im_dynfield_attribute_values aav, cr_revisions cr, im_dynfield_objects ao
         where ao.object_id in ($sql_object_id_list)
           and ao.im_dynfield_object_id = cr.item_id 
           and cr.revision_id = aav.revision_id
           and aav.superseed_revision_id is null
         order by ao.object_id, aav.im_dynfield_attribute_id
  </querytext>
</fullquery>

<fullquery name="im_dynfield::attribute::value::save.im_dynfield_attribute_value_new">
  <querytext>
        select im_dynfield_attribute_value__new (
                :revision_id,
                :im_dynfield_attribute_id,
                :option_map_id,
                :address_id,
                :number_id,
                :time,
                :value,
                :value_mime_type
        )
  </querytext>
</fullquery>


<fullquery name="im_dynfield::attribute::value::save.im_dynfield_attribute_value_save">
  <querytext>
        select im_dynfield_attribute_value__save (
                :revision_id,
                :im_dynfield_attribute_id,
                :option_map_id,
                :address_id,
                :number_id,
                :time,
                :value,
                :value_mime_type
        )
  </querytext>
</fullquery>

<fullquery name="contacts::get::ad_form_elements.select_attributes">
  <querytext>
	select *
        from contact_attributes ca,
             contact_widgets cw,
             contact_attribute_object_map caom,
             contact_attribute_names can
        where caom.object_id = :object_id
              and ca.im_dynfield_attribute_id = can.im_dynfield_attribute_id
              and can.locale = :locale
              and caom.im_dynfield_attribute_id = ca.im_dynfield_attribute_id
              and ca.widget_id = cw.widget_id
              and not ca.depreciated_p
              and acs_permission__permission_p(ca.im_dynfield_attribute_id,:user_id,'write')
        order by caom.sort_order
  </querytext>
</fullquery>


<fullquery name="contacts::get::values::multirow.select_attribute_values">
<querytext>

       select ca.im_dynfield_attribute_id,
                 ca.attribute, 
                 cav.option_map_id,
                 cav.address_id,
                 cav.number_id,
                 to_char(cav.time,'YYYY MM DD') as time,
                 cav.value,
                 cav.value_format,
                 cw.storage_column
            from contact_attributes ca,
                 contact_widgets cw,
                 contact_attribute_object_map caom left join 
                     ( select *
                         from contact_attribute_values 
                        where party_id = :party_id
                          and not deleted_p ) cav
                 on (caom.im_dynfield_attribute_id = cav.im_dynfield_attribute_id)
           where caom.object_id = '$object_id'
             and caom.im_dynfield_attribute_id = ca.im_dynfield_attribute_id
             and ca.widget_id = cw.widget_id
             and not ca.depreciated_p
             and (
                      cav.option_map_id   is not null 
                   or cav.address_id      is not null
                   or cav.number_id       is not null
                   or cav.value           is not null
                   or cav.time            is not null
                   or ca.attribute in ($custom_field_sql_list)
                 )
             and acs_permission__permission_p(ca.im_dynfield_attribute_id,'$user_id','$permission')
           order by caom.sort_order
</querytext>
</fullquery>


<fullquery name="contacts::get::values::multirow.organization_name_from_party_id">
  <querytext>
        select name
          from organizations
         where organization_id = :party_id
  </querytext>
</fullquery>


<fullquery name="contacts::get::values::multirow.legal_name_from_party_id">
  <querytext>
        select legal_name
          from organizations
         where organization_id = :party_id 
  </querytext>
</fullquery>


<fullquery name="contacts::get::values::multirow.reg_number_from_party_id">
  <querytext>
        select reg_number
          from organizations
         where organization_id = :party_id 
  </querytext>
</fullquery>


<fullquery name="contacts::get::values::multirow.organization_types_from_party_and_im_dynfield_attribute_id">
  <querytext>
        select cao.option_id, cao.option
        from contact_attribute_options cao,
               organization_types ot,
               organization_type_map otm
        where cao.option = ot.type
           and cao.im_dynfield_attribute_id  = :im_dynfield_attribute_id
           and otm.organization_type_id = ot.organization_type_id
           and otm.organization_id = :party_id
  </querytext>
</fullquery>


<fullquery name="contacts::get::values::multirow.first_names_from_party_id">
  <querytext>
        select first_names
          from persons
         where person_id = :party_id
  </querytext>
</fullquery>


<fullquery name="contacts::get::values::multirow.last_name_from_party_id">
  <querytext>
        select last_name
          from persons
         where person_id = :party_id
  </querytext>
</fullquery>


<fullquery name="contacts::get::values::multirow.email_from_party_id">
  <querytext>
        select email
          from parties
         where party_id = :party_id
  </querytext>
</fullquery>


<fullquery name="contacts::get::values::multirow.url_from_party_id">
  <querytext>
        select url
          from parties
         where party_id = :party_id
  </querytext>
</fullquery>


<fullquery name="contacts::get::values::multirow.select_options_from_map">
  <querytext>
        select cao.option, cao.option_id
          from contact_attribute_options cao,
               contact_attribute_option_map caom
         where caom.option_id = cao.option_id
           and caom.option_map_id = :option_map_id
  </querytext>
</fullquery>

<fullquery name="contacts::save::ad_form::values.select_attributes">
  <querytext>
        select *
            from contact_attributes ca,
                  contact_widgets cw,
                  contact_attribute_object_map caom,
                  contact_attribute_names can
            where caom.object_id = :object_id
              and ca.im_dynfield_attribute_id = can.im_dynfield_attribute_id
              and can.locale = :locale
              and caom.im_dynfield_attribute_id = ca.im_dynfield_attribute_id
              and ca.widget_id = cw.widget_id
              and not ca.depreciated_p
              and acs_permission__permission_p(ca.im_dynfield_attribute_id,:user_id,'write')
            order by caom.sort_order
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.select_old_address_id">
  <querytext>
        select cav.address_id as old_address_id
        from contact_attribute_values cav,
             postal_addresses pa
        where cav.party_id = :party_id
           and cav.im_dynfield_attribute_id = :im_dynfield_attribute_id
           and not cav.deleted_p
           and cav.address_id = pa.address_id
           and pa.delivery_address = :delivery_address
           and pa.municipality = :municipality
           and pa.region = :region
           and pa.postal_code = :postal_code
           and pa.country_code = :country_code
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.select_old_number_id">
  <querytext>
        select cav.number_id as old_number_id
        from contact_attribute_values cav,
             telecom_numbers tn
        where cav.party_id = :party_id
           and cav.im_dynfield_attribute_id = :im_dynfield_attribute_id
           and not cav.deleted_p
           and cav.number_id = tn.number_id
           and tn.subscriber_number = :attribute_value_temp
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.get_option_map_id">
  <querytext>
        select option_map_id 
	from contact_attribute_values
	where party_id = :party_id
	   and im_dynfield_attribute_id = :im_dynfield_attribute_id and not deleted_p
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.get_old_options">
  <querytext>
        select option_id
	from contact_attribute_option_map 
	where option_map_id  = :option_map_id
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.get_new_option_map_id">
  <querytext>
        select nextval('contact_attribute_option_map_id_seq') as option_map_id
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.insert_options_map">
  <querytext>
        insert into contact_attribute_option_map
           (option_map_id,party_id,option_id)
        values
           (:option_map_id,:party_id,:option_id)
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.update_parties_email">
  <querytext>
        update parties set email = :attribute_value_temp where party_id = :party_id
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.update_parties_url">
  <querytext>
        update parties set url = :attribute_value_temp where party_id = :party_id
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.update_organizations_name">
  <querytext>
        update organizations set name = :attribute_value_temp where organization_id = :party_id
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.update_organizations_legal_name">
  <querytext>
        update organizations set legal_name = :attribute_value_temp where organization_id = :party_id
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.update_organizations_reg_number">
  <querytext>
        update organizations set reg_number = :attribute_value_temp where organization_id = :party_id
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.delete_org_type_maps">
  <querytext>
        delete from organization_type_map where organization_id = :party_id
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.get_organization_type_id">
  <querytext>
        select organization_type_id
        from contact_attribute_options cao,
             organization_types ot
        where cao.option = ot.type
           and cao.option_id  = :option_id
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.insert_mapping">
  <querytext>
        insert into organization_type_map
           (organization_id, organization_type_id)
        values
           (:party_id, :organization_type_id)
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.update_persons_first_names">
  <querytext>
        update persons set first_names = :attribute_value_temp where person_id = :party_id
  </querytext>
</fullquery>


<fullquery name="contacts::save::ad_form::values.update_persons_last_name">
  <querytext>
        update persons set last_name = :attribute_value_temp where person_id = :party_id
  </querytext>
</fullquery>


</queryset>

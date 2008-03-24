<?xml version="1.0"?>
<queryset>

<fullquery name="ams::widget_options_not_cached.get_options">
  <querytext>
    select option,
           option_id,
	   title as pretty_name
      from ams_option_types aot, acs_objects ao
     where attribute_id = :attribute_id
	and aot.option_id = ao.object_id
       and not deprecated_p
     order by sort_order
  </querytext>
</fullquery>

<fullquery name="ams::widgets_init.select_widgets_to_deactivate">
  <querytext>
    select *
      from ams_widgets
     where active_p is true
       and widget not in ($sql_list_of_valid_procs)
  </querytext>
</fullquery>

<fullquery name="ams::widgets_init.save_widget">
  <querytext>
    select ams_widget__save (
      :widget,
      :pretty_name,
      :value_method,
      :active_p
    ) 
  </querytext>
</fullquery>

<fullquery name="ams::util::text_save.save_value">
  <querytext>
    select ams_value__text_save (
      :text,
      :text_format
    )
  </querytext>
</fullquery>

<fullquery name="ams::util::time_save.save_value">
  <querytext>
    select ams_value__time_save (
      :time
    )
  </querytext>
</fullquery>

<fullquery name="ams::util::number_save.save_value">
  <querytext>
    select ams_value__number_save (
      :number
    )
  </querytext>
</fullquery>

<fullquery name="ams::util::postal_address_save.save_value">
  <querytext>
    select ams_value__postal_address_save (
      :delivery_address,
      :municipality,
      :region,
      :postal_code,
      :country_code,
      :additional_text,
      :postal_type
    )
  </querytext>
</fullquery>

<fullquery name="ams::util::telecom_number_save.save_value">
  <querytext>
    select ams_value__telecom_number_save (
      :itu_id,
      :national_number,
      :area_city_code,
      :subscriber_number,
      :extension,
      :sms_enabled_p,
      :best_contact_time,
      :location,
      :phone_type_id
    )
  </querytext>
</fullquery>

<fullquery name="ams::util::options_save.options_value_id">
  <querytext>
    select value_id
      from ams_option_ids
     where ams_value__options(value_id) = :options
  </querytext>
</fullquery>

<fullquery name="ams::util::options_save.option_map">
  <querytext>
    select ams_option__map (
      :value_id,
      :option_id
    )
  </querytext>
</fullquery>

</queryset>

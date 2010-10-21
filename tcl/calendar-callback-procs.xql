<?xml version="1.0"?>
<queryset>

  <fullquery name="callback::merge::MergeShowUserInfo::impl::calendar.get_calendars">
    <querytext>	
	select calendar_name
	from calendars
	where owner_id = :user_id
    </querytext>
  </fullquery>	

  <fullquery name="callback::merge::MergePackageUser::impl::calendar.get_from_calendars">
    <querytext>	
	select calendar_id,package_id
	from calendars
	where owner_id = :from_user_id
    </querytext>
  </fullquery>	
  
  <fullquery name="callback::merge::MergePackageUser::impl::calendar.get_repeated_pkgs">
    <querytext>	
      select count(*)
      from calendars
      where owner_id = :to_user_id
      and package_id = :l_pkg_id
    </querytext>
  </fullquery>	

  <fullquery name="callback::merge::MergePackageUser::impl::calendar.calendars_upd">
    <querytext>	
      update calendars
      set owner_id = :to_user_id
      where owner_id = :from_user_id
      and calendar_id = :l_cal_id
    </querytext>
  </fullquery>	

  <fullquery name="callback::merge::MergePackageUser::impl::calendar.gettocalid">
    <querytext>	
      select calendar_id 
      from calendars 
      where package_id = :l_pkg_id 
      and owner_id = :to_user_id
    </querytext>
  </fullquery>	

  <fullquery name="callback::merge::MergePackageUser::impl::calendar.calendar_items_upd">
    <querytext>	
      update cal_items 
      set on_which_calendar = :to_cal_id
      where on_which_calendar = :l_cal_id
    </querytext>
  </fullquery>	

  <fullquery name="callback::merge::MergePackageUser::impl::calendar.del_from_cal">
    <querytext>	
      delete
      from calendars
      where calendar_id = :l_cal_id
    </querytext>
  </fullquery>	

	
</queryset>

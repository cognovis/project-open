<master>
<property name="title">#calendar.Calendars#</property>

<include src="/packages/calendar/www/navbar" view="@view@" base_url="@ad_conn_url@" date="@date@">

  <div id="viewadp-mini-calendar">
    <if @view@ eq "list">
      <include src="mini-calendar" base_url="view" view="@view@" date="@date@" period_days="@period_days@">
    </if>
    <else>
      <include src="mini-calendar" base_url="view" view="@view@" date="@date@">
    </else>
    <p>
    <a href="@add_item_url@" title="#calendar.Add_Item#" class="button">#calendar.Add_Item#</a>
    <if @admin_p@ true>
      <a href="admin/" title="#calendar.lt_Calendar_Administrati#" class="button">#calendar.lt_Calendar_Administrati#</a>
    </if>
    </p>
  
    <if @calendar_personal_p@ false>
	    <p>@notification_chunk;noquote@</p>
    </if>
  
    <include src="cal-options">	
   </div>

  <div id="viewadp-cal-table">
    <if @view@ eq "list">
      <include src="view-list-display"
        portlet_p="0"
        start_date="@start_date@"
        return_url="@return_url@"
        end_date="@end_date@"
        date="@date@"
        period_days="@period_days@"
        sort_by="@sort_by@"
        show_calendar_name_p="@show_calendar_name_p@"
        export="@export@"> 
    </if>

    <if @view@ eq "day">
      <include src="view-one-day-display"
        date="@date@" 
        start_display_hour="7"
        end_display_hour="22"
        return_url="@return_url@"
        calendar_url=""
        show_calendar_name_p="@show_calendar_name_p@">
    </if>
    
    <if @view@ eq "week">
      <include src="view-week-display"
        date="@date@"
        return_url="@return_url@"
        calendar_url=""
        show_calendar_name_p="@show_calendar_name_p@">
    </if>
    
    
    <if @view@ eq "month">
      <include src="view-month-display"
        date="@date@"
        return_url="@return_url@"
        calendar_url=""
        show_calendar_name_p="@show_calendar_name_p@">
    </if>
   </div>

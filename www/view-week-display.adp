<table class="cal-table-display" cellpadding="0" cellspacing="0" border="0" width="99%">
<tr>
    <td class="cal-month-title-text nobr">
	<a href="@previous_week_url@" title="#calendar.prev_week#"><img border=0 src="<%=[dt_left_arrow]%>" alt="#calendar.prev_week#"></a>
	@dates@
	<a href="@next_week_url@" title="#calendar.next_week#"><img border=0 src="<%=[dt_right_arrow]%>" alt="#calendar.next_week#"></a>
    </td>
</tr>
<tr>
  <td>
  
    <table cellpadding="0" cellspacing="0" border="0">
    <multiple name="items">
      <tr>
      <td valign=top class="cal-week">@items.start_date_weekday@:</td>
      <td width="95%" class="cal-week">
          <a href="@items.day_url@" title="#calendar.Go_to_date#">@items.start_date@</a>
          <a href="@items.add_url@" title="#calendar.Add_Item#">
          <img border="0" align="right" src="/resources/acs-subsite/add.gif" alt="#calendar.Add_Item#">
          </a>
      </td>
      </tr>
    
      <tr>
        <td class="cal-week-event" colspan=3>
        <if @items.event_name@ true>

	        <table class="cal-week-events" cellpadding="0" cellspacing="0">
	        <tbody>
	        <group column="day_of_week">
	          <if @items.event_name@ true>
	            <tr>
	            <td>
	            <if @items.no_time_p@ true>
	            <span class="cal-week-event-notime">
	            </if>
	            <if @items.no_time_p@ false>
	            @items.start_time@ - @items.end_time@
	            </if>
	            <a href="@items.event_url@" title="#calendar.goto_items_event_name#">@items.event_name@</a>
	            <if @items.no_time_p@ true>
	            </span>
	            </if>
	            <if @show_calendar_name_p@>
	              <span class="cal-text-grey-sml">[@items.calendar_name@]</span>
	            </if>
	            </td>
	            </tr>
	           </if>
	        </group>
	        </tbody>
	        </table>

        </if>
        </td>
       </tr>
      </td>
      </tr>
    </multiple>
    </table>



    
  </td>
</tr>
</table>

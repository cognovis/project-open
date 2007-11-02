<table class="cal-table-display" cellpadding="1" cellspacing="2" width="99%">
  <tr>
    <td class="cal-month-title-text nobr">
	<a href="@previous_week_url@" title="#calendar.prev_day#"><img border=0 src="<%=[dt_left_arrow]%>" alt="#calendar.prev_day#"></a>
	@dates@
	<a href="@next_week_url@" title="#calendar.next_day#"><img border=0 src="<%=[dt_right_arrow]%>" alt="#calendar.next_day#"></a>
    </td>
  </tr>
  <tr>
    <td>
      <table>
      <tr>
      <td>

	<table>
	<tr class="cal-row-light">
	<td class="cal-day-time">
		<a href="@item_add_without_time@" title="#calendar.Add_all_day_event#"><img border="0" src="/resources/acs-subsite/add.gif" alt="#calendar.Add_all_day_event#"> #calendar.Add_all_day_event#</a>
	</td>
	<td>
	
		<table> 
		<multiple name="items_without_time">
		      <tr>
		      <td class="cal-day-event-notime">
		      <a href="@items_without_time.event_url@" title="#calendar.goto_items_without_time_event_name#">@items_without_time.event_name@</a>
		      </td>
		      </tr>
		</multiple>
		</table>

	</td>
	</tr>

	<if @items:rowcount@ gt 0>
	<multiple name="items">
	<if @items.current_hour@ odd>
	  <tr class="odd">
	</if>
	<else>
	  <tr class="even">
	</else>
	    
			<td width="10%" class="cal-day-time">     
			  <nobr>
			  <a href="@items.add_url@" title="#calendar.Add_item_beginning_at#"><img border="0" src="/resources/acs-subsite/add.gif" alt="#calendar.Add_item_beginning_at#"> @items.localized_current_hour@</a>
			  </nobr>
			</td>
	    
			<group column="current_hour">
			  <if @items.event_name@ true>
			    <td class="cal-day-event" rowspan="@items.rowspan@"  colspan="@items.colspan@" valign="top">
			      <a href="@items.event_url@" title="#calendar.goto_items_event_name#">@items.event_name@  (@items.start_time@ - @items.end_time@)</a>
			      <if @show_calendar_name_p@>
				<span class="cal-text-grey-sml">@items.calendar_name@</span>
			      </if>
			    </td>
			  </if>
			</group>
	</tr>
	</multiple>
			</table>


	</if>


	  </td>
	</tr>
      </table>
    </td>
  </tr>
</table>

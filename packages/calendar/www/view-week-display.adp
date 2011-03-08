  <table id="cal-table-week" cellpadding="0" cellspacing="1" border="0" width="@week_width@@width_units@">
    <caption class="cal-table-caption">
      <a href="@previous_week_url@" title="#calendar.prev_week#"><img src="/resources/calendar/images/left.gif" alt="#calendar.prev_week#"></a>
      &nbsp;#calendar.Week_of# @dates@&nbsp;
      <a href="@next_week_url@" title="#calendar.next_week#"><img src="/resources/calendar/images/right.gif" alt="#calendar.next_week#"></a>
    </caption>

    <thead>
      <tr>
        <th id="hours">#calendar.Hours#</th>
        <multiple name="days_of_week">
          <th id="wday_@days_of_week.day_num@" style="width:@days_of_week.width@@width_units@">
            <a href="@days_of_week.weekday_url@" title="#calendar.goto_weekday#">@days_of_week.day_short@ @days_of_week.monthday@</a>
          </th>
        </multiple>
      </tr>
    </thead>

    <tbody>
      <tr>
        <td headers="hours" style="vertical-align: top; width:@time_of_day_width@@width_units@"><div class="day-time-1"><p>@grid_first_hour@</p></div></td>
        <td headers="wday_0" style="vertical-align: top; width:@day_width_0@@width_units@" class="week-event-1">
          <div class="week-entry-box">
            <multiple name="items">
              <div class="week-entry-item @items.style_class@" style="position: absolute; top:@items.top@@hour_height_units@; left: @items.left@@width_units@; height:@items.height@@hour_height_units@;">
                <p><if @items.num_attachments@ gt 0><img src="/resources/calendar/images/attach.png" alt=""></if><a href="@items.event_url@" title="#calendar.goto_items_event_name#">@items.event_name@</a></p>
              </div>
            </multiple>
          </div>
        </td>
        <td headers="wday_1" class="week-event-1" style="width:@day_width_1@@width_units@">&nbsp;</td>
        <td headers="wday_2" class="week-event-1" style="width:@day_width_2@@width_units@">&nbsp;</td>
        <td headers="wday_3" class="week-event-1" style="width:@day_width_3@@width_units@">&nbsp;</td>
        <td headers="wday_4" class="week-event-1" style="width:@day_width_4@@width_units@">&nbsp;</td>
        <td headers="wday_5" class="week-event-1" style="width:@day_width_5@@width_units@">&nbsp;</td>
        <td headers="wday_6" class="week-event-1" style="width:@day_width_6@@width_units@">&nbsp;</td>
      </tr>
      <multiple name="grid">
		<tr>
          <if @grid.rownum@ odd>
			<td headers="hours"><div class="day-time-2"><p>@grid.hour@</p></div></td>
            <multiple name="days_of_week">
              <td headers="wday_@days_of_week.day_num@" class="week-event-2"></td>
            </multiple>
          </if>
          <else>
			<td headers="hours"><div class="day-time-1"><p>@grid.hour@</p></div></td>
            <multiple name="days_of_week">
              <td headers="wday_@days_of_week.day_num@" class="week-event-1"></td>
            </multiple>
          </else>
		</tr>
      </multiple>
    </tbody>
  </table>

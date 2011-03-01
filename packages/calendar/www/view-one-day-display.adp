  <table id="cal-table-day" cellpadding="0" cellspacing="1" border="0" width="90%">
    <caption class="cal-table-caption">@pretty_date@</caption>
    <thead>
      <tr>
        <th id="hours">#calendar.Hours#</th>
        <th id="events">#calendar.Events#</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td headers="hours" style="vertical-align: top;"> <div class="day-time-1"><p><a href="@grid_first_add_url@" title="#calendar.Add_item_beginning_at#">@grid_first_hour@</a></p></div></td>
        <td headers="events" style="vertical-align: top; width:80%" class="day-event-1" valign="top">
          <div id="day-entry-box">
            <multiple name="items">
              <div id="day-entry-@items.rownum@" class="day-entry-item @items.style_class@" style="top: @items.top@@hour_height_units@; height: @items.height@@hour_height_units@; @items.style@"><p><if @items.num_attachments@ gt 0><img src="/resources/calendar/images/attach.png" alt=""></if><a href="@items.event_url@" title="#calendar.goto_items_event_name#">@items.event_name@</a></p></div>
            </multiple>
          </div><!-- day-entry-box -->
        </td>
      </tr>
      <multiple name="grid">
        <tr>
          <if @grid.rownum@ even>
            <td headers="hours"> <div class="day-time-1"><p><a href="@grid.add_url@" title="#calendar.Add_item_beginning_at#">@grid.hour@</a></p></div></td>
            <td headers="events" class="day-event-1" style="width: 80%" valign="top">
            </td>
          </if>
          <else>
            <td headers="hours"> <div class="day-time-2"><p><a href="@grid.add_url@" title="#calendar.Add_item_beginning_at#">@grid.hour@</a></p></div></td>
            <td headers="events" class="day-event-2" style="width: 80%" valign="top"></td>
          </else>
        </tr>
      </multiple>
    </tbody>
  </table>

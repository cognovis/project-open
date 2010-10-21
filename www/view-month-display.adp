  <table class="cal-month-table" cellpadding="0" cellspacing="0" border="0" width="90%">

    <caption class="cal-table-caption">
      <a href="@previous_month_url@#calendar" title="#calendar.prev_month#"><img src="/resources/calendar/images/left.gif" alt="#calendar.prev_month#"></a>
      &nbsp;@month_string@ @year@&nbsp;
      <a href="@next_month_url@#calendar" title="#calendar.next_month#"><img src="/resources/calendar/images/right.gif" alt="#calendar.next_month#"></a>
    </caption>

    <thead>
      <tr>
        <multiple name="weekday_names">
          <th id="mday_@weekday_names.weekday_num@">
            @weekday_names.weekday_long@
          </th>
        </multiple>
      </tr>
    </thead>

    <tbody>

      <multiple name="items">

        <if @items.beginning_of_week_p@ true>
          <tr>
        </if>

        <if @items.outside_month_p@ true>
          <td class="cal-month-day-inactive" style="width: 14%;">&nbsp;</td>
        </if>     
        <else>
          <if @items.today_p@ true>
            <td headers="mday_@items.weekday_num@" class="cal-month-today"  style="width: 14%;" onclick="javascript:location.href='@items.add_url@';" onkeypress="javascript:acs_KeypressGoto('@items.add_url@',event);">
          </if>
          <else>
            <td headers="mday_@items.weekday_num@" class="cal-month-day"  style="width: 14%;" onclick="javascript:location.href='@items.add_url@';"onkeypress="javascript:acs_KeypressGoto('@items.add_url@',event);">
          </else>
          &nbsp;<span class="screen-reader-only">[</span><a href="@items.day_url@" title="#calendar.goto_day_items_pretty_date#">@items.day_number@</a><span class="screen-reader-only"> ]</span>

          <group column="day_number">
            <if @items.event_name@ true>
              <div class="cal-month-event @items.style_class@">
                <a href="@items.event_url@" title="#calendar.goto_items_event_name#">
                  <if @items.time_p@ true>@items.start_time@</if>
                  @items.event_name@
                  <if @items.num_attachments@ gt 0><img src="/resources/calendar/images/attach.png" alt=""></if>
                  <if @show_calendar_name_p@>
                    <span class="cal-text-grey-sml"> [@items.calendar_name@]</span>
                  </if>
                </a>
              </div>
            </if>
          </group>

        </td>
        </else>

        <if @items.end_of_week_p@ true>
          </tr>
        </if>

      </multiple>

    </tbody>
  </table>

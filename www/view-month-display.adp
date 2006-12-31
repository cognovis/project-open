 <table class="cal-table-display" cellpadding="0" cellspacing="0" border="0" width="99%">
  <tr>
    <td class="cal-month-title-text" colspan="7">
      <a href="@previous_month_url;noquote@" title="#calendar.prev_month#"><img border=0 src="<%=[dt_left_arrow]%>" alt="#calendar.prev_month#"></a>
      @month_string@ @year@
      <a href="@next_month_url;noquote@" title="#calendar.next_month#"><img border=0 src="<%=[dt_right_arrow]%>" alt="#calendar.next_month#"></a>
    </td>
  </tr>
  <tr>
    <td>

      <table class="cal-month-table" cellpadding="2" cellspacing="2" border="5">
        <tbody>
          <tr>
            <multiple name="weekday_names">
              <th width="14%" class="cal-month-day-title">
                @weekday_names.weekday_short@
              </th>
            </multiple>
          </tr>

          <tr>
            <multiple name="items">
              <if @items.beginning_of_week_p@ true>
                <tr>
              </if>

              <if @items.outside_month_p@ true>
                <td class="cal-month-day-inactive">&nbsp;</td>
              </if>     
              <else>
                <if @items.today_p@ true>
                  <td class="cal-month-today" <if @items.day_url@ not nil>onclick="javascript:location.href='@items.day_url@';"</if>>
                </if>
                <else>
                  <td class="cal-month-day" <if @items.day_url@ not nil>onclick="javascript:location.href='@items.day_url@';"</if>>
                </else>
                  <if @items.day_url@ not nil>
                     <a href="@items.day_url@" title="#calendar.goto_day_items_day_number#">@items.day_number@</a> <if @add_p@><a href="@items.add_url@" title="#calendar.Add_Item#"><img border="0" src="/resources/acs-subsite/add.gif" alt="#calendar.Add_Item#"></a></if>
                    </if>
                    <else>
                     @items.day_number@
                    </else>

                  <group column="day_number">
                    <if @items.event_name@ true>
                      <div class="cal-month-event">
                        <if @items.time_p@ true>@items.ansi_start_time@</if>
                        <a href="@items.event_url@" title="#calendar.goto_items_event_name#">@items.event_name@</a>
                        <if @show_calendar_name_p@>
                          <span class="cal-text-grey-sml"><if @show_calendar_name_p@>[@items.calendar_name@]</if> </span>
                        </if>
                      </div>
                    </if>
                  </group>

                </td>
              </else>
              <if @items.end_of_week_p@ true>
                </tr>
              </if>
            </multiple>

          </tr>
        </tbody>
      </table>
    </td>
  </tr>
</table>





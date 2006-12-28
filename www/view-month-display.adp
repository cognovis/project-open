 <table class="cal-table-display" cellpadding="0" cellspacing="0" border="0" width="99%">
  <tr>
    <td class="cal-month-title-text" colspan="7">
      <a href="@previous_month_url@"><img border=0 src="<%=[dt_left_arrow]%>" alt="back one month"></a>
      @month_string@ @year@
      <a href="@next_month_url@"><img border=0 src="<%=[dt_right_arrow]%>" alt="forward one month"></a>
    </td>
  </tr>
  <tr>
    <td>

      <table class="cal-month-table" cellpadding="2" cellspacing="2" border="5">
        <tbody>
          <tr>
            <multiple name="weekday_names">
              <td width="14%" class="cal-month-day-title">
                @weekday_names.weekday_short@
              </td>
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
                  <td class="cal-month-today" onclick="javascript:location.href='@items.add_url@';">
                </if>
                <else>
                  <td class="cal-month-day" onclick="javascript:location.href='@items.add_url@';">
                </else>
                  <a href="@items.day_url@">@items.day_number@</a>

                  <group column="day_number">
                    <if @items.event_name@ true>
                      <div class="cal-month-event">
                        <if @items.time_p@ true>@items.ansi_start_time@</if>
                        <a href=@items.event_url@>@items.event_name@</a>
                        <if @show_calendar_name_p@>
                          <span class="cal-text-grey-sml"> [@items.calendar_name@]</span>
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





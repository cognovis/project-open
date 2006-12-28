<table class="cal-table-display" cellpadding="1" cellspacing="2" width="99%">
  <tr>
    <td class="cal-month-title-text">
      <a href="@previous_week_url@"><img border=0 src="<%=[dt_left_arrow]%>" alt="back one day"></a>
      @dates@
      <a href="@next_week_url@"><img border=0 src="<%=[dt_right_arrow]%>" alt="forward one day"></a>
    </td>
  </tr>
  <tr>
    <td>
      <table>
      <tr>
      <td>
        <tr>
          <td>
            <tr class="cal-row-light">
            <td width="1%" class="cal-day-time"><a href="@item_add_without_time@"><img border="0" align="left" src="/resources/acs-subsite/add.gif" alt="No Time"></a></td>
            <td>
            <table> 
              <multiple name="items_without_time">
              <tr>
              <td class="cal-day-event-notime">
              <a href="@items_without_time.event_url@">@items_without_time.event_name@</a>
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
                  <a href="@items.add_url@">@items.localized_current_hour@</a>
                </td>
    
                <group column="current_hour">
                  <if @items.event_name@ true>
                    <td class="cal-day-event" rowspan="@items.rowspan@"  colspan="@items.colspan@" valign="top">
                      <a href="@items.event_url@">@items.event_name@  (@items.start_time@ - @items.end_time@)</a>
                      <if @show_calendar_name_p@>
                        <span class="cal-text-grey-sml">@items.calendar_name@</span>
                      </if>
                    </td>
                  </if>
                </group>
                </tr>
               </multiple>
             </if>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>

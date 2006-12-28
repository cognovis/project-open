 <table class="cal-table-display" cellpadding="0" cellspacing="0" border="0" width="99%">
<tr>
<td>
          <form name="frmdays" class="cal-frm-compact">
            <table width="100%" cellspacing="0" cellpadding="0" border="0">
              <tbody><tr valign="middle">
                <td align="left">
                  <h5>@title@</h5>
                </td>
                <td align="right">
                  #calendar.Events_over_a#
                  <input type="text" class="cal-field" id="period_days" name="period_days" value="@period_days@" size="3" maxlength="3">
                  #calendar.day_rolling_period#
                  <input class="cal-button-sml" type="submit" value="#acs-kernel.common_go#">
                  @form_vars;noquote@
                </td>
              </tr>
            </tbody></table>
          </form>


<if @items:rowcount@ gt 0>
        
<table class="cal-table-display" border=0 cellspacing=0 cellpadding=2>
  <tr class="cal-table-header">
  <th align=left>#acs-datetime.Day_of_Week#</th>
  <th align="center"><a href="@start_date_url@">#calendar.Date_1#</a></th>
  <th align="center">#calendar.Start_Time#</th>
  <th align="center">#calendar.End_Time#</th>
  <th align="center"><a href="@item_type_url@">#calendar.Type_1#</a></th>
  <th align=left>Title</th></tr>

  <multiple name="items">

  <group column="weekday">

  <if @items.flip@ odd>
    <tr class="cal-row-dark">
  </if>
  <else>
    <tr class="cal-row-light">
  </else>  

  <td class="@items.today@" align=left>@items.weekday@</td>
  <td class="@items.today@" align="center">@items.start_date@</td>
  <td class="@items.today@" align="center">@items.start_time@</td>
  <td class="@items.today@" align="center">@items.end_time@</td>
  <td class="@items.today@" align="center">@items.item_type@</td>
  <td class="@items.today@"
  align=left><a href="@items.event_url@">@items.event_name@</a>

  <if @show_calendar_name_p@>
  (@items.calendar_name@)
  </if>
  </td>

  </tr>

  </group>
  </multiple>
</table>
</if>
<else>
<i>#calendar.No_Items#</i>
</else>
</td>
</tr>
</table>

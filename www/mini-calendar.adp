<table class="mini-calendar" cellpadding="0" cellspacing="0">
  <tr class="view-list">
    <multiple name="views">
      <if @views.active_p@ true>
        <td class="selected">
          <a href="@views.url@" title="#calendar.select_views_name#">@views.name@</a>
        </td>
      </if>
      <else>
        <td>
          <a href="@views.url@" title="#calendar.select_views_name#">@views.name@</a>
        </td>
      </else>
    </multiple>
  </tr>
  
  <tr>
    <td colspan="4">
      <table class="header" cellspacing="0" cellpadding="0">
        <tr>
          <if @view@ eq "month">
            <td class="back">
              <a href="@prev_year_url@" title="#calendar.prev_year#""><img border="0" src="/resources/acs-subsite/left.gif" alt="#calendar.prev_year#"></a>
            </td>
            <td class="current_view" colspan="2">@curr_year@</td>
            <td class="forward">
              <a href="@next_year_url@" title="#calendar.next_year#"><img border="0" src="/resources/acs-subsite/right.gif" alt="#calendar.next_year#"></a>
            </td>
          </if>
          <else>
            <td class="back">
              <a href="@prev_month_url@" title="#calendar.prev_month#"><img border=0 src="/resources/acs-subsite/left.gif" alt="#calendar.prev_month#"></a>
            </td>
            <td class="current_view" colspan="2">@curr_month@</td>
            <td class="forward">
              <a href="@next_month_url@" title="#calendar.next_month#"><img border=0 src="/resources/acs-subsite/right.gif" alt="#calendar.next_month#"></a>
            </td>
          </else>
        </tr>
      </table>
    </td>
  </tr>
    
  
  <tr>
    <td colspan="4">
      <table id="at-a-glance" cellspacing="0" cellpadding="0">

        <if @view@ eq month>
          <multiple name="months">
             <if @months.new_row_p@ true>
              </tr><tr>
            </if>
             <if @months.current_month_p@ true>
              <td class="months selected"><a href="@months.url@" title="#calendar.goto_months_name#">@months.name@</a></td>
            </if>
            <else>
              <td class="months"><a href="@months.url@" title="#calendar.goto_months_name#">@months.name@</a></td>
            </else>         
           </multiple>
        </if>

        <else>
          <tr class="days">
            <multiple name="days_of_week">
              <th>@days_of_week.day_short@</th>
            </multiple>
          </tr>
      
          <multiple name="days">
            <if @days.beginning_of_week_p@ true>
              <tr>
            </if>
        
            <if @days.active_p@ true>
              <if @days.today_p@ true>
                <td class="today" onclick="javascript:location.href='@days.url@';">
                  <a href="@days.url@" title="#calendar.goto_days_day_number#">@days.day_number@</a>
                </td>
              </if>
              <else>
                <td class="active" onclick="javascript:location.href='@days.url@';">
                  <a href="@days.url@"  title="#calendar.goto_days_day_number#">@days.day_number@</a>
                </td>
              </else>
            </if>
            <else>
              <td class="inactive" onclick="javascript:location.href='@days.url@';">
                <a href="@days.url@"  title="#calendar.goto_days_day_number#">@days.day_number@</a>
              </td>
            </else>
        
            <if @days.end_of_week_p@ true>
              </tr>
            </if>
          </multiple>
        </else>
 
      </table>
  
    </td>
  </tr>
  <tr id="jump">
    <td colspan="4">
      <p>  
      <if @today_p@ true>
        #acs-datetime.Today#
      </if>
      <else>
        <a href="@today_url@" title="#calendar.goto_today#">#acs-datetime.Today#</a> 
       </else>
  
      #acs-datetime.is# <%=[dt_ansi_to_pretty]%>
      </p>  

      <form method=get action=@base_url@>
        <input type="text" name="date" size="10"> 
        <input type="image" src="/resources/acs-subsite/go.gif" name="#calendar.Go_to_date#" alt="#calendar.Go_to_date#" border="0">
        <br>#acs-datetime.Date_as_YYYYMMDD#
        <input type="hidden" name="view" value="day">
        @form_vars;noquote@
        @page_num_formvar;noquote@
      </form>
    </td>
  </tr>
</table>

<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">@main_navbar_label@</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<form>
<table border=0 cellspacing=1 cellpadding=1>
<tr valign=top><td>
        <table border=0 cellspacing=1 cellpadding=1>
        <tr>
          <td class=form-label>Start Date</td>
          <td class=form-widget>
            <input type=textfield name=start_date value=@start_date@>
          </td>
        </tr>
        <tr>
          <td class=form-label>End Date</td>
          <td class=form-widget>
            <input type=textfield name=end_date value=@end_date@>
          </td>
        </tr>
        <tr>
          <td class=form-label></td>
          <td class=form-widget><input type=submit value=Submit></td>
        </tr>
        </table>
</td><td>
        <table border=0 cellspacing=1 cellpadding=1>
        </table>
</td></tr>
</table>
</form>


@html;noquote@


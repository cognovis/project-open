<table width="100%" cellspacing=0 cellpadding=0 border=0>
  <tr>
    <td bgcolor=#cccccc>
      <table width="100%" cellspacing=1 cellpadding=4 border=0>
        <tr bgcolor=#ccccff>
          <td colspan=2>
            <table width="100%" cellspacing="0" cellpadding="0" border="0">
              <tr>
                <td width="25%">
                  
                  (<a href="@transition.assignment_url@">assignment</a>)
                  (<a href="@transition.attributes_url@">attributes</a>)
                  (<a href="@transition.actions_url@">actions</a>)
                </td>
                <th align=center valign=middle>
                  Task: @transition.transition_name@
                  (<a href="@transition.edit_url@">edit</a>)
                </th>
                <td align="right" width="25%">
                  <if @transitions.delete_url@ not nil>
                    (<a href="@transition.delete_url@">delete task</a>)
                  </if>
                  <else>
                    &nbsp;
                  </else>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        <tr bgcolor=#ffffe4>
          <th width="50%">Input Places</th>
          <th width="50%">Output Places</th>
        </tr>
        <tr bgcolor=#eeeeee>
          <td valign="top">
            <dl>
              <multiple name="input_places">
                <dt>
                  <a href="@input_places.url@">@input_places.place_name@</a>
                </dt>
                <dd>
                  <if @input_places.arc_delete_url@ not nil>
                    (<a href="@input_places.arc_delete_url@">delete arc</a>)
                  </if>
                </dd>
              </multiple>
            </dl>
          </td>
          <td valign="top">
            <dl>
              <multiple name="output_places">
                <dt>
                  <a href="@output_places.url@">@output_places.place_name@</a>
                  <if @output_places.guard_pretty@ not nil><font color=red>[ @output_places.guard_pretty@ ]</font></if>
                </dt>
                <dd>
                  <if @output_places.guard_pretty@ not nil>
                    (<a href="@output_places.guard_edit_url@">edit guard</a>)
                    (<a href="@output_places.guard_delete_url@">delete guard</a>)
                  </if>
                  <else>
                    (<a href="@output_places.guard_add_url@">add guard</a>)
                  </else>
                  <if @output_places.arc_delete_url@ not nil>
                    (<a href="@output_places.arc_delete_url@">delete arc</a>)
                  </if>
                </dd>
              </multiple>
            </dl>
          </td>
        </tr>
        <tr bgcolor=#eeeeee>
          <td>&nbsp;</td>
          <td align=center>
            &nbsp;
            <if @transition.arc_add_url@ not nil>
              (<a href="@transition.arc_add_url@">add arc</a>)
            </if>
            <if @transition.arc_delete_url@ not nil>
              (<a href="@transition.arc_delete_url@">delete arc</a>)
            </if>
            &nbsp;
          </th>
        </tr>
      </table>
    </td>
  </tr>
</table>
            


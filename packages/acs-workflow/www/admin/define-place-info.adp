<table width="100%" cellspacing=0 cellpadding=0 border=0>
  <tr>
    <td bgcolor=#cccccc>
      <table width="100%" cellspacing=1 cellpadding=4 border=0>
        <tr bgcolor=#ccccff>
          <td colspan=2>

            <table width="100%" cellspacing=0 cellpadding=0 border=0>
              <tr>
                <td width="20%">&nbsp;</td>
                <th align=center>
                  Place: @place.place_name@
                  (<a href="@place.edit_url@">edit</a>)
                </th>
                <td align=right width="20%">
                  <if @place.delete_url@ not nil>
                    (<a href="@place.delete_url@">delete place</a>)
                  </if>
                  <else>
                    (can't delete place)
                  </else>
                </td>
              </tr>
            </table>

          </td>
        </tr>
        <tr bgcolor=#ffffe4>
          <th width="50%">Producing Transitions</th>
          <th width="50%">Consuming Transitions</th>
        </tr>
        <tr bgcolor=#eeeeee>
          <td valign="top">
            <dl>
              <multiple name="producing_transitions">
                <dt>
                  <a href="@producing_transitions.url@">@producing_transitions.transition_name@</a>
                  <if @producing_transitions.guard_pretty@ not nil>
                    <font color=red>[ @producing_transitions.guard_pretty@ ]</font>
                  </if>
                </dt>
                <dd>
                  <if @producing_transitions.guard_pretty@ not nil>
                    (<a href="@producing_transitions.guard_edit_url@">edit guard</a>)
                    (<a href="@producing_transitions.guard_delete_url@">delete guard</a>)
                  </if>
                  <else>
                    (<a href="@producing_transitions.guard_add_url@">add guard</a>)
                  </else>
                  <if @producing_transitions.arc_delete_url@ not nil>
                    (<a href="@producing_transitions.arc_delete_url@">delete arc</a>)
                  </if>
                </dd>
              </multiple>
            </dl>
          </td>
          <td valign="top">
            <dl>
              <multiple name="consuming_transitions">
                <dt>
                  <a href="@consuming_transitions.url@">@consuming_transitions.transition_name@</a>
                </dt>
                <dd>
                  <if @consuming_transitions.arc_delete_url@ not nil>
                    (<a href="@consuming_transitions.arc_delete_url@">delete arc</a>)
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
            <if @place.arc_add_url@ not nil>
              (<a href="@place.arc_add_url@">add arc</a>)
            </if>
	    <else>
		(can't add arc)
	    </else>
            <if @place.arc_delete_url@ not nil>
              (<a href="@place.arc_delete_url@">delete arc</a>)
            </if>
	    <else>
		(can't delete arc)
	    </else>
            &nbsp;
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>


<master>
<property name="title">@workflow_name;noquote@ Summary</property>
<property name="context">@context;noquote@</property>

<h3><a href="@cases_url_for_state.active@">@num_cases_in_state.active@</a> Active Cases</h3>

<if @workflow_img_tag@ not nil>
  <center>
    @workflow_img_tag;noquote@
  </center>
</if>

<p>

<if @simple_p@ ne 1>
  <h3>Started</h3>
  <blockquote>
    <table cellspacing="0" cellpadding="0" border="0">
      <tr>
	<td bgcolor="#cccccc">
	  <table width="100%" cellspacing="1" cellpadding="4" border="0">
	    <tr bgcolor="#ffffe4">
	      <th align="left">Task</th>
	      <th align="left">Number of cases</th>
	      <th align="left">Graph</th>
	    </tr>
	    <multiple name="transitions">
	      <tr valign="middle" bgcolor="#eeeeee">
		<td>@transitions.transition_name@</td>
		<td align="center">
		  <if @transitions.num_cases@ gt 0>
		      <a href="@transitions.cases_url@">&nbsp;@transitions.num_cases@&nbsp;</a>
		  </if>
		</td>
		<td>
		  <if @transitions.num_cases@ gt 0>
		    <img src="pixel-blue.gif" height="8" width="@transitions.num_pixels@" alt="graph">
		  </if>
		</td>
	      </tr>
	    </multiple>
	  </table>
	</td>
      </tr>
    </table>
  </blockquote>

  <h3>Pending</h3>
  <blockquote>
    <table cellspacing="0" cellpadding="0" border="0">
      <tr>
	<td bgcolor="#cccccc">
	  <table width="100%" cellspacing="1" cellpadding="4" border="0">
	    <tr bgcolor="#ffffe4">
	      <th align="left">State</th>
	      <th align="left">Number of cases</th>
	      <th align="left">Graph</th>
	    </tr>
	    <multiple name="places">
	      <tr valign="middle" bgcolor="#eeeeee">
		<td>@places.place_name@</td>
		<td align="center">
		  <if @places.num_cases@ gt 0>
		    <a href="@places.cases_url@">&nbsp;@places.num_cases@&nbsp;</a>
		  </if>
		</td>
		<td>
		  <if @places.num_cases@ gt 0>
		    <img src="pixel-blue.gif" height="8" width="@places.num_pixels@" alt="graph">
		  </if>
		</td>
	      </tr>
	    </multiple>
	  </table>
	</td>
      </tr>
    </table>
  </blockquote>
</if>


<else>
  <h3>State Chart</h3>
  <table cellspacing="0" cellpadding="0" border="0">
    <tr>
      <td bgcolor="#cccccc">
        <table width="100%" cellspacing="1" cellpadding="4" border="0">
          <tr bgcolor="#ffffe4">
            <th align="left">Task</th>
            <multiple name="simple_steps">
	      <td bgcolor="#ffffe4" align="center">
                <if @simple_steps.type@ eq "place">@simple_steps.name@</if>
                <if @simple_steps.type@ eq "transition"><b>@simple_steps.name@</b></if>
              </td>
            </multiple>
          </tr>
          <tr bgcolor="#ffffe4">
            <th align="left">Number of cases</th>
            <multiple name="simple_steps">
              <td bgcolor="#eeeeee" align="center">@simple_steps.num_cases@</td>
            </multiple>
	  </tr>
	</table>
      </td>
    </tr>
  </table>
</else>
    
</master>

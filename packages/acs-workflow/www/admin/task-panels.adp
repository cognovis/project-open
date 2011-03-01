<master>
<property name="title">Panels for @transition_name;noquote@</property>
<property name="context">@context;noquote@</property>

<!--
Context: [ 
  <multiple name="context_slider">
    <if @context_slider.rownum@ ne 1>|</if>
    <if @context_slider.selected_p@ eq 1><b>@context_slider.title@</b></if>
    <else><a href="@context_slider.url@">@context_slider.title@</a></else>
  </multiple>
]
(<a href="@context_add_url@">create new context</a>)
-->

<p>

<table>
  <tr>
    <td width="10%">&nbsp;</td>
    <td>
      <table cellspacing="0" cellpadding="0" border="0">
	<tr>
	  <td bgcolor="#cccccc">
	    <table width="100%" cellspacing=1 cellpadding=4 border="0">
              <tr bgcolor="#ffffe4">
		<th>No.</th>
		<th>Header</th>
		<th>URL</th>
                <th>Action</th>
              </tr>
              <if @panels:rowcount@ eq 0>
                 <tr bgcolor="#eeeeee">
                   <td colspan="4">
                     <em>No panels</em>
                   </td>
                 </tr>
              </if>
              <else>
		<multiple name="panels">
		  <tr bgcolor="#eeeeee">
		    <td align="right">@panels.sort_order@.</td>
		    <td>@panels.header@</td>
		    <td><code>@panels.template_url@</code></td>
		    <td>
		      <if @panels.edit_url@ not nil>
			(<a href="@panels.edit_url@">edit</a>)
		      </if>
		      <if @panels.delete_url@ not nil>
			(<a href="@panels.delete_url@">delete</a>)
		      </if>
		      <if @panels.move_up_url@ not nil>
			(<a href="@panels.move_up_url@">move up</a>)
		      </if>
		    </td>
		  </tr>
		</multiple>    
              </else>
            </table>
          </td>
        </tr>
      </table>
    </td>
    <td width="10%">&nbsp;</td>
  </tr>

  <tr><td colspan="3">&nbsp;</td></tr>

  <tr>
    <td>&nbsp;</td>
    <td colspan="2">(<a href="@panel_add_url@">add panel</a>)</td>
  </tr>

  <tr><td colspan=3>&nbsp;</td></tr>

  <form action="define" method="post">
  <input type="hidden" name="workflow_key" value="@workflow_key@" />
  <input type="hidden" name="transition_key" value="@transition_key@" />
  <tr bgcolor="#dddddd">
    <td colspan="3" align="right">
      <input type=submit value="Done" />
    </td>
  </tr>
  </form>
</table>

</master>

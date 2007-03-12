<property name="focus">@focus;noquote@</property>


<table>
<tr>
  <td>
	<div id="register-login">
	<formtemplate id="login"></formtemplate>
	</div>
  </td>
</tr>
<tr>
  <td>

	<table cellspacing=0 cellpadding=0 border=0 width="100%">
	<tr valign=center>
	<td>
		<if @forgotten_pwd_url@ not nil>
		  <if @email_forgotten_password_p@ true>
		  <a href="@forgotten_pwd_url@">#acs-subsite.Forgot_your_password#</a>
		  <br />
		  </if>
		</if>
		
		<if @self_registration@ true>
		
		<if @register_url@ not nil>
		  <a href="@register_url@">#acs-subsite.Register#</a>
		</if>
		
		</if>
	</td>
	<td align=right>
		<table>
		  <tr><td align=center>Powered by</td></tr>
		  <tr>
		    <td align=center>
		      <a href="http://www.project-open.com/">
		        <img 
			  src="/intranet/images/project_open.70x26.gif" 
			  alt="Open Source based Project Management" 
			  title="Open Source based Project Management, Collaboration, Controlling and Workflow" 
			  border=0
		        >
		      </a>
		    </td>
		  </tr>
		</table>
	</td>
	</tr>
	</table>

  </td>
</tr>
</table>

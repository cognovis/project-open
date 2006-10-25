<master src="../lib/master">
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>
<if @notification_link@ not nil><property name="notification_link">@notification_link;noquote@</property></if>

<p>
  <formtemplate id="bug"></formtemplate>
</p>

<if @user_id@ eq 0>
  <p>
    You're not logged in. For more options, <a href="@login_url@">log in now</a>.
  </p>
</if>

<if @enabled_action_id@ nil>
  <div style="font-size: 75%;" align="right">
    <if @user_agent_p@ false>
      (<a href="@show_user_agent_url@">show user agent</a>)
    </if>
    <else>
      (<a href="@hide_user_agent_url@">hide user agent</a>)
    </else>
  </div>
</if>


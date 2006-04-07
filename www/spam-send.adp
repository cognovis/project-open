<master src=../../intranet-core/www/master>
<property name="context">@context;noquote@</property>
<property name="title">#intranet-core.Spam_Queued#</property>
<property name="main_navbar_label">admin</property>

<h1>Success!</h1>

<if @approved_p@ eq f> 
  <p> This message requires administrative approval before it will be sent.
</if>

<p>You can <a href="spam-edit?spam_id=@spam_id@">edit your message</a> 
before it gets sent out.

<p>
Here is the message that we have sent out:
</p>

<pre>@subject_subs@</pre>
<pre>@body_plain_subs@</pre>

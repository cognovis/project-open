<master>
<property name="title">Subscription Change Complete</property>
<property name="context">@context;noquote@</property>

You may now
<ul>
<li><a href="@review_url@">Review your subscription</a>.</li>
<if @return_url@ not nil>
<li><a href="@return_url@">Return to where you were</a>.</li>
</if>
</ul>

<master src=../../intranet-core/www/master>
<property name="context">@context;noquote@</property>
<property name="title">#intranet-core.Spam_Show_Users#</property>
<property name="main_navbar_label">admin</property>

<h1>Spamming Users</h1>

<p>    
The following people are about to receive your spam:
</p>

<ul>
 <multiple name="spam_list">
 <if @spam_list.name@ nil>
   <li>@spam_list.email@
 </if>
 <else>
  <li>@spam_list.name@ (@spam_list.email@)
 </else>
 </multiple>
</ul>
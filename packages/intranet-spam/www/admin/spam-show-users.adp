<master>
<property name="title">Show spam recipients</property>
<property name="context">"show recipients"</property>

The following people are about to receive your spam:

<ul>
 <multiple name="spam_list">
 <if @spam_list.name@ nil>
   <li>@spam_list.email@</li>
 </if>
 <else>
  <li>@spam_list.name@ (@spam_list.email@)</li>
 </else>
 </multiple>
</ul>
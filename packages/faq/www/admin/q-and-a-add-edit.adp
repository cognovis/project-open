<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>
<property name="focus">new_quest_answ.question</property>

<formtemplate id="new_quest_answ"></formtemplate>
<if @use_categories_p@ and @category_container@ eq "package_id">
    <a href="@category_map_url@" class="action_link">#categories.Site_wide_categories#</a>
</if>

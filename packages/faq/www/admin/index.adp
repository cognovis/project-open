<master>
<property name="title">@title;noquote@</property>
<property name="context">@context;noquote@</property>
<h1>@title;noquote@</h1>
<listtemplate name="faqs"></listtemplate>

<ul class="action-links">
    <li><a href="faq-add-edit" title="#faq.Create_a_new_FAQ#">#faq.Create_a_new_FAQ#</a></li>
    <li><a href="configure?<%=[export_url_vars return_url]%>" title="#faq.Configure_FAQ_Preferences#">#faq.Configure#</a></li>
    <if @use_categories_p@ and @category_container@ eq "package_id">
        <li><a href="@category_map_url@" class="action_link" title="#faq.Site_wide_categories#">#faq.Site_wide_categories#</a></li>
    </if>
</ul>

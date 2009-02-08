<if @contact_master_template@ eq /packages/intranet-contacts/lib/contact-master>
  <master src=/packages/intranet-core/www/master>
  <property name="title">@title@</property>
  <property name="context">@context@</property>
  <if @focus@ not nil>
    <property name="focus">@focus@</property>
  </if>
  <property name="navbar_list">@navbar@</property>
  <property name="sub_navbar">@contacts_navbar_html;noquote@</property>
</if>
<else>
  <master src="@contact_master_template@">
  <property name="party_id">@party_id@</property>
  <if @title@ not nil><property name="title">@title;noquote@</property></if>
  <if @context@ not nil><property name="context">@context;noquote@</property></if>
</else>

<slave>

<% set page_title "V[string range [im_core_version] 0 5]" %>

<master>
  <property name="title">#acs-subsite.Log_In#</property>
  <property name="context">{#acs-subsite.Log_In#}</property>

<include src="@login_template@" return_url="@return_url;noquote@" no_frame_p="1" authority_id="@authority_id@" username="@username;noquote@" email="@email;noquote@" &="__adp_properties">

<table cellSpacing=0 cellPadding=5 width="100%" border=0>
  <tr><td>
        <br><br><br>
    Comments? Contact:
    <A href="mailto:support@project-open.com">support@project-open.com</A>
  </td></tr>
</table>



<!-- packages/intranet-confdb/www/new.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master>
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">conf_items</property>

<h2>@page_title@</h2>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<if @form_mode@ eq "display" >
<table width="100%">
  <tr valign="top">
    <td width="50%">

	      <table cellpadding=2 cellspacing=0 border=1 frame=void width='100%'>
	        <tr>
	         <td class=tableheader align=left width='99%'>
		   <%= [lang::message::lookup "" intranet-confdb.Conf_Item "Configuration Item"] %>
		 </td>
	        </tr>
	        <tr>
	          <td class=tablebody>
</if>
	    <formtemplate id=form></formtemplate>
<if @form_mode@ eq "display" >
		  </td>
	        </tr>
	      </table>
      <br>
      <%= [im_component_bay left] %>
    </td>
    <td width="50%">

	      <table cellpadding=2 cellspacing=0 border=1 frame=void width='100%'>
	        <tr>
	         <td class=tableheader align=left width='99%'>
	<%= [lang::message::lookup "" intranet-confdb.Assoc_Projects "Associated Projects"] %>
	         </td>
	        </tr>
	        <tr>
	          <td class=tablebody>
		    <listtemplate name="assoc_projects"></listtemplate>
	          </td>
	        </tr>
	      </table>


	<br>
      <%= [im_component_bay right] %>
    </td>
  </tr>
</table>
</if>

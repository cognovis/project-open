<master>
<property name="context">@context;noquote@</property>
<property name="title">@title;noquote@</property>
<property name="header_stuff"><SCRIPT Language="JavaScript" src="/resources/diagram/diagram/diagram.js"></SCRIPT></property>



<table>
  <tr>
   <td>
   <h1> #monitoring.Detail#: @mounted@</h1>
   <li> #monitoring.Frequency#:@df_frequency@ #monitoring.hours# 
   <li> total de registros:@total@ - exibidos @start@ a @end@
   <li>
   <form action="detail" method="get">
   <input type="text" name="limit" value="@limit@" size="2">
   <input type="hidden" name="mounted" value="@mounted@">
   <input type="submit" value="Quantidade de Registros" name="dflog" >
   </form>
   
   </td>
  </tr>
  <tr>
   <td>
      <diagram name="disk_detail"></diagram>
   </td>
  </tr>
</table>

<table align="right">
  <tr>
    <td>
      <multiple name="links">
        <a href="@links.url@">@links.value@</a>
        <if @links.rownum@ ne @links:rowcount@> | </if>
      </multiple>
    </td>
  </tr>
</table>
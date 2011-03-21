  <table valign="top" align="center">
    <multiple name="project_info">
      <if @project_info.heading@ not nil>
        <tr>
          <td colspan="2" align="left">
            <h3 class="contact-title">@project_info.heading@</h3>
          </td>
        </tr>
      </if>
      <tr>
        <td align="right" valign="top" class="attribute">@project_info.field;noquote@:</td>
        <td align="left" valign="top" class="value">@project_info.value;noquote@</td>
      </tr>
    </multiple>
    <tr>
      <td>
        <form action="/intranet-cust-berendsen/projektantrag" method="POST">
          <input type="hidden" name="project_id" value="@project_id@" />
            <input type="hidden" name="return_url" value="@return_url@" />
              <input type="submit" value="#intranet-cust-berendsen.Projektantrag#" name="submit1" />
        </form>
      </td>
      <if @write@ and @edit_project_base_data_p@>
        <td>
          <form action="/intranet-cust-berendsen/projects/project-ae" method="POST">
            <input type="hidden" name="project_id" value="@project_id@" />
              <input type="hidden" name="return_url" value="@return_url@" />
                <input type="submit" value="#intranet-core.Edit#" name="submit3" />
          </form>
        </td>
      </if>
      <else>
        <td> &nbsp; </td>
      </else>
    </tr>
  </table>
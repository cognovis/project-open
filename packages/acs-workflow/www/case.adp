<master>
<property name="title">@case.object_name;noquote@ case</property>
<property name="context">@context;noquote@</property>

<table width="100%" cellspacing="4" cellpadding="2" border="0">
  <tr>
    <td valign="top">

      <!-- Left side --> 

      <!-- State panel -->
      <table width="100%" cellspacing="0" cellpadding="0" border="0">
        <tr>
          <td bgcolor="#cccccc">
            <table border="0" cellspacing="1" cellpadding="2" width="100%">
              <tr bgcolor="#ccccff">
                <th>
                  This case is currently @case.state@
                </th>
              </tr>
              <tr bgcolor="#ffffff">
                <td>
                  <table width="100%" cellspacing="0" cellpadding="0" border="0">
                    <tr>
                      <td>
                        <if @actions:rowcount@ gt 0>
			  Change state:
			  <multiple name="actions">
			    (<a href="@actions.url@">@actions.title@</a>)
			  </multiple>
                        </if>
                      </td>
                      <td align="right">
                        (<a href="@case.debug_url@">debug case</a>)
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>

      <p>

      <!-- Active Tasks -->
      <table width="100%" cellspacing="0" cellpadding="0" border="0">
        <tr>
          <td bgcolor="#cccccc">
            <table border="0" cellspacing="1" cellpadding="2" width="100%">
              <tr bgcolor="#ccccff">
                <th>
                  Active Tasks
                </th>
              </tr>
              <tr bgcolor="#ffffff">
                <td>
                  <include src="active-tasks" case_id="@case_id;noquote@" return_url="@return_url;noquote@">
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>

      <p>
 
      <!-- Manual Assignments -->
      <table width="100%" cellspacing="0" cellpadding="0" border="0">
        <tr>
          <td bgcolor="#cccccc">
            <table border="0" cellspacing="1" cellpadding="2" width="100%">
              <tr bgcolor="#ccccff">
                <th>
                  Manual Assignments
                </th>
              </tr>
              <tr bgcolor="#ffffff">
                <td>
                  <include src="case-assignments-table" case_id="@case_id;noquote@">
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>

      <p>

      <!-- Deadlines -->
      <table width="100%" cellspacing="0" cellpadding="0" border="0">
        <tr>
          <td bgcolor="#cccccc">
            <table border="0" cellspacing="1" cellpadding="2" width="100%">
              <tr bgcolor="#ccccff">
                <th>
                  Deadlines
                </th>
              </tr>
              <tr bgcolor="#ffffff">
                <td>
                  <include src="case-deadlines-table" case_id="@case_id;noquote@">
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>

      <p>

      <!-- Past Tasks -->
      <table width="100%" cellspacing="0" cellpadding="0" border="0">
        <tr>
          <td bgcolor="#cccccc">
            <table border="0" cellspacing="1" cellpadding="2" width="100%">
              <tr bgcolor="#ccccff">
                <th>
                  Past Tasks
                </th>
              </tr>
              <tr bgcolor="#ffffff">
                <td>
                  <include src="finished-tasks" case_id="@case_id;noquote@">
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>

      <p>

      <!-- Attributes -->
      <table width="100%" cellspacing="0" cellpadding="0" border="0">
        <tr>
          <td bgcolor="#cccccc">
            <table border="0" cellspacing="1" cellpadding="2" width="100%">
              <tr bgcolor="#ccccff">
                <th>
                  Attributes
                </th>
              </tr>
              <tr bgcolor="#ffffff">
                <td>
                  <include src="case-attributes-table" case_id="@case_id;noquote@">
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>

    </td>
    <td align="center" valign="top">

      <!-- Right side -->

      <!-- Case graph -->
      <table width="100%" cellspacing="0" cellpadding="0" border="0">
        <tr>
          <td bgcolor="#cccccc">
            <table border="0" cellspacing="1" cellpadding="2" width="100%">
              <tr bgcolor="#ccccff">
                <th>
                  Process State
                </th>
              </tr>
              <tr bgcolor="#ffffff">
                <td>
                  <include src="case-state-graph" case_id="@case_id;noquote@" size="3,10">
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
 
    </td>
  </tr>
  <tr>

    <!-- Bottom row -->

    <td colspan="2">
      <include src="journal" case_id="@case.case_id;noquote@">
    </td>
  </tr>
</table>

</master>


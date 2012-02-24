<master>
<property name="title">#acs-workflow.lt_caseobject_namenoquot_1#</property>
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
                  #acs-workflow.lt_This_case_is_currentl#
                </th>
              </tr>
              <tr bgcolor="#ffffff">
                <td>
                  <table width="100%" cellspacing="0" cellpadding="0" border="0">
                    <tr>
                      <td>
                        <if @actions:rowcount@ gt 0>
			  #acs-workflow.Change_state#
			  <multiple name="actions">
			    (<a href="@actions.url@">@actions.title@</a>)
			  </multiple>
                        </if>
                      </td>
                      <td align="right">
                        (<a href="@case.debug_url@">#acs-workflow.debug_case#</a>)
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
                  #acs-workflow.Active_Tasks#
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
                  #acs-workflow.Manual_Assignments#
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
                  #acs-workflow.Deadlines#
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
                  #acs-workflow.Past_Tasks#
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
                  #acs-workflow.Attributes#
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
                  #acs-workflow.Process_State#
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



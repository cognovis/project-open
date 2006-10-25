<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
  
  <table cellpadding=3 cellspacing=1 border=0>
    <tr class="form-element">
      <td class="form-label">Enabled in state
      </td>
      <td class="form-widget">
      <listtemplate    name="states"></listtemplate>
      <div class="form-help-text">
        <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
        The task is available only in these states.
      </div>
    </td>
    </tr>
    <tr class="form-element">
      <td class="form-label">Other Preconditions
      </td>
      <td class="form-widget">
              <select>
                <option selected></option>
                <option>Random, 2 outcomes</option>
                <option>Random, 3 outcomes</option>
                <option>contains(input string, test string)</option>
                </select>
                <input type="submit" value="Add Condition">
        <div class="form-help-text">
          <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
          All of these conditions must also be true for the task to be enabled.
        </div>
      </td>
    </tr>
        <tr class="form-element">
                  <td class="form-label">
                Mode
               </td>
                  <td class="form-widget">
              <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                <input type="radio">Trigger instantly</input><br/>
                <input type="radio"><span style="color:green">Wait for a trigger</span></input><br/>
                <input type="radio" checked><span style="color:red">Start another workflow</span></input>
                </font>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                </div>
            </td>
          </tr>

          <tr class="form-element">
                  <td class="form-label" style="background-color:pink">
                    Child Workflow
               </td>
                  <td class="form-widget">
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
              <select>
                <option>Prepare Report for Legal Case</option>
                <option selected>AskInfo/Give Info</option>
                </select> <input type="submit" value="..."> <a
    href="mockup-sim-ft-5">Edit this task</a>
                </font>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                    Which Workflow?
                </div>
            </td>
          </tr>
          <tr class="form-element">
                  <td class="form-label" style="background-color:pink">
                    Asker Role: 
               </td>
                  <td class="form-widget">
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
              <select>
                 <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
                <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
               <option>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Secretary</option>
                <option selected>Partner</option>
              </select>
                </font>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                    Which Role in "Elementary Private Law" matches the role of Client in "Prepare Report for Basic Legal Case"?
                </div>
            </td>
          </tr>
          <tr class="form-element">
                  <td class="form-label" style="background-color:pink">
                    Giver Role: 
               </td>
                  <td class="form-widget">
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
              <select>
                <option selected>Lawyer</option>
                <option>Client</option>
                <option>Other Lawyer</option>
                <option>Other Client</option>
                <option>Secretary</option>
                <option>Partner</option>
              </select>
                </font>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                    Which Role in "Elementary Private Law" matches the role of Lawyer in "Prepare Report for Basic Legal Case"?
                </div>
            </td>
          </tr>
        <tr class="form-element">
                  <td class="form-label">
                Duration
               </td>
                  <td class="form-widget">
              <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                <input type="radio" checked>No time limit</input><br/>
                <input type="radio">Trigger after <input type="text" name="timeout" size="10" /></input></input><br/>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                  Duration is of the form '1 hour' or '1 day' etc
                  
                  </div>
                                  </font>
            </td>
          </tr>
          <tr class="form-element">
            <td class="form-label">
              Outcome
            </td>
            <td class="form-widget">
            <input type="radio" name="outcome" checked>Don't change state</input><br>
            <input type="radio" name="outcome">Change to state:</input>
               <select>
                 <option>Getting Information from client</option>
                 <option>Researching Report</option>
                 <option>Editing Report</option>
                 <option>Completed</option>
                 </select><br/>
            </td>
          </tr>
          <tr class="form-element">
            <td class="form-label">
              Additional Effects
            </td>
            <td class="form-widget">
              <div class="form-help-text">
                <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
                When this task is completed, these things also happen
              </div>
            </td>
          </tr>

</table>
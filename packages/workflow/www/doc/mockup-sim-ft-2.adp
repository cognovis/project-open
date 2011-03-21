<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
  
  <table cellpadding=3 cellspacing=1 border=0>
    <tr class="form-element">
      <td rowspan="2">
        Enable
      </td>
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
        <input type="submit" value="Add a condition ..."/>
        <div class="form-help-text">
          <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
          All of these conditions must also be true for the task to be enabled.
        </div>
      </td>
    </tr>
    <tr class="form-element">
    <td rowspan="8" style="border-top: 1px solid black; border-bottom: 1px solid black" >
    Trigger
    </td>
      <td class="form-label">
        Mode
      </td>
      <td class="form-widget">
        <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
          <input type="radio">Trigger instantly</input><br/>
          <input type="radio"><span style="color:green">Wait for a trigger</span></input><br/>
          <input type="radio" checked><span
          style="color:red">Start another workflow and wait for it to complete</span></input>
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
                <option selected>Prepare Report for Legal Case</option>
                <option>Ask Info</option>
                <option>Give Info</option>
                </select> <input type="submit" value="...">
                </font><a href="mockup-sim-ft-3">Edit this
    workflow</a> Create a workflow
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                    Which Workflow?
                </div>
            </td>
          </tr>
          <tr class="form-element">
                  <td class="form-label" style="background-color:pink">
                    Client Role: 
               </td>
                  <td class="form-widget">
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
              <select>
                <option selected>Salesperson</option>
                <option>Salesperson's Lawyer</option>
                <option>Customer</option>
                <option>Customer's Lawyer</option>
                <option>Secretary1</option>
                <option>Secretary2</option>
                <option>Partner1</option>
                <option>Partner2</option>
                </font>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                    Which Role in "Elementary Private Law" matches the role of Client in "Prepare Report for Basic Legal Case"?
                </div>
            </td>
          </tr>
          <tr class="form-element">
                  <td class="form-label" style="background-color:pink">
                    Lawyer Role: 
               </td>
                  <td class="form-widget">
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
              <select>
                <option>Salesperson</option>
                <option selected>Salesperson's Lawyer</option>
                <option>Customer</option>
                <option>Customer's Lawyer</option>
                <option>Secretary1</option>
                <option>Secretary2</option>
                <option>Partner1</option>
                <option>Partner2</option>
                </font>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                    Which Role in "Elementary Private Law" matches the role of Lawyer in "Prepare Report for Basic Legal Case"?
                </div>
            </td>
          </tr>
          <tr class="form-element">
                  <td class="form-label" style="background-color:pink">
                    Other Client's Lawyer Role:
               </td>
                  <td class="form-widget">
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
              <select>
                <option>Salesperson</option>
                <option>Salesperson's Lawyer</option>
                <option>Customer</option>
                <option selected>Customer's Lawyer</option>
                <option>Secretary1</option>
                <option>Secretary2</option>
                <option>Partner1</option>
                <option>Partner2</option>
                </font>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                    Which Role in "Elementary Private Law" matches this role in "Prepare Report for Basic Legal Case"?
                </div>
            </td>
          </tr>
          <tr class="form-element">
                  <td class="form-label" style="background-color:pink">
                    Mentor Role: 
               </td>
                  <td class="form-widget">
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
              <select>
                <option>Salesperson</option>
                <option>Salesperson's Lawyer</option>
                <option>Customer</option>
                <option>Customer's Lawyer</option>
                <option>Secretary1</option>
                <option>Secretary2</option>
                <option selected>Partner1</option>
                <option>Partner2</option>
                </font>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                    Which Role in "Elementary Private Law" matches this role in "Prepare Report for Basic Legal Case"?
                </div>
            </td>
          </tr>
          <tr class="form-element">
                  <td class="form-label" style="background-color:pink">
                    Secretary Role: 
               </td>
                  <td class="form-widget">
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
              <select>
                <option>Salesperson</option>
                <option>Salesperson's Lawyer</option>
                <option>Customer</option>
                <option>Customer's Lawyer</option>
                <option selected>Secretary1</option>
                <option>Secretary2</option>
                <option>Partner1</option>
                <option>Partner2</option>
</select>                </font>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                    Which Role in "Elementary Private Law" matches this role in "Prepare Report for Basic Legal Case"?
                </div>
            </td>
          </tr>
          <tr class="form-element">
                  <td class="form-label" style="background-color:pink">
                    Lawyer Role: 
               </td>
                  <td class="form-widget">
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
              <select>
                <option>Salesperson</option>
                <option selected>Salesperson's Lawyer</option>
                <option>Customer</option>
                <option>Customer's Lawyer</option>
                <option>Secretary1</option>
                <option>Secretary2</option>
                <option>Partner1</option>
                <option>Partner2</option>
</select>
                </font>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                    Which Role in "Elementary Private Law" matches this role in "Prepare Report for Basic Legal Case"?
                </div>
            </td>
          </tr>
        <tr class="form-element">
        <td rowspan="3">
        Outcome
        </td>
                  <td class="form-label">
                Duration
               </td>
                  <td class="form-widget">
              <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                <input type="radio" checked>No time limit</input><br/>
                <input type="radio">Trigger after <input type="text" name="timeout" size="10" /></input></input><br/>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                  Duration is of the form '1 hour' or '1 day' etc.  To have this expire without effect, put a time limit in the <a href="">parent task</a> (what if this task is in the top-level workflow)
                  
                  </div>
                                  </font>
            </td>
          </tr>
          <tr class="form-element">
            <td class="form-label">
              Outcome
            </td>
            <td class="form-widget">
            <input type="radio" name="outcome">Don't change state</input><br>
            <input type="radio" name="outcome">Change to state: </input><select><option>Inactive</option><option>Complete</option></select><br/>
            </td>
          </tr>
          <tr class="form-element">
            <td class="form-label">
              Additional Outcome Effects
            </td>
            <td class="form-widget">
              <input type="submit" value="Add an outcome effect ..."/>
              <div class="form-help-text">
                <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
                  Additional commands to run after task is completed
               </div>
            </td>
          </tr>
</table>
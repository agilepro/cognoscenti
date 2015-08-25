<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.ValueElement"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.IDRecord"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't edit a user's profile.");

    uProf = findSpecifiedUserOrDefault(ar);

    //the following should be impossible since above log-in is checked.
    if (uProf == null)
    {
        throw new Exception("Can not find a user.");
    }
    boolean selfEdit = uProf.getKey().equals(ar.getUserProfile().getKey());
    if (!selfEdit)
    {
        //there is one super user who is allowed to edit other user profiles
        //that user is specified in the system properties -- by KEY
        String superUser = ar.getSystemProperty("su");
        if (superUser==null || !superUser.equals(ar.getUserProfile().getKey()))
        {
            throw new Exception("You are not user '"+uProf.getName()+"' and can not edit that user's record.");
        }
    }

    String go  = "UserProfile.jsp?u="+uProf.getKey();

    String openid = uProf.getUniversalId();

    String desc = uProf.getDescription();
    String name = uProf.getName();
    String homePage = uProf.getHomePage();
    long lastLogin = uProf.getLastLogin();
    long lastUpdated = uProf.getLastUpdated();
    ValueElement[] favs = uProf.getFavorites();

    pageTitle = "User: "+uProf.getName();
%>

<%@ include file="Header.jsp"%>



    <div class="section">
        <div class="section_title">
            <h1 class="left">User Profile &raquo; <% ar.writeHtml(openid);%></h1>
            <div class="clearer">&nbsp;</div>
        </div>
        <div class="section_body">


            <form name="taskForm" action="EditUserProfileAction.jsp" method="post">
                <input type="hidden" name="u" value="<% ar.writeHtml(uProf.getKey());%>" />
                <input type="hidden" name="openid" value="<% ar.writeHtml(openid);%>" />
                <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
                <input type="hidden" name="go" value="<% ar.writeHtml(go);%>" />
                <button type="submit" id="saveBtn" name="action" value="Save">Update Profile</button>
                <button type="submit" id="cancellBtn" name="action" value="Cancel">Cancel Changes</button>
                <br/><br/>
                <table class="Design8" width="98%">
                    <col width="20%"/>
                    <col width="80%"/>
                    <tr>
                        <td>Unique Id</td>
                        <td class="Odd"><% ar.writeHtml(uProf.getKey());%></td>
                    </tr>
                    <tr>
                        <td>Name</td>
                        <td class="Odd"><input type="text" name="name" style="WIDTH:97%;" value="<% ar.writeHtml(name);%>"/></td>
                    </tr>
                    <tr>
                        <td>Description</td>
                        <td class="Odd"><textarea name="description" style="WIDTH: 97%; HEIGHT:74px"><% ar.writeHtml(desc);%></textarea></td>
                    </tr>
                    <tr>
                        <td>Home Page</td>
                        <td class="Odd"><input type="text" name="homepage" style="WIDTH:97%;" value="<% ar.writeHtml(homePage);%>"/></td>
                    </tr>
                    <tr>
                        <td>Preferred Eamil</td>
                        <td class="Odd"><select name="prefEmail">
                        <%
                        String prefEmail = uProf.getPreferredEmail();
                        for (String emailx : uProf.getEmailList())
                        {
                            %>
                            <option value="<%
                            ar.writeHtml(emailx);
                            if (emailx.equals(prefEmail))
                            {
                                %>" selected="selected<%
                            }
                            %>"><% ar.writeHtml(emailx); %></option><%
                        }
                        %></select></td>
                    </tr>
<% if (!selfEdit) { %>
                    <tr>
                        <td>Disable User</td>
                        <td class="Odd"><input type="checkbox" name="disable" value="yes"
                        <% if (uProf.getDisabled()) { %> checked="checked"<% } %>></td>
                    </tr>
<% } %>
                </table>
            </form>
            <br/>
            <table class="Design8" width="98%">
<%
    for (IDRecord anid : uProf.getIdList())
    {
%>
        <form name="taskForm" action="EditUserProfileAction.jsp" method="post">
            <input type="hidden" name="u" value="<% ar.writeHtml(uProf.getKey());%>" />
            <input type="hidden" name="openid" value="<% ar.writeHtml(openid);%>" />
            <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
            <input type="hidden" name="go" value="<% ar.writeHtml(go);%>" />
            <input type="hidden" name="modid" value="<% ar.writeHtml(anid.getLoginId());%>" />
            <tr>
               <td><%if (anid.isEmail()){out.write("Email");}else{out.write("OpenID");}%></td>
               <td class="Odd"><% ar.writeHtml(anid.getLoginId());%></td>
               <td class="Odd"> <input type="submit" name="action" value="Remove ID">
                           confirm: <input type="checkbox" name="delconf" value="yes"></td>
            </tr>
        </form>
<%
    }
%>
                </table>
            </div>
        </div>
        <br/>
        <div class="section">
            <div class="section_title">
                <h1 class="left">Favorites</h1>
                <div class="section_date right">
                    <button type="button" id="addBtn" name="action" value="Add">Add</button>
                    <button type="button" id="delBtn" name="action" value="Remove">Remove</button>
                    <button type="button" id="delAllBtn" name="action" value="Remove All">Remove All</button>
                </div>
                <div class="clearer">&nbsp;</div>
            </div>
            <div class="section_body">
                <table  class="Design8" width="98%" id="favTable">
                <col width="5%"/>
                <col width="5%"/>
                <col width="30%"/>
                <col width="60%"/>
                <thead>
                    <tr>
                    <td>No</td>
                    <td>Select</td>
                    <td>Display Name</td>
                    <td>Address</td>
                    </tr>
                </thead>
                <tbody>
                </tbody>
                </table>
            </div>
        </div>
        <br/>
    <br/>
    <br/>

    <script type="text/javascript">

        var saveBtn = new YAHOO.widget.Button("saveBtn");
        var cancellBtn = new YAHOO.widget.Button("cancellBtn");

        var addBtn = new YAHOO.widget.Button('addBtn');
        var delBtn = new YAHOO.widget.Button('delBtn');
        var delAllBtn = new YAHOO.widget.Button('delAllBtn');

        addBtn.on('click', appendTableRow);
        delBtn.on('click', deleteTableRow);
        delAllBtn.on('click', deleteAllRows);

        var counter = 0;

<%
        if (favs != null && favs.length >0 )
        {
            for (int i=0; i<favs.length; i++)
            {
                out.write("populateTableRow(");
                ar.writeHtml("'" + favs[i].name + "'");
                ar.writeHtml(", '" + favs[i].value + "'");
                out.write(");");
            }
        }
%>

        function populateTableRow(name, address)
        {
            counter = counter + 1;
            var tbl = document.getElementById('favTable');
            var tbody = tbl.tBodies[0];
            var rowCount = tbody.rows.length;
            var row = document.createElement('tr');

            var cell1 = document.createElement('td');
            cell1.innerHTML = (counter);

            var cell2 = document.createElement('td');
            var cbx =  document.createElement('input');
            cbx.setAttribute('name','check');
            cbx.setAttribute('type','checkbox');
            cbx.setAttribute('id','check');
            cell2.appendChild(cbx);

            var cell3 = document.createElement('td');
            var inp1 =  document.createElement('input');
            inp1.setAttribute('name','fn_'+counter);
            inp1.setAttribute('type','text');
            inp1.setAttribute('value', name);
            inp1.setAttribute('size', '35');
            cell3.appendChild(inp1);

            var cell4 = document.createElement('td');
            var inp2 =  document.createElement('input');
            inp2.setAttribute('name','fa_'+counter);
            inp2.setAttribute('type','text');
            inp2.setAttribute('value', address);
            inp2.setAttribute('size', '60');

            cell4.appendChild(inp2);

            row.appendChild(cell1);
            row.appendChild(cell2);
            row.appendChild(cell3);
            row.appendChild(cell4);


            if((rowCount%2) == 0)
            {
                row.className = "Odd";
            }
            tbody.appendChild(row);
        }

        function appendTableRow()
        {
            populateTableRow('', '');
        }

        function deleteTableRow()
        {
            var tbl = document.getElementById("favTable");
            var tbody = tbl.tBodies[0];
            var rowCount = tbody.rows.length;

            for (var idx=0; idx<rowCount; idx++)
            {
                var row = tbody.rows[idx];
                var cell = row.cells[1];
                var node = cell.lastChild;
                if (node.checked == true){
                    tbody.deleteRow(idx);
                }
            }
        }

        function deleteAllRows()
        {
            var tbl = document.getElementById("favTable");
            var tbody = tbl.tBodies[0];
            var rowCount = tbody.rows.length -1;
            for (var idx=rowCount; idx >= 0; idx--) {
                tbody.deleteRow(idx)
            }
        }

    </script>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

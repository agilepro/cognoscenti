<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can not run page to create a user profile.");

    String userToFind = ar.reqParam("id");

    String go  = "FindUser.jsp?id="+URLEncoder.encode(userToFind,"UTF-8");

    String openid = userToFind;

    //if it has an @ then it is probably an email address
    boolean probablyEmail = (userToFind.indexOf("@")>=0);
    String emailCheck = "";
    String oidCheck = "";
    if (probablyEmail)
    {
        emailCheck = " checked=\"checked\"";
    }
    else
    {
        oidCheck = " checked=\"checked\"";
    }

    String desc = "";
    String name = "";
    String email = userToFind;

    pageTitle = "Create New User";
%>

<%@ include file="Header.jsp"%>

    <form name="taskForm" action="CreateUserProfileAction.jsp" method="post">
        <input type="hidden" name="id" value="<% ar.writeHtml(userToFind);%>" />
        <input type="hidden" name="go" value="<% ar.writeHtml(go);%>" />
        <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>


        <div class="section">
            <div class="section_title">
                <h1 class="left">Create User Profile</h1>
                <div class="clearer">&nbsp;</div>
            </div>
            <div class="section_body">
                <p>Can not find a profile for this user, would you like to <b>create one</b>?</p>

                <table class="Design8" width="98%">
                    <col width="20%"/>
                    <col width="80%"/>
                    <tr>
                        <td>Given:</td>
                        <td class="Odd"><% ar.writeHtml(openid);%></td>
                    </tr>
                    <tr>
                        <td>Specify:</td>
                        <td class="Odd">
                            Above is a
                            <input type="radio" name="idtype" value="email"<%=emailCheck%>> Email Address
                            <input type="radio" name="idtype" value="openid"<%=oidCheck%>> Opend ID
                        </td>
                    </tr>
                    <tr>
                        <td>Name</td>
                        <td class="Odd"><input type="text" name="name" style="WIDTH:97%;" value="<% ar.writeHtml(name);%>"/></td>
                    </tr>
                    <tr>
                        <td>Description</td>
                        <td class="Odd"><textarea name="description" style="WIDTH: 97%; HEIGHT:74px"><% ar.writeHtml(desc);%></textarea></td>
                    </tr>
                </table>
            </div>
        </div>
        <br/>
        <button type="submit" id="saveBtn" name="action" value="Save">Create Profile</button>
        <button type="submit" id="cancellBtn" name="action" value="Cancel">Cancel</button>
    </form>
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

<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.ConfigFile"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="java.io.File"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Properties"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%
    AuthRequest ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Can't create a page.");

    String pt = ar.reqParam("pt"); //page title
    String p  = ar.defParam("CreatePage.jsp", null);   //page id
    boolean pageIdSpecified = true;
    if (p==null)
    {
        p = "----------";
        pageIdSpecified = false;
    }
    String pp = ar.defParam("pp", "");          //parent process
    String b  = ar.reqParam("b");               //account (book)
    String gs = ar.defParam("gs", "");          //goal subject
    String gd = ar.defParam("gd", "");          //goal description

    //if there is a source page, then set it as the hooked link
    String s = ar.defParam("s", null);               //source page
    if (s!=null) {
        session.setAttribute("hook", s);
    }

    if (pageIdSpecified && ar.getCogInstance().pageExists(p)) {
        NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
        response.sendRedirect(ar.getResourceURL(ngp,""));
    }

    File root = ar.getCogInstance().getConfig().getDataFolderOrFail()
    File[] children = root.listFiles();

    pageTitle = "Create New Page";

%>
<%@ include file="Header.jsp"%>


    <h3>Would you like to create a new project?</h3>

    <script>
        var actBtn = new YAHOO.widget.Button("action");
    </script>

    <form action="CreatePageAction.jsp" method="post">
    <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
    <button type="submit" id="actBtn" name="action" value="Create Page">Create Project</button><br/>

    <b>Project Details</b>
    <br/>
    <table width="80%" class="Design8">
        <col width="20%">
        <col width="80%">
        <tr>
            <td>Project Key:</td>
            <td class="odd">
                <input type="text" name="p" value="<%ar.writeHtml(p);%>" style="WIDTH:100%;" readonly>
            </td>
        </tr>
        <tr>
            <td>Full Name:</td>
            <td class="odd">
                <input type="text" name="fullName" value="<%ar.writeHtml(pt);%>" style="WIDTH:100%;">
            </td>
        </tr>
        <tr>
            <td>Abbreviation:</td>
            <td class="odd">
                <input type="text" name="abbreviation" value="" style="WIDTH:100%;"><br/>
            </td>
        </tr>
        <tr>
            <td>Site:</td>
            <td class="odd">
        <%
            //we have to make sure that a valid account name was sent
            for (int i=0; i<children.length; i++)
            {
                File child = children[i];
            }
            boolean pickedOne = false;
            for (int i=0; i<children.length; i++)
            {
                File child = children[i];
                String fileName = child.getName();
                if (!fileName.endsWith(".book"))
                {
                    //ignore all files except those that end in .book
                    continue;
                }
                String key = fileName.substring(0,fileName.length()-5);
                NGBook aBook = ar.getCogInstance().getSiteByIdOrFail(key);
                if (!aBook.primaryOrSecondaryPermission(ar.getUserProfile()))
                {
                    continue;
                }
                String aKey = aBook.getKey();
                String checked = "";
                if (b.equals(aKey))
                {
                    checked = " checked=\"checked\"";
                }
                pickedOne = true;
        %>
                <input type="radio" name="book" value="<%ar.writeHtml(aKey);%>"<%=checked%>/>
                <% ar.writeHtml(aBook.getFullName()); %>
                <br/>
<%
            }
            if (!pickedOne)
            {
                %>In order to create a project, you must be a member of at least one account.<%
                %><input type="hidden" name="book" value="?NotAllowed?"/><%
            }
%>
            </td>
        </tr>
        <tr>
            <td>Admin:</td>
            <td class="odd">
                <% ar.getUserProfile().writeLink(ar); %><br/>
            </td>
        </tr>
    </table>

    <br/>

    <b>Subprocess Linking</b>
    <br/>
    <table width="80%" class="Design8">
        <col width="20%">
        <col width="80%">
        <tr>
            <td>Parent Link</td>
            <td class="odd"><input type="text" name="pp" value="<%ar.writeHtml(pp);%>" style="WIDTH:100%;"></td>
        </tr>
        <tr>
            <td>Link Using</td>
            <td class="odd">
              <input type="radio" name="wflink" value="yes"> Wf-XML Linking
              <input type="radio" name="wflink" value="no" checked="checked"> Browser Redirect (NuGen only)
            </td>
        </tr>
    </table>

    <br/>

    <b>Goal Details</b>
    <br/>
    <table width="80%" class="Design8">
        <col width="20%">
        <col width="80%">
        <tr>
            <td>Subject</td>
            <td class="odd"><input type="text" name="processSynopsis" value="<%ar.writeHtml(gs);%>" style="WIDTH:100%;"></td>
        </tr>
        <tr>
            <td>Description</td>
            <td class="odd"><textarea name="processDesc" style="WIDTH:98%; HEIGHT:74px;"><%ar.writeHtml(gd);%></textarea></td>
        </tr>
    </table>

    <br/>

    <b>Template</b>
    <br/>
    <table width="80%" class="Design8">
        <col width="20%">
        <col width="80%">
        <tr>
            <td>Template Name</td>
            <td class="odd"><input type="text" name="template" value="" style="WIDTH:100%;"></td>
        </tr>
    </table>

    <br/>
    </form>


<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

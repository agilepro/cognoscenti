<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="java.io.File"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Properties"
%><%@page import="org.w3c.dom.Element"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);

    uProf = findSpecifiedUserOrDefault(ar);

    ngb = null;

    pageTitle = "Unknown User";
    if (uProf!=null)
    {
        pageTitle = "User: "+uProf.getName();
    }
    specialTab = "My Workspaces";
%>


<%@ include file="Header.jsp"%>

<%
    if (ar.isLoggedIn() && uProf!=null)
    {
%>
    <div class="pagenavigation">
        <div class="pagenav">
            <div class="left"><%ar.writeHtml(uProf.getName());%> &raquo; List of Workspaces</div>
            <div class="right"></div>
            <div class="clearer">&nbsp;</div>
        </div>
        <div class="pagenav_bottom"></div>
    </div>


    <div class="section">
        <div class="section_title">
            <h1 class="left">List of Workspaces</h1>
            <div class="section_date right"></div>
            <div class="clearer">&nbsp;</div>
        </div>
        <div class="section_body">

            <div id="listofpagesdiv">
                <table id="pagelist">
                    <thead>
                        <tr>
                            <th>No</th>
                            <th>Page Name</th>
                            <th>Last Modified</th>
                            <th>Comment</th>
                        </tr>
                    </thead>
                    <tbody>


<%
    int i=0;
    for (NGPageIndex ngpi : ar.getCogInstance().getAllPagesForAdmin(uProf)) {
        String linkAddr = ar.retPath + "p/" + ngpi.containerKey + "/public.htm";
%>
        <tr>
            <td>
                <%=(++i)%>
            </td>
            <td>
                <a href="<%ar.writeHtml(linkAddr);%>" title="navigate to the page"><%ar.writeHtml( ngpi.containerName);%></a>
            </td>
            <td>
                <%SectionUtil.nicePrintTime(ar, ngpi.lastChange, ar.nowTime);%>
            </td>
            <td>
<%
        if (ngpi.isOrphan())
        {
            out.write("Orphaned");
        }
        else if (ngpi.requestWaiting)
        {
            out.write("Pending Requests");
        }
%>

            </td>
        </tr>
<%
    }

%>
                    </tbody>
                </table>
            </div>

        </div>
    </div>
<%
    }
    else if (ar.isLoggedIn())   //unknown user
    {
%>
        <p>unable to find user.</p>
<%
    }
    else   //unknown user
    {
%>
        <p>You must be logged in, in order to see information about users.</p>
<%
    }
%>

    <script type="text/javascript">
        YAHOO.util.Event.addListener(window, "load", function()
        {
            YAHOO.example.EnhanceFromMarkup = function()
            {
                var myColumnDefs = [
                    {key:"no",label:"No",formatter:YAHOO.widget.DataTable.formatNumber,sortable:true,resizeable:true},
                    {key:"pagename",label:"Page Name", sortable:true,resizeable:true},
                    {key:"lastmodified",label:"Last Modified", sortable:true,resizeable:true},
                    {key:"comments",label:"comments",sortable:true, resizeable:true}
                ];

                var myDataSource = new YAHOO.util.DataSource(YAHOO.util.Dom.get("pagelist"));
                myDataSource.responseType = YAHOO.util.DataSource.TYPE_HTMLTABLE;
                myDataSource.responseSchema = {
                    fields: [{key:"no", parser:"number"},
                            {key:"pagename"},
                            {key:"lastmodified"},
                            {key:"comments"}]
                };

                var oConfigs = {
                    paginator: new YAHOO.widget.Paginator({
                        rowsPerPage: 200
                    }),
                    initialRequest: "results=999999"
                };


                var myDataTable = new YAHOO.widget.DataTable("listofpagesdiv", myColumnDefs, myDataSource, oConfigs,
                {caption:"",sortedBy:{key:"no",dir:"desc"}});

                return {
                    oDS: myDataSource,
                    oDT: myDataTable
                };
            }();
        });
    </script>



<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

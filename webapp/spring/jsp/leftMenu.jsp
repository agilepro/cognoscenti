<%@page import="org.socialbiz.cog.NGContainer"
%><%@page import="org.socialbiz.cog.NGTerm"
%><%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.UserPage"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*

Optional Parameter:

    1. pageId : This is the id of a Project and used to retrieve NGPage.

    //Used only in case of logged in
    2. headerType   : This is used to pass header type as hidden parameter when the search form is submitted.
    3. tabId        : This is used to pass tab Id as hidden parameter when the search form is submitted.
*/

    String pageId = ar.defParam("pageId", null);

    String headerType = null;
    String tabId = null;
    if (ar.isLoggedIn()) {
        headerType = (String)request.getAttribute("headerType");
        tabId = (String)request.getAttribute("tabId");
    }

%><%String goLogin=ar.getCompleteURL();
    NGContainer ngp = null;
    NGBook ngb = null;
    if(pageId!=null){
        ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
        if (ngp!=null) {
            ar.setPageAccessLevels(ngp);
            if(ngp instanceof NGPage) {
                ngb = ((NGPage)ngp).getSite();
            }
        }
    }%>
<!-- this is the beginning of LeftMenu.jsp -->
<script>
    var CPATH_LEFTNAV = '<%=request.getContextPath()%>';
</script>
<div>
    <%
    if (!ar.isLoggedIn()) {
    %>
    <div class="generalLinks" onclick="expandCollapseLeftNav('leftNav_1')">
        <img alt="" src="<%=ar.retPath%>assets/collapseBlackIcon.gif" id="imgLN1" border="0" />General Links
    </div>
    <div class="leftNavContent first" id="leftNav_1" style="display:block;">
        <!-- Begin leftPanel -->
        <p>Please <a href="<%=ar.retPath%>t/EmailLoginForm.htm?go=<%ar.writeURLData(goLogin);%>">log-in</a>
        or <a href="<%=ar.retPath%>t/EmailLoginForm.htm?go=<%ar.writeURLData(goLogin);%>">register</a></p>
    </div>
    <%
    }
    else {
        UserProfile uProf = ar.getUserProfile();
    %>
    <div class="searchLink">Search</div>
    <div class="searchLinkContent">
        <div>
            <form method="get" id="searchform" action="<%=ar.retPath%>t/searchPublicNotes.htm">
                <table class="search">
                    <tr>
                        <td><input type="text" name="searchText" size="16" id="qs"/></td>
                        <td><input type="image" src="<%=ar.baseURL%>button_go.gif" /></td>
                    </tr>
                </table>
            </form>
        </div>
    </div>
    <%
    }
    %>
    <div class="generalLinks" onclick="expandCollapseLeftNav('leftNav_2')"><img
              alt="" src="<%=ar.baseURL%>assets/expandBlackIcon.gif" id="imgLN2"
              border="0" />Recently Visited Projects</div>
    <div class="leftNavContent" id="leftNav_2">
        <ul style="list-style:none;margin:0;padding:0;">
            <%
            NGSession ngsession = ar.ngsession;
            if (ngsession!=null)
            {
                Vector<RUElement> recent = ngsession.recentlyVisited;
                RUElement.sortByDisplayName(recent);
                for (RUElement rue : recent)
                {
                    NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(rue.key);
                    if (ngpi!=null && ngpi.isProject())
                    {
                        ngpi.writeTruncatedLink(ar, 20);
                        ar.write("<br/>\n");
                    }
                }
            }
            %>
        </ul>
    </div>
    <%
    // To This Project & From This Project should be displayed only when displaying the page.
    if (ngp != null)
    {
        NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(ngp.getKey());
    %>
    <div class="generalLinks" onclick="expandCollapseLeftNav('leftNav_4')">
        <img alt="" src="<%=ar.baseURL%>assets/expandBlackIcon.gif" id="imgLN4" border="0" />To This Project</div>
    <div class="leftNavContent" id="leftNav_4">
        <ul  style="list-style:none;margin:0;padding:0;">
            <%
            if (ngpi!=null)
            {
                for (NGPageIndex refB : ngpi.getInLinkPages())
                {
                    refB.writeTruncatedLink(ar, 20);
                    ar.write("\n<br/>\n");
                }
            }
            %>
        </ul>
    </div>
    <div class="generalLinks" onclick="expandCollapseLeftNav('leftNav_5')">
        <img alt="" src="<%=ar.baseURL%>assets/expandBlackIcon.gif" id="imgLN5" border="0" />From This Project</div>
    <div class="leftNavContent" id="leftNav_5">
        <ul  style="list-style:none;margin:0;padding:0;">
            <%
            if (ngpi!=null)
            {
                for (NGPageIndex refB : ngpi.getOutLinkPages())
                {
                    refB.writeTruncatedLink(ar, 20);
                    ar.write("\n<br/>\n");
                }
            }
            %>
        </ul>
    </div>
    <div class="generalLinks" onclick="expandCollapseLeftNav('leftNav_6')">
        <img alt="" src="<%=ar.baseURL%>assets/expandBlackIcon.gif" id="imgLN6"
                 border="0" />Tags</div>
    <div class="leftNavContent" id="leftNav_6">
        <ul  style="list-style:none;margin:0;padding:0;">
            <%
            if (ngpi!=null)
            {
                for (NGTerm term : ngpi.hashTags)
                {
                    ar.write("\n<b>#");
                    ar.writeHtml(term.sanitizedName);
                    ar.write("</b><br/>\n");
                    for (NGPageIndex tagRef : term.targetLeaves)
                    {
                        tagRef.writeTruncatedLink(ar, 20);
                        ar.write("<br/>\n");
                    }
                }
            }
            %>
        </ul>
    </div>
    <%
    } // To This Page & From This Page should be displayed only when displaying the page.
    %>
</div>
<!-- this is the end of LeftMenu.jsp -->
<% out.flush(); %>

<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.ValueElement"
%><%@page import="org.socialbiz.cog.WatchRecord"
%><%@page import="org.socialbiz.cog.IDRecord"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to see user profile.");

    uProf = findSpecifiedUserOrDefault(ar);

    String go  = "UserList.jsp";

    pageTitle = "User: unknown";
    specialTab = "Home";

    //this controls the displaying of the magic number on the profile page
    boolean isTestSetup = false;

    if (uProf!=null)
    {
        pageTitle = "User: "+uProf.getName();
    }
%>

<%@ include file="Header.jsp"%>

<%
    if (!ar.isLoggedIn())
    {
        out.write("<p>please log in to see the user profile</p>");
    }
    else if (uProf==null)
    {
        out.write("<p>Unable to find a user profile specified.</p>");
    }
    else
    {
        go  = "EditUserProfile.jsp?u="+uProf.getKey();
        String key = uProf.getKey();
        String name = uProf.getName();
        String homePage = uProf.getHomePage();
        long lastLogin = uProf.getLastLogin();
        long lastUpdated = uProf.getLastUpdated();
        ValueElement[] favs = uProf.getFavorites();
        List<WatchRecord> watchList = uProf.getWatchList();

        boolean viewingSelf = ar.getUserProfile().getKey().equals(uProf.getKey());

%>

        <br/>
        <div class="section">
            <div class="section_title">
                <h1 class="left">Watched Workspaces</h1>
                <div class="section_date right">
                </div>
                <div class="clearer">&nbsp;</div>
            </div>
            <div class="section_body">
                <table  class="Design8" width="690" id="favTable">
                <col width="300"/>
                <col width="150"/>
                <col width="150"/>
                <thead>
                    <tr>
                    <td>Name</td>
                    <td>Most Recent Change</td>
                    <td>Visited</td>
                    </tr>
                </thead>
                <tbody>

<%

        if (watchList != null)
        {
            Hashtable visitDate = new Hashtable();
            List<NGPageIndex> watchedProjects = new ArrayList<NGPageIndex>();
            for (WatchRecord wr : watchList) {
                String pageKey = wr.getPageKey();
                NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(pageKey);
                if (ngpi!=null) {
                    watchedProjects.add(ngpi);
                    visitDate.put(ngpi.containerKey, new Long(wr.getLastSeen()));
                }
            }

            NGPageIndex.sortInverseChronological(watchedProjects);
            for (NGPageIndex ngpi : watchedProjects) {
                long  changeTime = 0;
                ar.write("<tr><td><a href=\"");
                ar.writeHtml(ar.retPath);
                ar.writeHtml(ar.getResourceURL(ngpi, "public.htm"));
                ar.write("\" title=\"navigate to the watched page\">");
                ar.writeHtml(ngpi.containerName);
                ar.write("</a>");
                changeTime = ngpi.lastChange;
                ar.write("</td><td>");
                SectionUtil.nicePrintTime(ar, changeTime, ar.nowTime);
                ar.write("</td><td>");
                Long lastSeen = (Long) visitDate.get(ngpi.containerKey);
                SectionUtil.nicePrintTime(ar, lastSeen.longValue(), ar.nowTime);
                ar.write("</td></tr>");
            }
        }
%>
                </tbody>
                </table>
            </div>
        </div>



        <div class="section">
            <div class="section_title">
                <h1 class="left">Project Templates</h1>
                <div class="section_date right">
                </div>
                <div class="clearer">&nbsp;</div>
            </div>
            <div class="section_body">
                <table  class="Design8" width="690" id="favTable">
                <col width="300"/>
                <col width="150"/>
                <thead>
                    <tr>
                    <td>Name</td>
                    <td>Most Recent Change</td>
                    </tr>
                </thead>
                <tbody>

<%

        UserPage uPage = ar.getUserPage();
        List<String> allTemplates = uPage.getProjectTemplates();
        if (allTemplates != null) {
            List<NGPageIndex> sortedTemplates = new ArrayList<NGPageIndex>();
            for (String pageKey : allTemplates) {
                NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(pageKey);
                if (ngpi!=null) {
                    sortedTemplates.add(ngpi);
                }
            }

            NGPageIndex.sortInverseChronological(sortedTemplates);
            for (NGPageIndex ngpi : sortedTemplates) {
                long  changeTime = 0;
                ar.write("<tr><td><a href=\"");
                ar.writeHtml(ar.retPath);
                ar.writeHtml(ar.getResourceURL(ngpi, "public.htm"));
                ar.write("\" title=\"navigate to the watched page\">");
                ar.writeHtml(ngpi.containerName);
                ar.write("</a>");
                changeTime = ngpi.lastChange;
                ar.write("</td><td>");
                SectionUtil.nicePrintTime(ar, changeTime, ar.nowTime);
                ar.write("</td></tr>");
            }
        }
%>
                </tbody>
                </table>
            </div>
        </div>


        <br/>
        <div class="section">
            <div class="section_title">
                <h1 class="left">Favorites</h1>
                <div class="section_date right">
                </div>
                <div class="clearer">&nbsp;</div>
            </div>
            <div class="section_body">
                <table  class="Design8" width="98%" id="favTable">
                <col width="300"/>
                <col width="300"/>
                <thead>
                    <tr>
                    <td>Name</td>
                    <td>Address</td>
                    </tr>
                </thead>
                <tbody>

<%
        if (favs != null && favs.length >0 )
        {
            for (int i=0; i<favs.length; i++)
            {
                ar.write("<tr><td><a href=\"");
                ar.writeHtml(favs[i].value);
                ar.write("\" title=\"navigate to this favorite page\">");
                ar.writeHtml(favs[i].name);
                ar.write("</td><td>");
                ar.writeHtml(favs[i].value);
                ar.write("</td></tr>");
            }
        }
%>
                </tbody>
                </table>
            </div>
        </div>
    <br/>
    <div class="section">
        <div class="section_title">
            <h1 class="left">Document Repository Connections</h1>
            <div class="section_date right"><a name="Folders" href="MountFolder.jsp"  target="_blank">New Connection</a></div>
            <div class="clearer">&nbsp;</div>
        </div>
            <div class="section_body">
<%
                displayUserFoldersX(ar);

%>
            </div>
        </div>
    <br/>

<%
    }
%>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

<%!

    public void displayUserFoldersX(AuthRequest ar)
            throws Exception {
        try {
            Writer out = ar.w;
            String go = ar.getCompleteURL();

            UserPage uPage = ar.getUserPage();
            ar.write("<table class=\"Design8\" width=\"98%\" id=\"folderTable\">");
            ar.write("<col width=\"300\"/>");
            ar.write("<col width=\"300\"/>");

            for (ConnectionSettings cSet : uPage.getAllConnectionSettings()) {

                ar.write("\n<tr>");
                ar.write("\n   <td align=\"left\">");
                ar.write("<h3>");

                String dname = getShortName(cSet.getDisplayName(), 38);

                String fdLink = ar.retPath + "FolderDisplay.jsp?symbol="
                   + URLEncoder.encode(cSet.getId()+"/", "UTF-8");

                ar.write("  <a href=\"");
                ar.writeHtml(fdLink);
                ar.write("\"");
                writeTitleAttribute(ar, cSet.getDisplayName(), 38);
                ar.write("><img allign=\"absbottom\" src=\"");
                ar.write(ar.retPath);
                ar.write("cfolder.gif");
                ar.write("\">" + dname + "</a>");
                if (cSet.isDeleted())
                {
                    ar.write(" (deleted)");
                }
                ar.write("\n   </td>");
                ar.write("\n   <td align=\"left\">");

                String addLink = ar.retPath
                        + "addFile.jsp"
                        + "?fid="
                        + URLEncoder.encode(cSet.getId(), "UTF-8")
                        + "&dname="
                        + URLEncoder.encode(cSet.getDisplayName(),
                                "UTF-8") + "&go="
                        + URLEncoder.encode(go, "UTF-8");
                ar.write("  <a href=\"");
                ar.writeHtml(addLink);
                ar.write("\">ADD</a>&nbsp;&nbsp;");

                String updateLink = ar.retPath
                        + "updateFolder.jsp"
                        + "?fid="
                        + URLEncoder.encode(cSet.getId(), "UTF-8")
                        + "&go=" + URLEncoder.encode(go, "UTF-8");
                ar.write("  <a href=\"");
                ar.writeHtml(updateLink);
                ar.write("\"><img allign=\"absbottom\" src=\"");
                ar.write(ar.retPath);
                ar.write("update.gif\" title=\"Update\">");
                ar.write("</a>");
                ar.write("&nbsp;&nbsp;");


                ar.write("</td>");
                ar.write("</tr>");
            }
            ar.write("</table>");
        } catch (Exception e) {
            throw e;
        }

    }


%>
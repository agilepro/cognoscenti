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
%><%
    ar = AuthRequest.getOrCreate(request, response, out);
    ar.assertLoggedIn("Unable to see user profile.");

    uProf = findSpecifiedUserOrDefault(ar);
    if (uProf==null) {
        //actually it will never get here, just including this code to make it
        //clear that uProf will never be null
        throw new Exception("Unable to find the user with specified key.");
    }

    String go  = "EditUserProfile.jsp?u="+uProf.getKey();

    pageTitle = "User: unknown";
    specialTab = "Settings";

    //this controls the displaying of the magic number on the profile page
    boolean isTestSetup = false;

    pageTitle = "User: "+uProf.getName();

%>
<%@ include file="Header.jsp"%>
<%

    String key = uProf.getKey();
    String name = uProf.getName();
    String homePage = uProf.getHomePage();
    long lastLogin = uProf.getLastLogin();
    long lastUpdated = uProf.getLastUpdated();
    ValueElement[] favs = uProf.getFavorites();
    List<WatchRecord> watchList = uProf.getWatchList();
    List<IDRecord> allIds = uProf.getIdList();

    boolean viewingSelf = ar.getUserProfile().getKey().equals(uProf.getKey());
    String apuLink = "apu/"+uProf.getKey()+"/user.json";

%>

        <div class="section">
            <div class="section_title">
                <h1 class="left">User Profile &raquo; <% ar.writeHtml(key);%></h1>
                <div class="section_date right">
                    <% if (viewingSelf) { %>
                    <a href="ChangePassword.jsp?go=<% ar.writeURLData(ar.getCompleteURL()); %>&key=<% ar.writeURLData(key); %>">Change Your Password</a> &nbsp; - &nbsp;
                    <a href="EditUserProfile.jsp?u=<%ar.writeURLData(key);%>" title="edit this profile">Edit Your Profile</a>
                    <% } %>
                    </div>
                <div class="clearer">&nbsp;</div>
            </div>
            <div class="section_body">
            <%
                 if (uProf.getDisabled())
                 {
                     %><p><img src="warning.gif"> User is disabled.</p><%
                 }
                 if (uProf.getPreferredEmail()==null)
                 {
                     %><p><img src="warning.gif"> User has no email address.</p><%
                 }
                 if (uProf.getName()==null || uProf.getName().length()==0)
                 {
                     %><p><img src="warning.gif"> User has no display name.</p><%
                 }

            %>
                <table class="Design8" width="98%">
                    <col width="20%"/>
                    <col width="80%"/>
                    <tr>
                        <td>Unique Id</td>
                        <td class="Odd"><% ar.writeHtml(key);%></td>
                    </tr>
                    <tr>
                        <td>APU Link</td>
                        <td class="Odd"><a href="<% ar.writeHtml(apuLink);%>"><% ar.writeHtml(apuLink);%></a></td>
                    </tr>
                    <tr>
                        <td>Name</td>
                        <td class="Odd"><% ar.writeHtml(name);%></td>
                    </tr>
                    <tr>
                        <td>Description</td>
                        <td class="Odd"><% ar.writeHtml(uProf.getDescription());%></td>
                    </tr>
                    <tr>
                        <td>Home Page</td>
                        <td class="Odd"><% ar.writeHtml(homePage);%></td>
                    </tr>
                    <tr>
                        <td>Last Login</td>
                        <td class="Odd"><% SectionUtil.nicePrintDate(out, lastLogin); %>
                            as <% ar.writeHtml(uProf.getLastLoginId());%></td>
                    </tr>
                    <tr>
                        <td>Last Updated</td>
                        <td class="Odd"><% SectionUtil.nicePrintDate(out, lastUpdated); %></td>
                    </tr>
                    <tr>
                        <td>Preferred Email</td>
                        <td class="Odd">Email notifications will be sent to this address:<br/>
                                        <%ar.writeHtml(uProf.getPreferredEmail());%></td>
                    </tr>
<%
        int idCount = 0;
        for  (IDRecord anId : allIds)
        {
            idCount++;

            %><tr><td><%
            String thisID = anId.getLoginId();
            if (anId.isEmail())
            {
                out.write("Email");
                %></td><td class="Odd"><%
                ar.writeHtml(thisID);
            }
            else
            {
                out.write("OpenID");
                %></td><td class="Odd"><%
                ar.writeHtml(thisID);
            }
            listOthersWithID(ar,thisID, uProf);
            %>
            </td></form></tr>
            <%
        }

        //only display the 'add id' button if we are showing the user
        //their own page.
        if (viewingSelf || ar.isSuperAdmin())
        {
%>
                    <tr>
                        <td></td>
                        <form action="AddUserId.jsp">
                        <input type="hidden" name="go" value="UserProfile.jsp?u=<%ar.writeURLData(uProf.getKey());%>">
                        <input type="hidden" name="u" value="<%ar.writeHtml(uProf.getKey());%>">
                        <td class="Odd">
                          <input type="submit" value="Add Another Email or OpenID">
                        </td>
                        </form>
                    </tr>
<%      }
        if (ar.isSuperAdmin()) {   %>
                    <tr>
                        <td></td>
                        <form action="UserProfileAction.jsp">
                        <input type="hidden" name="go" value="UserProfile.jsp?u=<%ar.writeURLData(uProf.getKey());%>">
                        <input type="hidden" name="u" value="<%ar.writeHtml(uProf.getKey());%>">
                        <td class="Odd">
                          <input type="submit" name="action" value="Disable User">
                        </td>
                        </form>
                    </tr>
<%      }   %>

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
                <h1 class="left">Watched Pages</h1>
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
                    <td>Visited & Changed Since Visit</td>
                    </tr>
                </thead>
                <tbody>

<%
        if (watchList != null) {
            for (WatchRecord wr : watchList) {
                NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(wr.getPageKey());
                long  changeTime = 0;
                if (ngpi!=null) {
                    ar.write("<tr><td><a href=\"");
                    ar.writeHtml(ar.retPath);
                    ar.writeHtml(ar.getResourceURL(ngpi, "public.htm"));
                    ar.write("\" title=\"navigate to the watched page\">");
                    ar.writeHtml(ngpi.containerName);
                    ar.write("</a>");
                    changeTime = ngpi.lastChange;
                }
                else
                {
                    ar.write("<tr><td>");
                    ar.writeHtml(wr.getPageKey());
                }
                ar.write("</td><td>");
                SectionUtil.nicePrintTime(ar, wr.getLastSeen(), ar.nowTime);
                if (wr.getLastSeen() < changeTime)
                {
                    ar.write(" <b>(changed ");
                    SectionUtil.nicePrintTime(ar, changeTime, ar.nowTime);
                    ar.write(")</b>");
                }
                ar.write("</td></tr>");
            }
        }
%>
                </tbody>
                </table>
            </div>
        </div>
    <br/>
    <br/>
    <ul>

<%
        if (ar.isSuperAdmin())
        {
            for (String email : uProf.getEmailList())
            {
%>
    <li>Check magic number for <a href="MagicNumber.jsp?id=<%ar.writeURLData(email);%>"><%ar.writeHtml(email);%></a>
    </li>
<%
            }
        }

%>
    </ul>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>

<%!


    public void listOthersWithID(AuthRequest ar, String id, UserProfile thisUser)
        throws Exception
    {
        UserProfile[] allOfEm = UserManager.getAllUserProfiles();
        for (UserProfile other : allOfEm)
        {
            if (other.hasAnyId(id))
            {
                if (!other.getKey().equals(thisUser.getKey()))
                {
                    ar.write("<br/><b>--------&gt; <font color=\"red\">this id ALSO owned by: </font></b>");
                    other.writeLink(ar);
                }
            }
        }
    }

%>

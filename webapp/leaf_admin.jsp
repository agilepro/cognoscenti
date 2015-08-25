<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.NGSection"
%><%@page import="org.socialbiz.cog.SectionDef"
%><%@page import="org.socialbiz.cog.SectionFormat"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.UserManager"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Element"
%><%

    ar = AuthRequest.getOrCreate(request, response, out);

    String p = ar.reqParam("p");
    ngp = ar.getCogInstance().getProjectByKeyOrFail(p);
    ar.setPageAccessLevels(ngp);
    ar.assertAdmin("old admin page is only for project administrators and you must be logged in to access it.");

    boolean isMember = ar.isMember();
    boolean isAdmin = ar.isAdmin();

    ar.retPath="../../";
    Vector allSecs = ngp.getAllSections();

    String[] names = ngp.getPageNames();

    ngb = ngp.getSite();
    if (ngb==null)
    {
        throw new Exception("Logic Error, should never get a null value from getAccount");
    }
    String bookName = ngb.getFullName();
    String thisPageAddress = ar.getResourceURL(ngp,"admin.htm");

    pageTitle = ngp.getFullName();
    specialTab = "Admin";
    newUIResource = "admin.htm";

    String licId = ngp.getLicenses().get(0).getId();%>

<%@ include file="Header.jsp"%>

<%
    headlinePath(ar, "Admin Only Section");



    if (!ar.isStaticSite())
    {
%>
      <form action="<%=ar.retPath%>EditLeaflet.jsp" method="get" target="_blank">
      <input type="hidden" name="p" value="<%ar.writeHtml(p);%>">
      <input type="hidden" name="viz" value="3">
      <input type="hidden" name="go" value="<%ar.writeHtml(ar.getCompleteURL());%>">
      <input type="submit" value="Create New Admin Note">
      </form>
    <%
        }
        writeLeaflets(ngp, ar, SectionDef.ADMIN_ACCESS);
    %>


<div class="section">
<!-- ------------------------------------------------- -->
    <div class="section_title">
    Project Goal and Purpose
    </div>
    <div class="section_body">
    <table>
<%
    ProcessRecord process = ngp.getProcess();

    String goal = process.getSynopsis();
    String purpose = process.getDescription();
    String beam = ngp.getUpstreamLink();
%>
    <form action="<%=ar.retPath%>ChangeGoalAction.jsp" method="post">
    <input type="hidden" name="p" value="<%ar.writeHtml(p);%>">
    <input type="hidden" name="go" value="<%ar.writeHtml(thisPageAddress);%>">
    <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
    <tr><td>Goal:</td>
      <td>
      <input type="text" name="goal" size="60" value="<%ar.writeHtml(goal);%>">
      </td>
    </tr>
    <tr><td>Purpose:</td>
      <td>
      <textarea name="purpose" rows="5" cols="60"><%
        ar.writeHtml(purpose);
      %></textarea>
      </td>
    </tr>
    <tr><td>Upstream:</td>
      <td>
      <input type="text" name="beam" size="60" value="<%ar.writeHtml(beam);%>">
      <a href="beam1.htm">Sync</a>
      </td>
    </tr>
    <tr><td></td><td>
    <input type="submit" name="action" value="Update Goal and Purpose">
    </td></tr>
    </form>
    </table>
    </div>
</div>


<div class="section">
<!-- ------------------------------------------------- -->
    <div class="section_title">
    Delete Project
    </div>
    <div class="section_body">

    <form action="<%=ar.retPath%>DeletePageAction.jsp" method="post">
    <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
    <input type="hidden" name="p" value="<%ar.writeHtml(p);%>">
    <input type="hidden" name="go" value="<%ar.writeHtml(thisPageAddress);%>">
    <%
        if (!ngp.isDeleted()) {
    %>
    <input type="submit" name="action" value="Delete Project">
    <%
        } else {
    %>
    <p>Project was deleted by <%
        UserProfile.writeLink(ar, ngp.getDeleteUser());
    %>
        <%
            SectionUtil.nicePrintTime(ar, ngp.getDeleteDate(), ar.nowTime);
        %>
    <input type="submit" name="action" value="Un-Delete Project">
    <%
        }
    %>
    </form>
    </div>
</div>

<div class="section">
<!-- ------------------------------------------------- -->
    <div class="section_title">
    REST API for this project
    </div>
    <div class="section_body">


<%
    String pageKey = ngp.getKey();
   String bookKey = ngb.getKey();

   UserProfile up2 = ar.getUserProfile();
   String uProfileAd = null;
   if(up2 != null)
   {
       String profileid = up2.getKey();
       uProfileAd = "u/" + profileid + "/profile.xml";
   }

   String fAlltask = "s/Tasks/f/alltask.xml?lic="+licId;
   String fActivetask = "s/Tasks/f/activetask.xml?lic="+licId;
   String fCompletetask = "s/Tasks/f/completetask.xml?lic="+licId;
   String fFutureask = "s/Tasks/f/futuretask.xml?lic="+licId;
   String auProfileAd = "u/*/profile.xml?lic="+licId;

   String pContentAd = "p/" + pageKey + "/leaf.xml?lic="+licId;
   String pUserListAd = "p/" + pageKey + "/userlist.xml?lic="+licId;
   String pLicenseAd = "p/" + pageKey + "/l/*/license.xml?lic="+licId;
   String pParentAd = "p/" + pageKey + "/parent.xml?lic="+licId;
   String bContentAd = "b/" + bookKey + "/book.xml?lic="+licId;
   String bUserListAd = "b/" + bookKey + "/userlist.xml?lic="+licId;
   String bPageListAd = "b/" + bookKey + "/pagelist.xml?lic="+licId;
%>

<ul>
  <li>TaskList
        <ul>
            <li>My All Task <a href="<%=ar.retPath%><%ar.writeHtml(fAlltask);%>" target="restapi">
                    <%
                        ar.writeHtml(fAlltask);
                    %></a></li>
            <li>My Active Task <a href="<%=ar.retPath%><%ar.writeHtml(fActivetask);%>" target="restapi">
                    <%
                        ar.writeHtml(fActivetask);
                    %></a></li>
            <li>My Complete Task <a href="<%=ar.retPath%><%ar.writeHtml(fCompletetask);%>" target="restapi">
                    <%
                        ar.writeHtml(fCompletetask);
                    %></a></a></li>
            <li>My Future Task <a href="<%=ar.retPath%><%ar.writeHtml(fFutureask);%>" target="restapi">
                    <%
                        ar.writeHtml(fFutureask);
                    %></a></li>
            <li>UserProfile List <a href="<%=ar.retPath%><%ar.writeHtml(auProfileAd);%>" target="restapi">
                    <%
                        ar.writeHtml(auProfileAd);
                    %></a></li>
            <%
                if(uProfileAd != null){
            %>
                    <li>UserProfile <a href="<%=ar.retPath%><%ar.writeHtml(uProfileAd);%>" target="restapi">
                        <%
                            ar.writeHtml(uProfileAd);
                        %></a></li>
            <%
                }
            %>

        </ul>
   </li>
   <li>Project
         <ul>
            <li>Project Content <a href="<%=ar.retPath%><%=pContentAd%>" target="restapi"><%=pContentAd%></a></li>
            <li>User List <a href="<%=ar.retPath%><%=pUserListAd%>" target="restapi"><%=pUserListAd%></a></li>
            <li>License List <a HREF="<%=ar.retPath%><%=pLicenseAd%>" TARGET="restapi"><%=pLicenseAd%></a></li>
            <li>Site
                <ul>
                    <li>Site Content <a href="<%=ar.retPath%><%=bContentAd%>" target="restapi">
                             <%=bContentAd%></a></li>
                    <li>User List <a href="<%=ar.retPath%><%=bUserListAd%>" target="restapi">
                             <%=bUserListAd%></a></li>
                    <li>Project List <a href="<%=ar.retPath%><%=bPageListAd%>" target="restapi">
                             <%=bPageListAd%></a></li>
                </ul>
            </li>
            <li>Section
                <ul>
<%
    Enumeration senum = allSecs.elements();
    while (senum.hasMoreElements())
    {
        NGSection sec = (NGSection) senum.nextElement();
        String secName = sec.getName();
        if(secName.equals("Tasks"))
        {
            String stProcess = "p/" + pageKey + "/process.xml";
            String stContent = "p/" + pageKey + "/s/" + secName + "/section.xml";
            String stHistory = "p/" + pageKey + "/s/" + secName + "/history.xml";
%>
            <li>Goals
                <ul>
                    <li>Section Content <a href="<%=ar.retPath%><%ar.writeHtml(stContent);%>" target="restapi">
                                <%
                                    ar.writeHtml(stContent);
                                %></a></li>
                    <li>Process <a href="<%=ar.retPath%><%ar.writeHtml(stProcess);%>" target="restapi">
                                <%
                                    ar.writeHtml(stProcess);
                                %></a></li>
                    <li>History <a href="<%=ar.retPath%><%ar.writeHtml(stHistory);%>" target="restapi">
                                <%
                                    ar.writeHtml(stHistory);
                                %></a></li>
            <%
                for (GoalRecord tr : ngp.getAllGoals())
                                    {
                                        String taskid = tr.getId();
                                        String stTaskData = "p/" + pageKey + "/s/Tasks/id/"+taskid+"/data.xml";
            %>
                    <li>Get Task Data <a href="<%=ar.retPath%><%=stTaskData%>" target="restapi">
                                <%ar.writeHtml(stTaskData);%></a></li>
            <%
            }
            %>
                </ul>
            </li>
<%
        }
        else
        {
            String sContentAddr = "p/" + pageKey + "/s/" + secName + "/section.xml";

 %>
        <li><% ar.writeHtml(secName); %> <a href="<%=ar.retPath%><% ar.writeHtml(sContentAddr); %>" target="restapi"><%ar.writeHtml(sContentAddr);%></a></li>
 <%
        }
     }
 %>
                </ul>
            </li>
        </ul>

    </li>
    <li>Search <a href="<%=ar.retPath%>p/factory/search.xml?qs=nugen" target="restapi">p/factory/search.xml?qs=nugen</a></li>
    <li>CLASS <% ar.writeHtml(ngp.getClass().getSimpleName()); %></li>
</ul>
<h2>NEW</h2>
<ul>
<%
    String apiPath = ar.retPath+"api/"+ngb.getKey()+"/"+ngp.getKey()+"/";

    %><li>Summary <a href="<%=apiPath%>summary.json">summary.json</a></li><%

    for (GoalRecord goalx : ngp.getAllGoals()) {
        %><li><a href="<%=apiPath%>goal<%=goalx.getId()%>/goal.json">goal <%=goalx.getId()%></a></li><%
    }

    for (AttachmentRecord att : ngp.getAllAttachments()) {
        %><li><a href="<%=apiPath%>doc<%=att.getId()%>/<%=att.getNiceName()%>">attachment <%=att.getNiceName()%></a></li><%
    }

    for (NoteRecord note : ngp.getAllNotes()) {
        String saniName = SectionUtil.sanitize(note.getSubject());
        if (saniName.length()<2) {
            saniName="note";
        }
        %><li><a href="<%=apiPath%>note<%=note.getId()%>/<%=saniName%>.htm">note <%=note.getId()%> HTML</a></li><%
        %><li><a href="<%=apiPath%>note<%=note.getId()%>/<%=saniName%>.txt">note <%=note.getId()%> text</a></li><%
    }

%>
</ul>
    </div>
</div>

<%@ include file="Footer.jsp"%>
<%@ include file="functions.jsp"%>


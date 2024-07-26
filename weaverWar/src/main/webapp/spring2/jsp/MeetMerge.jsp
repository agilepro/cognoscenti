<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.MeetingRecord"
%><%@page import="com.purplehillsbooks.weaver.LicenseForUser"
%><%@page import="com.purplehillsbooks.weaver.AccessControl"
%><%@page import="com.purplehillsbooks.weaver.MicroProfileMgr"
%><%@page import="com.purplehillsbooks.weaver.mail.ChunkTemplate"
%><%@page import="com.purplehillsbooks.json.JSONException"
%><%@page import="java.util.HashSet"
%><%

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);

    String id = ar.reqParam("id");
    MeetingRecord meet = ngw.findMeeting(id);

    JSONObject meetingJSON = meet.getFullJSON(ar, ngw, false);
    
 
    
    List<File> allLayouts = MeetingRecord.getAllLayouts(ar, ngw);
    
    String layoutName = ar.defParam("tem", "FullDetail.chtml");
    File layoutFile = MeetingRecord.findMeetingLayout(ar,ngw,layoutName);        
    
    
    %>
    <script>
    window.setMainPageTitle("Meeting Display"); 

    var app = angular.module('myApp');    
    app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
        //no real function here
    });
     </script>
     
<div>
    
    <div class="upRightOptions rightDivContent">    
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
        <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Lists all the meetings"
              href="MeetingList.htm" >Meeting List</a></li>
        <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Opens or closes all of the agenda items for the meeting"
              href="MeetingHtml.htm?id=<%=id%>" >Edit Meeting</a></li>
        <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Opens or closes all of the agenda items for the meeting"
              href="MeetPrint.htm?id=<%=id%>&tem=<% ar.writeHtml(layoutFile.getName()); %>" >Print It</a></li>
        <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Opens or closes all of the agenda items for the meeting"
              href="SendNote.htm?meet=<%=id%>&layout=<% ar.writeHtml(layoutFile.getName()); %>" >Email It</a></li>
        </ul>
      </span>
    </div>
    
    <div class="upRightOptions rightDivContent"  style="right:150px">    
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu2" data-toggle="dropdown" title="Choose the layout to display with">
        <span class="fa fa-diamond"></span>&nbsp;<span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
        <% for (File temName: allLayouts) { %>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Opens or closes all of the agenda items for the meeting"
              href="MeetMerge.htm?id=<%=id%>&tem=<% ar.writeHtml(temName.getName()); %>" >
                  <span class="fa fa-diamond"></span>&nbsp;
                  <% ar.writeHtml(conditionFileName(temName.getName())); %></a></li>
        <% } %>
        </ul>
      </span>
    </div>    
    <div class="well">
    <%
    
    ChunkTemplate.streamIt(ar.w, layoutFile,   meetingJSON, ar.getUserProfile().getCalendar() );         
    
%>
    </div>
  </div>



<script src="<%=ar.retPath%>new_assets/templates/ActionItemCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/CommentModal.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/ResponseModal.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/DecisionModal.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/AttachActionCtrl.js"></script>
<%!
/**
* convert XxxYyyZzz.chmtl 
*    into Xxx Yyy Zzz
*/
public String conditionFileName(String fileName) {
    if (!fileName.endsWith("chtml")) {
        return fileName;
    }
    StringBuilder sb = new StringBuilder();
    sb.append(fileName.charAt(0));
    for (int i=1; i<fileName.length()-6; i++) {
        char ch = fileName.charAt(i);
        if (ch>='A' && ch<='Z') {
            sb.append(' ');
        }
        sb.append(ch);
    }
    return sb.toString();
}

%>

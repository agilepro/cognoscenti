<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="org.socialbiz.cog.LicenseForUser"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%@page import="org.socialbiz.cog.mail.ChunkTemplate"
%><%@page import="com.purplehillsbooks.json.JSONException"
%><%@page import="java.util.HashSet"
%><%

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);

    String id = ar.reqParam("id");
    MeetingRecord meet = ngw.findMeeting(id);

    JSONObject meetingJSON = meet.getFullJSON(ar, ngw);
    
    //add some calculation
    long time = meet.getStartTime();
    JSONArray agenda = meetingJSON.getJSONArray("agenda");
    for (int i=0; i<agenda.length(); i++) {
        JSONObject agendaItem = agenda.getJSONObject(i);
        agendaItem.put("schedStart", time);
        time = time + (agendaItem.getLong("duration")*60000);
        agendaItem.put("schedEnd", time);
        
        JSONArray actionItems = agendaItem.getJSONArray("actionItems");
        JSONArray aiList = new JSONArray();
        for (int j=0; j<actionItems.length(); j++) {
            String guid = actionItems.getString(j);
            GoalRecord gr = ngw.getGoalOrNull(guid);
            if (gr!=null) {
                JSONObject oneAI = new JSONObject();
                oneAI.put("synopsis", gr.getSynopsis());
                oneAI.put("id", gr.getId());
                oneAI.put("state", gr.getState());
                oneAI.put("url", ar.baseURL + ar.getResourceURL(ngw, "task"+gr.getId()+".htm"));
                aiList.put(oneAI);
            }
        }
        agendaItem.put("aiList", aiList);
        
        JSONArray docList = agendaItem.getJSONArray("docList");
        JSONArray attList = new JSONArray();
        for (int j=0; j<docList.length(); j++) {
            String guid = docList.getString(j);
            int pos = guid.lastIndexOf("@");
            guid = guid.substring(pos+1);
            AttachmentRecord arec = ngw.findAttachmentByID(guid);
            if (arec!=null) {
                JSONObject oneAI = new JSONObject();
                oneAI.put("id", arec.getId());
                oneAI.put("name", arec.getNiceName());
                oneAI.put("url", ar.baseURL + ar.getResourceURL(ngw, "docinfo"+arec.getId()+".htm"));
                attList.put(oneAI);
            }
        }
        agendaItem.put("attList", attList);        
    }
    
    
    List<File> allLayouts = MeetingRecord.getAllLayouts(ar, ngw);
    
    String layoutName = ar.defParam("tem", "FullDetail.chtml");
    File layoutFile = MeetingRecord.findMeetingLayout(ar,ngw,layoutName);        
    
    
    %>
    <script>    window.setMainPageTitle("Meeting Display"); </script>
    
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
              href="meetingFull.htm?id=<%=id%>" >Edit Meeting</a></li>
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



<script src="<%=ar.retPath%>templates/ActionItemCtrl.js"></script>
<script src="<%=ar.retPath%>templates/CommentModal.js"></script>
<script src="<%=ar.retPath%>templates/ResponseModal.js"></script>
<script src="<%=ar.retPath%>templates/OutcomeModal.js"></script>
<script src="<%=ar.retPath%>templates/DecisionModal.js"></script>
<script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachTopicCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachActionCtrl.js"></script>
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

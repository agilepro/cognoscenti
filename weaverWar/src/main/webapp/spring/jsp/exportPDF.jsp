<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%/*
Required parameter:

    1. pageId : This is the id of a Workspace and used to retrieve NGWorkspace.

*/

    ar.assertLoggedIn("Must be logged in to generate a PDF");

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

    UserProfile uProf = ar.getUserProfile();
    String pageTitle = ngp.getFullName();
%>


<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    $scope.idontknow = "";

    $scope.createPdf = function() {
        document.getElementById("exportPdfFrom").submit();
        alert("look");
    }
});

</script>

<script>
    window.setMainPageTitle("Print Workspace to PDF");

    function unSelect(type){
        var obj = document.getElementById(type);
        obj.checked = false;
    }
    function selectAll(type){
        if(type == 'public'){
            var obj = document.getElementsByName("publicNotes");
            var allPublic = document.getElementById("publicNotesAll");
            var setting = true;
            for(i=0; i<obj.length ; i++){
                if(allPublic.checked == true){
                    obj[i].checked = true;
                }else{
                    obj[i].checked = false;
                }
            }
        }
        if(type == 'meeting'){
            var obj = document.getElementsByName("meetings");
            var allPublic = document.getElementById("meetingAll");
            for(i=0; i<obj.length ; i++){
                if(allPublic.checked == true){
                    obj[i].checked = true;
                }else{
                    obj[i].checked = false;
                }
            }
        }
    }
</script>


<!-- MAIN CONTENT SECTION START -->
<div>

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="" ng-click="createPdf()">Export PDF</a></li>
        </ul>
      </span>
    </div>


    <form name="exportPdfFrom" id="exportPdfFrom"  action="pdf/page.pdf"  method="get">
        <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
        <input type="submit" class="btn btn-primary btn-raised" value="Export PDF" />

        <table class="table">
        <tr><td>Decisions : </td>
            <td><input type="checkbox" checked="checked" name="decisions"  value="decisions"/></td></tr>
        <tr><td>Attachments : </td>
            <td><input type="checkbox" checked="checked" name="attachments"  value="attachments"/></td></tr>
        <tr><td>ActionItems : </td>
            <td><input type="checkbox" checked="checked" name="actionItems"  value="actionItems"/></td></tr>
        <tr><td>Roles : </td>
            <td><input type="checkbox" checked="checked" name="roles"  value="roles"/></td></tr>
        <tr><td>Include Comments : </td>
            <td><input type="checkbox" checked="checked" name="comments"  value="comments"/></td></tr>
        <tr><td>Debug Lines : </td>
            <td><input type="checkbox" name="debugLines"  value="debugLines"/></td></tr>
        </table>

        <div class="generalHeading">Discussion Topics :</div>
        <table border="0px solid gray" class="table">
            <thead>
            <tr>
               <th width="75%">&nbsp;&nbsp;&nbsp;<b>Subject</b></th>
                <th><b><input type="checkbox" name="publicNotesAll" id="publicNotesAll" 
                              onclick="return selectAll('public')" checked="checked" /> &nbsp; Select All </b></th>
            </tr>
            </thead>
            <%
                for(TopicRecord noteRec:ngp.getAllDiscussionTopics()){
                    if (noteRec.isDeleted()) {
                        continue;
                    }
                    if (noteRec.isDraftNote()) {
                        continue;
                    }
            %>
            <tr>
                <td>
                  &nbsp;<i class="fa fa-lightbulb-o"></i>&nbsp; <% ar.writeHtml(noteRec.getSubject()); %>
                </td>
                <td>
                  &nbsp;&nbsp;&nbsp; <input type="checkbox" name="publicNotes" checked="checked" value="<%ar.writeHtml(noteRec.getId());%>"  onclick="return unSelect('publicNotesAll')"/>
                </td>
            </tr>
          <%
            }
          %>
        </table>
        
        
        <div class="generalHeading">Meetings :</div>
        <table border="0px solid gray" class="table">
            <thead>
            <tr>
               <th width="75%">&nbsp;&nbsp;&nbsp;<b>Meeting</b></th>
                <th><b><input type="checkbox" name="meetingAll" id="meetingAll" 
                              onclick="return selectAll('meeting')" checked="checked" /> &nbsp; Select All </b></th>
            </tr>
            </thead>
            <%
                for(MeetingRecord meetRec:ngp.getMeetings()){
            %>
            <tr>
                <td>
                  &nbsp;<i class="fa fa-gavel"></i>&nbsp; <% ar.writeHtml(meetRec.getName()); %>
                </td>
                <td>
                  &nbsp;&nbsp;&nbsp; <input type="checkbox" name="meetings" checked="checked" value="<%ar.writeHtml(meetRec.getId());%>"  onclick="return unSelect('meetingAll')"/>
                </td>
            </tr>
          <%
            }
          %>
        </table>
    </form>

</div>

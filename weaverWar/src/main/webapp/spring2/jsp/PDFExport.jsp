<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/include.jsp"
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
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Print PDF");
    $scope.idontknow = "";

    $scope.createPdf = function() {
        document.getElementById("exportPdfFrom").submit();
    }
});

</script>

<script>

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
<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">Refresh</button>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name">Print Workspace to PDF</h1>
    </span>
</div>
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<div class="container-fluid override">
            <span class="btn btn-raised btn-default btn-comment mx-5" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a role="menuitem" tabindex="-1"
            ng-click="createPdf()">Export PDF</a>
        </span>
        </div>
        <div class="d-flex col-12 mx-5"><div class="contentColumn">
    <form name="exportPdfFrom" id="exportPdfFrom"  action="pdf/page.pdf"  method="get">
        <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
        

        <table class="table">
        <tr><td width="75%">Decisions : </td>
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
<hr/>
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
        <hr/>
        
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
    </div>
</div>

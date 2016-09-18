<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%/*
Required parameter:

    1. pageId : This is the id of a Workspace and used to retrieve NGPage.

*/

    ar.assertLoggedIn("Must be logged in to generate a PDF");

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

    UserProfile uProf = ar.getUserProfile();
    String pageTitle = ngp.getFullName();
%>


<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
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
            for(i=0; i<obj.length ; i++){
                var allPublic = document.getElementById("publicNotesAll");
                if(allPublic.checked == true){
                    obj[i].checked = true;
                }else{
                    obj[i].checked = false;
                }
            }
        }else if(type == 'member'){
            var obj = document.getElementsByName("memberNotes");
            for(i=0; i<obj.length ; i++){
                var allMember = document.getElementById("memberNotesAll");
                if(allMember.checked == true){
                    obj[i].checked = true;
                }else{
                    obj[i].checked = false;
                }
            }
        }
    }
</script>


<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Export PDF
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="" ng-click="createPdf()">Export PDF</a></li>
            </ul>
          </span>

        </div>
    </div>


    <form name="exportPdfFrom" id="exportPdfFrom"  action="pdf/page.pdf"  method="get">
        <input type="hidden" name="encodingGuard" value="<%ar.writeHtml("\u6771\u4eac");%>"/>
        <br/>
        <table width="800">
            <tr>
                <td colspan="2" align="right">
                    <input type="submit" class="btn btn-primary" value="Export PDF" >
                </td>
            </tr>
        </table>
        <div class="generalHeading">Public Topics :</div>
        <br>
        <table border="0px solid gray" class="gridTable" width="800">
            <thead>
            <tr>
               <th width="75%">&nbsp;&nbsp;&nbsp;<b>Subject</b></th>
                <th><b><input type="checkbox" name="publicNotesAll" id="publicNotesAll" onclick="return selectAll('public')" checked="checked" /> &nbsp; Select All </b></th>
            </tr>
            </thead>
            <tr>
                <td colspan="2">&nbsp;</td>
            </tr>
            <%
                List<TopicRecord> publicComments = ngp.getVisibleNotes(ar, SectionDef.PUBLIC_ACCESS);
                for(int i=0;i<publicComments.size();i++){
                    TopicRecord noteRec = publicComments.get(i);
            %>
            <tr>
                <td>
                  &nbsp;&nbsp;&nbsp; <% ar.writeHtml(noteRec.getSubject()); %>
                </td>
                <td>
                  &nbsp;&nbsp;&nbsp; <input type="checkbox" name="publicNotes" checked="checked" value="<%ar.writeHtml(noteRec.getId());%>"  onclick="return unSelect('publicNotesAll')"/>
                </td>
            </tr>
          <%
            }
          %>
        </table>
        <br><br>
<%
if (ar.isMember()) {
%>
        <div class="generalHeading">Member Topics :</div>
        <br>
        <table border="0px solid gray" class="gridTable" width="800">
            <%
                List<TopicRecord> memberComments = ngp.getVisibleNotes(ar, SectionDef.MEMBER_ACCESS);
                if(memberComments.size() == 0) {
                    %> No member topics found. <%
                }
                else{
            %>
            <thead>
                <tr>
                    <th width="75%">&nbsp;&nbsp;&nbsp;<b>Subject</b></th>
                    <th><b><input type="checkbox" name="memberNotesAll" id="memberNotesAll" onclick="return selectAll('member')" /> &nbsp; Select All</b></th>
                </tr>
            </thead>
            <tr>
                <td colspan="2">&nbsp;</td>
            </tr>
         <%
                    for(int i=0;i<memberComments.size();i++) {
                        TopicRecord noteRec = memberComments.get(i);
         %>
            <tr>
                <td>
                  &nbsp;&nbsp;&nbsp; <%ar.writeHtml(noteRec.getSubject()); %>
                </td>
                <td>
                  &nbsp;&nbsp;&nbsp;<input type="checkbox" name="memberNotes"  value="<%ar.writeHtml(noteRec.getId()); %>" onclick="return unSelect('memberNotesAll')"/>
                </td>
            </tr>
          <%            }
                    }
          %>

        </table>
<% } %>

    </form>

</div>

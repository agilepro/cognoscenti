<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="java.net.URLDecoder"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%/*
Required parameters:

    1. pageId : This is the id of an project and here it is used to retrieve NGPage (Project's Details).
    2. aid : This is document/attachment id which is used to get information of the attachment being downloaded.

*/

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();
    UserProfile uProf = ar.getUserProfile();


    String aid      = ar.reqParam("aid");
    AttachmentRecord attachment = ngp.findAttachmentByIDOrFail(aid);
    String version  = ar.defParam("version", null);

    JSONObject docInfo = attachment.getJSON4Doc(ar, ngp);

    long fileSizeInt = attachment.getFileSize(ngp);
    String fileSize = String.format("%,d", fileSizeInt);

    boolean canAccessDoc = AccessControl.canAccessDoc(ar, ngp, attachment);


    String access = "Member Only";
    if (attachment.getVisibility()<=1) {
        access = "Public";
    }

    String accessName = attachment.getNiceName();
    String relativeLink = "a/"+accessName+"?version="+attachment.getVersion();
    String permaLink = ar.getResourceURL(ngp, relativeLink);
    if("URL".equals(attachment.getType())){
        permaLink = attachment.getStorageFileName();
    }

//TODO: this terminology is 'getEditModeUser' is really about 'maintainers' of a document.
//should be reworked
    String editUser = attachment.getEditModeUser();

    AddressListEntry ale = new AddressListEntry(attachment.getModifiedBy());


%>

<link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet" />

<!-- something in here is needed for the html bind -->
<link href="<%=ar.retPath%>jscript/textAngular.css" rel="stylesheet" />
<script src="<%=ar.retPath%>jscript/textAngular-rangy.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular-sanitize.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular.min.js"></script>

<script type="text/javascript">
document.title="<% ar.writeJS(attachment.getDisplayName());%>";

var app = angular.module('myApp', ['ui.bootstrap','textAngular']);
app.controller('myCtrl', function($scope, $http) {
    $scope.docInfo = <%docInfo.write(out,2,4);%>;
    $scope.myComment = "";
    $scope.canUpdate = <%=canAccessDoc%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.saveComment = function() {
        var saveRecord = {};
        saveRecord.id = $scope.docInfo.id;
        saveRecord.universalid = $scope.docInfo.universalid;
        saveRecord.newComment = $scope.myComment;
        $scope.isCreatingComment = false;
        $scope.savePartial(saveRecord);
    }
    $scope.savePartial = function(recordToSave) {
        var postURL = "docsUpdate.json?did="+recordToSave.id;
        var postdata = angular.toJson(recordToSave);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.docInfo = data;
            $scope.myComment = "";
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

});
</script>



<script type="text/javascript" src="<%=ar.retPath%>jscript/attachment.js"></script>



<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Access Document
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem"
                  href="docinfo{{docInfo.id}}.htm">Access Document</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="docsRevise.htm?aid={{docInfo.id}}" >Upload New Version</a></li>
              <li role="presentation"><a role="menuitem"
                  href="editDetails{{docInfo.id}}.htm">Edit Details</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="fileVersions.htm?aid={{docInfo.id}}">List Versions</a></li>
              <li role="presentation"><a role="menuitem"
                  href="sendNote.htm?att={{docInfo.id}}">Send Document by Email</a></li>
            </ul>
          </span>

        </div>
    </div>



    <table border="0px solid red" width="800">
        <tr>
            <td colspan="3">
                <table>
                    <tr>
                        <td class="gridTableColummHeader">
                            <span ng-show="'FILE'==docInfo.attType">Document Name:</span>
                            <span ng-show="'URL'==docInfo.attType">Link Name:</span>
                        </td>
                        <td style="width: 20px;"></td>
                        <td><b>{{docInfo.name}}</b>
                            <span ng-show="docInfo.deleted">
                                <img src="<%=ar.retPath%>deletedLink.gif"> <font color="red">(DELETED)</font>
                            </span>
                        </td>
                    </tr>
                    <tr>
                        <td style="height: 5px"></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader">Description:</td>
                        <td style="width: 20px;"></td>
                        <td>
                        <%ar.writeHtml(attachment.getDescription());%>
                        </td>
                    </tr>
                    <tr>
                        <td style="height: 5px"></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader">
                        <%if("FILE".equals(attachment.getType())){ %> Uploaded by: <%}else if("URL".equals(attachment.getType())){ %>
                        Attached by <%} %>
                        </td>
                        <td style="width: 20px;"></td>
                        <td>
                        <% ale.writeLink(ar); %> on <% SectionUtil.nicePrintTime(ar, attachment.getModifiedDate(), ar.nowTime); %>
                        </td>
                    </tr>
                    <tr>
                        <td style="height: 5px"></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader">Accessibility:</td>
                        <td style="width: 20px;"></td>
                        <%if(!attachment.getReadOnlyType().equals("on")){ %>
                        <td>
                        <% ar.writeHtml(access);%>
                        </td>
                        <%}else{ %>
                        <td>
                        <% ar.writeHtml(access);%> and Read only Type</td>
                        <%} %>
                    </tr>
<%if("FILE".equals(attachment.getType())){ %>
                    <tr>
                        <td style="height: 5px"></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader">Version:</td>
                        <td style="width: 20px;"></td>
                        <td><%=attachment.getVersion()%>
                         - Size: <%=fileSize%> bytes</td>
                    </tr>
                    <tr>
                        <td style="height: 5px"></td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader">Maintained by:</td>
                        <td style="width: 20px;"></td>
                        <td><% ar.writeHtml(editUser); %></td>
                    </tr>
<%}%>
                </table>
            </td>
        </tr>
        <tr>
            <td style="height: 10px"></td>
        </tr>
        <tr>
            <td class="gridTableColummHeader"></td>
            <td style="width: 20px;"></td>
            <%
                if (attachment.getVisibility() == SectionDef.PUBLIC_ACCESS || (attachment.getVisibility() == SectionDef.MEMBER_ACCESS && (ar.isLoggedIn() || canAccessDoc)))
                {
            %>
            <td>
            <%if("FILE".equals(attachment.getType())){ %> <a
                href="<%=ar.retPath%><%ar.writeHtml(permaLink); %>"><img
                src="<%=ar.retPath%>download.gif" border="0"></a> <%}else if("URL".equals(attachment.getType())){ %>
            <a href="#"
                onclick="return openWin(<%ar.writeQuote4JS(permaLink); %>);"><img
                src="<%=ar.retPath%>assets/btnAccessLinkURL.gif" border="0"></a> <%} %>

            </td>
        </tr>
        <% if (ar.isLoggedIn() && !attachment.isDeleted() && "FILE".equals(attachment.getType()) ) { %>
        <tr>
            <td style="height: 20px"></td>
        </tr>
<% }
    }
    else{
%>
        <tr>
            <td class="gridTableColummHeader"></td>
            <td style="width: 20px;"></td>
            <td><a href="#"><img
                src="<%=ar.retPath%>downloadInactive.gif" border="0"></a><br />
            <span class="red">* You need to log in to download this
            document.</span></td>
        </tr>
<%
    }
%>

        <tr>
            <td></td>
            <td style="width: 20px;"></td>
            <td>

                <div ng-repeat="cmt in docInfo.comments">
                   <div class="leafContent" style="border: 1px solid lightgrey;border-radius:8px;padding:5px;margin-top:15px;background-color:#EEE">
                       <div style="">
                           <i class="fa fa-comments-o"></i> Comment {{cmt.time | date}} - <a href="#"><span class="red">{{cmt.userName}}</span></a>
                       </div>
                       <div class="" ng-click="startEdit(cmt)" style="border: 1px solid lightgrey;border-radius:6px;padding:5px;background-color:white">
                         <div ng-bind-html="cmt.html"></div>
                       </div>
                   </div>
                </div>

                <div style="height:20px;"></div>


                <div ng-show="canUpdate">
                    <div class="well leafContent" style="width:100%" ng-show="isCreatingComment">
                      <div ng-model="myComment"
                          ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]"
                          text-angular="" class="" style="width:100%;"></div>

                      <button ng-click="saveComment()" class="btn btn-danger">Create <i class="fa fa-comments-o"></i> Comment</button>
                          <button ng-click="isCreatingComment=false" class="btn btn-danger">Cancel</button>
                    </div>
                    <div ng-hide="isCreatingComment" style="margin:20px;">
                        <button ng-click="isCreatingComment=true" class="btn btn-default">
                            Create New <i class="fa fa-comments-o"></i> Comment</button>
                    </div>
                </div>
                <div ng-hide="canUpdate">
                    <i>You have to be logged in and a member of this project in order to create a comment</i>
                </div>

            </td>
        </tr>

        <tr>
            <td style="height: 10px"></td>
        </tr>
        <tr>
            <td class="gridTableColummHeader"></td>
            <td style="width: 20px;"></td>
            <td><span class="tipText">This web page is a secure and
            convenient way to send documents to others collaborating on projects.
            The email message does not carry the document, but only a link to this
            page, so that email is small. Then, from this page, you can get the
            very latest version of the document. Documents can be protected by
            access controls.</span></td>
        </tr>

    </table>

</div>
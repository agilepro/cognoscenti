<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@page import="org.socialbiz.cog.spring.Constant"
%><%@page import="org.socialbiz.cog.dms.RemoteLinkCombo"
%><%@page import="org.socialbiz.cog.AttachmentVersion"
%><%@page import="org.socialbiz.cog.dms.ConnectionType"
%><%@page import="org.socialbiz.cog.dms.ConnectionSettings"
%><%

    String pageId  = ar.reqParam("pageId");
    String go      = ar.defParam("go", "listAttachments.htm" );
    NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to see meetings");

    String aid      = ar.reqParam("aid");
    AttachmentRecord attachment = ngp.findAttachmentByIDOrFail(aid);

    JSONObject docInfo = attachment.getJSON4Doc(ar, ngp);

    JSONArray allLabels = ngp.getJSONLabels();

// NEEDED???
    String atype = attachment.getType();
    boolean isExtra    = atype.equals("EXTRA");
    boolean isGone     = atype.equals("GONE");
    boolean isURL      = "URL".equals(atype);
    boolean isFile     = "FILE".equals(atype);
    boolean allowPrivate = ngp.getSite().getAllowPrivate();
    
    List<AttachmentVersion> vers = attachment.getVersions(ngp);
    boolean isGhost = vers.size()==0;
    boolean isModified = attachment.hasUncommittedChanges(vers);
    long fileSizeInt = attachment.getFileSize(ngp);
    String fileSize = String.format("%,d", fileSizeInt);
    String mimeType=MimeTypes.getMimeType(attachment.getNiceName());

/*   PROTOTYPE
    $scope.docInfo = {
      "attType": "FILE",
      "deleted": false,
      "description": "",
      "id": "8170",
      "labelMap": {
        "NO Game": true,
        "Urgent": true
      },
      "modifiedtime": 1433396730716,
      "modifieduser": "kswenson@us.fujitsu.com",
      "name": "Wines_of_Silicon_Valley.pdf",
      "public": false,
      "size": 1149455,
      "universalid": "EZIGICMWG@facility-1-wellness-circle@8170",
      "upstream": false
    };
*/
%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Document Details");
    $scope.docInfo = <%docInfo.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.today = (new Date()).getTime();
    $scope.convertDays = function(time) {
        var fract = (time-$scope.today)/(24*60*60*1000);
        return Math.floor(fract+.4);
    }
    $scope.allowPrivate = <%=allowPrivate%>;
    if (!$scope.allowPrivate) {
        $scope.docInfo.public = true;
    }

    $scope.futureDays = 30;
    if ($scope.docInfo.purgeDate>0) {
        $scope.futureDays = $scope.convertDays($scope.docInfo.purgeDate);
    }

    $scope.startPurge = function() {
        $scope.docInfo.purgeDate = $scope.today + ($scope.futureDays*24*60*60*1000);
    }
    $scope.stopPurge = function() {
        $scope.docInfo.purgeDate = 0;
    }
    $scope.setDays = function() {
        //first, make sure that the future days is reasonable
        if ($scope.futureDays<=1) {
            $scope.futureDays = 1;
        }
        $scope.docInfo.purgeDate = $scope.today + ($scope.futureDays*24*60*60*1000);
    }

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.hasRole = function(roleName) {
        return $scope.docInfo.labelMap[roleName];
    }
    $scope.toggleRole = function(role) {
        $scope.docInfo.labelMap[role.name] = !$scope.docInfo.labelMap[role.name];
    }

    $scope.hasLabel = function(searchName) {
        return $scope.docInfo.labelMap[searchName];
    }
    $scope.toggleLabel = function(label) {
        $scope.docInfo.labelMap[label.name] = !$scope.docInfo.labelMap[label.name];
    }

    $scope.saveDoc = function() {
        var postURL = "docsUpdate.json?did="+$scope.docInfo.id;
        var postdata = angular.toJson($scope.docInfo);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            window.location = "<%ar.writeJS(go);%>";
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

});
</script>


<style>
.attentionBox {
    border:1px solid #f30000;
    padding:20px;
    margin:20px;
    background-color:#fef9d8;
}
.spacey {
    width:100%;
}
.spacey tr td {
    padding:3px;
}
.firstcol {
    width:130px;
}
</style>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem"
              href="#" ng-click="saveDoc()">Save Changes</a></li>
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


    <table class="spacey">
        <tr>
            <td class="firstColumn">Type:</td>
            <td>
                <input type="hidden" name="ftype" value="{{docInfo.attType}}">
                <span ng-show="{{docInfo.attType=='FILE'}}"><img src="<%=ar.retPath%>assets/images/iconFile.png"> File</span>
                <span ng-show="{{docInfo.attType=='URL'}}"><img src="<%=ar.retPath%>assets/images/iconUrl.png"> URL</span>
            </td>
        </tr>
        <tr>
            <td class="firstColumn">Access Name:</td>
            <td><input type="text" ng-model="docInfo.name" class="form-control"/>
            </td>
        </tr>
        <tr ng-show="'URL'==docInfo.attType">
            <td class="firstColumn">URL:</td>
            <td><input type="text" class="form-control" ng-model="docInfo.url"/></td>
        </tr>
        <tr>
            <td class="firstColumn">Description:</td>
            <td>
                <textarea ng-model="docInfo.description"  class="form-control"></textarea>
            </td>
        </tr>


        <% if (isURL) {}
           else if (isGhost) { %>
        <tr class="attentionBox">
            <td class="firstColumn">ATTENTION:</td>
            <td>
                Document has disappeared without a trace.
                The next time you synchronize it will be removed from the list of attachments.
            </td>
        </tr>
        <% } else if (isGone) { %>
        <tr class="attentionBox">
            <td class="firstColumn">ATTENTION:</td>
            <td>
                <table><tr><td width="200">
                <button type="submit" class="btn btn-primary btn-raised" name="actionType" value="Remove">Remove</button>
                <br/>
                <button type="submit" class="btn btn-primary btn-raised" name="actionType" value="RefreshWorking">Refresh from History</button>
                </td><td>
                Document has disappeared from the directory.  Do you want to mark it as deleted in the
                workspace, or refresh from the latest backed up copy?
                </td></tr></table>
            </td>
        </tr>
        <% } else if (isExtra) { %>
        <tr class="attentionBox">
            <td class="firstColumn">ATTENTION:</td>
            <td>
                <table><tr><td width="100">
                <button type="submit" class="btn btn-primary btn-raised" name="actionType" value="Add">Add</button>
                </td><td>
                Document has appeared in the workspace folder. <br/>Do you want to add it as an attachment?
                </td></tr></table>
            </td>
        </tr>
        <% } else if (isModified) { %>
        <tr class="attentionBox">
            <td class="firstColumn">ATTENTION:</td>
            <td>
                <table><tr><td width="200">
                <button type="submit" class="btn btn-primary btn-raised" name="actionType" value="Commit">Commit Changes</button>
                </td><td>
                Document has been modified in the workspace.  Do you want to commit these
                changes for safekeeping?
                </td></tr></table>
            </td>
        </tr>
        <% } %>

        <tr>
            <td class="firstColumn">Last Modified:</td>
            <td> {{docInfo.modifiedtime|date}} &nbsp;&nbsp; by &nbsp;&nbsp; {{docInfo.modifieduser}} </td>
        </tr>
        <%if(isFile)
        {
        %>
        <tr>
            <td class="firstColumn">Linked to:</td>
            <td  valign="top">
               <%
               if(attachment.hasRemoteLink()) {

                    RemoteLinkCombo rlc = attachment.getRemoteCombo();
                    String folderId = rlc.folderId;
                    UserPage up = ar.getUserPage();
                    ConnectionSettings cSet = up.getConnectionSettingsOrNull(folderId);
                    ConnectionType cType = up.getConnectionOrNull(folderId);
                    if(cType==null){
                        %><div>Connection broken <%ar.writeHtml(rlc.rpath);%></div><%
                    }
                    else if (cSet == null) {
                        String url = cType.getFullPath(rlc.rpath);
                        %><div>Public Web: <a href="<%ar.writeHtml(url);%>"><%ar.writeHtml(url);%></a></div><%
                    }
                    else if (cSet.isDeleted()){
                        String url = cType.getFullPath(rlc.rpath);
                        %><div>Connection Deleted: <%ar.writeHtml(url);%></div><%
                    }
                    else {
                        String connectionName = cSet.getDisplayName();
                        String url = cType.getFullPath(rlc.rpath);
                        AddressListEntry ale = new AddressListEntry(rlc.userKey);
                        %><br/><br/>
                        <b><%ar.writeHtml(connectionName);%></b>&nbsp;&nbsp; by &nbsp;&nbsp;<% ale.writeLink(ar); %>
                        <br/>
                        <a href="<%ar.writeHtml(url);%>"><%ar.writeHtml(url);%></a><%
                    }
               }else{
                   %><div>Not Linked</div><%
               } %>
            </td>
        </tr>
        <%
        }
        %>
        <tr>
            <td class="firstColumn">Permission:</td>
            <td  valign="top">
            <% if (!attachment.isPublic()) {
                   String publicNotAllowedMsg = "";
                   if("yes".equals(ngp.getAllowPublic())){
            %>
                       <input type="checkbox" ng-model="docInfo.public" ng-disabled="!allowPrivate" >
                       <img src="<%=ar.retPath %>assets/images/iconPublic.png"> Public Access
            <%
                   }else{
                       publicNotAllowedMsg = ar.getMessageFromPropertyFile("public.attachments.not.allowed", null);
                       ar.writeHtml(publicNotAllowedMsg);
                   }
               } else {
            %>
                   <input type="checkbox" ng-model="docInfo.public" ng-disabled="!allowPrivate" />
                   <img src="<%=ar.retPath %>assets/images/iconPublic.png" name="PUB" alt="Public" title="Public"/> Public Access
            <% } %>
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            <input type="checkbox" name="visMember" value="MEM" checked="checked" disabled="disabled"/>
            <img src="<%=ar.retPath %>assets/images/iconMember.png" name="MEM" alt="Member" title="Member" /> Member Access
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            <input type="checkbox" name="visUpstream" value="UPS"
                   <%if(attachment.isUpstream()){%> checked="checked" <%}%>/>
            <img src="<%=ar.retPath %>assets/images/iconUpstream.png" /> Upstream Sync
            </td>
        </tr>

        <tr>
            <td class="firstColumn">Labels:</td>
            <td>
              <span class="dropdown" ng-repeat="role in allLabels">
                <button class="labelButton" 
                    type="button" id="menu2"
                    data-toggle="dropdown" 
                    style="background-color:{{role.color}};"
                    ng-show="hasLabel(role.name)">
                    {{role.name}} <i class="fa fa-close"></i></button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                   <li role="presentation"><a role="menuitem" title="{{add}}"
                      ng-click="toggleLabel(role)" style="border:2px {{role.color}} solid;">
                      Remove Label:<br/>{{role.name}}</a></li>
                </ul>
              </span>
              <span>
                 <span class="dropdown">
                    <button class="btn btn-sm btn-primary btn-raised labelButton" 
                       type="button" 
                       id="menu1" 
                       data-toggle="dropdown"
                       title="Add Label"
                       style="padding:5px 10px">
                       <i class="fa fa-plus"></i></button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" 
                        style="width:320px;left:-130px">
                         <li role="presentation" ng-repeat="rolex in allLabels" style="float:left">
                             <button role="menuitem" tabindex="-1" ng-click="toggleLabel(rolex)" class="labelButton" 
                             ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}}">
                                 {{rolex.name}}</button>
                         </li>
                    </ul>
                 </span>
              </span>
            </td>
        </tr>
        <tr>
            <td class="firstColumn">Storage Term:</td>
            <td>
                <div ng-hide="docInfo.purgeDate" class="form-inline form-group">
                    <button class="btn btn-default btn-raised" ng-click="startPurge()"><i class="fa  fa-square-o"></i> Purge</button></div>
                <div ng-show="docInfo.purgeDate" class="form-inline form-group">
                    <button class="btn btn-default btn-raised" ng-click="stopPurge()" style="margin-right:20px">
                        <i class="fa  fa-check-square-o"></i> Purge in {{convertDays(docInfo.purgeDate)}} days</button>
                    <button ng-click="setDays()" class="btn btn-primary btn-raised">Set</button>
                    <input ng-model="futureDays" type="text" class="form-control"/>
                    
                </div>
                {{docInfo.purgeDate|date}}
            </td>
        </tr>
        <tr>
            <td class="firstColumn"></td>
            <td >
                <button ng-click="saveDoc()" class="btn btn-primary btn-raised">Save Changes</button>&nbsp;
            </td>
        </tr>
        <%
        if(isFile)
        {
        %>

        <tr>
            <td class="firstColumn">Accessible Link:</td>
            <td>
            <%
                String docLink=ar.retPath+ar.getResourceURL(ngp, "docinfo" + attachment.getId()
                      + ".htm?")+AccessControl.getAccessDocParams(ngp, attachment);
            %>
            Copy this link ( <a href="<%=docLink%>">{{docInfo.name}}</a> ) for unauthenticated access to attachment
            </td>
        </tr>
        <tr>
            <td class="firstColumn">Storage Name:</td>
            <td>
            <% ar.writeHtml(attachment.getStorageFileName()); %>
            </td>
        </tr>
        <tr>
            <td class="firstColumn">Size:</td>
            <td>
            <% ar.writeHtml(fileSize); %> bytes
            </td>
        </tr>
        <tr>
            <td class="firstColumn">Mime Type:</td>
            <td>
            <%
                ar.writeHtml(mimeType);
            %>
            </td>
        </tr>
        <%
        }
        %>
    </table>

</div>


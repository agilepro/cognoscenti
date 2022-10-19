<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="java.net.URLDecoder"
%><%@page import="com.purplehillsbooks.weaver.AttachmentVersion"
%><%@page import="com.purplehillsbooks.weaver.LicenseForUser"
%><%@page import="com.purplehillsbooks.weaver.AccessControl"
%><%/*
Required parameters:

    1. pageId : This is the id of a workspace and here it is used to retrieve NGWorkspace (Workspace's Details).
    2. aid : This is document/attachment id which is used to get information of the attachment being downloaded.

*/

    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace(); 
    ar.setPageAccessLevels(ngp);
    NGBook site = ngp.getSite();
    String wsUrl = ar.baseURL + ar.getResourceURL(ngp, "");
    UserProfile uProf = ar.getUserProfile();
    if (uProf==null) {
        throw new Exception("DocDetail.jsp can only be used when logged in");
    }
    String currentUser = uProf.getUniversalId();
    String currentUserName = uProf.getName();
    String currentUserKey = uProf.getKey();

    String aid      = ar.reqParam("aid");
    AttachmentRecord attachment = ngp.findAttachmentByIDOrFail(aid);
    String version  = ar.defParam("version", null);

    long fileSizeInt = attachment.getFileSize(ngp);
    String fileSize = String.format("%,d", fileSizeInt);

    boolean canAccessDoc = AccessControl.canAccessDoc(ar, ngp, attachment);
    boolean isMember = ar.canUpdateWorkspace();

    String relativeLink = "a/"+attachment.getNiceName()+"?version="+attachment.getVersion();
    String permaLink = ar.getResourceURL(ngp, relativeLink);
    if("URL".equals(attachment.getType())){
        permaLink = attachment.getURLValue();
    }
    
    
    JSONObject workspaceInfo = ngp.getConfigJSON();
    AddressListEntry ale = new AddressListEntry(attachment.getModifiedBy());

    JSONArray linkedMeetings = new JSONArray();
    for (MeetingRecord meet : attachment.getLinkedMeetings(ngp)) {
        linkedMeetings.put(meet.getListableJSON(ar));
    }
    JSONArray linkedTopics = new JSONArray();
    for (TopicRecord note : attachment.getLinkedTopics(ngp)) {
        linkedTopics.put(note.getJSON(ngp));
    }

    JSONArray linkedGoals = new JSONArray();
    for (GoalRecord goal : ngp.getAllGoals()) {
        boolean found = false;
        for (String otherId : goal.getDocLinks()) {
            if (otherId.equals(attachment.getUniversalId())) {
                found = true;
            }
        }
        if (found) {
            linkedGoals.put(goal.getJSON4Goal(ngp));
        }
    }

    JSONArray attachmentList = ngp.getJSONAttachments(ar);
    String docSpaceURL = "";
    if (uProf!=null) {
        LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
        docSpaceURL = ar.baseURL +  "api/" + site.getKey() + "/" + ngp.getKey()
                    + "/summary.json?lic="+lfu.getId();
    }
    String privateLink = ar.baseURL + ar.getResourceURL(ngp, "DocDetail.htm?aid="+aid);

    JSONArray allLabels = ngp.getJSONLabels();
    
    List<HistoryRecord> histRecs = ngp.getHistoryForResource(HistoryRecord.CONTEXT_TYPE_DOCUMENT,aid);
    
    JSONArray allHistory = new JSONArray();
    for (HistoryRecord hist : histRecs) {
        JSONObject jo = hist.getJSON(ngp, ar);
        allHistory.put(jo);
    }
    
    
%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Access Document");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceInfo = <%workspaceInfo.write(out,2,4);%>;
    $scope.docId   = "<%=aid%>";
    $scope.docInfo = {};
    $scope.linkedMeetings = <%linkedMeetings.write(out,2,4);%>;
    $scope.linkedTopics = <%linkedTopics.write(out,2,4);%>;
    $scope.linkedGoals = <%linkedGoals.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.history = <%allHistory.write(out,2,4);%>;
    $scope.wsUrl = "<%= wsUrl %>";
    $scope.creator = <%ale.getJSON().write(out,2,4);%>;
    $scope.generatedLink = "xxx";
    $scope.linkScope = "Private";
    $scope.privateLink = "<%ar.writeJS(privateLink);%>";

    $scope.myComment = "";
    $scope.canAccess = <%=canAccessDoc%>;
    $scope.isMember = <%=ar.canAccessWorkspace()%>;
    $scope.canUpdate = <%=ar.canUpdateWorkspace()%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.docSpaceURL = "<%ar.writeJS(docSpaceURL);%>";
    $scope.primitiveURL = "<%=ar.baseURL%><%ar.writeJS(permaLink);%>";

    
    $scope.navigateToActionItem = function(act) {
        window.location="task"+act.id+".htm";
    }
    $scope.navigateToTopic = function(topic) {
        window.location="noteZoom"+topic.id+".htm";
    }
    $scope.navigateToMeeting = function(meet) {
        window.location="MeetingHtml.htm?id="+meet.id;
    }

    $scope.allowCommentEmail = function() {
        return true;
    }


    $scope.needsUserResponse = function(cmt) {
        if (cmt.state!=12) { //not open
            return false;
        }
        var whatNot = $scope.getResponse(cmt);
        return (whatNot.length == 0);
    }
    $scope.getResponse = function(cmt) {
        var selected = cmt.responses.filter( function(item) {
            return item.user=="<%ar.writeJS(currentUser);%>";
        });
        return selected;
    }
    $scope.findComment = function(itemNotUsed, timestamp) {
        var selected = {};
        $scope.docInfo.comments.map( function(cmt) {
            if (timestamp==cmt.time) {
                selected = cmt;
            }
        });
        return selected;
    }

    $scope.assignedLabels = function() {
        var res = [];
        if (!$scope.docInfo || !$scope.docInfo.labelMap) {
            return res;
        }
        $scope.allLabels.forEach( function(item) {
            if ($scope.docInfo.labelMap[item.name]) {
                res.push(item);
            }
        });
        return res;
    }
    
    $scope.setDocumentData = function(data) {
        data.comments.forEach( function(cmt) {
            $scope.generateCommentHtml(cmt);
        });
        $scope.timerCorrection = data.serverTime - new Date().getTime();
        if (data.id == $scope.docId) {
            data.html = convertMarkdownToHtml(data.description);
            $scope.docInfo = data;
        }
        $scope.dataArrived = true;
    }
    $scope.getDocumentInfo = function() {
        if (!$scope.canAccess) {
            //avoid generating error if the user does not have access
            return;
        }
        $scope.isUpdating = true;
        var postURL = "docInfo.json?did="+$scope.docId;
        $http.get(postURL)
        .success( function(data) {
            $scope.setDocumentData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.getDocumentInfo();
    $scope.openDocDialog = function (doc) {
        
        var docsDialogInstance = $modal.open({
            animation: true,
            templateUrl: "<%= ar.retPath%>templates/DocumentDetail2.html<%=templateCacheDefeater%>",
            controller: 'DocumentDetailsCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                docId: function () {
                    return doc.id;
                },
                allLabels: function() {
                    return $scope.allLabels;
                },
                siteInfo: function() {
                    return $scope.siteInfo;
                },
                wsUrl: function() {
                    return $scope.wsUrl;
                }
            }
        });

        docsDialogInstance.result
        .then(function () {
            $scope.getDocumentInfo();
        }, function () {
            $scope.getDocumentInfo();
        });
    };
    $scope.imageName = function(player) {
        if (player.key) {
            if (player.key.indexOf("@")<0) {
                return player.key+".jpg";
            }
        }
        var lc = player.uid.toLowerCase();
        var ch = lc.charAt(0);
        var i =1;
        while(i<lc.length && (ch<'a'||ch>'z')) {
            ch = lc.charAt(i); i++;
        }
        return "fake-"+ch+".jpg";
    }
    $scope.navigateToCreator = function(player) {
        window.location="<%=ar.retPath%>v/"+encodeURIComponent(player.key)+"/PersonShow.htm";
    }
    $scope.composeEmail = function() {
        window.location="SendNote.htm?att="+$scope.docInfo.id;
    }
    

    $scope.generateLink = function() {
        if ($scope.linkScope == "Public") {
            $scope.generatedLink = $scope.privateLink+"&"+$scope.docInfo.magicNumber;
        }
        else {
            $scope.generatedLink = $scope.privateLink;
        }
    }
    $scope.generateLink();
    
    $scope.refreshCommentList = function() {
        $scope.getDocumentInfo();
    }
    $scope.cancelBackgroundTime = function() {
        //does not do anything now, no refresh on this page
    }
    $scope.extendBackgroundTime = function() {
        //does not do anything now, no refresh on this page
    }
    
    $scope.tuneNewComment = function(newComment) {
        newComment.containerType = "A";
        newComment.containerID = $scope.docId;
    }
    $scope.tuneNewDecision = function(newDecision, cmt) {
        newDecision.sourceId = $scope.docId;
        newDecision.sourceType = 8;
        newDecision.labelMap = $scope.docInfo.labelMap;
    }
    $scope.refreshCommentContainer = function() {
        $scope.getDocumentInfo();
    }
    setUpCommentMethods($scope, $http, $modal);
    $scope.setDocumentData(<% attachment.getJSON4Doc(ar,ngp).write(out,2,4); %>);
    
});

function copyTheLink() {
  /* Get the text field */
  var copyText = document.getElementById("generatedLink");

  /* Select the text field */
  copyText.select();

  /* Copy the text inside the text field */
  document.execCommand("copy");
} 
</script>
<script src="../../../jscript/AllPeople.js"></script>

<style>
.spacey {
    width:100%;
}
.spacey tr td {
    padding:5px;
}
.firstcol {
    width:180px;
}
.roomy {
    padding:5px;
}
.centered {
    width: 100%;
    display: flex;
    justify-content: center; 
}
.clipping {
    overflow: hidden;
    text-overflow: clip; 
    border-bottom:1px solid #EEEEEE;
    white-space: nowrap
}
.panelClickable {
    margin:4px;
    overflow: hidden;
    cursor: pointer;
}
</style>


<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

<div style="clear:both"></div>

<div class="col col-lg-6 col-sm-12">
  <div class="well">
    <div><b>{{docInfo.name}}</b> 
        <span ng-show="docInfo.deleted" style="color:red">
                <i class="fa fa-trash"></i> (DELETED)
        </span>
    </div>
    <div><div ng-bind-html="docInfo.html"></div></div>
    <div>
        {{docInfo.modifiedtime|cdate}} &nbsp;
        <span class="dropdown">
            <span id="menu1" data-toggle="dropdown">
            <img class="img-circle" src="<%=ar.retPath%>icon/{{creator.key}}.jpg" 
                 style="width:32px;height:32px" title="{{creator.name}} - {{creator.uid}}">
            </span>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                  tabindex="-1" ng-click="" style="text-decoration: none;text-align:center">
                  {{creator.name}}<br/>{{creator.uid}}</a></li>
              <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                  ng-click="navigateToCreator(creator)">
                  <span class="fa fa-user"></span> Visit Profile</a></li>
            </ul>
        </span> &nbsp;
        <span ng-show="docInfo.size>0">{{docInfo.size|number}} bytes</span>
      </div>
  </div>
  <div ng-show="canAccess">
      <div ng-show="docInfo.attType=='FILE'">
          <a href="<%=ar.retPath%><%ar.writeHtml(permaLink); %>"><img
          src="<%=ar.retPath%>download.gif"></a> 
          <hr/>
      </div>
      <div ng-show="docInfo.attType=='URL'">
        <a href="<%ar.write(permaLink); %>" target="_blank"><img
          src="<%=ar.retPath%>assets/btnAccessLinkURL.gif"></a> 
        <a href="CleanAtt.htm?path=<% ar.writeURLData(permaLink); %>" target="_blank">
          <button class="btn btn-primary btn-raised">View Text Only</button></a>
          <hr/>
      </div>
  </div>
  <div ng-hide="canAccess">
      <p>You are not able to access this document.</p>
  </div>
  
  <div ng-show="docInfo.deleted">
      This document has been put into the <i class="fa fa-trash"></i> trash and will 
      be deleted soon.
  </div>
  <div ng-hide="canUpdate">
      You are a read-only member of this site. 
      If you wish to update this document, ask the site administrator to make you
      an active (writeable) member of the site.
  </div>
  <div ng-show="canUpdate">
    <button class="btn btn-raised" ng-click="openDocDialog(docInfo)">Change Details</button>
    <p>Edit the document details, like name and description.  The name and description tell
    others what the purpose of the document is, and ultimately whether they
    want to access the document or not.<p>
  </div>
  <div ng-show="isMember">
    <button class="btn btn-raised" ng-click="makeLink = !makeLink">Get a link</button>
    <p ng-hide="makeLink">Generate a link that works the way you want.  You can make a private link that will allow only the current members of this workspace to download.  Or you can make a public link that makes the document available to anyone in the world with the link.  Your choice.<p>
    <div ng-show="makeLink">
      <div class="roomy">
        <input type="radio" ng-model="linkScope" value="Private" ng-click="generateLink()"> 
        <b>Private</b> - document can be accessed only by workspace members.
      </div>
      <div class="roomy">
        <input type="radio" ng-model="linkScope" value="Public" ng-click="generateLink()"> 
        <b>Public</b> - document can be accessed by anyone on the Internet.
      </div>
      <div class="roomy">
        <input type="text" ng-model="generatedLink" id="generatedLink"/>
        <button onClick="copyTheLink()" class="btn btn-sm btn-primary btn-raised">Copy to Clipboard</button>
      </div>
    </div>
  </div>
  <div ng-show="isMember">
    <button class="btn btn-default btn-raised" ng-click="composeEmail()">Send by email</button>
    <p>Compose an email with a number of links in it so that recipients can access this document safely, securely, and without cluttering email, or exceeding any email size limits.<p>
  </div>
</div>
<div class="col col-lg-6 col-sm-12" ng-hide="hideInfo" ng-dblclick="hideInfo=true">
    <h2>Sharing</h2>
    <p>Documents can be shared directly from Weaver, 
    internally to current members and externally to anyone in the world.</p>
    <div class="centered"><img src="../../../bits/safety-icon.png"/></div>
    <p>Sending a link to download directly from Weaver is <i>safer</i> than sending the document as an
    attachment to email, because the download is through a secure HTTPS channel.  
    Unlike emailing an attachment nobody else can intercept, see, or manipulate the contents of the file.
    The recipient will always get exactly the contents that were uploaded to Weaver.</p>
    <div class="centered"><img src="../../../bits/fast-email.png"/></div>
    <p>A link is smaller and more efficient than an attachment, 
    so it can be sent to anyone without cluttering their inbox. 
    This is great espectially important for very large files.  
    Sending a link to 100 MB or GB files avoids problems with size limits on email.</p>
    <div class="centered"><img src="../../../bits/clock-change.png"/></div>
    <p>Also, with a link, if the document is still changing, 
    all recipients will always have access to the latest version at the time they download.
    They never receive an out-of-date copy.</p>
</div>


<div class="col col-lg-6 col-sm-12">
    <div class="panel panel-default" ng-show="linkedTopics.length>0 && isMember">
      <div class="panel-heading headingfont">Attached To:
      </div>
      <div class="panel-body clipping">
          <div ng-repeat="topic in linkedTopics"
               class="panelClickable"
               ng-click="navigateToTopic(topic)">
            <i class="fa fa-lightbulb-o" style="font-size:130%"></i> {{topic.subject}}
          </div>
          <div ng-repeat="act in linkedGoals"
               class="panelClickable"
               ng-click="navigateToActionItem(act)">
            <img ng-src="<%=ar.retPath%>assets/goalstate/small{{act.state}}.gif"> {{act.synopsis}}
          </div>
          <div ng-repeat="meet in linkedMeetings"
               class="panelClickable"
               ng-click="navigateToMeeting(meet)">
            <i class="fa fa-gavel" style="font-size:130%"></i> {{meet.name}}
          </div>
      </div>
    </div>
</div>

<div style="clear:both"></div>



<div ng-show="canAccess" class="col col-lg-6 col-sm-12">
    <h3>Comments:</h3>
    <table style="max-width:800px">
      <tr ng-repeat="cmt in docInfo.comments">
         <%@ include file="/spring/jsp/CommentView.jsp"%>
      </tr>
    </table>    
    <div ng-hide="isCreatingComment" style="margin:20px;">
      <button ng-click="openCommentCreator(null, 1)" class="btn btn-default btn-raised">
        Create New <i class="fa fa-comments-o"></i> Comment</button>
    </div>
</div>
<div ng-show="canAccess" class="col col-lg-6 col-sm-12">
    <h3>History</h3>
    <table>

        <tr ng-repeat="hist in history"  >
            <td class="projectStreamIcons" style="padding:10px;">
              <span class="dropdown" >
                <span id="menu1" data-toggle="dropdown">
                <img class="img-circle" 
                     ng-src="<%=ar.retPath%>icon/{{hist.responsible.uid}}.jpg" 
                     style="width:32px;height:32px" 
                     title="{{hist.responsible.name}} - {{hist.responsible.uid}}">
                </span>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
                      tabindex="-1" style="text-decoration: none;text-align:center">
                      {{hist.responsible.name}}<br/>{{hist.responsible.uid}}</a></li>
                  <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
                      ng-click="navigateToCreator(hist.responsible)">
                      <span class="fa fa-user"></span> Visit Profile</a></li>
                </ul>
              </span>
            </td>
            <td class="projectStreamText" style="padding:10px;">
                {{hist.time|cdate}} - {{hist.responsible.name}}
                <br/>
                {{hist.ctxType}} "<b>{{hist.ctxName}}</b>"
                was {{hist.event}}.
                <br/>
                <i>{{hist.comments}}</i>

            </td>
        </tr>
    </table>
</div>

<script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>templates/DocumentDetail2.js"></script>
<script src="<%=ar.baseURL%>templates/EditLabelsCtrl.js"></script>
<script src="<%=ar.retPath%>jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>jscript/HtmlParser.js"></script>


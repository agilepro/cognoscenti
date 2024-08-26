<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/spring2/jsp/include.jsp"
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
    boolean hasURL = (permaLink != null && permaLink.length()>0);

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
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Access Document");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.workspaceInfo = <%workspaceInfo.write(out,2,4);%>;
    $scope.docId   = "<%=aid%>";
    $scope.docInfo = {};
    $scope.hasURL = <%=hasURL%>;
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
            templateUrl: "<%= ar.retPath%>new_assets/templates/DocumentDetail2.html<%=templateCacheDefeater%>",
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

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>


<div class="col-12 mx-4">
    <div class="container-fluid row">
        <div class="col-md-6 col-sm-12">
        <div class="well">
            <div class="row col-12">
                <h2 class="h5 me-2"><b>{{docInfo.name}}</b></h2>
            </div>
            <div class="row col-12">
                <span ng-show="docInfo.deleted" style="color:red">
                <i class="fa fa-trash"></i> (DELETED)
                </span>
                <span ng-bind-html="docInfo.html"></span>
                </div>
                <div class="row d-flex col-12">
                <span class="col-3">{{docInfo.modifiedtime|cdate}}</span> &nbsp;
                <span class="col-3 dropdown">
                    <ul class="navbar-btn p-0">
                    <li class="nav-item dropdown" id="user" data-toggle="dropdown">
                        <img class="rounded-5" src="<%=ar.retPath%>icon/{{creator.key}}.jpg" style="width:32px;height:32px" title="{{creator.name}} - {{creator.uid}}">
                        <ul class="dropdown-menu" role="menu" aria-labelledby="user">
                            <li role="presentation" style="background-color:lightgrey">
                                <a class="dropdown-item" role="menuitem" tabindex="0" style="text-decoration: none;text-align:left">
                  {{creator.name}}<br/>{{creator.uid}}</a></li>
                            <li role="presentation" style="cursor:pointer">
                                <a class="dropdown-item" role="menuitem" tabindex="0" ng-click="navigateToCreator(creator)">
                                <span class="fa fa-user"></span> Visit Profile</a></li>
                        </ul>
                    </li>
                    </ul>
                </span>
            
                <span class="col-3" ng-show="docInfo.size>0">{{docInfo.size|number}} bytes</span>
                
            </div>
                
        </div>
            <div class="row d-flex">

                <span class="col-5 ms-auto mb-0">
                <div ng-show="canAccess">
                <div ng-show="docInfo.attType=='FILE'">
                    <a href="<%=ar.retPath%><%ar.writeHtml(permaLink); %>">
                    <img src="<%=ar.retPath%>download.gif"></a>
                </div>
                <div ng-show="docInfo.attType=='URL'">
                    <div ng-show="hasURL">
                        <a href="<%ar.write(permaLink); %>" target="_blank">
                        <img src="<%=ar.retPath%>assets/btnAccessLinkURL.gif"></a>
                        <a href="WebFileShow.htm?aid=<% ar.writeURLData(aid); %>" target="_blank">
                        <button class="btn btn-primary btn-raised pull-right">Web File</button>
                        </a>
                    </div>
                    <div ng-hide="hasURL">
                        <button class="btn btn-danger btn-raised btn-wide btn-sm">Error - this web attachment has no URL</button>
                        <div class="alert" style="color:red">Someone in this workspace has attempted to attach a web page (URL) but they left the URL field empty, and so there is no place for us to direct you.  Someone should change details of this attached document and supply a suitable URL.</div>
                    </div>
                </div>
                </div>
                </span>
            

            </div>
        <hr/>
        <div ng-hide="canAccess">
      <p>You are not able to access this document.</p>
        </div>

        <div ng-show="docInfo.deleted">
      This document has been put into the <i class="fa fa-trash"></i> trash and will
      be deleted soon.
        </div>
        <div ng-hide="canUpdate">
      You are an observer of this site.
      If you wish to update this document, ask the site administrator to make you
      a creating user of the site.
        </div>
        <div class="row d-flex border-top border-1 pt-3" ng-show="canUpdate">
            <span class="col-3">
                <button class="btn btn-comment btn-secondary btn-raised" ng-click="openDocDialog(docInfo)">Document Settings</button>
            </span>
            <span class="col-8 me-3">
                <p>Edit the document details, like name and description.  The name and description tell others what the purpose of the document is, and ultimately whether they want to access the document or not.</p>
            </span>
        </div>
        <div class="row d-flex border-top border-1 pt-3"  ng-show="isMember">
            <span class="col-3">
                <button class="btn btn-comment btn-secondary btn-raised" ng-click="makeLink = !makeLink">Get a link</button>
            </span>
            <span class="col-8 me-3">
                <p ng-hide="makeLink">Generate a link that works the way you want.  You can make a private link that will allow only the current members of this workspace to download.  Or you can make a public link that makes the document available to anyone in the world with the link.  Your choice.</p>
            <span  ng-show="makeLink">
                <div class="col-8 my-2">
                    <input type="radio" ng-model="linkScope" value="Private" ng-click="generateLink()"> <b>Private</b> - document can be accessed only by workspace members.
                </div>
                <div class="col-8 my-2">
                    <input type="radio" ng-model="linkScope" value="Public" ng-click="generateLink()">
                    <b>Public</b> - document can be accessed by anyone on the Internet.
                </div>
                <div class="col-8 my-2">
                    <input type="text" ng-model="generatedLink" id="generatedLink"/>
                    <button onClick="copyTheLink()" class="btn btn-sm btn-primary btn-raised">Copy to Clipboard</button>
                </div>
            </span>
            </span>
        </div>
        <div class="row d-flex border-top border-1 pt-3" ng-show="isMember">
            <span class="col-3">
                <button class="btn btn-comment btn-secondary btn-raised" ng-click="composeEmail()">Send by email</button></span>
            <span class="col-8 me-3">
                <p>Compose an email with a number of links in it so that recipients can access this document safely, securely, and without cluttering email, or exceeding any email size limits.</p>
            </span>
        </div>
        <div class="row d-flex border-top border-1 pt-3" ng-show="isMember">
            <span class="col-3">
                <a class="btn btn-secondary btn-raised" role="menuitem" tabindex="-1" href="DocsRevise.htm?aid={{docId}}" >Versions</a></span>
            <span class="col-8 me-3">
                <p>View the history of changes to this document.</p>
            </span>
        </div>
        <!--experimental mobile UI not ready in new UI-->
        <!--<div>
            <a href="DocView.wmf?docId={{docId}}" class="btn btn-default btn-raised btn-wide btn-secondary"><i class="fa fa-bolt"></i> Experimental Mobile UI</a>
        </div>-->
        <hr>
        <div ng-show="canAccess" class="well mt-2">
            <span class="h5">Comments:</span>
            <div class="container">
                <span ng-repeat="cmt in docInfo.comments">
            <%@ include file="/spring2/jsp/CommentView.jsp" %>
                </span>
            </div>
            <div ng-hide="isCreatingComment" >
                <button ng-click="openCommentCreator(null, 1)" class="btn-comment btn-raised mx-2 my-md-3 my-sm-3">
                Create New <i class="fa fa-comments-o"></i> Comment</button>
            </div>
        </div>
        </div>

<div class="col-md-6 col-sm-12 px-3" ng-hide="hideInfo" ng-dblclick="hideInfo=true">
    <div class="well">
        <span class="h5">Sharing</span>
                    <p>Documents can be shared directly from Weaver,internally to current members and externally to anyone in the world.</p>

        <div class="d-flex border-top border-1 pt-3">
        <div class="me-3"><img src="../../../bits/safety-icon.png"/></div>
        <p>Sending a link to download directly from Weaver is <i>safer</i> than sending the document as an
    attachment to email, because the download is through a secure HTTPS channel.
    Unlike emailing an attachment nobody else can intercept, see, or manipulate the contents of the file.
    The recipient will always get exactly the contents that were uploaded to Weaver.</p>
        </div>

        <div class="d-flex border-top border-1 pt-3">
    <div class="me-3"><img src="../../../bits/fast-email.png"/></div>
    <p>A link is smaller and more efficient than an attachment,
    so it can be sent to anyone without cluttering their inbox.
    This is especially important for very large files.
        Sending a link to 100 MB or GB files avoids problems with size limits on email.</p> </div>

        <div class="d-flex border-top border-1 pt-3">
    <div class="me-3"><img src="../../../bits/clock-change.png"/></div>

    <p>Also, with a link, if the document is still changing,
    all recipients will always have access to the latest version at the time they download.
    They never receive an out-of-date copy.</p>
        </div>
    </div>
    

    <div class="card" ng-show="linkedTopics.length>0 && isMember">
                <div class="card-heading headingfont">Attached To:
                </div>
                <div class="card-body clipping">
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
        
    
    <div class="well mt-2" ng-show="canAccess">
        <span class="h5">History</span>

            
        <span ng-repeat="hist in history"  >
            <span class=" projectStreamIcons">
                <span class="col-2 dropdown" >
                    <ul class="navbar-btn p-0 list-inline">
                        <li class="nav-item dropdown" id="user2" data-toggle="dropdown">
                            <img class="rounded-5" ng-src="<%=ar.retPath%>icon/{{hist.responsible.uid}}.jpg" style="width:32px;height:32px" title="{{hist.responsible.name}} - {{hist.responsible.uid}}">
                            <ul class="dropdown-menu" role="menu" aria-labelledby="user">
                                <li role="presentation" style="background-color:lightgrey">
                                  <a class="dropdown-item" role="menuitem" tabindex="0" style="text-decoration: none;text-align:left">
                      {{hist.responsible.name}}<br/>{{hist.responsible.uid}}</a></li>
                      <li role="presentation" style="cursor:pointer">
                        <a class="dropdown-item" role="menuitem" tabindex="0" ng-click="navigateToCreator(hist.responsible)">
                      <span class="fa fa-user"></span> Visit Profile</a></li>
                            </ul>
                        </li>
                    </ul>
                </span>
                <span class="col-5 projectStreamText">
                {{hist.time|cdate}} - {{hist.responsible.name}}
                <br/>
                {{hist.ctxType}} "<b>{{hist.ctxName}}</b>"
                was {{hist.event}}.
                <br/>
                <i>{{hist.comments}}</i>
                </span>
            </span>
        </span>
    </div>
</div>
        </div>
</div>


<script src="<%=ar.retPath%>new_assets/templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/DocumentDetail2.js"></script>
<script src="<%=ar.baseURL%>new_assets/templates/EditLabelsCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/HtmlToMarkdown.js"></script>
<script src="<%=ar.retPath%>new_assets/jscript/HtmlParser.js"></script>

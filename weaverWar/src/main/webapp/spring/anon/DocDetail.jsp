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
    String currentUser = "";
    String currentUserName = "";
    String currentUserKey = "";
    if (uProf!=null) {
        currentUser = uProf.getUniversalId();
        currentUserName = uProf.getName();
        currentUserKey = uProf.getKey();
    }


    String aid      = ar.reqParam("aid");
    AttachmentRecord attachment = ngp.findAttachmentByIDOrFail(aid);
    String version  = ar.defParam("version", null);

    long fileSizeInt = attachment.getFileSize(ngp);
    String fileSize = String.format("%,d", fileSizeInt);

    boolean canAccessDoc = AccessControl.canAccessDoc(ar, ngp, attachment);

    String relativeLink = "a/"+attachment.getNiceName()+"?version="+attachment.getVersion();
    String permaLink = ar.getResourceURL(ngp, relativeLink);
    if("URL".equals(attachment.getType())){
        permaLink = attachment.getURLValue();
    }
    
    
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
    
    
    
%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Document Details");
    $scope.siteInfo = <%site.getConfigJSON().write(out,2,4);%>;
    $scope.docId   = "<%=aid%>";
    $scope.docInfo = <% attachment.getJSON4Doc(ar,ngp).write(out,2,4); %>;
    $scope.linkedMeetings = <%linkedMeetings.write(out,2,4);%>;
    $scope.linkedTopics = <%linkedTopics.write(out,2,4);%>;
    $scope.linkedGoals = <%linkedGoals.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.wsUrl = "<%= wsUrl %>";
    $scope.creator = <%ale.getJSON().write(out,2,4);%>;
    $scope.generatedLink = "xxx";
    $scope.linkScope = "Private";
    $scope.privateLink = "<%ar.writeJS(privateLink);%>";

    $scope.myComment = "";
    $scope.canAccess = <%=canAccessDoc%>;

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
        window.location="meetingHtml.htm?id="+meet.id;
    }
    $scope.commentTypeName = function(cmt) {
        if (cmt.commentType==2) {
            return "Proposal";
        }
        if (cmt.commentType==3) {
            return "Round";
        }
        if (cmt.commentType==5) {
            return "Minutes";
        }
        return "Comment";
    }

    $scope.allowCommentEmail = function() {
        return true;
    }

    
    $scope.stateStyle = function(cmt) {
        if (cmt.state==11) {
            return "background-color:yellow;";
        }
        if (cmt.state==12) {
            return "background-color:#DEF;";
        }
        return "background-color:#EEE;";
    }
    $scope.stateClass = function(cmt) {
        if (cmt.state==11) {
            return "comment-state-draft";
        }
        if (cmt.state==12) {
            return "comment-state-active";
        }
        return "comment-state-complete";
    }
    $scope.postComment = function(itemNotUsed, cmt) {
        cmt.state = 12;
        if (cmt.commentType == 1 || cmt.commentType == 5) {
            //simple comments go all the way to closed
            cmt.state = 13;
        }
        $scope.updateComment(cmt);
    }
    $scope.deleteComment = function(itemNotUsed, cmt) {
        cmt.deleteMe = true;
        $scope.updateComment(cmt);
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
    $scope.getFullDoc = function(docId) {
        var doc = {};
        $scope.attachmentList.filter( function(item) {
            if (item.universalid == docId) {
                doc = item;
            }
        });
        return doc;
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
        $scope.timerCorrection = data.serverTime - new Date().getTime();
        data.docs.forEach( function(rec) {
            if (rec.id == $scope.docId) {
                rec.html = convertMarkdownToHtml(rec.description);
                $scope.docInfo = rec;
            }
        });
        $scope.dataArrived = true;
    }
    $scope.getDocumentList = function() {
        $scope.isUpdating = true;
        var postURL = "docsList.json";
        $http.get(postURL)
        .success( function(data) {
            $scope.setDocumentData(data);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

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
    $scope.navigateToUser = function(player) {
        window.location="<%=ar.retPath%>v/FindPerson.htm?uid="+encodeURIComponent(player.key);
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
    
    $scope.downloadDocument = function(doc) {
        if (doc.attType=='URL') {
             window.open(doc.url,"_blank");
        }
        else {
            window.open("a/"+doc.name,"_blank");
        }
    }
    
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
    max-width:200px;
    overflow: hidden;
    cursor: pointer;
}
</style>


<div>

<%@include file="ErrorPanel.jsp"%>

<% if (ar.isLoggedIn()) { %>
    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem"
              href="docinfo{{docInfo.id}}.htm">Access Document</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="DocsRevise.htm?aid={{docInfo.id}}" >Versions</a></li>
          <li role="presentation"><a role="menuitem"
              href="SendNote.htm?att={{docInfo.id}}">Send Document by Email</a></li>
        </ul>
      </span>
    </div>
<% } %>    

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
            <img class="img-circle" src="<%=ar.retPath%>icon/{{imageName(creator)}}" 
                 style="width:32px;height:32px" title="{{creator.name}} - {{creator.uid}}"/>
        </span> &nbsp;
        <span ng-show="docInfo.size>0">{{docInfo.size|number}} bytes</span>
      </div>
  </div>
  <div ng-show="docInfo.attType=='FILE'">
      <a href="<%=ar.retPath%><%ar.writeHtml(permaLink); %>"><img
      src="<%=ar.retPath%>download.gif"></a> 
  </div>
  <div ng-show="docInfo.attType=='URL'">
    <a href="<%ar.write(permaLink); %>" target="_blank"><img
      src="<%=ar.retPath%>assets/btnAccessLinkURL.gif"></a> 
    <a href="CleanAtt.htm?path=<% ar.writeURLData(permaLink); %>" target="_blank">
      <button class="btn btn-primary btn-raised">View Text Only</button></a>
  </div>
  
  <div ng-show="docInfo.deleted">
     This document has been put into the <i class="fa fa-trash"></i> trash and will 
     be deleted soon.
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




</div>

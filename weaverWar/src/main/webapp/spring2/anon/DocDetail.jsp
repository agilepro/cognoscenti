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
        window.location="MeetingHtml.htm?id="+meet.id;
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
        $scope.timerCorrection = data.serverTime - new Date().getTime();
        if (data.id == $scope.docId) {
            data.html = convertMarkdownToHtml(data.description);
            $scope.docInfo = data;
        }
    }
    $scope.setDocumentData($scope.docInfo);

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
    
    $scope.downloadDocument = function(doc) {
        if (doc.attType=='URL') {
             window.open(doc.url,"_blank");
        }
        else {
            window.open("a/"+doc.name,"_blank");
        }
    }
    
    $scope.login = function() {
        SLAP.loginUserRedirect();
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

<div class="col col-lg-6 col-md-6 col-sm-12">
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
            <img class="img-circle" src="<%=ar.retPath%>icon/{{creator.uid}}.jpg" 
                 style="width:32px;height:32px" title="{{creator.name}} - {{creator.uid}}"/>
        </span> &nbsp;
        <span ng-show="docInfo.size>0">{{docInfo.size|number}} bytes</span>
      </div>
  </div>
  <div ng-hide="canAccess">
      <p>Sorry: you are not able to access this document because you are not logged in, and the link you used requires you to authenticate as a member of this workspace.</p>
      <p>If you actually are a member of this Weaver workspace, then please <button ng-Click="login()">Login</button>
      <p>You need to be a member of the workspace, or have been provided a special access link to the document.  Please contact the person who has provided this link and let them know you would like access.</p>
      <p>If you would like to be a member of this workspace, then after logging in you can request membership.</p>
      <p>If have no login for Weaver, you may <button ng-Click="login()">Register</button> an email address for logging in.
  </div>
  <div ng-show="canAccess">
      <p>You have received special access to this document.</p>
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
   </div>
 
  <div ng-show="docInfo.deleted">
     This document has been put into the <i class="fa fa-trash"></i> trash and will 
     be deleted soon.
  </div>

</div>
<div class="col col-lg-6 col-md-6 col-sm-12" ng-hide="hideInfo" ng-dblclick="hideInfo=true">
    <h2>Welcome to Weaver</h2>
   <p>Weaver allows members to share documents directly with anyone in a controlled way.
    Instead of attaching a large document as an attachment to an email, Weaver provides
    links to access and download documents directly.  Members can easily upload from
    anywhere as well.</p>
    <div class="centerIcon"><img src="../../../bits/safety-icon.png"/></div>
    <p>Downloading directly from Weaver is <i>safer</i> than sending the document as an
    attachment to email, because the download is through a secure HTTPS channel.  
    Unlike emailing an attachment nobody else can intercept, see, or manipulate the contents of the file.
    The recipient will always get exactly the contents that were uploaded to Weaver.</p>
    <div class="centerIcon"><img src="../../../bits/fast-email.png"/></div>
    <p>A link is smaller and more efficient than an attachment, 
    so it can be sent to you without cluttering your inbox. 
    This is great espectially important for very large files.  
    Sending a link to hundred MB or GB files avoids problems with size limits on email.</p>
    <div class="centerIcon"><img src="../../../bits/clock-change.png"/></div>
    <p>Also, if the document has changed recently,
    you will be downloading the latest version at the time.
    You will never receive an out-of-date copy.</p>
    <hr/>
    <div class="centerIcon"><img src="../../../bits/weaver-logo-header.png"/></div>
    <p>Weaver is developed by a team of volunteers to make tools to allow 
    community groups to collaborate more effectively, and to get more done.
    Please join our effort.   We help groups all over the worlsd.</p>
    <p>You can <a href="../../index.htm">get your own free Weaver site</a>,
    and use it to collaborate more effectively 
    using a technique known as Dynamic Governance.
    Give it a try.</p>
    <p>If you want to know more, we have a sequence of 
       <a href="https://s06.circleweaver.com/TutorialList.html">training videos</a>
       which will help explain exactly what Weaver can do for you and your team.</p>
</div>


</div>

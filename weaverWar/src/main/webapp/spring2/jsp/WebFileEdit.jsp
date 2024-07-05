<%@ page language="java" contentType="text/html;charset=UTF-8" pageEncoding="UTF-8"
%><%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.capture.CapturePage"
%><%@page import="com.purplehillsbooks.streams.NullWriter"
%><%@page import="com.purplehillsbooks.weaver.capture.WebFile"
%><%
    ar.assertLoggedIn("You need to Login to Upload a file.");
    String attachmentId = ar.reqParam("aid");
    int sectionNumber = DOMFace.safeConvertInt(ar.reqParam("sec"));
    String userKey = ar.getUserProfile().getKey();
    
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();

    AttachmentRecord att = ngw.findAttachmentByIDOrFail(attachmentId);
    WebFile wf = att.getWebFile();
    
    JSONObject wfjson = wf.getJson();
    JSONObject sectionLines = wf.getSectionParagraphsAndSentences(sectionNumber);

%>

<script>
var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    window.setMainPageTitle("Compressed Web File");
    $scope.userKey = "<% ar.writeJS(userKey); %>";
    $scope.attId = "<% ar.writeJS(attachmentId); %>";
    $scope.sectionNumber = <%= sectionNumber %>;
    $scope.webFile = <% wfjson.write(out,2,4); %>;
    $scope.originalUrl = "<% ar.writeJS(att.getURLValue()); %>";
    $scope.attName = "<% ar.writeJS(att.getNiceName()); %>";
    $scope.sectionLines = <% sectionLines.write(out,2,4); %>;
    $scope.showHidden = false;

    $scope.articleSections  =[];
    $scope.linkSections = [];
    $scope.hiddenSections = [];
    $scope.reportError = function(data) {
        console.log("DANGER DANGER DANGER", data);
    };
    $scope.findSection = function(secNum) {
        for (let sec of $scope.webFile.sections) {
            if (sec.originPos == secNum) {
                return sec;
            }
        }
        throw "cant find section "+secNum;
    }
    $scope.section = $scope.findSection($scope.sectionNumber);
    $scope.oldComments = [];
    if (!$scope.section.comments) {
        $scope.section.comments = {};
    }
    if ($scope.section.comments[$scope.userKey]) {
        $scope.oldComments = $scope.section.comments[$scope.userKey];
    }
    
    console.log("OLDCOMMENTS", $scope.oldComments);

    $scope.openOriginal = function() {
        window.open($scope.originalUrl, "_blank");
    }
    $scope.download = function() {
        window.location="WebFileShow.htm?att=<%=attachmentId%>&capture=y";
    }
    $scope.sharable = function() {
        window.location="WebFilePrint.htm?aid=<%=attachmentId%>";
    }
    $scope.edit = function(art) {
        window.location="WebFileEdit.htm?aid=<%=attachmentId%>&sec="+art.originPos;
    }
    
    function findComment(para, sent) {
        for (let cmt of $scope.oldComments) {
            if (cmt.para == para && cmt.sent == sent) {
                return cmt.cmt;
            }
        }
        return "";
    }

    $scope.saveComments = function() {
        let commentList = [];
        let paraNum = 0;
        for (let paragraph of $scope.sectionLines.paragraphs) {
            paraNum++;
            let sentNum = 0;
            for (let sent of paragraph.lines) {
                sentNum++;
                if (sent.cmt && sent.cmt.trim().length>0) {
                    commentList.push( {
                        para: paraNum,
                        sent: sentNum,
                        cmt: sent.cmt.trim()
                    });
                }
            }
            
        }
        let mainObj = {comments: commentList};

        var postURL = "UpdateWebFileComments.json?aid="+$scope.attId+"&sec="+$scope.sectionNumber;
        var postdata = angular.toJson(mainObj);
        console.log("SAVING", mainObj);
        $http.post(postURL, postdata)
        .success( function(data) {
            console.log("GOT BACK", data);
            $scope.webFile = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }

    function searchIndexNoLink(str, search, limit) {
        let pos = 0;
        let skipping=false;
        while (pos<str.length) {
            let ch = str[pos++];
            if (skipping) {
                if (ch == "]") {
                    skipping = false;
                }
            }
            else {
                if (ch == search) {
                    if (pos > limit) {
                        return pos-1;
                    }
                }
                else if (ch == "[") {
                    skipping = true;
                }
            }
        }
        return -1;
    }


    function findBreak(str) {
        if (str.length<80) {
            return -1;
        }
        var dotPos = searchIndexNoLink(str, ".", 10);
        var semiPos = searchIndexNoLink(str, ";", 10);
        var quesPos = searchIndexNoLink(str, "?", 10);
        var bangPos = searchIndexNoLink(str, "!", 10);
        var res = str.length;
        if (dotPos>0 && dotPos<res) {
            res = dotPos;
        }
        if (semiPos>0 && semiPos<res) {
            res = semiPos;
        }
        if (quesPos>0 && quesPos<res) {
            res = quesPos;
        }
        if (bangPos>0 && bangPos<res) {
            res = bangPos;
        }
        while (str.charAt(res+1)=='.') {
            res++;
        }
        if (str.charAt(res+1)=='\"') {
            res++;
        }
        if (str.charAt(res+1)=='”') {
            res++;
        }
        if (str.charAt(res+1)=='\'') {
            res++;
        }
        if (str.charAt(res+1)=='\’') {
            res++;
        }
        if (str.charAt(res+1)==')') {
            res++;
        }
        return res;
    }
    
    
    function addComments() {
        for (let paragraph of $scope.sectionLines.paragraphs) {
            for (let line of paragraph.lines) {
                line.cmt = findComment(paragraph.paraNum, line.lineNum);
            }
        }
    }
    
    addComments();
    console.log($scope.sectionLines);
    
});
</script>
<style>

.otherRows{
    width: 600px;
}
.firstRow{
    border-top:2px red solid;
    width: 600px;
}

</style>

<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

    <div class="cleanedWebStyle">
        <h2>{{attName}}</h2>
        <h2>§{{section.originPos}}</h2>
        
        <table class="table">
        <tbody>
          <tr>
           <td>P</td>
           <td>S</td>
           <td></td>
           <td><button class="btn btn-primary btn-raised" ng-click="saveComments()">Save Your Comments</button></td>
          </tr>
        </tbody>
        <tbody ng-repeat="paragraph in sectionLines.paragraphs">
          <tr ng-repeat="sent in paragraph.lines">
           <td>{{paragraph.paraNum}}</td>
           <td>{{sent.lineNum}}</td>
           <td style="max-width:400px">
              <div ng-bind-html="sent.text|wiki"></div>
           </td>
           <td style="width:400px">
              <textarea type="text" ng-model="sent.cmt" class="form-control"></textarea>
           </td>
          </tr>
        </tbody>
        </table>
        
    </div>

</div>
<!-- end WebFileShow.jsp -->

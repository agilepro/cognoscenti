<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    ar.assertLoggedIn("You need to Login to Upload a file.");

    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }

    String folderVal = ar.defParam("folder", null);
    List<String> folders = UtilityMethods.splitString(folderVal, '|');
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    if (ngp.isFrozen()) {
        throw new Exception("Program Logic Error: addDocument.jsp "
           +"should never be invoked when the workspace is frozen.  "
           +"Please check the logic of the controller.");
    }
    String folderPart = "";
    if (folderVal!=null) {
        folderPart = "?folder="+URLEncoder.encode(folderVal, "UTF-8");
    }
    JSONArray attachArray = new JSONArray();
    for (AttachmentRecord doc : ngp.getAllAttachments()) {
        attachArray.put( doc.getJSON4Doc(ar, ngp) );
    }

    JSONArray allLabels = ngp.getJSONLabels();
    for (CustomRole role : ngp.getAllRoles()) {
        allLabels.put( role.getJSON() );
    }

%>

<script src="https://apis.google.com/js/api.js"></script>
<script src="https://apis.google.com/js/platform.js" async defer></script>
<script src="https://apis.google.com/js/client.js"></script>

<script>
/******************** GLOBAL VARIABLES ********************/
var SCOPES = ['https://www.googleapis.com/auth/drive'];
var CLIENT_ID = '866856018924-boo9af1565ijlrsd0760b10lqdqlorkg.apps.googleusercontent.com';
var FOLDER_NAME = "";
var FOLDER_ID = "root";
var FOLDER_PERMISSION = true;
var FOLDER_LEVEL = 0;
var NO_OF_FILES = 1000;
var DRIVE_FILES = [];
var FILE_COUNTER = 0;
var FOLDER_ARRAY = [];
var SIGNED_IN=false;

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal) {
    window.setMainPageTitle("Link Google Docs");
    window.MY_SCOPE = $scope;
    $scope.attachmentList = <% attachArray.write(out, 2,2); %>;
    $scope.allLabels      = <% allLabels.write(out, 2,2); %>;
    $scope.filter = "";
    
    $scope.driveFiles = [];
    $scope.parentStack = [];

    $scope.startGetFiles = function() {
        var authparam = {
            'client_id': CLIENT_ID,
            'scope': 'https://www.googleapis.com/auth/drive',
            'immediate': false
        };
        console.log("Now Requesting: ", authparam);
        gapi.auth.authorize(authparam, $scope.handleAuthResult);
    }
    //check the return authentication of the login is successful, we display the drive box and hide the login box.
    $scope.handleAuthResult = function(authResult) {
        if (!authResult || authResult.error) {
            console.log("NOT AUTHORIZED: ", authResult);
            return;
        }
        $scope.getDriveFiles();
    }


    $scope.getDriveFiles = function(){
        console.log("Loading Google Drive files...");
        gapi.client.load('drive', 'v2', $scope.getFiles);
    }
    $scope.getFiles = function(){
        console.log("Getting folder: ", FOLDER_ID);
        var query = {
            'maxResults': NO_OF_FILES,
            'q': "trashed=false and '" + FOLDER_ID + "' in parents"
        }
        
        var request = gapi.client.drive.files.list(query);
        request.execute(function (resp) {
            if (resp.error) {
                console.log("Error: " + resp.error.message);
                return;
            }
            $scope.driveFiles = resp.items;
            $scope.driveFiles.sort( function(a,b) {
                if (a.title.toLowerCase()<b.title.toLowerCase()) {return -1}
                return 1;
            });
            $scope.$apply();
            console.log("Got Files: ", $scope.driveFiles);
        });
    }

    $scope.isFolder = function(gfile) {
        return ("application/vnd.google-apps.folder" == gfile.mimeType);
    }
    $scope.isAttachable = function(gfile) {
        if ($scope.isFolder(gfile)) {
            return false;
        }
        var found = false;
        
        $scope.attachmentList.forEach( function(item) {
            if (item.url == gfile.embedLink) {
                found = true;
            }
        });
        return !found;
    }
    $scope.isAttached = function(gfile) {
        if ($scope.isFolder(gfile)) {
            return false;
        }
        var found = false;
        $scope.attachmentList.forEach( function(item) {
            if (item.url == gfile.embedLink) {
                found = true;
            }
        });
        return found;
    }


    $scope.checkUser = function() {
        console.log("checkUser getBasicProfile", googleUser.getBasicProfile());
    }
    $scope.showFiles = function() {
        var params = {'maxResults': 5 };
        var resultList = gapi.client.drive.files.list(params);
        console.log("showFiles", resultList);
    }    
    
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.loggedIn = false;
    $scope.setLogin = function(boolVal) {
        $scope.loggedIn = boolVal;
    }
    $scope.filterFiles = function() {
        var selected = [];
        var lcFilter = $scope.filter.toLowerCase();
        $scope.driveFiles.forEach( function(item) {
            if (item.title.toLowerCase().indexOf(lcFilter)>=0) {
                selected.push(item);
            }
         });
         return selected;
    }
    $scope.drillDown = function(gfile) {
        if ($scope.isFolder(gfile)) {
            $scope.parentStack.push(FOLDER_ID);
            FOLDER_ID = gfile.id;
            $scope.driveFiles = [];
            $scope.getFiles();
        }
    }
    $scope.popUp = function(gfile) {
        if ($scope.parentStack.length>0) {
            FOLDER_ID = $scope.parentStack.pop();
            $scope.driveFiles = [];
            $scope.getFiles();
        }
    }
    $scope.preview = function(gfile) {
        window.open(gfile.embedLink,'_blank');
    }
    
    $scope.openAttachDocument = function (item) {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/GoogleDoc.html<%=templateCacheDefeater%>',
            controller: 'GoogleDocCtrl',
            size: 'lg',
            resolve: {
                gfile: function () {
                    return JSON.parse(JSON.stringify(item));
                },
                attachmentList: function() {
                    return $scope.attachmentList;
                },
                allLabels: function() {
                    return $scope.allLabels;
                }
            }
        });

        attachModalInstance.result
        .then(function (docList) {
            item.docList = docList;
            $scope.saveAgendaItem(item);
        }, function () {
            //cancel action - nothing really to do
        });
    };
    
});    


var googleUser = null;
var googleUserProfile = null;

function onSuccessFunc(user) {
    googleUser = user;
    window.MY_SCOPE.setLogin(true);
    window.MY_SCOPE.$apply();
    console.log("onSuccessFunc", user);
}

</script>



<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

<table><tr>
<td>
</td>
<td> 
    <button ng-click="startGetFiles()" class="btn btn-primary btn-raised" 
            ng-hide="driveFiles.length>0">List Files from Google Drive</button>
</td>
<td> 
        <button class="" 
            ng-hide="parentStack.length==0" ng-click="popUp()">
                <i class="fa  fa-arrow-circle-up"></i></button>
</td>
<td >
  <div class="well form-inline">
    <label for="filter"> Filter </label>
    <input type="text" ng-model="filter" class="form-control">
  </div>
</td>
<td>
</td> 
</tr></table>


    
    <table class="table">
    <tr ng-show="parentStack.length>0">
        
    <td></td>
    <td> . . </td>
    <td><button class="" ng-click="popUp()">
                <i class="fa  fa-arrow-circle-up"></i></button>
    </td>
    </tr>
    <tr ng-repeat="gfile in filterFiles()">
    <td style="width:50px;"><img src="{{gfile.iconLink}}"></td>
    <td>{{gfile.title}}</td>
    <td style="width:50px;">
        <button ng-show="isFolder(gfile)" class="" 
            ng-click="drillDown(gfile)"><i class="fa fa-folder-open-o"></i></button>
    </td>
    <td style="width:50px;">
        <button ng-show="isAttachable(gfile)" class="" 
            ng-click="openAttachDocument(gfile)"><i class="fa fa-paperclip"></i></button>
        <span ng-show="isAttached(gfile)" 
              style="color:tomato;padding:10px;" 
              title="already attached to this workspace">
            <i class="fa fa-paperclip"></i></span>
    </td>
    <td style="width:50px;">
        <button ng-hide="isFolder(gfile)" class="" 
            ng-click="preview(gfile)"><i class="fa fa-eye"></i></button>
    </td>
    <td style="width:100px;">{{gfile.modifiedDate | date}}</td>
    </tr>
    </table>

    <div class="guideVocal" ng-hide="loggedIn">
        You will need to be logged into Google with the account that owns the Google Drive
        folder from which you want to retrieve the documents.   
        <br/> <br/>
        <div class="g-signin2" data-onsuccess="onSuccessFunc" data-theme="dark"></div>
        <br/>
        You also will need to give 
        permissions to this application to be able to access that folder.
        
        Clicking this button may help you log in and give permissions.
    </div>
</div>


<script src="<%=ar.retPath%>templates/GoogleDocCtrl.js"></script>
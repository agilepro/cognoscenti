<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.UserManager"
%><%@page import="com.purplehillsbooks.weaver.UserProfile"
%><%@page import="java.util.TimeZone"
%><%

    ar.assertLoggedIn("Can't edit a user's profile.");
    UserProfile uProf = findSpecifiedUserOrDefault(ar);
    UserProfile runningUser = ar.getUserProfile();
    boolean isSuperAdmin = ar.isSuperAdmin();

    //the following should be impossible since above log-in is checked.
    if (uProf == null) {
        throw new Exception("Must be logged in to edit a user's profile.");
    }
    boolean selfEdit = uProf.getKey().equals(runningUser.getKey());
    if (!selfEdit) {
        //there is one super user who is allowed to edit other user profiles
        //that user is specified in the system properties -- by KEY
        if (!isSuperAdmin) {
            throw new Exception("User "+runningUser.getName()
                +" is not allowed to edit the profile of user "+uProf.getName());
        }
    }
    
    JSONObject userObj = uProf.getFullJSON();

    String photoSource = ar.retPath+"assets/photoThumbnail.gif";
    String imagePath = uProf.getImage();
    if(imagePath!=null && imagePath.length() > 0){
        photoSource = ar.retPath+"icon/"+imagePath;
    }
    Object errMsg = session.getAttribute("error-msg");
    
%>

<script type="text/javascript">
var MY_SCOPE = "FOO";
var myApp = angular.module('myApp');
myApp.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Change Your Icon Image");
    $scope.profile = <%userObj.write(out,2,4);%>;
    MY_SCOPE = $scope;
    
    $scope.myTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        console.log("ERROR", serverErr);
        errorPanelHandler($scope, serverErr);
    };

    $scope.fileProgress = [];
    $scope.cancelUpload = function(oneProgress) {
        oneProgress.done = true;
        oneProgress.status = "Cancelled";
    }
    $scope.startUpload = function(oneProgress) {
        let fileName = oneProgress.file.name.toLowerCase();
        if (!fileName.endsWith(".jpg")) {
            //alert("File must be a JPG file");
            //return;
        }
        oneProgress.status = "Starting";
        oneProgress.loaded = 0;
        oneProgress.percent = 0;
        oneProgress.labelMap = $scope.filterMap;
        var postURL = "UserPostOps.json";
        var postdata = '{"op": "tempFile"}';
        $scope.showError=false;
        console.log("REQUESTING TEMP FILE NAME");
        
        $http.post(postURL, postdata)
        .success( function(data) {
            oneProgress.tempFileName = data.tempFileName;
            oneProgress.tempFileURL = data.tempFileURL;
            $scope.actualUpload(oneProgress);
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.actualUpload = function(oneProgress) {
        oneProgress.status = "Uploading";
        console.log("UPLOADING TO: "+oneProgress.tempFileURL);

        var xhr = new XMLHttpRequest();
        xhr.upload.addEventListener("progress", function(e){
          $scope.$apply( function(){
            if(e.lengthComputable){
              oneProgress.loaded = e.loaded;
              oneProgress.percent = Math.round(e.loaded * 100 / e.total);
              console.log("progress event: "+oneProgress.loaded+" / "+e.total+"  ==  "+oneProgress.percent+"   "+oneProgress.status);
            } else {
              oneProgress.percent = 50;
            }
          });
        }, false);
        xhr.upload.addEventListener("load", function(data) {
            $scope.nameUploadedFile(oneProgress);
        }, false);
        xhr.upload.addEventListener("error", $scope.reportError, false);
        xhr.upload.addEventListener("abort", $scope.reportError, false);
        xhr.open("PUT", oneProgress.tempFileURL);
        xhr.send(oneProgress.file);
    };
    $scope.nameUploadedFile = function(oneProgress) {
        oneProgress.status = "Finishing";
        var postURL = "UserPostOps.json";
        var op = {op: "finishIcon"};
        op.tempFileName = oneProgress.tempFileName;
        op.doc = {};
        op.doc.description = oneProgress.description;
        op.doc.name = oneProgress.file.name;
        op.doc.size = oneProgress.file.size;
        op.doc.labelMap = oneProgress.labelMap;
        var postdata = JSON.stringify(op);
        console.log("UPLOADING DONE: finishing icon");
        $http.post(postURL, postdata)
        .success( function(data) {
            if (data.exception || data.error) {
                $scope.reportError(data);
                return;
            }
            oneProgress.status = "DONE";
            oneProgress.done = true;
            oneProgress.doc = data;
            console.log("UPLOADING ALL DONE SUCCESS");
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    
    
    $scope.updatePersonal = function() {
        var newProfile = {};
        newProfile.name = $scope.profile.name;
        newProfile.description = $scope.profile.description;
        newProfile.notifyPeriod = $scope.profile.notifyPeriod;
        newProfile.timeZone = $scope.profile.timeZone;
        $scope.updateServer(newProfile);
    }
    $scope.updateServer = function(newProfile) {
        console.log("UPDATE PROFILE WITH", newProfile);
        var postURL = "updateProfile.json";
        $http.post(postURL, JSON.stringify(newProfile))
        .success( function(data) {
            //$scope.profile = data;
            window.location='UserSettings.htm';
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.exit = function() {
        window.location='UserSettings.htm';
    }
    
    $scope.addEmail = function() {
        var newProfile = {};
        newProfile.preferred = $scope.newEmail;
        $scope.updateServer(newProfile);
    }
    $scope.selectTimeZone = function(newTimeZone) {
        $scope.profile.timeZone = newTimeZone;
        var newProfile = {};
        newProfile.key = $scope.profile.key;
        newProfile.timeZone = newTimeZone;
        $scope.updateServer(newProfile);
    }
});

</script>


<div>

<%@include file="../jsp/ErrorPanel.jsp"%>

<div class="container-fluid">
    <div class="row">
            <span class="col-2 m-3" style="cursor: pointer;">
                <button class="btn btn-secondary btn-raised btn-comment btn-wide py-1" ng-click="exit()">Return to Profile</button>
            </span>
        </div>
        
        <div class="row-cols-3 d-flex  m-3">
<div class="d-flex col-9">
            <div class="contentColumn">
                <div class="form-group d-flex">
                    <label class="col-md-2 control-label h6"></label>
                    <div class="col-md-10">
                        <p>Drag and drop a JPG image into the spot below. 
                        <ul><li>It must be less than 1MB in size</li>
                        <li>ideally should be about 100 pixels square.</li>
                        <li>Image formats other than JPG are not supported.</li>
                        </ul>
                    </div>
                </div>
                <div class="form-group d-flex">
                    <label class="col-md-2 control-label h6">Drop Here:</label>
                    <div class="col-md-10">
                        <div id="holder" class="nicenice">Drop Your Image Here</div>
                    </div>
                </div>
                <div ng-repeat="fp in fileProgress" class="form-group d-flex">
                    <div class="well col-10">
                        <div class="row d-flex">
                          <span class="col-6"><b>{{fp.file.name}}</b></span>

                          <span class="col-4 h6">{{fp.status}}</span>
                        </div>
                        <div style="padding:5px;">
                            <div style="text-align:center">{{fp.status}}:  {{fp.loaded|number}} of {{fp.file.size|number}} bytes</div>
                            <div class="progress">
                                <div class="progress-bar progress-bar-success" role="progressbar"
                                       aria-valuenow="50" aria-valuemin="0" aria-valuemax="100"
                                       style="width:{{fp.percent}}%">
                                </div>
                            </div>
                        </div>

                        <div ng-hide="fp.done">
                            <button ng-click="startUpload(fp)" class="btn btn-primary btn-raised">
                                Upload</button>
                            <button ng-click="cancelUpload(fp)" class="btn btn-primary btn-raised">
                                Cancel</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
            
    </div>



</div>

<%!

    public UserProfile findSpecifiedUserOrDefault(AuthRequest ar) throws Exception {
        String userKey = ar.reqParam("userKey");
        UserProfile up = UserManager.getUserProfileByKey(userKey);
        if (up==null) {
            Thread.sleep(3000);
            throw WeaverException.newBasic(
                "Can not find a user with key = '%s'.  This page requires a valid key.", 
                userKey);
        }
        return up;
    }

%>
<script>
var holder = document.getElementById('holder');
holder.ondragenter = function (e) {
    e.preventDefault();
    this.className = 'nicenice lvl-over';
    return false;
};
holder.ondragleave = function () {
    this.className = 'nicenice';
    return false;
};
holder.ondragover = function (e) {
    e.preventDefault()
}
holder.ondrop = function (e) {
    e.preventDefault();

    var newFiles = e.dataTransfer.files;
    if (!newFiles) {
        alert("Oh.  It looks like you are using a browser that does not support the dropping of files.  Currently we have no other solution than using Mozilla or Chrome or the latest IE for uploading files.");
        return;
    }
    if (newFiles.length==0) {
        console.log("Strange, got a drop, but no files included");
    }

    this.className = 'nicenice';
    var scope = MY_SCOPE;


    for (var i=0; i<newFiles.length; i++) {
        var newProgress = {};
        newProgress.file = newFiles[i];
        newProgress.status = "Preparing";
        newProgress.done = false;
        scope.fileProgress.push(newProgress);
    }
    scope.$apply();
};
</script>

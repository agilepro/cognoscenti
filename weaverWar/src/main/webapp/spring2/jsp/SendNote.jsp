<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%@page import="com.purplehillsbooks.weaver.CustomRole"
%><%@page import="com.purplehillsbooks.weaver.LicenseForUser"
%><%@page import="com.purplehillsbooks.weaver.mail.EmailGenerator"
%><%!
    String pageTitle="Compose EMail";
%><%
/*
Required parameters:  

    1. pageId  : This is the id of a Workspace and used to retrieve NGWorkspace.

Optional Parameters:

    1. eGenId       : This is the id of a Email Generator.  If omitted a NEW one is created.
    2. intro        : This is the introductory comment in email.
    3. subject      : Set subject of email.
    4. noteId       : This is Topic id which can be included in the email as body contents
    5. att          : The id of an attachement to automatically include
    6. meet         : The id of a meeting to automatically include

    6. exclude      : This is used to check if responders are excluded or not.
    7. tempmem      : Used to provide temprary membership.
    9. attach{docid}: This optional parameter is used to get list of earlier selected document.
*/
    //set 'forceTemplateRefresh' in config file to 'true' to get this
    String templateCacheDefeater = "";
    if ("true".equals(ar.getSystemProperty("forceTemplateRefresh"))) {
        templateCacheDefeater = "?t="+System.currentTimeMillis();
    }

    String pageId      = ar.reqParam("pageId");
    String siteId      = ar.reqParam("siteId");
    String meetId      = ar.defParam("meet", null);
    String layout      = ar.defParam("layout", null);
    String mailSubject  = ar.defParam("subject", null);
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    ar.assertAccessWorkspace("Must be a member to send email");
    UserProfile uProf = ar.getUserProfile();
    AddressListEntry uAle = new AddressListEntry(uProf);
    List<File> allLayouts = MeetingRecord.getAllLayouts(ar, ngw);
    JSONArray allLayoutNames = new JSONArray();
    for (File aFile : allLayouts) {
        allLayoutNames.put(aFile.getName());
    }
    
    JSONObject meeting = new JSONObject();
    JSONArray meetingParticipants = new JSONArray();
    JSONArray meetingAttendees = new JSONArray();
    JSONArray meetingNonAttendees = new JSONArray();
    JSONArray meetingExpected = new JSONArray();
    JSONArray meetingNotExpected = new JSONArray();
    JSONArray meetingAssignment = new JSONArray();

    String eGenId      = ar.defParam("id", null);
    String selectedRole = "Members";
    JSONObject emailInfo = null;
    String targetRole = null;
    if (eGenId!=null) {
        EmailGenerator eGen = ngw.getEmailGeneratorOrFail(eGenId);
        List<AddressListEntry> allALEs = AddressListEntry.toAddressList( eGen.getAlsoTo() );
        emailInfo = eGen.getJSON(ar, ngw);
        meetId = eGen.getMeetingId();
        boolean isMeeting = (meetId!=null && meetId.length()>0);
        if (isMeeting) {
            MeetingRecord mr = ngw.findMeetingOrNull(meetId);
            if (mr!=null) {
                emailInfo.put("meetingInfo", mr.getFullJSON(ar, ngw, false));
                if(mailSubject == null){
                    mailSubject = "Meeting: "+mr.getNameAndDate(mr.getOwnerCalendar());
                }
                meeting = mr.getFullJSON(ar, ngw, false);
            }
        }
    }
    else {
        emailInfo = new JSONObject();
        emailInfo.put("id", "~new~");
        emailInfo.put("state", 1);
        emailInfo.put("intro", ar.defParam("intro",
                "Sending this note to let you know about a recent update to this web page "
                +"has information that is relevant to you.  Follow the link to see the most recent version."));
        emailInfo.put("alsoTo", new JSONArray());
        emailInfo.put("excludeResponders", false);
        emailInfo.put("makeMembers", false);
        emailInfo.put("includeBody", true);
        emailInfo.put("scheduleTime", new Date().getTime());
        
        if (layout!=null) {
            emailInfo.put("meetingLayout", layout);
        }

        String noteId = ar.defParam("noteId", null);

        if (noteId!=null) {
            TopicRecord noteRec = ngw.getNoteOrFail(noteId);
            if(mailSubject == null){
                mailSubject = noteRec.getSubject();
            }
            if(mailSubject==null || mailSubject.trim().length()==0){
                mailSubject = "Sending Topic from Workspace";
            }
            emailInfo.put("noteInfo", noteRec.getJSONWithComments(ar, ngw));

            targetRole = noteRec.getTargetRole();
            emailInfo.put("alsoTo", AddressListEntry.getJSONArray(noteRec.getSubscriberRole().getExpandedPlayers(ngw)));
        }



        JSONArray docList = new JSONArray();
        String att  = ar.defParam("att", null);
        if (att!=null) {
            AttachmentRecord attRec = ngw.findAttachmentByID(att);
            if (attRec!=null) {
                docList.put(attRec.getUniversalId());
            }
        }
        emailInfo.put("docList", docList);

        boolean isMeeting = (meetId!=null && meetId.length()>0);
        if (isMeeting) {
            MeetingRecord mr = ngw.findMeetingOrNull(meetId);
            if (mr!=null) {
                emailInfo.put("meetingInfo", mr.getFullJSON(ar, ngw, false));
                if(mailSubject == null){
                    mailSubject = "Meeting: "+mr.getNameAndDate(mr.getOwnerCalendar());
                }
                emailInfo.put("alsoTo", AddressListEntry.getJSONArrayFromIds(mr.getParticipants()));
                meeting = mr.getFullJSON(ar, ngw, false);
                targetRole = mr.getTargetRole();
            }
        }

        if(mailSubject == null){
            mailSubject = "Message from Workspace "+ngw.getFullName();
        }
        emailInfo.put("subject", mailSubject);
        JSONArray defaultRoles = new JSONArray();
        if (targetRole!=null && targetRole.length()>0) {
            selectedRole = targetRole;
        }
        defaultRoles.put(selectedRole);
        emailInfo.put("roleNames", defaultRoles);

    }

    JSONArray allRoles = new JSONArray();
    for (NGRole role : ngw.getAllRoles()) {
        allRoles.put( role.getJSON() );
    }
    JSONArray attachmentList = ngw.getJSONAttachments(ar);

    String docSpaceURL = "";

    if (uProf!=null) {
        LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
        docSpaceURL = ar.baseURL +  "api/" + ngw.getSiteKey() + "/" + ngw.getKey()
                    + "/summary.json?lic="+lfu.getId();
    }

/* PROTOTYPE

    $scope.emailInfo = {
      "alsoTo": [{"uid":"foo@example.com","name":"Mr. Foo"}],
      "attachFiles": false,
      "docList": [],
      "excludeResponders": false,
      "id": "~new~",
      "includeBody": false,
      "intro": "Sending this note to let you know about a recent update to this web page has information that is relevant to you.  Follow the link to see the most recent version.",
      "makeMembers": false,
      "noteInfo": {
        "comments": [
          {
            "content": "xxx",
            "time": 1435356818486,
            "user": "kswenson@example.com"
          },
          {
            "content": "yyy",
            "time": 1435356822441,
            "user": "kswenson@example.com"
          }
        ],
        "deleted": false,
        "docList": ["EZIGICMWG@facility-1-wellness-circle@8170"],
        "draft": false,
        "html": "<p>xxx<\/p>\n",
        "id": "3896",
        "labelMap": {
          "Members": true,
          "NO Game": true
        },
        "modTime": 1435356792085,
        "modUser": {
          "name": "Keith Swenson",
          "uid": "kswenson@example.com"
        },
        "pin": 0,
        "public": true,
        "subject": "public topic",
        "universalid": "FLVQAPMWG@facility-1-wellness-circle@3896"
      },
      "roleNames": ["Members"],
      "subject": "public topic"
    };

    */
%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, $modal, AllPeople, $sce) {
    setUpLearningMethods($scope, $modal, $http);
    $scope.siteId = "<%ar.writeJS(siteId);%>";
    $scope.isNew = <%=(eGenId==null)%>;
    $scope.emailInfo = <%emailInfo.write(out,2,4);%>;
    $scope.allRoles = <%allRoles.write(out,2,4);%>;
    $scope.meeting = <%meeting.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allLayoutNames = <%allLayoutNames.write(out,2,4);%>;
    $scope.suppressEmail = <%=ngw.suppressEmail()%>;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.recipient = {};
    $scope.recipientList = [{uid:"kswenson@example.com",name:"K Swenson"}];
    $scope.renderedEmail = "<div>not specified yet</div>";

    $scope.newEmailAddress = "";
    $scope.newAttachment = "";
    
    if ($scope.emailInfo.status==1) {
        window.setMainPageTitle("Compose Email");
    }
    else {
        window.setMainPageTitle("Create Email");
    }
    
    if (!$scope.emailInfo.meetingLayout) {
        $scope.emailInfo.meetingLayout = "FullDetail.chtml";
    }

    $scope.saveEmail = function() {
        console.log("SAVE EMAIL", $scope.emailInfo);
        $scope.emailInfo.alsoTo.forEach(function(item) {
            if (!item.uid) {
                item.uid = item.name;
            }
        });
        var postURL = "emailGeneratorUpdate.json?id="+$scope.emailInfo.id;
        var postdata = angular.toJson($scope.emailInfo);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            if ($scope.emailInfo.sendIt == true || $scope.emailInfo.deleteIt == true) {
                window.location = "EmailCreated.htm";
                return;
            }
            if ($scope.isNew) {
                window.location = "SendNote.htm?id="+data.id;
            }
            $scope.emailInfo = data;
            console.log("Got Email Object", data);
            $scope.getRenderedEmail();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.getRenderedEmail = function() {
        var postURL = "renderEmail.json";
        var postObj = {id: $scope.emailInfo.id, toUser: $scope.recipient.uid};
        var postdata = angular.toJson(postObj);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.renderedEmail = $sce.trustAsHtml(data.html);
            $scope.renderedSubject = data.subject;
            if (data.addressees) {
                var newRecList = [];
                data.addressees.forEach( function(item) {
                    newRecList.push(item);
                });
                $scope.recipientList = newRecList;
            }
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.getRenderedEmail();
    $scope.sendEmail = function() {
        if ($scope.emailInfo.alsoTo.length==0) {
            alert("Specify who to send email to before pressing 'Send' button");
            return;
        }
        $scope.emailInfo.sendIt = true;
        $scope.emailInfo.scheduleIt = false;
        $scope.saveEmail();
    }
    $scope.scheduleEmail = function() {
        $scope.emailInfo.sendIt = false;
        $scope.emailInfo.scheduleIt = true;
        $scope.saveEmail();
    }
    $scope.deleteEmail = function() {
        $scope.emailInfo.sendIt = false;
        $scope.emailInfo.scheduleIt = false;
        $scope.emailInfo.deleteIt = true;
        $scope.saveEmail();
    }

    $scope.hasRole = function(roleName) {
        var rex = false;
        $scope.emailInfo.roleNames.map( function(val) {
            if (roleName == val) {
                rex = true;
                return true;
            }
        });
        return rex;
    }
    $scope.toggleRole = function(roleName) {
        if (!$scope.hasRole(roleName)) {
            $scope.emailInfo.roleNames.push(roleName);
        }
        else {
            var newSet = [];
            $scope.emailInfo.roleNames.map( function(val) {
                if (roleName != val) {
                    newSet.push(val);
                }
            });
            $scope.emailInfo.roleNames = newSet;
        }
    }
    $scope.addPlayers = function(role) {
        if (!role) {
            return;
        }
        role.players.forEach( function(player) {
            addToTo(player);
        });
    }
    $scope.addMeetingInvitees = function(role) {
        if (!$scope.meeting) {
            return;
        }
        $scope.meeting.participants.forEach( function(player) {
            addToTo(player);
        });
    }
    $scope.addMeetingAttendees = function(role) {
        if (!$scope.meeting) {
            return;
        }
        $scope.meeting.attended.forEach( function(uid) {
            addToTo(AllPeople.findUserFromID(uid, $scope.siteId));
        });
    }
    $scope.addMeetingNoShows = function(role) {
        if (!$scope.meeting) {
            return;
        }
        $scope.meeting.participants.forEach( function(player) {
            var found = false;
            $scope.meeting.attended.forEach( function(uid) {
                if (player.uid == uid) {
                    found = true;
                }
            });
            if (!found) {
                addToTo(player);
            }
        });
    } 
    $scope.addTopicSubscribers = function(role) {
        if (!$scope.emailInfo.noteInfo || !$scope.emailInfo.noteInfo.subscribers) {
            return;
        }
        $scope.emailInfo.noteInfo.subscribers.forEach( function(player) {
            addToTo(player);
        });
    }
    
    function addToTo(player) {
        var found = false;
        $scope.emailInfo.alsoTo.forEach( function(person) {
            if (person.name == player.name) {
                found = true;
            }
        });
        if (!found) {
            $scope.emailInfo.alsoTo.push({name: player.name, uid: player.uid});
        }
    }
    

    $scope.namePart = function(email) {
        var pos = email.indexOf("�");
        if (pos<0) {
            pos = email.indexOf("<");
        }
        if (pos<0) {
            return email;
        }
        return email.substring(0,pos);
    }
    $scope.emailPart = function(email) {
        var pos = email.indexOf("�");
        var pos2 = email.indexOf("�");
        if (pos<0 || pos2<pos) {
            pos = email.indexOf("<");
            pos2 = email.indexOf(">");
        }
        if (pos<0 || pos2<pos) {
            return email;
        }
        return email.substring(pos+1,pos2);
    }
    $scope.shortDoc = function(docName) {
        if (docName.length<36) {
            return docName;
        }
        var pos = docName.lastIndexOf(".");
        if (pos<30) {
            return docName.substring(0,36);
        }
        return docName.substring(0,30)+".."+docName.substring(pos);
    }
    $scope.explainState = function() {
        if ($scope.emailInfo.state==1) {
            return "Draft Email Message";
        }
        else if ($scope.emailInfo.state==2) {
            return "Scheduled to send: "+new Date($scope.emailInfo.scheduleTime);
        }
        else if ($scope.emailInfo.state==3) {
            return "Already sent: "+new Date($scope.emailInfo.sendDate);
        }
    }

    $scope.datePickOptions = {
        formatYear: 'yyyy',
        startingDay: 1
    };
    $scope.datePickDisable = function(date, mode) {
        return false;
    };


    $scope.loadPersonList = function(query) {
        //note: this is a hack, if the also to list has objects without
        //uid field, the input-tags form control fails to function
        //so this puts the uid value into the records.
        //Could not get this called from the input-tags control
        //when new tag created.  I don't know why.
        $scope.cleanUpAlsoTo();
        var people = AllPeople.findMatchingPeople(query, $scope.siteId);
        return people;
    }
    
    $scope.cleanUpAlsoTo = function() {
        $scope.emailInfo.alsoTo = cleanUserList($scope.emailInfo.alsoTo);
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
    $scope.navigateToDoc = function(docId) {
        window.location="DocDetail.htm?aid="+docId;
    }
    $scope.sendDocByEmail = function(docId) {
        window.location="SendNote.htm?att="+docId;
    }
    $scope.downloadDocument = function(doc) {
        if (doc.attType=='URL') {
             window.open(doc.url,"_blank");
        }
        else {
            window.open("a/"+doc.name,"_blank");
        }
    }
    $scope.unattachDocFromItem = function(docId) {
        var newList = [];
        $scope.emailInfo.docList.forEach( function(iii) {
            if (iii != docId) {
                newList.push(iii);
            }
        });
        $scope.emailInfo.docList = newList;
        //save is manual
    }
    $scope.openAttachDocument = function () {
        
        if ($scope.emailInfo.id=="~new~") {
            alert("Please 'Save & Preview' this email generator in order to change attached documents");
            return;
        }

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/AttachDocument.html<%=templateCacheDefeater%>',
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            resolve: {
                containingQueryParams: function() {
                    return "email="+$scope.emailInfo.id;
                },
                docSpaceURL: function() {
                    return "<%ar.writeJS(docSpaceURL);%>";
                }
            }
        });

        attachModalInstance.result
        .then(function (docList) {
            $scope.emailInfo.docList = docList;
            $scope.saveEmail();
        }, function () {
            //cancel action - nothing really to do
        });
    };

});

</script>
<script src="../../../jscript/AllPeople.js"></script>

<div>

<%@include file="ErrorPanel.jsp"%>

<div class="container override mx-4">
    <!--<div class="col-md-auto second-menu d-flex">
        <button type="button" data-bs-toggle="collapse" data-bs-target="#collapseSecondaryMenu" aria-expanded="false" aria-controls="collapseSecondaryMenu">
            <i class="fa fa-bars"></i>
        </button>
        <div class="collapse" id="collapseSecondaryMenu">
            <div class="col-md-auto">

                <span class="btn second-menu-btn btn-wide" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link " role="menuitem" href="EmailCreated.htm">
          Email Prepared</a>
        </span>

        <span class="btn second-menu-btn btn-wide" type="button" ng-click="openTopicCreator()" aria-labelledby="createNewTopic"><a class="nav-link" role="menuitem" href="EmailSent.htm">
            Email Sent</a>
          </span>
</div>
        </div>
    </div>
    <hr>-->
    <div class="col-12">
            <div ng-show="emailInfo.state==1">
                <form class="form-horizontal col-12">
                    <fieldset>
                        <div class="form-group d-flex">
                            <label class="col-md-2 control-label h5">Roles </label>
                            <div class="col-md-10">
                                <div class="form-inline flex-wrap">
                                    <button class="btn-comment btn-wide btn-raised" ng-click="showAddressingOptions=!showAddressingOptions">
                                    <i class="fa fa-plus"></i>&nbsp;Click here to see addressing options</button>
                                </div>
                            </div>
                        </div>
                        <div class="row d-flex m-3" ng-show="showAddressingOptions">
                            <div class="col-md-2 control-label h6">Add Members of: :</div>
                            <div class="col-md-10 well d-flex flex-wrap">
                                <div ng-repeat="role in allRoles" > <button class="btn-comment btn-wide mx-2 h6" ng-click="addPlayers(role)">
                                <span class="h6">{{role.name}}</span></button>
                            </div>
                        </div>
                        </div>
                        <!--Meeting Participants-->
                        <div class="row col-12 my-2">
                            <div ng-show="meeting.participants">
                                <label class="col-md-2 control-label h5">Meeting Participants:</label>
                                <span class="col-md-10">
                                    <button class="btn-comment btn-wide btn-raised" ng-click="addMeetingInvitees()" title="Add all the people invited to the meeting">Add Meeting Invitees</button>
                                    <button class="btn-comment btn-wide btn-raised" ng-click="addMeetingAttendees()" title="Add all the people who attended the meeting">Add Meeting Attendees</button>
                                    <button class="btn-comment btn-wide btn-raised" ng-click="addMeetingNoShows()" title="Add all the people invited but did not show up">Add Meeting No-shows</button>                           
                                </span>
                            </div>
                        </div>
                        <!--Topic Subscribers-->
                        <div class="row col-12 d-flex my-2">
                            <div ng-show="emailInfo.noteInfo.subscribers">
                                <label class="col-md-2 control-label h5">Topic Subscribers:</label>
                                <span class="col-md-10">
                                        <button class="btn-comment btn-wide btn-raised" ng-click="addTopicSubscribers()" title="Add all the people invited to the meeting">Add All Subscribers</button>
                                </span>
                            </div>
                        </div>
                        <!--Clear-->
                        <div class="row d-flex col-12 my-2">
                            <div class="form-group d-flex">
                                <label class="col-md-2 control-label h5">Clear:</label>
                                <span class="col-md-10">
                                        <button class="btn-comment btn-wide btn-raised" ng-click="emailInfo.alsoTo = []" title="Add all the people invited to the meeting">Clear Addressees</button>
                                </span>
                            </div>
                        </div>
                        <!--Send To-->
                        <div class="row d-flex col-12 my-2">
                            <label class="col-md-2 control-label h5" for="alsoalsoTo">Send To:</label>
                            <div class="col-md-10">
                                <tags-input ng-model="emailInfo.alsoTo" placeholder="Enter user name or id" display-property="name" key-property="uid" on-tag-clicked="toggleSelectedPerson($tag)" replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true" on-tag-added="cleanUpAlsoTo()" on-tag-removed="cleanUpAlsoTo()"> 
                                    <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
                                </tags-input>
                            </div>
                        </div>
                        <!--Subject-->
                        <div class="row form-group d-flex my-2">
                            <label class="col-md-2 control-label h5 " for="subject">Subject:</label>
                            <div class="col-md-10">
                                <input id="subject" ng-model="emailInfo.subject" class="form-control"/>
                            </div>
                        </div>
                        <!--Introduction-->
                        <div class="row my-2 form-group d-flex">
                            <label class="col-md-2 control-label h5 " for="intro">Introduction:</label>
                            <div class="col-md-10">
                                <textarea id="intro" ng-model="emailInfo.intro" class="form-control markDownEditor" style="height:200px" title="Enter a message in Mark-Down format" placeholder="Enter a message in 'Mark-Down' format">
                                </textarea>
                            </div>
                        </div>
                        <!--Attachments-->
                        <div class="row my-3 form-group d-flex" >
                            <label class="col-md-2 control-label h5 " for="intro">Attachments:</label>
                            <button class="btn-comment btn-default btn-raised" ng-click="openAttachDocument()">Attachments</button>
                            <div class="col-md-6">
                                <div ng-repeat="docid in emailInfo.docList" style="vertical-align: top">
                                    <div ng-repeat="fullDoc in [getFullDoc(docid)]">
                                        <span ng-click="navigateToDoc(docid)">
                                            <img src="<%=ar.retPath%>assets/images/iconFile.png" ng-show="fullDoc.attType=='FILE'">
                                            <img src="<%=ar.retPath%>assets/images/iconUrl.png" ng-show="fullDoc.attType=='URL'">
                                        </span> &nbsp;
                                        <span ng-click="downloadDocument(fullDoc)">
                                            <span class="fa fa-external-link" ng-show="fullDoc.attType=='URL'"></span>
                                            <span class="fa fa-download" ng-hide="fullDoc.attType=='URL'"></span>
                                        </span> &nbsp; 
                                        {{fullDoc.name}}
                                    </div>
                                </div>
                                <div ng-hide="emailInfo.docList && emailInfo.docList.length>0" class="doubleClickHint">
                    Click to add / remove attachments
                                </div>
                            </div>
                        </div>
                        <!--Type-->
                        <div class="row my-3 form-group d-flex" ng-click="emailInfo.attachFiles=!emailInfo.attachFiles" >
                            <label class="col-md-1 control-label h6 ms-5">Type:</label>
                            <div class="col-md-9 h6 ">
                                <input type="checkbox" ng-model="emailInfo.attachFiles"/>  
                Include attachment data directly in the email <b><em>(unsafe)</em></b>
                            </div>
                        </div>  
                        <!--Meeting-->        
                        <div class="row my-3 form-group d-flex" ng-show="emailInfo.meetingInfo.name">
            <hr/>
                        <label class="col-md-2 control-label h5">Meeting:</label>
                        <div class="col-md-10">
                            <span class="h6" style="cursor:default">{{emailInfo.meetingInfo.name}}</span> </div>
                            <div class="row my-3">
                                <label class="col-md-2 control-label h5">Layout:</label>
                                <div class="col-md-2"> 
                            <select class="form-control btn btn-comment btn-wide btn-raised" style="text-align: left;" ng-model="emailInfo.meetingLayout" ng-options="n for n in allLayoutNames"></select></div>
                        </div>
                        </div>
                        <!--Discussion-->
                        <div class="row my-3 form-group d-flex" ng-show="emailInfo.noteInfo.subject">
            <hr/>          
                            <label class="col-md-2 control-label h5">Discussion Topic:</label>
                            <div class="col-md-10">
                                <div class="togglebutton">
                                <span class="col-md-2 btn-comment btn-wide btn-sm px-2 me-2">{{emailInfo.noteInfo.subject}}</span>
                                <label class="h6">
                                    <input type="checkbox" ng-model="emailInfo.includeBody"> Include text in email? &nbsp;
                                </label>
                            </div>
                        </div>
                        </div>
                        <!--Action Items-->
                        <div class="row my-3 form-group d-flex">
            <hr/>
                            <label class="col-md-2 control-label h5">Include Action Items:</label>
                            <div class="col-md-10">
                                <span class="btn-wide h6" ng-click="emailInfo.tasksOption='None'">
                                    <input type="radio" ng-model="emailInfo.tasksOption" value="None"> None &nbsp 
                                </span>
                                <span class="btn-wide mx-2 h6" ng-click="emailInfo.tasksOption='Assignee'">
                                    <input type="radio" ng-model="emailInfo.tasksOption" value="Assignee"> Only to Assignee &nbsp 
                                </span>
                                <span class="btn-wide mx-2 h6" ng-click="emailInfo.tasksOption='All'">
                                    <input type="radio" ng-model="emailInfo.tasksOption" value="All"> All Action Items to Everyone
                                </span>
                            </div>
                        </div>
          
                                    <!-- Form Control Schedule Time Begin -->
                                    <!--div class="form-group" >
            <label class="col-md-2 control-label" for="scheduledTime">When?</label>
            <div class="col-md-10">
                <div class="togglebutton col-md-4">
                  <label>
                    <input type="checkbox" ng-model="emailInfo.scheduleIt"> Send later?
                  </label>
                </div>
              <span class="col-md-4" ng-show="emailInfo.scheduleIt">
                At:  
                <span datetime-picker ng-model="emailInfo.scheduleTime" datetime-picker 
                    class="form-control" style="max-width:300px">
                    {{emailInfo.scheduleTime|date:"dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm  '&nbsp;  GMT'Z"}}
                </span> 
              </span>
            </div>
          </div-->
                        <!-- status -->
                        <div class="row my-3 form-group d-flex">
            <hr/>
                            <label class="col-md-2 control-label h5">Status:</label>
                            <div class="col-md-10 h6">
                            {{explainState()}}
                            </div>
                        </div>
                        <!--Suppression-->
                        <div class="row my-3 form-group d-flex" ng-show="suppressEmail">
                            <label class="col-md-2 control-label h5">Suppression:</label>
                            <div class="col-md-10">
                                <div class="form-inline text-red-emphasis h6" >
                                <b>Note:</b> suppressEmail enabled. No actual email will be sent from from this workspace. Email will appear in the database as if it had been sent.
                                </div>
                            </div>
                        </div>
        <!-- Form Control BUTTONS -->
                        <div class="row my-3 form-group d-flex">
                            <div class="col-md-12 form-group d-flex">
                                <button ng-click="deleteEmail()" class="btn btn-danger btn-raised me-auto" ng-hide="emailInfo.id=='~new~'">Delete</button>
                                <button ng-click="saveEmail()" class="btn btn-secondary btn-raised ms-auto">Save &amp; Preview</button>
                                <button ng-click="sendEmail()" class="btn btn-secondary btn-raised mx-1" ng-show="suppressEmail">Simulate Sending</button>
                                <button ng-click="sendEmail()" class="btn btn-primary btn-raised mx-1" ng-hide="suppressEmail">Send Now</button>
                            </div>
                        </div>
                    </fieldset>
                </form>
            </div>
        </div>
            <div class="container well">
                <div class="row form-group d-flex">
                    <div class="my-2">
                    <h4>Preview Email for a specific recipient:</h4></div>
                    <label class="col-md-2 control-label h5 ms-5">For Recipient: </label>
                    <div class="col-md-6">
                        <select class="form-control" ng-model="recipient" ng-options="rec as rec.name for rec in recipientList track by rec.uid"></select>
                    </div>
                    <!--<div class="col-md-4">
                        <button ng-click="getRenderedEmail()" class=" btn-comment btn-wide h6">Preview Email</button>
                    </div>-->
                </div>
            
        

                <div class="instruction h6 mt-3">This is what the email will look like:<br/><br/></div>
  
                <div class="well" style="padding:30px">
                    <div style="padding:10px">{{renderedSubject}}</div>
                    <div ng-bind-html="renderedEmail"></div>
                </div>


                <div style="height:100px"></div>
            </div>
        </div>
    </div>
  
<script src="<%=ar.retPath%>new_assets/templates/AttachDocumentCtrl.js"></script>

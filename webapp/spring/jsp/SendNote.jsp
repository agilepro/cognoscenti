<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.CustomRole"
%><%@page import="org.socialbiz.cog.LicenseForUser"
%><%@page import="org.socialbiz.cog.EmailGenerator"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%!
    String pageTitle="Send Topic By Mail";
%><%
/*
Required parameters:

    1. pageId  : This is the id of a Workspace and used to retrieve NGPage.

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
    NGWorkspace ngw = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngw);
    ar.assertMember("Must be a member to send email");
    UserProfile uProf = ar.getUserProfile();
    AddressListEntry uAle = new AddressListEntry(uProf);

    String eGenId      = ar.defParam("id", null);
    String selectedRole = "Members";
    JSONObject emailInfo = null;
    if (eGenId!=null) {
        EmailGenerator eGen = ngw.getEmailGeneratorOrFail(eGenId);
        emailInfo = eGen.getJSON(ar, ngw);
    }
    else {
        String targetRole = null;
        emailInfo = new JSONObject();
        emailInfo.put("id", "~new~");
        emailInfo.put("intro", ar.defParam("intro",
                "Sending this note to let you know about a recent update to this web page "
                +"has information that is relevant to you.  Follow the link to see the most recent version."));
        emailInfo.put("alsoTo", new JSONArray());
        emailInfo.put("excludeResponders", false);
        emailInfo.put("makeMembers", false);
        emailInfo.put("includeBody", false);
        emailInfo.put("scheduleTime", new Date().getTime());

        String mailSubject  = ar.defParam("subject", null);
        String noteId = ar.defParam("noteId", null);

        if (noteId!=null) {
            TopicRecord noteRec = ngw.getNoteOrFail(noteId);
            if(mailSubject == null){
                mailSubject = noteRec.getSubject();
            }
            if(mailSubject==null || mailSubject.trim().length()==0){
                mailSubject = "Sending Topic from Workspace";
            }
            emailInfo.put("noteInfo", noteRec.getJSONWithHtml(ar, ngw));

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


        String meetId      = ar.defParam("meet", null);
        if (meetId!=null && meetId.length()>0) {
            MeetingRecord mr = ngw.findMeeting(meetId);
            if (mr!=null) {
                emailInfo.put("meetingInfo", mr.getFullJSON(ar, ngw));
                if(mailSubject == null){
                    mailSubject = "Meeting: "+mr.getNameAndDate(mr.getOwnerCalendar());
                }
                emailInfo.put("alsoTo", AddressListEntry.getJSONArrayFromIds(mr.getParticipants()));
            }
            targetRole = mr.getTargetRole();
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
            "user": "kswenson@us.fujitsu.com"
          },
          {
            "content": "yyy",
            "time": 1435356822441,
            "user": "kswenson@us.fujitsu.com"
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
          "uid": "kswenson@us.fujitsu.com"
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
    window.setMainPageTitle("Compose Email");
    $scope.isNew = <%=(eGenId==null)%>;
    $scope.emailInfo = <%emailInfo.write(out,2,4);%>;
    $scope.allRoles = <%allRoles.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.recipient = {};
    $scope.recipientList = [{uid:"kswenson@us.fujitsu.com",name:"K Swenson"}];
    $scope.renderedEmail = "<div>not specified yet</div>";

    $scope.newEmailAddress = "";
    $scope.newAttachment = "";

    $scope.saveEmail = function() {
        console.log("SAVE EMAIL");
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
                window.location = "listEmail.htm";
                return;
            }
            if ($scope.isNew) {
                console.log("OK, we need to navigate to thenew ID");
                window.location = "sendNote.htm?id="+data.id;
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
        console.log("recipient is NOW", $scope.recipient);
        var postObj = {id: $scope.emailInfo.id, toUser: $scope.recipient.uid};
        var postdata = angular.toJson(postObj);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.renderedEmail = $sce.trustAsHtml(data.html);
            $scope.renderedSubject = data.subject;
            console.log("got RENDER", data);
            if (data.addressees) {
                var newRecList = [];
                data.addressees.forEach( function(item) {
                    newRecList.push(item);
                });
                $scope.recipientList = newRecList;
                console.log("Updated list to", $scope.recipientList);
            }
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
    $scope.getRenderedEmail();
    $scope.sendEmail = function() {
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
    $scope.addPlayers = function() {
        console.log("addPlayers: ",$scope.selectedRole);
        if (!$scope.selectedRole) {
            return;
        }
        $scope.allRoles.forEach( function(role) {
            if (role.name == $scope.selectedRole.name) {
                role.players.forEach( function(player) {
                    addToTo(player);
                });
            }
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
            console.log("Adding player: ",player);
            $scope.emailInfo.alsoTo.push({name: player.name, uid: player.uid});
        }
        else {
            console.log("Ignorint player: ",player);
            
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
        var people = AllPeople.findMatchingPeople(query);
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
        var doc = $scope.getFullDoc(docId);
        window.location="docinfo"+doc.id+".htm";
    }
    $scope.navigateToDocDetails = function(docId) {
        var doc = $scope.getFullDoc(docId);
        window.location="editDetails"+doc.id+".htm";
    }
    $scope.sendDocByEmail = function(docId) {
        var doc = $scope.getFullDoc(docId);
        window.location="sendNote.htm?att="+doc.id;
    }
    $scope.downloadDocument = function(docId) {
        var doc = $scope.getFullDoc(docId);
        window.location="a/"+doc.name;
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

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/AttachDocument.html<%=templateCacheDefeater%>',
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            resolve: {
                docList: function () {
                    return JSON.parse(JSON.stringify($scope.emailInfo.docList));
                },
                attachmentList: function() {
                    return $scope.attachmentList;
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

<style>
.spaceBefore {
    margin-top:20px;
}
</style>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="" ng-click="saveEmail()" >Save Changes</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              href="" ng-click="sendEmail()" >Send Email</a></li>
        </ul>
      </span>
    </div>

    <div>
      <form class="form-horizontal">
        <fieldset>
          <div class="form-group">
            <label class="col-md-2 control-label">Roles</label>
            <div class="col-md-10">
              <div class="form-inline">
                <select ng-model="selectedRole" ng-options="role.name for role in allRoles" class="form-control"></select>
                <button class="btn btn-primary btn-sm btn-raised" ng-click="addPlayers()" ng-show="selectedRole">
                    <i class="fa fa-plus"></i> Add Players from {{selectedRole.name}} </button>
              </div>
            </div>
          </div>
          <div class="form-group">
            <label class="col-md-2 control-label" for="alsoalsoTo">Send To</label>
            <div class="col-md-10">
              <tags-input ng-model="emailInfo.alsoTo" placeholder="Enter user name or id" display-property="name" 
                      key-property="uid" on-tag-clicked="toggleSelectedPerson($tag)"
                      replace-spaces-with-dashes="false" add-on-space="true" add-on-comma="true"
                      on-tag-added="cleanUpAlsoTo()" 
                      on-tag-removed="cleanUpAlsoTo()">
                  <auto-complete source="loadPersonList($query)" min-length="1"></auto-complete>
              </tags-input>
            </div>
          </div>
          <div class="form-group">
            <label class="col-md-2 control-label" for="subject">Subject</label>
            <div class="col-md-10">
              <input id="subject" ng-model="emailInfo.subject" class="form-control"/>
            </div>
          </div>
          <div class="form-group">
            <label class="col-md-2 control-label" for="intro">Introduction</label>
            <div class="col-md-10">
              <textarea id="intro" ng-model="emailInfo.intro" class="form-control" style="height:200px"
                  title="Enter a message in Mark-Down format">
              </textarea>
            </div>
          </div>
          
          <div class="form-group">
          <hr/>
            <label class="col-md-2 control-label">Attachments</label>
            <div class="col-md-10">
              <span ng-repeat="docid in emailInfo.docList" style="vertical-align: top">
                  <span class="dropdown" title="Access this attachment">
                      <button class="attachDocButton" id="menu1" data-toggle="dropdown">
                      <img src="<%=ar.retPath%>assets/images/iconFile.png"> 
                      {{getFullDoc(docid).name | limitTo : 15}}</button>
                      <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" style="cursor:pointer">
                        <li role="presentation" style="background-color:lightgrey">
                            <a role="menuitem" 
                            title="This is the full name of the document"
                            ng-click="navigateToDoc(docid)">{{getFullDoc(docid).name}}</a></li>
                        <li role="presentation"><a role="menuitem" 
                            title="Use DRAFT to set the meeting without any notifications going out"
                            ng-click="navigateToDoc(docid)">Access Document</a></li>
                        <li role="presentation"><a role="menuitem"
                            title="Use PLAN to allow everyone to get prepared for the meeting"
                            ng-click="downloadDocument(docid)">Download File</a></li>
                        <li role="presentation"><a role="menuitem"
                            title="Use RUN while the meeting is actually in session"
                            ng-click="navigateToDocDetails(docid).htm">Document Details</a></li>
                        <li role="presentation"><a role="menuitem"
                            title="Use RUN while the meeting is actually in session"
                            ng-click="sendDocByEmail(docid)">Send by Email</a></li>
                        <li role="presentation"><a role="menuitem"
                            title="Use RUN while the meeting is actually in session"
                            ng-click="unattachDocFromItem(docid)">Un-attach</a></li>
                      </ul>
                  </span>
              </span>
              <button class="btn btn-sm btn-primary btn-raised" ng-click="openAttachDocument()"
                  title="Attach a document">
                  ADD </button>
              
            </div>
          </div>
          <div class="form-group">
            <label class="col-md-2 control-label"></label>
            <div class="col-md-10">
                <div class="form-inline">
                    <span class="form-control" ng-click="emailInfo.includeBody=!emailInfo.includeBody">
                        <input type="checkbox" ng-model="emailInfo.includeBody"/>  Include Files as Attachments
                    </span>
                </div>
            </div>
          </div>
          
          <div class="form-group" ng-show="emailInfo.meetingInfo.name">
            <hr/>
            <label class="col-md-2 control-label">Meeting</label>
            <div class="col-md-10">
              <span class="btn btn-sm btn-default btn-raised">{{emailInfo.meetingInfo.name}}</span>
              Included into email
            </div>
          </div>

          <div class="form-group" ng-show="emailInfo.noteInfo.subject">
            <hr/>          
            <label class="col-md-2 control-label">Discussion Topic</label>
            <div class="col-md-10">
                <div class="togglebutton">
                  <span class="btn btn-sm btn-default btn-raised">{{emailInfo.noteInfo.subject}}</span>
                  <label>
                    <input type="checkbox" ng-model="emailInfo.includeBody"> Include text in email? &nbsp;
                  </label>
                </div>
            </div>
          </div>
          <div class="form-group">
            <hr/>
            <label class="col-md-2 control-label">Action Items:</label>
            <div class="col-md-10">
                <div class="form-inline">
                    <span class="form-control" ng-click="emailInfo.tasksOption='None'">
                        <input type="radio" ng-model="emailInfo.tasksOption" value="None"> None &nbsp 
                    </span>
                    <span class="form-control" ng-click="emailInfo.tasksOption='Assignee'">
                        <input type="radio" ng-model="emailInfo.tasksOption" value="Assignee"> Only to Assignee &nbsp 
                    </span>
                    <span class="form-control" ng-click="emailInfo.tasksOption='All'">
                        <input type="radio" ng-model="emailInfo.tasksOption" value="All"> All Action Items to Everyone
                    </span>
                </div>
            </div>
          </div>
          <hr/>
          <!-- Form Control Schedule Time Begin -->
          <div class="form-group" >
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
          </div>
          <!-- status -->
          <div class="form-group">
            <label class="col-md-2 control-label">Status</label>
            <div class="col-md-10">
               {{explainState()}}
            </div>
          </div>
        <!-- Form Control BUTTONS -->
        <div class="row">
          <div class="col-md-12 form-group text-right">
            <button ng-click="deleteEmail()" class="btn btn-warning btn-raised" 
                    ng-hide="emailInfo.id=='~new~'">Delete</button>
            <button ng-click="saveEmail()" class="btn btn-primary btn-raised">Save &amp; Preview</button>
            <button ng-click="sendEmail()" class="btn btn-primary btn-raised">Send Now</button>
          </div>
        </div>
      </fieldset>
      </form>
    </div>



  <div class="form-inline">
     For Recipient <select class="form-control" ng-model="recipient" ng-options="rec as rec.name for rec in recipientList track by rec.uid"></select>
     <button ng-click="getRenderedEmail()" class="btn btn-primary btn-raised">Preview Email</button>
  </div>
  <div class="instruction">This is what the email will look like:<br/><br/></div>
  
  <div class="well" style="padding:50px">
     <div style="padding:15px">{{renderedSubject}}</div>
     <div ng-bind-html="renderedEmail"></div>
  </div>


  <div style="height:200px"></div>
</div>
  
<script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>

<%!

    private static String composeFromAddress(NGContainer ngc) throws Exception
    {
        StringBuilder sb = new StringBuilder("^");
        String baseName = ngc.getFullName();
        int last = baseName.length();
        for (int i=0; i<last; i++)
        {
            char ch = baseName.charAt(i);
            if ( (ch>='0' && ch<='9') || (ch>='A' && ch<='Z') || (ch>='a' && ch<='z') || (ch==' '))
            {
                sb.append(ch);
            }
        }

        //now add email address in angle brackets
        sb.append(" �");
        sb.append(EmailSender.getProperty("mail.smtp.from"));
        sb.append("�");
        return sb.toString();
    }

%>

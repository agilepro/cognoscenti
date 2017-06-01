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

    String pageId      = ar.reqParam("pageId");
    NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngw);
    ar.assertMember("Must be a member to send email");
    UserProfile uProf = ar.getUserProfile();
    AddressListEntry uAle = new AddressListEntry(uProf);
    String userFromAddress = uAle.generateCombinedAddress();

    String eGenId      = ar.defParam("id", null);
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

        emailInfo.put("from", userFromAddress);
        emailInfo.put("alsoTo", new JSONArray());
        emailInfo.put("excludeResponders", false);
        emailInfo.put("includeSelf", false);
        emailInfo.put("makeMembers", false);
        emailInfo.put("includeBody", false);
        emailInfo.put("scheduleTime", new Date().getTime());

        String meetId      = ar.defParam("meet", null);
        if (meetId!=null && meetId.length()>0) {
            MeetingRecord mr = ngw.findMeeting(meetId);
            if (mr!=null) {
                emailInfo.put("meetingInfo", mr.getFullJSON(ar, ngw));
                if(mailSubject == null){
                    mailSubject = "Meeting: "+mr.getNameAndDate();
                }
            }
            targetRole = mr.getTargetRole();
        }

        if(mailSubject == null){
            mailSubject = "Message from Workspace "+ngw.getFullName();
        }
        emailInfo.put("subject", mailSubject);
        JSONArray defaultRoles = new JSONArray();
        if (targetRole!=null && targetRole.length()>0) {
            defaultRoles.put(targetRole);
        }
        else {
            defaultRoles.put("Members");
        }
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
      "from": "Keith Swenson �kswenson@us.fujitsu.com�",
      "id": "~new~",
      "includeBody": false,
      "includeSelf": false,
      "intro": "Sending this note to let you know about a recent update to this web page has information that is relevant to you.  Follow the link to see the most recent version.",
      "makeMembers": false,
      "noteInfo": {
        "comments": [
          {
            "content": "this is a comment on a topic.   I cut back to Weaver and am back on Katie\u2019s training screen. I decide to look at our training materials. A tag in the corner of the front pages says that the whole package is scheduled for review in seven months. I click on Minutes in the tag and view the record of the decision a year ago to adopt the materials and set a one-year review date. No one had expressed any doubts at the time. I close the minutes and the training materials, and there is the familiar ring of Wellness Support faces again.",
            "time": 1435356818486,
            "user": "kswenson@us.fujitsu.com"
          },
          {
            "content": "I cut back to Weaver and am back on Katie\u2019s training screen. I decide to look at our training materials. A tag in the corner of the front pages says that the whole package is scheduled for review in seven months. I click on Minutes in the tag and view the record of the decision a year ago to adopt the materials and set a one-year review date. No one had expressed any doubts at the time. I close the minutes and the training materials, and there is the familiar ring of Wellness Support faces again.",
            "time": 1435356822441,
            "user": "kswenson@us.fujitsu.com"
          }
        ],
        "deleted": false,
        "docList": ["EZIGICMWG@facility-1-wellness-circle@8170"],
        "draft": false,
        "html": "<p>\nthis is a public note\n<\/p>\n<p>\nasdf asd  fas  df  \n<br>alksdjflaskdfjlakj sdf\n<\/p>\n<p>\nas  dfas  dfasd  fas  dfasdf\n<\/p>\n<p>\nI click on Training Records and see that she has had full standard Alzheimer\u2019s training. I close the training record and look at her personal development plan that we did after her first 60 days of employment. Nothing unusual in it and there was even one comment about \u201cThe residents love your smile. Keep smiling!\u201d I click the State Software button and go through their clumsy system to review incident reports for the last several months, and see that there were a variety of reports regarding our Stage 3 residents involving different residents and different caregivers. I note the locations of some of those reports on the pop up scrach pad. Now I had a mystery. What\u2019s going on with our protocols around Stage 3 Alzheimers?\n<\/p>\n<p>\nI click on Training Records and see that she has had full standard Alzheimer\u2019s training. I close the training record and look at her personal development plan that we did after her first 60 days of employment. Nothing unusual in it and there was even one comment about \u201cThe residents love your smile. Keep smiling!\u201d I click the State Software button and go through their clumsy system to review incident reports for the last several months, and see that there were a variety of reports regarding our Stage 3 residents involving different residents and different caregivers. I note the locations of some of those reports on the pop up scrach pad. Now I had a mystery. What\u2019s going on with our protocols around Stage 3 Alzheimers?\n<\/p>\n",
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

var app = angular.module('myApp', ['ui.bootstrap','ngTagsInput','ui.bootstrap.datetimepicker']);
app.controller('myCtrl', function($scope, $http, $modal, AllPeople) {
    window.setMainPageTitle("Compose Email");
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

    $scope.newEmailAddress = "";
    $scope.newAttachment = "";

    $scope.saveEmail = function() {
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
            if ($scope.emailInfo.sendIt == true) {
                window.location = "listEmail.htm";
                return;
            }
            $scope.emailInfo = data;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    }
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
    $scope.dummyDate1 = new Date();
    $scope.datePickOpen = false;
    $scope.openDatePicker = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen = true;
    };
    $scope.datePickOpen1 = false;
    $scope.openDatePicker1 = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen1 = true;
    };


    $scope.loadPersonList = function(query) {
        return AllPeople.findMatchingPeople(query);
    }
    $scope.onTimeSet = function (newDate, secondparam) {
        $scope.emailInfo.scheduleTime = newDate.getTime();
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
    $scope.openAttachDocument = function () {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/AttachDocument.html?t=<%=System.currentTimeMillis()%>',
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

    <div class="well">
      <form class="form-horizontal">
        <fieldset>
          <div class="form-group">
            <label class="col-md-2 control-label" for="from">From</label>
            <div class="col-md-10">
              <select ng-model="emailInfo.from"  class="form-control" style="width: 380px">
                <option value="<% ar.writeHtml(userFromAddress); %>"><% ar.writeHtml(userFromAddress); %></option>
                <option value="<% ar.writeHtml(composeFromAddress(ngw)); %>"><% ar.writeHtml(composeFromAddress(ngw)); %></option>
              </select>
            </div>
          </div>
          <div class="form-group">
            <label class="col-md-2 control-label" for="from">To Role</label>
            <div class="col-md-10">
              <span ng-repeat="role in allRoles">
                <span class="role-label" ng-show="hasRole(role.name)">
                   <span class="label" style="background-color: {{role.color}} !important">{{role.name}}</span>
                   <a title="Remove Role {{role.name}}" ng-click="toggleRole(role.name)"><i class="fa fa-minus"></i></a>
                </span>
              </span>
              <span>
                 <span class="dropdown">
                   <button class="btn btn-primary btn-sm btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                     <i class="fa fa-plus"></i> Add Role
                   </button>
                   <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                     <li role="presentation" ng-repeat="rolex in allRoles">
                         <div role="menuitem" tabindex="-1" href="#"  ng-click="toggleRole(rolex.name)" class="label role-label"
                         ng-hide="hasRole(rolex.name)" style="margin: 0.3em; background-color:{{rolex.color}};">
                             {{rolex.name}}</div></li>
                   </ul>
                 </span>
              </span>
            </div>
          </div>
          <div class="form-group">
            <label class="col-md-2 control-label" for="alsoalsoTo">Also to</label>
            <div class="col-md-10">
              <tags-input ng-model="emailInfo.alsoTo" placeholder="Enter user name or id" display-property="name" key-property="uid" on-tag-clicked="toggleSelectedPerson($tag)" class="form-control">
                  <auto-complete source="loadPersonList($query)"></auto-complete>
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
              <textarea id="intro" ng-model="emailInfo.intro" class="form-control"></textarea>
            </div>
          </div>
          <div class="form-group" ng-show="emailInfo.noteInfo.id">
            <label class="col-md-2 control-label" for="includeBody">Topic</label>
            <div class="col-md-10">
              <input id="includeBody" ng-model="emailInfo.includeBody" class="form-control"/>
            </div>
          </div>
          <div class="form-group" ng-show="emailInfo.meetingInfo.name">
            <label class="col-md-2 control-label">Meeting</label>
            <div class="col-md-10">
              Include meeting <i>'{{emailInfo.meetingInfo.name}}'</i> into email
            </div>
          </div>
          <div class="form-group">
            <label class="col-md-2 control-label">Attachments</label>
            <div class="col-md-10">
              <span ng-repeat="docid in emailInfo.docList" class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                   ng-click="navigateToDoc(docid)">
                      <img src="<%=ar.retPath%>assets/images/iconFile.png"> {{getFullDoc(docid).name}}
              </span>
              <button class="btn btn-sm btn-primary btn-raised" ng-click="openAttachDocument()"
                  title="Attach a document">
                  ADD </button>
              <input type="checkbox" ng-model="emailInfo.includeBody"/>  Include Files as Attachments
            </div>
          </div>
          <div class="form-group">
            <label class="col-md-2 control-label">Options</label>
            <div class="col-md-10">
              <div class="inline-form">
                <div class="togglebutton col-md-4">
                  <label>
                    <input type="checkbox" ng-model="emailInfo.excludeResponders">  Exclude Responders
                  </label>
                </div>
                <div class="togglebutton col-md-4">
                  <label>
                    <input type="checkbox" ng-model="emailInfo.includeSelf">  Include Yourself
                  </label>
                </div>
                <div class="togglebutton col-md-4">
                  <label>
                    <input type="checkbox" ng-model="emailInfo.makeMembers">  Make below people members
                  </label>
                </div>
              </div>
              <div class="col-md-10">
                <div class="togglebutton">
                  <label>
                    <input type="checkbox" ng-model="emailInfo.scheduleIt"> Send later?
                  </label>
                </div>
              </div>
            </div>
          </div>
          <!-- Form Control Schedule Time Begin -->
          <div class="form-group ng-hide form-hide" ng-show="emailInfo.scheduleIt">
            <label class="col-md-2 control-label" for="scheduledTime">When?</label>
            <div class="col-md-10">
              <span class="form-control">
                <a class="dropdown-toggle" id="dropdown2" role="button" data-toggle="dropdown" data-target="#" href="#">
                  {{ emailInfo.scheduleTime | date:'dd-MMM-yyyy' }} &nbsp;at&nbsp; {{ emailInfo.scheduleTime | date:'HH:mm' }} &nbsp; &nbsp; {{tzIndicator}}
                </a>
                <ul class="dropdown-menu" role="menu" aria-labelledby="dLabel">
                  <datetimepicker data-ng-model="emailInfo.scheduleTime"
                       data-datetimepicker-config="{ dropdownSelector: '#dropdown2',minuteStep: 15}"
                       data-on-set-time="onTimeSet(newDate)"></datetimepicker>
                </ul>
              </span>
            </div>
          </div>
          <!-- Form Control BUTTONS Begin -->
          <div class="form-group">
            <label class="col-md-2 control-label" for="unsubscribe">Unsubscribe</label>
            <div class="col-md-10">
              People who receive email messages because they are a member of a role,
              will have the option to remove themselves from the role.
              These links take you to a sample message for a fictional user
              email address "sample@example.com" that such a person would see
              <span ng-repeat="role in allRoles">
                  <a href="<%=ar.retPath%>t/EmailAdjustment.htm?p=<%=URLEncoder.encode(pageId,"UTF-8")%>&st=role&role={{role.name}}&email=sample@example.com&mn=<%=URLEncoder.encode(ngw.emailDependentMagicNumber("sample@example.com"),"UTF-8")%>">{{role.name}}</a>,
              </span>
            </div>
          </div>
          <!-- Form Control BUTTONS Begin -->
          <div class="form-group">
            <label class="col-md-2 control-label" for="status"></label>
            <div class="col-md-10">
              <span class="text-info">Status: {{explainState()}}</span>
            </div>
          </div>
        <!-- Form Control BUTTONS -->
        <div class="row">
          <div class="col-md-12 form-group text-right">
            <button ng-click="saveEmail()" class="btn btn-primary btn-raised">Save Changes</button>
            <button ng-click="sendEmail()" class="btn btn-primary btn-raised">Send Now</button>
          </div>
        </div>
      </fieldset>
      </form>
    </div>
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

<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.CustomRole"
%><%@page import="org.socialbiz.cog.EmailSender"
%><%@page import="org.socialbiz.cog.EmailGenerator"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%!
    String pageTitle="Send Note By Mail";
%><%
/*
Required parameters:

    1. pageId  : This is the id of a Project and used to retrieve NGPage.

Optional Parameters:

    1. eGenId       : This is the id of a Email Generator.  If omitted a NEW one is created.
    2. intro        : This is the introductory comment in email.
    3. subject      : Set subject of email.
    4. noteId       : This is Note id which can be included in the email as body contents
    5. att          : The id of an attachement to automatically include
    6. meet         : The id of a meeting to automatically include

    6. exclude      : This is used to check if responders are excluded or not.
    7. tempmem      : Used to provide temprary membership.
    9. attach{docid}: This optional parameter is used to get list of earlier selected document.
*/

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to send email");
    UserProfile uProf = ar.getUserProfile();
    AddressListEntry uAle = new AddressListEntry(uProf);
    String userFromAddress = uAle.generateCombinedAddress();

    String eGenId      = ar.defParam("id", null);
    JSONObject emailInfo = null;
    if (eGenId!=null) {
        EmailGenerator eGen = ngp.getEmailGeneratorOrFail(eGenId);
        emailInfo = eGen.getJSON(ar, ngp);
    }
    else {
        emailInfo = new JSONObject();
        emailInfo.put("id", "~new~");
        emailInfo.put("intro", ar.defParam("intro",
                "Sending this note to let you know about a recent update to this web page "
                +"has information that is relevant to you.  Follow the link to see the most recent version."));

        String mailSubject  = ar.defParam("subject", null);
        String noteId = ar.defParam("noteId", null);

        if (noteId!=null) {
            NoteRecord noteRec = ngp.getNoteOrFail(noteId);
            if(mailSubject == null){
                mailSubject = noteRec.getSubject();
            }
            if(mailSubject==null || mailSubject.trim().length()==0){
                mailSubject = "Sending Note from Project";
            }
            emailInfo.put("noteInfo", noteRec.getJSONWithHtml(ar));
        }



        JSONArray attachments = new JSONArray();
        String att  = ar.defParam("att", null);
        if (att!=null) {
            AttachmentRecord attRec = ngp.findAttachmentByID(att);
            if (attRec!=null) {
                attachments.put(attRec.getJSON4Doc(ar, ngp));
            }
        }
        emailInfo.put("attachments", attachments);

        emailInfo.put("from", userFromAddress);
        JSONArray defaultRoles = new JSONArray();
        defaultRoles.put("Members");   //By default, send email to members
        emailInfo.put("roleNames", defaultRoles);
        emailInfo.put("alsoTo", new JSONArray());
        emailInfo.put("excludeResponders", false);
        emailInfo.put("includeSelf", false);
        emailInfo.put("makeMembers", false);
        emailInfo.put("includeBody", false);
        emailInfo.put("scheduleTime", new Date().getTime());

        String meetId      = ar.defParam("meet", null);
        if (meetId!=null && meetId.length()>0) {
            MeetingRecord mr = ngp.findMeeting(meetId);
            if (mr!=null) {
                emailInfo.put("meetingInfo", mr.getFullJSON(ar, ngp));
                if(mailSubject == null){
                    mailSubject = "Meeting: "+mr.getNameAndDate();
                }
            }
        }

        if(mailSubject == null){
            mailSubject = "Message from Project "+ngp.getFullName();
        }
        emailInfo.put("subject", mailSubject);

    }

    JSONArray allRoles = new JSONArray();
    for (NGRole role : ngp.getAllRoles()) {
        allRoles.put( role.getJSON() );
    }
    JSONArray attachmentList = ngp.getJSONAttachments(ar);
    JSONArray allPeople = ngp.getAllPeopleInProject();

/* PROTOTYPE

    $scope.emailInfo = {
      "alsoTo": [],
      "attachFiles": false,
      "attachments": [],
      "excludeResponders": false,
      "from": "Keith Swenson «kswenson@us.fujitsu.com»",
      "id": "~new~",
      "includeBody": false,
      "includeSelf": false,
      "intro": "Sending this note to let you know about a recent update to this web page has information that is relevant to you.  Follow the link to see the most recent version.",
      "makeMembers": false,
      "noteInfo": {
        "comments": [
          {
            "content": "this is a comment on a note.   I cut back to Weaver and am back on Katie\u2019s training screen. I decide to look at our training materials. A tag in the corner of the front pages says that the whole package is scheduled for review in seven months. I click on Minutes in the tag and view the record of the decision a year ago to adopt the materials and set a one-year review date. No one had expressed any doubts at the time. I close the minutes and the training materials, and there is the familiar ring of Wellness Support faces again.",
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
        "subject": "public note",
        "universalid": "FLVQAPMWG@facility-1-wellness-circle@3896"
      },
      "roleNames": ["Members"],
      "subject": "public note"
    };

    */
%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.emailInfo = <%emailInfo.write(out,2,4);%>;
    $scope.allRoles = <%allRoles.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allPeople = <%allPeople.write(out,2,4);%>;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.newEmailAddress = "";
    $scope.newAttachment = "";

    $scope.addAddress = function(val) {
        if (!val) {
            return;
        }
        $scope.newEmailAddress = "";
        for (var i=0; i<$scope.emailInfo.alsoTo.length; i++) {
            if (val == $scope.emailInfo.alsoTo[i]) {
                return;
            }
        }
        $scope.emailInfo.alsoTo.push(val);
    }
    $scope.removeAddress = function(val) {
        var newVal = [];
        for( var i=0; i<$scope.emailInfo.alsoTo.length; i++) {
            var sample = $scope.emailInfo.alsoTo[i];
            if (sample!=val) {
                newVal.push(sample);
            }
        }
        $scope.emailInfo.alsoTo = newVal;
        $scope.newEmailAddress = val;
    }
    $scope.addAttachment = function(val) {
        if (!val) {
            return;
        }
        if (!val.universalid) {
            return;   //must be a real document record
        }
        $scope.newAttachment = "";
        for (var i=0; i<$scope.emailInfo.attachments.length; i++) {
            if (val == $scope.emailInfo.attachments[i]) {
                return;
            }
        }
        $scope.emailInfo.attachments.push(val);
    }
    $scope.removeAttachment = function(val) {
        var newVal = [];
        for( var i=0; i<$scope.emailInfo.attachments.length; i++) {
            var sample = $scope.emailInfo.attachments[i];
            if (sample.name!=val) {
                newVal.push(sample);
            }
        }
        $scope.emailInfo.attachments = newVal;
        $scope.newAttachment = val;
    }

    $scope.saveEmail = function() {
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
        $scope.meetingTime.setHours($scope.meetingHour);
        $scope.meetingTime.setMinutes($scope.meetingMinutes);
        $scope.meetingTime.setSeconds(0);
        $scope.emailInfo.scheduleTime = $scope.meetingTime.getTime();
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
        var pos = email.indexOf("«");
        if (pos<0) {
            pos = email.indexOf("<");
        }
        if (pos<0) {
            return email;
        }
        return email.substring(0,pos);
    }
    $scope.emailPart = function(email) {
        var pos = email.indexOf("«");
        var pos2 = email.indexOf("»");
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
    $scope.extractDateParts = function() {
        $scope.meetingTime = new Date($scope.emailInfo.scheduleTime);
        $scope.meetingHour = $scope.meetingTime.getHours();
        $scope.meetingMinutes = $scope.meetingTime.getMinutes();
    };
    $scope.extractDateParts();

});

</script>


<!--  here is where the content goes -->

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Compose Email
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="" ng-click="saveEmail()" >Save Changes</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="" ng-click="sendEmail()" >Send Email</a></li>
            </ul>
          </span>

        </div>
    </div>


        <table>
            <tr><td style="height:20px"></td></tr>

            <tr>
                <td class="gridTableColummHeader">From:</td>
                <td style="width:20px;"></td>
                <td class="form-inline form-group">
                    <select ng-model="emailInfo.from"  class="form-control" style="width: 380px">
                      <option value="<% ar.writeHtml(userFromAddress); %>"><% ar.writeHtml(userFromAddress); %></option>
                      <option value="<% ar.writeHtml(composeFromAddress(ngp)); %>"><% ar.writeHtml(composeFromAddress(ngp)); %></option>
                    </select>
                      <span class="dropdown">
                        <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                        Options <span class="caret"></span></button>
                        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                          <li role="presentation"><a role="menuitem" tabindex="-1"
                              href="#"  ng-click="emailInfo.excludeResponders=!emailInfo.excludeResponders">
                              <input type="checkbox" ng-model="emailInfo.excludeResponders" ng-click="emailInfo.excludeResponders=!emailInfo.excludeResponders">
                                  Exclude Responders</a></li>
                          <li role="presentation"><a role="menuitem" tabindex="-1"
                              href="#"  ng-click="emailInfo.includeSelf=!emailInfo.includeSelf">
                              <input type="checkbox" ng-model="emailInfo.includeSelf" ng-click="emailInfo.includeSelf=!emailInfo.includeSelf">
                                  Include Yourself</a></li>
                          <li role="presentation"><a role="menuitem" tabindex="-1"
                              href="#"  ng-click="emailInfo.makeMembers=!emailInfo.makeMembers">
                              <input type="checkbox" ng-model="emailInfo.makeMembers" ng-click="emailInfo.makeMembers=!emailInfo.makeMembers">
                                  Make below people members</a></li>
                          <li role="presentation"><a role="menuitem" tabindex="-1"
                              href="#"  ng-click="emailInfo.includeBody=!emailInfo.includeBody">
                              <input type="checkbox" ng-model="emailInfo.attachFiles" ng-click="emailInfo.includeBody=!emailInfo.includeBody">
                                  Include Files as Attachments</a></li>
                        </ul>
                      </span>
                </td>
            </tr>
            <tr><td style="height:20px"></td></tr>
            <tr>
                <td class="gridTableColummHeader">To Role:</td>
                <td style="width:20px;"></td>
                <td>
                  <span class="dropdown" ng-repeat="role in allRoles">
                    <button class="btn btn-sm dropdown-toggle" type="button" id="menu2"
                       data-toggle="dropdown" style="margin:2px;padding: 2px 5px;font-size: 11px;background-color:{{role.color}};"
                       ng-show="hasRole(role.name)">{{role.name}}</button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
                       <li role="presentation"><a role="menuitem" title="{{add}}"
                          ng-click="toggleRole(role.name)">Remove Role:<br/>{{role.name}}</a></li>
                    </ul>
                  </span>
                  <span>
                     <span class="dropdown">
                       <button class="btn btn-sm btn-primary dropdown-toggle" type="button" id="menu1" data-toggle="dropdown"
                       style="padding: 2px 5px;font-size: 11px;"> + </button>
                       <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                         <li role="presentation" ng-repeat="rolex in allRoles">
                             <button role="menuitem" tabindex="-1" href="#"  ng-click="toggleRole(rolex.name)" class="btn btn-sm"
                             ng-hide="hasRole(rolex.name)" style="margin:2px;background-color:{{rolex.color}};">
                                 {{rolex.name}}</button></li>
                       </ul>
                     </span>
                  </span>
                </td>
            </tr>
            <tr><td style="height:20px"></td></tr>
            <tr>
                <td class="gridTableColummHeader">Also To:</td>
                <td style="width:20px;"></td>
                <td>
                  <span class="dropdown" ng-repeat="add in emailInfo.alsoTo">
                    <button class="btn btn-sm dropdown-toggle" type="button" id="menu1"
                       data-toggle="dropdown" style="margin:2px;padding: 2px 5px;font-size: 11px;">
                       {{namePart(add)}}</button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                       <li role="presentation"><a role="menuitem" title="{{add}}"
                          ng-click="removeAddress(add)">Remove Address:<br/>{{add}}</a></li>
                    </ul>
                  </span>
                  <span >
                    <button class="btn btn-sm btn-primary" ng-click="showAddEmail=!showAddEmail"
                        style="margin:2px;padding: 2px 5px;font-size: 11px;">+</button>
                  </span>
                </td>
            </tr>
            <tr>
                <td></td>
                <td style="width:20px"></td>
                <td></td>
            </tr>
            <tr ng-show="showAddEmail">
                <td ></td>
                <td style="width:20px;"></td>
                <td class="form-inline form-group">
                    <button ng-click="addAddress(newEmailAddress);showAddEmail=false" class="form-control btn btn-primary">
                        Add This Email</button>
                    <input type="text" ng-model="newEmailAddress"  class="form-control"
                        placeholder="Enter Email Address" style="width:350px;"
                        typeahead="name for name in allPeople | filter:$viewValue | limitTo:8">
                </td>
            </tr>
            <tr><td style="height:30px"></td></tr>
            <tr>
                <td class="gridTableColummHeader">Subject:</td>
                <td style="width:20px;"></td>
                <td>
                    <input type="text" ng-model="emailInfo.subject"  class="form-control"/>
                </td>
            </tr>
            <tr><td style="height:10px"></td></tr>
            <tr>
                <td class="gridTableColummHeader" valign="top">Introduction:</td>
                <td style="width:20px;"></td>
                <td>
                    <textarea ng-model="emailInfo.intro"  class="form-control"></textarea>
                </td>
            </tr>
            <tr><td style="height:10px"></td></tr>
            <tr ng-show="emailInfo.noteInfo.id">
                <td class="gridTableColummHeader">Note:</td>
                <td style="width:20px;"></td>
                <td><input type="checkbox" ng-model="emailInfo.includeBody"> Include note <i>'{{emailInfo.noteInfo.subject}}'</i> into email</td>
            </tr>
            <tr ng-show="emailInfo.meetingInfo.name">
                <td class="gridTableColummHeader">Meeting:</td>
                <td style="width:20px;"></td>
                <td>Include meeting <i>'{{emailInfo.meetingInfo.name}}'</i> into email</td>
            </tr>
            <tr><td style="height:30px"></td></tr>
            <tr>
                <td class="gridTableColummHeader" valign="top">Include these Attachments:</td>
                <td style="width:20px;"></td>
                <td>
                  <div>
                      <span class="dropdown" ng-repeat="doc in emailInfo.attachments">
                        <button class="btn dropdown-toggle" type="button" id="menu1"
                          data-toggle="dropdown" style="margin:2px;padding: 2px 5px;font-size: 11px;">
                        {{shortDoc(doc.name)}}</button>
                        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                          <li role="presentation"><a role="menuitem" tabindex="-1"
                              ng-click="removeAttachment(doc.name)">Remove Document:<br/>{{doc.name}}</a></li>
                        </ul>
                      </span>
                      <span >
                        <button class="btn btn-sm btn-primary" ng-click="showAddDoc=!showAddDoc"
                            style="margin:2px;padding: 2px 5px;font-size: 11px;">+</button>
                      </span>
                  </div>
            </tr>
            <tr><td style="height:10px"></td></tr>
            <tr ng-show="showAddDoc">
                <td ></td>
                <td style="width:20px;"></td>
                <td class="form-inline form-group">
                    <button ng-click="addAttachment(newAttachment);showAddDoc=false" class="btn btn-primary">Add Document</button>
                    <input type="text" ng-model="newAttachment"  class="form-control" placeholder="Enter Document Name"
                     style="width:350px;" typeahead="att as att.name for att in attachmentList | filter:$viewValue | limitTo:8">
                </td>
            </tr>
            <tr><td style="height:30px"></td></tr>
            <tr>
                <td class="gridTableColummHeader"></td>
                <td style="width:20px;"></td>
                <td>
                    <button ng-click="saveEmail()" class="btn btn-primary">Save Changes</button>
                    <button ng-click="sendEmail()" class="btn btn-primary">Send Email Now</button>
                </td>
            </tr>
            <tr><td style="height:10px"></td></tr>
            <tr>
                <td class="gridTableColummHeader"></td>
                <td style="width:20px;"></td>
                <td class="form-inline form-group">
                    <button ng-click="scheduleEmail()" class="btn btn-primary">Schedule For Later</button>
                    on
                    <input type="text"
                        style="width:150;"
                        class="form-control"
                        datepicker-popup="dd-MMMM-yyyy"
                        ng-model="meetingTime"
                        is-open="datePickOpen"
                        min-date="minDate"
                        datepicker-options="datePickOptions"
                        date-disabled="datePickDisable(date, mode)"
                        ng-required="true"
                        ng-click="openDatePicker($event)"
                        close-text="Close"/>
                        at
                        <select style="width:50;" ng-model="meetingHour" class="form-control" >
                            <option value="0">00</option>
                            <option value="1">01</option>
                            <option value="2">02</option>
                            <option value="3">03</option>
                            <option value="4">04</option>
                            <option value="5">05</option>
                            <option value="6">06</option>
                            <option value="7">07</option>
                            <option value="8">08</option>
                            <option value="9">09</option>
                            <option>10</option>
                            <option>11</option>
                            <option>12</option>
                            <option>13</option>
                            <option>14</option>
                            <option>15</option>
                            <option>16</option>
                            <option>17</option>
                            <option>18</option>
                            <option>19</option>
                            <option>20</option>
                            <option>21</option>
                            <option>22</option>
                            <option>23</option>
                        </select> :
                        <select  style="width:50;" ng-model="meetingMinutes" class="form-control" >
                            <option value="0">00</option>
                            <option>15</option>
                            <option>30</option>
                            <option>45</option>
                        </select>
                </td>
            </tr>

            <tr><td style="height:20px"></td></tr>
            <tr>
                <td class="gridTableColummHeader" valign="top">Status:</td>
                <td style="width:20px;"></td>
                <td>{{explainState()}}</td>
            </tr>
<%
String overrideAddress = EmailSender.getProperty("overrideAddress");
if (overrideAddress!=null && overrideAddress.length()>0) {
%>
            <tr><td style="height:20px"></td></tr>
            <tr>
                <td class="gridTableColummHeader" valign="top">Override Address Active:</td>
                <td style="width:20px;"></td>
                <td>Note: this server is configured in email test mode.  Messages will be composed to
                    users and participants having different email addresses, but the messages will
                    not actually be sent there!  Instead, all email from this server will actually
                    be sent to the override address (<b><% ar.writeHtml(overrideAddress); %></b>).
                    This is configured in the WEB-INF/EmailNotification.properties file by
                    giving a value to the 'overrideAddress' property.   Leave this property
                    empty in order to take the server out of test mode, into production mode,
                    where it actually sends email to the actual addresses.</td>
            </tr>
<%
}
%>


            <tr><td style="height:30px"></td></tr>
            <tr>
                <td class="gridTableColummHeader" valign="top">Unsubscribe:</td>
                <td style="width:20px;"></td>
                <td>
                    People who receive email messages because they are a member of a role,
                    will have the option to remove themselves from the role.
                    These links take you to a sample message for a fictional user
                    email address "sample@example.com" that such a person would see
                    <span ng-repeat="role in allRoles">
                        <a href="<%=ar.retPath%>t/EmailAdjustment.htm?p=<%=URLEncoder.encode(pageId,"UTF-8")%>&st=role&role={{role.name}}&email=sample@example.com&mn=<%=URLEncoder.encode(ngp.emailDependentMagicNumber("sample@example.com"),"UTF-8")%>">{{role.name}}</a>,
                    </span>
                </td>
            </tr>
        </table>
    </div>
</div>

<%!

    private static String composeFromAddress(NGContainer ngc) throws Exception
    {
        StringBuffer sb = new StringBuffer("^");
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
        sb.append(" «");
        sb.append(EmailSender.getProperty("mail.smtp.from"));
        sb.append("»");
        return sb.toString();
    }

%>

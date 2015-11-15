<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@page import="org.socialbiz.cog.LeafletResponseRecord"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%/*
Required parameter:

    1. pageId : This is the id of a Workspace and used to retrieve NGPage.
    2. lid    : This is id of note (NoteRecord).

*/

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);

    boolean isLoggedIn = ar.isLoggedIn();

    //there might be a better way to measure this that takes into account
    //magic numbers and tokens
    boolean canUpdate = ar.isMember();

    NGBook ngb = ngp.getSite();
    UserProfile uProf = ar.getUserProfile();
    String currentUser = "NOBODY";
    String currentUserName = "NOBODY";
    if (uProf!=null) {
        //this page can be viewed when not logged in, possibly with special permissions.
        //so you can't assume that uProf is non-null
        currentUser = uProf.getUniversalId();
        currentUserName = uProf.getName();
    }

    String lid = ar.reqParam("lid");
    NoteRecord note = ngp.getNoteOrFail(lid);

    boolean canAccessNote  = AccessControl.canAccessNote(ar, ngp, note);
    if (!canAccessNote) {
        throw new Exception("Program Logic Error: this view should only display when user can actually access the note.");
    }

    JSONObject noteInfo = note.getJSONWithHtml(ar);
    JSONArray attachmentList = ngp.getJSONAttachments(ar);


%>

<!-- something in here is needed for the html bind -->
<link href="<%=ar.retPath%>jscript/textAngular.css" rel="stylesheet" />
<script src="<%=ar.retPath%>jscript/textAngular-rangy.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular-sanitize.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular.min.js"></script>

<style>
.ta-editor {
    min-height: 150px;
    max-height: 600px;
    width:600px;
    height: auto;
    overflow: auto;
    font-family: inherit;
    font-size: 100%;
    margin:20px 0;
}
</style>

<script type="text/javascript">
document.title="<% ar.writeJS(note.getSubject());%>";

var app = angular.module('myApp', ['ui.bootstrap', 'textAngular']);
app.controller('myCtrl', function($scope, $http) {
    $scope.noteInfo = <%noteInfo.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.canUpdate = <%=canUpdate%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.fixUpChoices = function() {
        $scope.noteInfo.comments.map( function(cmt) {
            if (!cmt.choices || cmt.choices.length==0) {
                cmt.choices = ["Consent", "Object"];
            }
        });
    }
    $scope.fixUpChoices();

//which editor is open
    $scope.editCmt = "NOTHING";
    $scope.editResp = "NOTHING";


    $scope.myComment = "";
    $scope.myPoll = false;

    $scope.createComment = function() {
        var saveRecord = {};
        saveRecord.id = $scope.noteInfo.id;
        saveRecord.universalid = $scope.noteInfo.universalid;
        saveRecord.newComment = {};
        saveRecord.newComment.html = $scope.myComment;
        saveRecord.newComment.poll = $scope.myPoll;
        $scope.savePartial(saveRecord);
        $scope.editCmt='NOTHING';
    }
    $scope.updateComment = function(cmt) {
        var saveRecord = {};
        saveRecord.id = $scope.noteInfo.id;
        saveRecord.universalid = $scope.noteInfo.universalid;
        saveRecord.comments = [];
        saveRecord.comments.push(cmt);
        $scope.savePartial(saveRecord);
        $scope.editCmt='NOTHING';
    }
    $scope.saveDocs = function() {
        var saveRecord = {};
        saveRecord.id = $scope.noteInfo.id;
        saveRecord.universalid = $scope.noteInfo.universalid;
        saveRecord.docList = $scope.noteInfo.docList;
        $scope.savePartial(saveRecord);
    }

    $scope.savePartial = function(recordToSave) {
        var postURL = "updateNote.json?nid="+$scope.noteInfo.id;
        var postdata = angular.toJson(recordToSave);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.noteInfo = data;
            $scope.fixUpChoices();
            $scope.myComment = "";
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.getDocs = function() {
        var res = [];
        $scope.noteInfo.docList.map( function(docId) {
            $scope.attachmentList.map( function(oneDoc) {
                if (oneDoc.universalid == docId) {
                    res.push(oneDoc);
                }
            });
        });
        return res;
    }
    $scope.filterDocs = function(filter) {
        var res = [];
        for(var i=0; i<$scope.attachmentList.length; i++) {
            var oneDoc = $scope.attachmentList[i];
            if (oneDoc.name.indexOf(filter)>=0) {
                res.push(oneDoc);
            }
            else if (oneDoc.description.indexOf(filter)>=0) {
                res.push(oneDoc);
            }
        }
        return res;
    }
    $scope.addAttachment = function(doc) {
        for (var i=0; i<$scope.noteInfo.docList.length; i++) {
            if (doc.universalid == $scope.noteInfo.docList[i]) {
                alert("Document already attached: "+doc.name);
                return;
            }
        }
        $scope.noteInfo.docList.push(doc.universalid);
        $scope.saveDocs();
        $scope.newAttachment = "";
    }
    $scope.removeAttachment = function(doc) {
        var newVal = [];
        $scope.noteInfo.docList.map( function(docId) {
            if (docId!=doc.universalid) {
                newVal.push(docId);
            }
        });
        $scope.noteInfo.docList = newVal;
        $scope.saveDocs();
    }

    $scope.getMyResponse = function(cmt) {
        var selected = [];
        cmt.responses.map( function(item) {
            if (item.user=="<%ar.writeJS(currentUser);%>") {
                selected.push(item);
            }
        });
        if (selected.length == 0) {
            var newResponse = {};
            newResponse.user = "<%ar.writeJS(currentUser);%>";
            cmt.responses.push(newResponse);
            selected.push(newResponse);
        }
        return selected;
    }

    $scope.startResponse = function(cmt, pickedChoice) {
        $scope.editResp =  cmt.time;
        $scope.editCmt  =  'NOTHING';
        var myList = $scope.getMyResponse(cmt);
        if (myList.length>0) {
            myList[0].choice = pickedChoice;
        }
    }

    $scope.startEdit = function(cmt) {
        $scope.editCmt  = cmt.time;
        $scope.editResp = 'NOTHING';
    }

    $scope.stopEdit = function() {
        $scope.editCmt  = 'NOTHING';
        $scope.editResp = 'NOTHING';
    }

    $scope.createModifiedProposal = function(cmt) {
        $scope.editCmt  = 'NEW';
        $scope.editResp = 'NOTHING';
        $scope.myComment = cmt.html;
        $scope.myPoll = true;

    }

    $scope.getComments = function() {
        var res = [];
        $scope.noteInfo.comments.map( function(item) {
            res.push(item);
        });
        res.sort( function(a,b) {
            return a.time - b.time;
        });
        return res;
    }

});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            {{noteInfo.subject}}
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="notesList.htm">List Topics</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="editNote.htm?nid={{noteInfo.id}}" target="_blank">Edit This Topic</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="pdf/note{{noteInfo.id}}.pdf?publicNotes={{noteInfo.id}}">Generate PDF</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="sendNote.htm?noteId={{noteInfo.id}}">Send Topic By Email</a></li>
            </ul>
          </span>

        </div>
    </div>

    <div class="leafContent">
      <div ng-bind-html="noteInfo.html"></div>
      <div><br/><i>Last modified by <a href="findUser.htm?uid={{noteInfo.modUser.uid}}"><span class="red">{{noteInfo.modUser.name}}</span></a> on {{noteInfo.modTime|date}}</i></div>
    </div>


    <div class="generalHeading" style="margin-top:50px;">Attachments</div>

    <div style="width:100%">
      <div>
          <div class="dropdown" ng-repeat="doc in getDocs()">
            <a href="docinfo{{doc.id}}.htm">
                <img src="<%=ar.retPath%>assets/images/iconFile.png" ng-show="'FILE'==doc.attType">
                <img src="<%=ar.retPath%>assets/images/iconUrl.png" ng-show="'URL'==doc.attType">
                {{doc.name}}</a>
          </div>
      </div>
    </div>


    <div style="height:30px;"></div>



      <table>

      <tr ng-repeat="cmt in getComments()">
           <td style="width:50px;vertical-align:top;padding:15px;">
               <img id="cmt{{cmt.time}}" class="img-circle" style="height:35px;width:35px;" src="<%=ar.retPath%>/users/{{cmt.userKey}}.jpg">
           </td>
           <td>
               <div class="leafContent" style="border: 1px solid lightgrey;border-radius:8px;padding:5px;margin-top:15px;background-color:#EEE">
                   <div style="">
                       <span ng-hide="cmt.poll"><i class="fa fa-comments-o"></i></span>
                       <span ng-show="cmt.poll"><i class="fa fa-star-o"></i></span>
                       &nbsp; {{cmt.time | date}} - <a href="<%=ar.retPath%>v/{{cmt.userKey}}/userSettings.htm"><span class="red">{{cmt.userName}}</span></a>
<% if (isLoggedIn) { %>
                       <span  ng-click="startEdit(cmt)" ng-show="editResp=='NOTHING' && editCmt=='NOTHING' && cmt.user=='<%ar.writeJS(currentUser);%>'">- <a href="">EDIT</a></span>
                       <span ng-hide="cmt.emailSent">-email pending-</span>
<% } %>
                   </div>
                   <div class=""
                        style="border: 1px solid lightgrey;border-radius:6px;padding:5px;background-color:white"
                        ng-hide="editCmt==cmt.time">
                     <div ng-bind-html="cmt.html"></div>
                   </div>

<% if (isLoggedIn) { %>
                    <div class="well leafContent" style="width:100%" ng-show="editCmt==cmt.time && editResp=='NOTHING'">
                      <div ng-model="cmt.html"
                          ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]"
                          text-angular="" class="" style="width:100%;"></div>

                      <button ng-click="updateComment(cmt);stopEdit()" class="btn btn-danger">Save Changes</button>
                      <button ng-click="stopEdit()" class="btn btn-danger">Cancel</button>
                      &nbsp;
                      <input type="checkbox" ng-model="cmt.poll"> Proposal</button>
                    </div>
<% } %>

                   <table style="min-width:500px;" ng-show="editResp!=cmt.time">
                   <tr ng-repeat="resp in cmt.responses">
                       <td style="padding:5px;max-width:100px;">
                           <b>{{resp.choice}}</b><br/>
                           {{resp.userName}}
                       </td>
                       <td style="padding:5px;">
                          <div ng-bind-html="resp.html"></div>
                       </td>
                   </tr>
                   </table>
<% if (isLoggedIn && canUpdate) { %>

                   <div ng-show="cmt.poll && editCmt=='NOTHING' && editResp=='NOTHING'">
                       Respond: <span ng-repeat="choice in cmt.choices">&nbsp;
                           <button class="btn btn-primary" ng-click="startResponse(cmt, choice)">
                               {{choice}}
                           </button>
                       </span>&nbsp;
                       <button class="btn btn-default" ng-click="createModifiedProposal(cmt)">Make Modified Proposal</button>
                   </div>
                   <div ng-show="cmt.poll && editCmt=='NOTHING' && editResp=='NOTHING'  && cmt.user=='<%ar.writeJS(currentUser);%>'">
                       <button class="btn btn-default" ng-click="cmt.poll=false;updateComment(cmt)">Close Response Period</button>
                       <button class="btn btn-default" ng-click="createModifiedProposal(cmt)">Make Modified Proposal</button>
                   </div>
                   <div ng-show="cmt.poll && editCmt=='NOTHING' && editResp==cmt.time">
                       <h2>Your Response: <%ar.writeHtml(currentUserName);%></h2>
                       <div ng-repeat="myResp in getMyResponse(cmt)">
                          <div class="form-inline form-group">
                              Choice:  <select class="form-control" ng-model="myResp.choice" ng-options="onch as onch for onch in cmt.choices"></select>
                          </div>
                          <div ng-model="myResp.html"
                              ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]"
                              text-angular="" class="" style="width:100%;"></div>
                       </div>
                      <button ng-click="updateComment(cmt);stopEdit()" class="btn btn-danger">Save Response</button>
                      <button ng-click="stopEdit()" class="btn btn-danger">Cancel</button>
                   </div>
<% } %>
               </div>
           </td>
       </tr>


    <tr><td style="height:20px;"></td></tr>

    <tr>
    <td></td>
    <td>
    <div ng-show="canUpdate && editResp=='NOTHING'">
        <div ng-show="editCmt=='NOTHING'" style="margin:20px;">
            <button ng-click="myPoll=false;editCmt='NEW'" class="btn btn-default">
                Create New <i class="fa fa-comments-o"></i> Comment</button>
            <button ng-click="myPoll=true;editCmt='NEW'" class="btn btn-default">
                Create New <i class="fa fa-star-o"></i> Proposal</button>
        </div>
        <div class="well leafContent" style="width:100%" ng-show="editCmt=='NEW'" >
          <div ng-model="myComment"
              ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]"
              text-angular="" class="" style="width:100%;"></div>

          <button ng-click="createComment()" class="btn btn-danger" ng-hide="myPoll">
              Create <i class="fa fa-comments-o"></i> Comment</button>
          <button ng-click="createComment()" class="btn btn-danger" ng-show="myPoll">
              Create <i class="fa fa-star-o"></i> Proposal</button>
          <button ng-click="myComment='';myPoll=false;editCmt='NOTHING'" class="btn btn-danger">Cancel</button>
          &nbsp;
          <input type="checkbox" ng-model="myPoll"> Proposal</button>
        </div>
    </div>
    <div ng-hide="canUpdate">
        <i>You have to be logged in and a member of this workspace in order to create a comment</i>
    </div>
    </td>
    </tr>

</table>






<%
    String choices = note.getChoices();
    String[] choiceArray = UtilityMethods.splitOnDelimiter(choices, ',');

    int allowedLevel = note.getVisibility();
    String mnnote = ar.defParam("emailId", null);

    if( !note.isDeleted()){
        if (choiceArray.length>0 && (ar.isLoggedIn() || mnnote != null))
        {
            UserProfile up = ar.getUserProfile();
            String userId = "";
            LeafletResponseRecord llr = null;
            if(up == null){
                userId = ar.reqParam("emailId");
                up = UserManager.findUserByAnyId(userId);
            }else{
                userId = up.getUniversalId();
            }
            if (up!=null) {
                llr = note.getOrCreateUserResponse(up);
            }
            else {
                //this is for the case that an invite was sent to someone who has
                //never made a profile.
                llr = note.accessResponse(userId);
            }

    String data = llr.getData();

%>















        <form method="post" action="leafletResponse.htm">
            <input type="hidden" name="lid" value="<% ar.writeHtml(lid); %>">
            <input type="hidden" name="uid" value="<% ar.writeHtml(userId); %>">
            <input type="hidden" name="mnnote" value="<% ar.writeHtml(mnnote); %>">
            <input type="hidden" name="go" value="<% ar.writeHtml(ar.getCompleteURL()); %>">

            <br><br>
            <div class="generalContent">

                <div class="generalHeading">Your Response</div>

                <table cellpadding="0" cellspacing="0" width="100%">
                    <tr><td style="height:5px" colspan="3"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2">Choice:</td>
                        <td style="width:20px;"></td>
                        <td>
                            <%
                            for (String ach : choiceArray)
                                {
                                    String isChecked = "";
                                    if (ach.equals(llr.getChoice())) {
                                        isChecked = " checked=\"checked\"";
                                    }
                                    %>
                                    <input type="radio" name="choice"<%ar.writeHtml(isChecked);%> value="<%
                                    ar.writeHtml(ach);
                                    %>"> <%
                                    ar.writeHtml(ach);
                                    %> &nbsp; <%
                                }
                            %>
                        </td>
                    </tr>
                    <tr><td style="height:8px" colspan="3"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2" valign="top">Response:</td>
                        <td style="width:20px;"></td>
                        <td>
                              <textarea name="data" class="textAreaGeneral" rows="4"><% ar.writeHtml(data); %></textarea>
                          </td>
                    </tr>
                    <tr><td style="height:8px" colspan="3"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td>
                          <input class="btn btn-primary" type="submit" name="action" value="Update">
                        </td>
                    </tr>
                    <tr>
                        <td class="gridTableColummHeader_2"></td>
                        <td style="width:20px;"></td>
                        <td>
                          <i>You can change your response at any time by visiting this page again.</i>
                        </td>
                    </tr>
                </table>
            </form>

            <%
            }
        }
            %>

            <br><br>

            <div class="generalHeading">Responses</div>
            <table cellpadding="0" cellspacing="0" width="100%">
                <tr><td style="height:5px" colspan="3"></td></tr>
            <%
            Vector<LeafletResponseRecord> recs = note.getResponses();
            Hashtable choiceTotals= new Hashtable();
            int count =0;

            for (LeafletResponseRecord llr : recs)
            {
                AddressListEntry ale = new AddressListEntry(llr.getUser());
                String choice = llr.getChoice();
                Integer tot = (Integer) choiceTotals.get(choice);
                if (tot==null)
                {
                    tot = new Integer(1);
                }
                else
                {
                    tot = new Integer( tot.intValue()+1 );
                }
                choiceTotals.put(choice, tot);
                if(count==0){
                %><tr><td  width="180px" valign="top">
                <%
                }else{
                %>

                 <tr><td valign="top">
                <%}
                ale.writeLink(ar);
                %></td><td><b><%
                ar.writeHtml(choice);
                %></b> - <%
                SectionUtil.nicePrintTime(out, llr.getLastEdited(), ar.nowTime);
                %><br/><%
                WikiConverter.writeWikiAsHtml(ar,llr.getData());
                %></td></tr>
                <%
            }

            %>
            </table>
            <br><br>

            <div class="generalHeading">Totals</div>
            <table cellpadding="0" cellspacing="0" width="100%">
                <tr><td style="height:5px" colspan="3"></td></tr>
                <%
                for (String ach : choiceArray)
                {
                    int val = 0;
                    Integer tot = (Integer) choiceTotals.get(ach);
                    if (tot!=null)
                    {
                        val=tot.intValue();
                    }
                    %>
                    <tr><td width="180px"><b><%
                    ar.writeHtml(ach);
                    %>:</b></td>
                    <td> <%ar.writeHtml(String.valueOf(val));%></td>
                    </tr>
                <%
                }
                %>
            </table>
            <br><br>

            <div class="generalHeading">History</div>
            <table >
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td>
                    <%
                        List<HistoryRecord> histRecs = ngp.getAllHistory();
                        for (HistoryRecord hist : histRecs)
                        {
                            if (hist.getContextType()==HistoryRecord.CONTEXT_TYPE_LEAFLET
                                && lid.equals(hist.getContext()))
                            {
                                AddressListEntry ale = new AddressListEntry(hist.getResponsible());
                                UserProfile responsible = ale.getUserProfile();
                                String photoSrc = ar.retPath+"assets/photoThumbnail.gif";
                                if(responsible!=null && responsible.getImage().length() > 0){
                                    photoSrc = ar.retPath+"users/"+responsible.getImage();
                                }
                                %>
                                <tr>
                                     <td class="projectStreamIcons"><a href="#"><img class="img-circle" src="<%=photoSrc%>" alt="" width="50" height="50" /></a></td>
                                     <td colspan="2"  class="projectStreamText" style="max-width:800px;">
                                         <%

                                         NGWebUtils.writeLocalizedHistoryMessage(hist, ngp, ar);
                                         ar.write("<br/>");
                                         SectionUtil.nicePrintTime(out, hist.getTimeStamp(), ar.nowTime);
                                         %>
                                     </td>
                                </tr>
                                <tr><td style="height:10px"></td></tr>
                                <%
                            }
                        }
                    %>
                    </td>
                </tr>
            </table>
        </div>
    <%


    out.flush();
%>

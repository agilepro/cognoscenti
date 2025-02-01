<!-- begin CommentView.jsp -->

<script>
function setUpCommentMethods($scope, $http, $modal) {
    $scope.openCommentCreator = function(notUsed, type, oldComment, defaultBody) {
        $scope.extendBackgroundTime();
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Comments can not be modified in a frozen workspace.");
            return;
        }
        if (!<%=ar.canUpdateWorkspace()%>) {
            alert("You must be a member of workspace to make a comment.");
            return;
        }
        var newComment = {};
        newComment.commentType = type;
        newComment.responses = [];
        $scope.tuneNewComment(newComment);
        newComment.time = -1;
        newComment.dueDate = (new Date()).getTime() + (7*24*60*60*1000);
        newComment.state = 11;
        newComment.isNew = true;
        newComment.user = "<%ar.writeJS(currentUser);%>";
        newComment.userName = "<%ar.writeJS(currentUserName);%>";
        newComment.userKey = "<%ar.writeJS(currentUserKey);%>";
        if (type==2 || type==3) {
            $scope.defaultProposalAssignees().forEach( function(item) {
                newComment.responses.push({
                    "choice": "None",
                    "body": "",
                    "user": item.uid,
                    "key": item.key,
                    "userName": item.name,
                });
            });
        }
        
        if (oldComment) {
            newComment.replyTo = oldComment.time;
            newComment.containerID = oldComment.containerID;
            newComment.containerType = oldComment.containerType;
            oldComment.responses.forEach( function( aResponse ) {
                var found = false;
                newComment.responses.forEach( function( newReponse ) {
                    if (newReponse.user == aResponse.user) {
                        found = true;
                    }
                });
                if (!found) {
                    newComment.responses.push( {user: aResponse.user, userName: aResponse.userName, choice: "None"} );
                }
            });
        }
        if (defaultBody) {
            newComment.body = defaultBody;
        }
        $scope.openCommentEditor(null, newComment);
    }
    
    $scope.openCommentEditor = function (itemNotUsed, cmt) {
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Comments can not be modified in a frozen workspace.");
            return;
        }
        $scope.cancelBackgroundTime();
        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/CommentModal.html<%=templateCacheDefeater%>',
            controller: 'CommentModalCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                cmt: function () {
                    return cmt;
                },
                attachmentList: function() {
                    return $scope.attachmentList;
                },
                docSpaceURL: function() {
                    return $scope.docSpaceURL;
                },
                parentScope: function() { return $scope; },
                siteId: function() {return $scope.siteInfo.key}
            }
        });

        modalInstance.result.then(function (returnedCmt) {
            $scope.refreshCommentList();
            $scope.extendBackgroundTime();
        }, function () {
            //cancel action - nothing really to do
            $scope.refreshCommentList();
            $scope.extendBackgroundTime();
        });
    };
    
    $scope.openResponseEditor = function (cmt, user) {
        $scope.cancelBackgroundTime();
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\nComments can not be modified in a frozen workspace.");
            return;
        }
        
        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/ResponseModal.html<%=templateCacheDefeater%>',
            controller: 'ModalResponseCtrl',
            size: 'lg',
            backdrop: "static",
            resolve: {
                responseUser: function () {
                    return user;
                },
                cmtId: function () {
                    return cmt.time;
                }
            }
        });

        modalInstance.result.then(function (response) {
            $scope.refreshCommentList();
        }, function () {
            //cancel action - nothing really to do
            $scope.refreshCommentList();
        });
    };

    $scope.downloadDocument = function(doc) {
        if (doc.attType=='URL') {
             window.open(doc.url,"_blank");
        }
        else {
            window.open("a/"+doc.name,"_blank");
        }
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
        if (cmt.commentType==6) {
            return "comment-phase-change";
        }
        if (cmt.state==11) {
            return "comment-state-draft";
        }
        if (cmt.state==12) {
            return "comment-state-active";
        }
        return "comment-state-complete";
    }
    $scope.cmtStateName = function(cmt) {
        if (cmt.state==11) {
            return "Draft";
        }
        if (cmt.state==12) {
            return "Active";
        }
        return "Completed";
    }
    $scope.createModifiedProposal = function(item, cmt) {
        //close the comment 
        cmt.state = 13;
        cmt.outcome = "Proposal modified\n\n" + cmt.outcome;
        $scope.updateComment(cmt);
        
        $scope.openCommentCreator(item,2,cmt,cmt.body);  //proposal
    }
    $scope.replyToComment = function(cmt) {
        $scope.openCommentCreator(null,1,cmt);  //simple comment
    }
    
    $scope.deleteComment = function(cmt) {
        if (!confirm("Are you sure you want to delete this?   (No UNDO)")) {
            return;
        }
        var newCmt = {};
        newCmt.time = cmt.time;
        newCmt.deleteMe = true;
        $scope.updateComment(newCmt);
    }
    $scope.removeResponse =  function(cmt,resp) {
        $scope.extendBackgroundTime();
        if (!confirm("Are you sure you want to remove the response from "+resp.userName)) {
            return;
        }
        cmt.responses.forEach( function(item) {
            if (item.user == resp.user) {
                item.removeMe = true;
            }
        });
        $scope.updateComment(cmt);
    }
    $scope.updateComment = function(cmt) {
        var postdata = angular.toJson(cmt);
        var postURL = "updateComment.json?cid="+cmt.time;
        console.log(postURL,cmt);
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.refreshCommentList();
        })
        .error( function(data) {
            $scope.reportError(data);
        });
    }
    $scope.postComment = function(itemNotUsed, cmt) {
        cmt.state = 12;
        if (cmt.commentType == 1 || cmt.commentType == 5) {
            //simple comments go all the way to closed
            cmt.state = 13;
        }
        $scope.updateComment(cmt);
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
    $scope.getFullDoc = function(docId) {
        var doc = {};
        $scope.attachmentList.forEach( function(item) {
            if (item.universalid == docId) {
                doc = item;
            }
        });
        return doc;
    }
    $scope.navigateCmtToDoc = function(docId) {
        var doc = $scope.getFullDoc(docId);
        if (!doc.id) {
            console.log("navigateToDoc: "+docId, doc);
            alert("Can not find doc to navigate to");
            return;
        }
        if (doc.attType=='URL') {
            window.open(doc.url, "_blank");
        }
        else {
            window.location="DocDetail.htm?aid="+doc.id;
        }
    }

    $scope.containerLink = function(cmt) {
        if (cmt.containerType=="M") {
            var colonPos = cmt.containerID.indexOf(":");
            var meetingId = cmt.containerID.substring(0,colonPos);
            var agendaItem = cmt.containerID.substring(colonPos+1);
            return "MeetingHtml.htm?id="+meetingId+"&mode=Items&ai="+agendaItem;
        }
        else if (cmt.containerType=="T") {
            return "noteZoom"+cmt.containerID+".htm"
        }
        else if (cmt.containerType=="A") {
            return "DocDetail.htm?aid="+cmt.containerID;
        }
        else if (cmt.commentType==4) {
            //this is a meeting fake comment record
        }
        else {
            console.log("Sorry, I can't understand this comment", cmt);
        }
    }
    
    $scope.generateCommentHtml = function(cmt) {
        cmt.html2 = convertMarkdownToHtml(cmt.body);
        cmt.outcomeHtml = convertMarkdownToHtml(cmt.outcome);
        if (cmt.responses) {
            cmt.responses.forEach( function(item) {
                item.html = convertMarkdownToHtml(item.body);
            });
        }
    }
    
    $scope.getOutcomeHtml = function(cmt) {
        if (cmt.outcomeHtml) {
            return cmt.outcomeHtml;
        }
        if (cmt.state<13) {
            return "<span style=\"color:lightgrey\">The outcome will appear here when closed.  Double-click here to close the "+$scope.commentTypeName(cmt)+".<span>";
        }
        else {
            return "<span style=\"color:lightgrey\">No outcome recorded for this "+$scope.commentTypeName(cmt)+".<span>";
        }
    }
    $scope.getResponseHtml = function(resp) {
        if (resp.html) {
            return resp.html;
        }
        return "<span style=\"color:lightgrey\">No response provided</span>";
    }
    $scope.navigateToCommentor = function(cmt) {
        window.open("<%= ar.retPath%>v/"+encodeURIComponent(cmt.userKey)+"/PersonShow.htm","_blank");
    }
    
    $scope.createDecision = function(newDecision) {
        /*
        if (!$scope.canUpdate) {
            alert("Unable to update discussion because you are an observer");
            return;
        }
        */
        $scope.cancelBackgroundTime();
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Comments can not be modified in a frozen workspace.");
            return;
        }
        newDecision.num="~new~";
        newDecision.universalid="~new~";
        console.log("NEW DECISION", newDecision);
        var postURL = "updateDecision.json?did=~new~";
        var postData = angular.toJson(newDecision);
        $http.post(postURL, postData)
        .success( function(data) {
            $scope.extendBackgroundTime();
            console.log("SUCCESS DECISION:", data);
            $scope.refreshCommentList();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
            $scope.refreshCommentList();
        });
    };

    // close the proposal and create a decision
    $scope.openDecisionEditor = function (cmt) {
        //close the comment 
        cmt.state = 13;
        cmt.outcome = "Decision created\n\n" + cmt.outcome;
        $scope.updateComment(cmt);
        
        $scope.cancelBackgroundTime();
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Comments can not be modified in a frozen workspace.");
            return;
        }
        /*
        if (!$scope.canComment) {
            alert("You must be logged in to ceate a response");
            return;
        }
        */

        var newDecision = {
            num: "~new~",
            labelMap: {},
            sourceCmt: cmt.time
        };
        var newBody = cmt.body+"\n\n";
        cmt.responses.forEach( function (resp) {
            if (resp.choice=="Consent" || resp.choice=="Objection") {
                newBody = newBody + resp.alt.name + ": " + resp.choice + ": " + resp.body + "\n\n";
            }
        });
        newDecision.decision = newBody + cmt.outcome;
        $scope.tuneNewDecision(newDecision, cmt);

        var decisionModalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>new_assets/templates/DecisionModal.html<%=templateCacheDefeater%>',
            controller: 'DecisionModalCtrl',
            size: 'lg',
            resolve: {
                decision: function () {
                    return JSON.parse(JSON.stringify(newDecision));
                },
                allLabels: function() {
                    return $scope.allLabels;
                },
                siteInfo: function() {
                    return $scope.siteInfo;
                }
            }
        });

        decisionModalInstance.result.then(function (modifiedDecision) {
            $scope.createDecision(modifiedDecision);
        }, function () {
            $scope.refreshCommentList();
        });
    };
    
    
}
</script>


<div class="container-fluid override m-2">
    <div class="row p-0 mb-2">
        <span ng-show="cmt.commentType==1" title="{{cmtStateName(cmt)}} Comment">
            <span class="h5">Comment</span>
        </span>
        <span ng-show="cmt.commentType==2" title="{{cmtStateName(cmt)}} Proposal">
            <span class="h5">Proposal</span>
        </span>
        <span ng-show="cmt.commentType==3" title="{{cmtStateName(cmt)}} Round">
            <span class="h5">Round</span>
        </span>
        <span ng-show="cmt.commentType>=4" title="{{cmtStateName(cmt)}} Meeting">
            <span class="h5">UNKNOWN COMMENT TYPE {{cmt.commentType}}</span>
        </span>
        <!--user profile dropdown-->
        <div class="col-1 m-0">
            <ul class="navbar-btn p-0 mt-2" ng-show="cmt.commentType!=4">
                <li class="nav-item dropdown" id="userCommentor" data-toggle="dropdown">
                    <img class="rounded-5" ng-src="<%=ar.retPath%>icon/{{cmt.userKey}}.jpg" style="width:50px;height:50px" title="{{cmt.userName}} - {{cmt.user}}">
                    
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                    <li role="presentation" style="background-color:lightgrey">
                        <a class="dropdown-item" role="menuitem" tabindex="-1" style="text-decoration: none;text-align:center">{{cmt.userName}}<br/>{{cmt.user}}</a></li>
                    <li role="presentation" style="cursor:pointer">
                        <a class="dropdown-item" role="menuitem" tabindex="-1" ng-click="navigateToCommentor(cmt)">
                    <span class="fa fa-user"></span> Visit Profile </a></li>
                </ul>
                </li>
            </ul>
        </div>
        <!--info bar-->
        <div class="col-11 mt-1">
            
            <div class="comment-outer {{stateClass(cmt)}}">
                
                <ul type="button" class="btn-tiny btn  m-2 pt-1">
                    <li class="dropdown nav-item" id="commentList" data-toggle="dropdown">
                        <span ng-show="cmt.commentType==1" title="{{cmtStateName(cmt)}} Comment">
                            <i class="fa fa-comments-o" style="font-size:130%"></i>
                        </span>
                        <span ng-show="cmt.commentType==2" title="{{cmtStateName(cmt)}} Proposal">
                            <i class="fa fa-star-o" style="font-size:130%"></i>
                        </span>
                        <span ng-show="cmt.commentType==3" title="{{cmtStateName(cmt)}} Round">
                            <i class="fa fa-question-circle" style="font-size:130%"></i>
                        </span>
                        <span ng-show="cmt.commentType>=4" title="{{cmtStateName(cmt)}} Minutes">
                            <i class="fa fa-warning" style="font-size:130%"></i>
                        </span> 
                    <ul class="dropdown-menu" role="menu" aria-labelledby="commentList">
                    <li>
                        <a class="dropdown-item" role="menuitem" ng-click="openCommentEditor(null,cmt)">Edit {{commentTypeName(cmt)}}</a></li>
                    <li >
                        <a class="dropdown-item" role="menuitem" ng-show="cmt.commentType==2 || cmt.commentType==3" ng-click="openResponseEditor(cmt, '<%ar.writeJS(currentUser);%>')">Create/Edit Response</a></li>
                    <li >
                        <a class="dropdown-item" role="menuitem" ng-show="cmt.state==11 && cmt.user=='<%ar.writeJS(currentUser);%>'" ng-click="postComment(item, cmt)">Post Your {{commentTypeName(cmt)}}</a></li>
                    <li >
                        <a class="dropdown-item" role="menuitem" ng-show="cmt.user=='<%ar.writeJS(currentUser);%>'" ng-click="deleteComment(cmt)">Delete {{commentTypeName(cmt)}}</a></li>
                    <li >
                        <a class="dropdown-item" role="menuitem" ng-show="cmt.commentType==1" ng-click="openCommentCreator(item,1,cmt)">Reply</a></li>
                    <li>
                        <a class="dropdown-item" role="menuitem" ng-show="cmt.commentType==2" ng-click="createModifiedProposal(item,cmt)">Make Modified Proposal</a></li>
                    <li>
                        <a class="dropdown-item" role="menuitem" ng-show="cmt.commentType==2" ng-click="openDecisionEditor(cmt)">Create New Decision</a></li>
                </ul>
                    </li>
                </ul>&nbsp; 
                <span title="Created {{cmt.dueDate|cdate}}" ng-click="openCommentEditor(null,cmt)">{{cmt.time|cdate}}
                </span> -
                <a href="<%=ar.retPath%>v/{{cmt.userKey}}/UserSettings.htm">
                    <span class="red">{{cmt.userName}}</span>
                </a>
                <span ng-show="cmt.emailPending && !cmt.suppressEmail" ng-click="openCommentEditor(null,cmt)">-email pending-</span>
                <span ng-show="cmt.replyTo">
                <span ng-show="cmt.commentType==1">In reply to                 
                    <a style="border-color:white;" href="CommentZoom.htm?cid={{cmt.replyTo}}">
                        <i class="fa fa-comments-o"></i> {{findComment(item,cmt.replyTo).userName}}</a>
                </span>
                <span ng-show="cmt.commentType>1">Based on
                    <a style="border-color:white;" href="CommentZoom.htm?cid={{cmt.replyTo}}">
                        <i class="fa fa-star-o"></i> {{findComment(item,cmt.replyTo).userName}}</a>
                </span>
                </span>
                <span ng-show="cmt.includeInMinutes" style="color:gray" ng-click="openCommentEditor(null,cmt)"> [+minutes] </span>

                <span ng-show="cmt.commentType==6" style="color:green">
                    <i class="fa fa-arrow-right"></i> <b>{{showDiscussionPhase(cmt.newPhase)}}</b> Phase</span>
                
                <span class="me-2" style="float:right;">&nbsp;<a href="CommentZoom.htm?cid={{cmt.time}}"><i class="fa fa-external-link"></i></a></span>
                <span class="me-2" style="float:right;" ng-show="containerLink(cmt)">&nbsp;<a href="{{containerLink(cmt)}}"><i class="fa fa-bullseye"></i></a></span>
                <span class="me-2" style="float:right;color:green;" title="Due {{cmt.dueDate|cdate}}">{{calcDueDisplay(cmt)}}
                </span>
            </div>
        </div>
    </div>
    <div ng-show="cmt.state==11">
        Draft {{commentTypeName(cmt)}} needs posting to be seen by others
    </div>
    <div class="leafContent comment-inner px-2" ng-hide="cmt.meet || cmt.commentType==6" ng-dblclick="openCommentEditor(null,cmt)">
        <div ng-bind-html="cmt.html2"></div>
    </div>
    <div ng-show="cmt.meet" class="btn btn-comment btn-raised btn-wide"  style="margin:4px;" ng-click="navigateToMeeting(cmt.meet)">
        <i class="fa fa-gavel" style="font-size:130%"></i> {{cmt.meet.name}}, {{cmt.meet.startTime |cdate}}
    </div>
    <div ng-repeat="doc in cmt.docDetails">
        <span ng-show="doc.attType=='FILE'">
            <span class="rounded-5" ng-click="navigateToDoc(doc)"><img src="<%=ar.retPath%>new_assets/assets/images/iconFile.png">
            </span>&nbsp;
            <span ng-click="downloadDocument(doc)">
                <span class="fa fa-download"></span>
            </span>
        </span>
        <span ng-show="doc.attType=='URL'">
            <span ng-click="navigateToDoc(doc)">
                <img src="<%=ar.retPath%>new_assets/assets/images/iconUrl.png">
            </span> &nbsp;
            <span ng-click="navigateToLink(doc)">
                <span class="fa fa-external-link"></span>
            </span>
        </span>&nbsp; {{doc.name}}
    </div>

      <table style="min-width:500px;overflow:hidden;table-layout:fixed" ng-show="cmt.commentType==2 || cmt.commentType==3">
        <col style="width:120px;white-space:nowrap">
        <col style="width:10px">
        <col width="width:1*">
        <tr ng-repeat="resp in cmt.responses">
          <td style="padding:5px;max-width:100px;overflow:hidden;white-space:nowrap">
            <!--proposal response-->
            <div ng-show="cmt.commentType==2">
              <b>{{resp.choice}}</b></div>
            <div>{{resp.userName?resp.userName:resp.user}}</div>
          </td>
          <td>
            <span ng-show="cmt.state==12" ng-click="openResponseEditor(cmt, resp.user)" 
                  style="cursor:pointer;">
              <a title="Edit this response">
                <i class="fa fa-edit"></i></a>
            </span>
          </td>
          <td style="padding:5px;" ng-click="openResponseEditor(cmt, resp.user)">
            <div class="leafContent comment-inner px-2" ng-bind-html="getResponseHtml(resp)"></div>
          </td>
          <td ng-click="removeResponse(cmt,resp)" ng-show="cmt.state==12" >
            <span class="fa fa-trash" style="color:rgb(172, 8, 8)"></span>
          </td>
        </tr>
        <tr ng-show="noResponseYet(cmt, '<% ar.writeHtml(currentUserName); %>' )">
          <td style="padding:5px;max-width:100px;">
            <b>????</b>
            <br/>
            <% ar.writeHtml(currentUserName); %>
          </td>
          <td>
            <span ng-click="openResponseEditor(cmt,'<%ar.writeJS(currentUser);%>')" style="cursor:pointer;">
              <a href="#" title="Create a response to this {{commentTypeName(cmt)}}"><i class="fa fa-edit"></i></a>
            </span>
          </td>
          <td style="padding:5px;">
            <div class="leafContent comment-inner px-2">
              <span ng-click="openResponseEditor(cmt,'<%ar.writeJS(currentUser);%>')" style="cursor:pointer;color:grey">No response provided</span></div>
          </td>
        </tr>
      </table>
      <div class="leafContent comment-inner px-2" 
           ng-show="(cmt.commentType==2 || cmt.commentType==3)" 
           ng-click="openCommentEditor(null, cmt)"
           title="closing outcome of the round/proposal">
        <div ng-bind-html="getOutcomeHtml(cmt)"></div>
      </div>
      <!--Round only buttons-->
      <div class="d-flex mt-2" ng-show="cmt.commentType==3">
        <button class="btn btn-danger btn-default btn-raised me-2" ng-click="deleteComment(cmt)" 
                ng-show="cmt.state<=12">Delete</button>
        <button class="btn btn-default btn-secondary btn-raised me-2" ng-click="openCommentEditor(null,cmt)" ng-show="cmt.state<=12">Edit</button>
        <button class="btn btn-default btn-primary btn-raised ms-auto" ng-click="openCommentEditor(null,cmt)"
                 ng-show="cmt.state==12">Close Round</button>
      </div>
      <!--Proposal only buttons-->
      <div class="d-flex mt-2" ng-show="cmt.commentType==2">
        <button class="btn btn-default btn-danger btn-raised me-2" ng-click="deleteComment(cmt)" 
                ng-show="cmt.state<=12">Delete</button>
        <button class="btn btn-default btn-secondary btn-raised me-2" ng-click="openCommentEditor(null,cmt)" ng-show="cmt.state<=12">Edit</button>
        <button class="btn btn-primary btn-raised ms-auto px-2" ng-click="createModifiedProposal(item,cmt)"
                 ng-show="cmt.state==12">Make Modified Proposal</button>
        <button class="btn btn-primary btn-raised ms-2 px-2" ng-click="openDecisionEditor(cmt)"
                 ng-show="cmt.state==12">Close with Decision</button>
      </div>
      <div ng-show="cmt.replies.length>0 && cmt.commentType>1">
        See proposals:
        <span ng-repeat="reply in cmt.replies"><a href="CommentZoom.htm?cid={{reply}}" >
          <i class="fa fa-star-o"></i> {{findComment(item,reply).userName}}</a> </span>
      </div>
      <div ng-show="cmt.replies.length>0 && cmt.commentType==1">
        See replies:
        <span ng-repeat="reply in cmt.replies">
          <a href="CommentZoom.htm?cid={{reply}}" >
            <i class="fa fa-comments-o"></i> {{findComment(item,reply).userName}}
          </a>
        </span>
      </div>
      <div ng-show="cmt.decision">
        See Linked Decision: 
        <a href="DecisionList.htm#DEC{{cmt.decision}}"> 
          #{{cmt.decision}}</a>
      </div>
    </div>
  
   
   

<script src="<%=ar.retPath%>new_assets/templates/CommentModal.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/ResponseModal.js"></script>  
<script src="<%=ar.retPath%>new_assets/templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>new_assets/templates/DecisionModal.js"></script>
<!-- end CommentView.jsp -->
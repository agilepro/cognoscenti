<!-- begin CommentView.jsp -->

<script>
function setUpCommentMethods($scope, $http, $modal) {
    $scope.openCommentCreator = function(itemNotUsed, type, replyComment, defaultBody) {
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
        newComment.time = -1;
        newComment.dueDate = (new Date()).getTime() + (7*24*60*60*1000);
        newComment.commentType = type;
        newComment.state = 11;
        newComment.isNew = true;
        newComment.user = "<%ar.writeJS(currentUser);%>";
        newComment.userName = "<%ar.writeJS(currentUserName);%>";
        newComment.userKey = "<%ar.writeJS(currentUserKey);%>";
        newComment.responses = [];
        $scope.setContainerFields(newComment);
        if (type==2 || type==3) {
            $scope.defaultProposalAssignees().forEach( function(item) {
                newComment.responses.push({
                    "choice": "None",
                    "html": "",
                    "user": item.uid,
                    "key": item.key,
                    "userName": item.name,
                });
            });
        }
        
        if (replyComment) {
            console.log("This is a REPLY");
            newComment.replyTo = replyComment.time;
            newComment.containerID = replyComment.containerID;
            newComment.containerType = replyComment.containerType;
        }
        if (defaultBody) {
            newComment.html = defaultBody;
        }
        $scope.openCommentEditor({}, newComment);
    }
    
    $scope.openCommentEditor = function (itemNotUsed, cmt) {
        if ($scope.workspaceInfo.frozen) {
            alert("Sorry, this workspace is frozen by the administrator\Comments can not be modified in a frozen workspace.");
            return;
        }
        $scope.cancelBackgroundTime();
        var modalInstance = $modal.open({
            animation: true,
            templateUrl: '<%=ar.retPath%>templates/CommentModal.html<%=templateCacheDefeater%>',
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
            animation: false,
            templateUrl: '<%=ar.retPath%>templates/ResponseModal.html<%=templateCacheDefeater%>',
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
    $scope.createModifiedProposal = function(cmt) {
        $scope.openCommentCreator({},2,cmt.time,cmt.html);  //proposal
    }
    $scope.replyToComment = function(cmt) {
        $scope.openCommentCreator({},1,cmt.time);  //simple comment
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
        $scope.attachmentList.filter( function(item) {
            if (item.universalid == docId) {
                doc = item;
            }
        });
        return doc;
    }

    $scope.containerLink = function(cmt) {
        if (cmt.containerType=="M") {
            var colonPos = cmt.containerID.indexOf(":");
            var meetingId = cmt.containerID.substring(0,colonPos);
            var agendaItem = cmt.containerID.substring(colonPos+1);
            return "meetingHtml.htm?id="+meetingId+"&mode=Items&ai="+agendaItem;
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
        window.open("<%= ar.retPath%>v/FindPerson.htm?uid="+encodeURIComponent(cmt.userKey),"_blank");
    }
    
}
</script>



  <td style="width:50px;vertical-align:top;padding:15px">
      <span class="dropdown" ng-show="cmt.commentType!=4">
        <span id="menu1" data-toggle="dropdown">
          <img class="img-circle" 
             ng-src="<%=ar.retPath%>icon/{{cmt.userKey}}.jpg" 
             style="width:50px;height:50px" 
             title="{{cmt.userName}} - {{cmt.user}}">
        </span>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation" style="background-color:lightgrey"><a role="menuitem" 
              tabindex="-1" style="text-decoration: none;text-align:center">
              {{cmt.userName}}<br/>{{cmt.user}}</a></li>
          <li role="presentation" style="cursor:pointer"><a role="menuitem" tabindex="-1"
              ng-click="navigateToCommentor(cmt)">
              <span class="fa fa-user"></span> Visit Profile</a></li>
        </ul>
      </span>
  </td>
  <td>
    <div class="comment-outer  {{stateClass(cmt)}}">
      <div>
        <div class="dropdown" style="float:left" ng-show="cmt.commentType!=6">
          <button class="dropdown-toggle specCaretBtn" type="button"  id="menu"
                  data-toggle="dropdown"> 
            <span class="caret"></span>
          </button>
          <ul class="dropdown-menu" role="menu" aria-labelledby="menu">
            <li role="presentation">
              <a role="menuitem" ng-click="openCommentEditor(item,cmt)">Edit {{commentTypeName(cmt)}}</a></li>
            <li role="presentation" ng-show="cmt.commentType==2 || cmt.commentType==3">
              <a role="menuitem" ng-click="openResponseEditor(cmt, '<%ar.writeJS(currentUser);%>')">
                Create/Edit Response:</a></li>
            <li role="presentation" ng-show="cmt.state==11 && cmt.user=='<%ar.writeJS(currentUser);%>'">
              <a role="menuitem" ng-click="postComment(item, cmt)">Post Your {{commentTypeName(cmt)}}</a></li>
            <li role="presentation" ng-show="cmt.user=='<%ar.writeJS(currentUser);%>'">
              <a role="menuitem" ng-click="deleteComment(cmt)">
              Delete {{commentTypeName(cmt)}}</a></li>
            <li role="presentation" ng-show="cmt.commentType==1">
              <a role="menuitem" ng-click="openCommentCreator(item,1,cmt)">
              Reply</a></li>
            <li role="presentation" ng-show="cmt.commentType==2 || cmt.commentType==3">
              <a role="menuitem" ng-click="openCommentCreator(item,2,cmt,cmt.html)">
              Make Modified Proposal</a></li>
            <li role="presentation">
              <a role="menuitem" ng-click="openDecisionEditor(item, cmt)">
              Create New Decision</a></li>
            </ul>
          </div>

        <span ng-show="cmt.commentType==1" title="{{cmtStateName(cmt)}} Comment">
          <i class="fa fa-comments-o" style="font-size:130%"></i></span>
        <span ng-show="cmt.commentType==2" title="{{cmtStateName(cmt)}} Proposal">
          <i class="fa fa-star-o" style="font-size:130%"></i></span>
        <span ng-show="cmt.commentType==3" title="{{cmtStateName(cmt)}} Round">
          <i class="fa fa-question-circle" style="font-size:130%"></i></span>
        <span ng-show="cmt.commentType==5" title="{{cmtStateName(cmt)}} Minutes">
          <i class="fa fa-file-code-o" style="font-size:130%"></i></span>
               &nbsp; 
        <span title="Created {{cmt.dueDate|cdate}}"
              ng-click="openCommentEditor(item,cmt)">{{cmt.time|cdate}}</span> -
        <a href="<%=ar.retPath%>v/{{cmt.userKey}}/UserSettings.htm">
          <span class="red">{{cmt.userName}}</span>
        </a>
        <span ng-show="cmt.emailPending && !cmt.suppressEmail" 
              ng-click="openCommentEditor(item,cmt)">-email pending-</span>
        <span ng-show="cmt.replyTo">
          <span ng-show="cmt.commentType==1">
            In reply to                 
            <a style="border-color:white;" href="CommentZoom.htm?cid={{cmt.replyTo}}">
              <i class="fa fa-comments-o"></i> {{findComment(item,cmt.replyTo).userName}}</a>
          </span>
          <span ng-show="cmt.commentType>1">Based on
            <a style="border-color:white;" href="#cmt{{cmt.replyTo}}">
            <i class="fa fa-star-o"></i> {{findComment(item,cmt.replyTo).userName}}</a>
          </span>
        </span>
        <span ng-show="cmt.includeInMinutes" style="color:gray"
              ng-click="openCommentEditor(item,cmt)"> [+minutes] </span>
        <span ng-show="cmt.commentType==6" style="color:green">
            <i class="fa fa-arrow-right"></i> <b>{{showDiscussionPhase(cmt.newPhase)}}</b> Phase</span>
        <span style="float:right" >&nbsp;<a href="CommentZoom.htm?cid={{cmt.time}}"><i class="fa fa-external-link"></i></a></span>
        <span style="float:right" ng-show="containerLink(cmt)">&nbsp;<a href="{{containerLink(cmt)}}"><i class="fa fa-bullseye"></i></a></span>
        <span style="float:right;color:green;" title="Due {{cmt.dueDate|cdate}}">{{calcDueDisplay(cmt)}}</span>
        <div style="clear:both"></div>
      </div>
      <div ng-show="cmt.state==11">
        Draft {{commentTypeName(cmt)}} needs posting to be seen by others
      </div>
      <div class="leafContent comment-inner" ng-hide="cmt.meet || cmt.commentType==6"
           ng-dblclick="openCommentEditor(item,cmt)">
        <div ng-bind-html="cmt.html"></div>
      </div>
      <div ng-show="cmt.meet" class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
           ng-click="navigateToMeeting(cmt.meet)">
        <i class="fa fa-gavel" style="font-size:130%"></i> {{cmt.meet.name}}, {{cmt.meet.startTime |cdate}}
      </div>

      <table style="min-width:500px;overflow:hidden;table-layout:fixed" ng-show="cmt.commentType==2 || cmt.commentType==3">
        <col style="width:120px;white-space:nowrap">
        <col style="width:10px">
        <col width="width:1*">
        <tr ng-repeat="resp in cmt.responses">
          <td style="padding:5px;max-width:100px;overflow:hidden;white-space:nowrap">
            <div ng-show="cmt.commentType==2">
              <b>{{resp.choice}}</b></div>
            <div>{{resp.userName?resp.userName:resp.user}}</div>
          </td>
          <td>
            <span ng-show="cmt.state==12" ng-click="openResponseEditor(cmt, resp.user)" 
                  style="cursor:pointer;">
              <a href="#cmt{{cmt.time}}" title="Edit this response">
                <i class="fa fa-edit"></i></a>
            </span>
          </td>
          <td style="padding:5px;" ng-dblclick="openResponseEditor(cmt, resp.user)">
            <div class="leafContent comment-inner" ng-bind-html="getResponseHtml(resp)"></div>
          </td>
          <td ng-click="removeResponse(cmt,resp)" ng-show="cmt.state==12" >
            <span class="fa fa-trash" style="color:orange"></span>
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
            <div class="leafContent comment-inner">
              <span style="color:lightgrey">No response provided</span></div>
          </td>
        </tr>
      </table>
      <div ng-show="cmt.docList">
          <span class="btn btn-sm btn-default btn-raised" ng-repeat="docId in cmt.docList" ng-click="navigateToDoc(docId)">
              <img src="<%=ar.retPath%>assets/images/iconFile.png"> {{getFullDoc(docId).name}} 
          </span>
      </div>
      <div class="leafContent comment-inner" 
           ng-show="(cmt.commentType==2 || cmt.commentType==3)" 
           ng-dblclick="openCommentEditor(item, cmt)"
           title="closing outcome of the round/proposal">
        <div ng-bind-html="getOutcomeHtml(cmt)"></div>
      </div>
      <div ng-show="cmt.replies.length>0 && cmt.commentType>1">
        See proposals:
        <span ng-repeat="reply in cmt.replies"><a href="#cmt{{reply}}" >
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
  </td>
   
   

<script src="<%=ar.retPath%>templates/CommentModal.js"></script>
<script src="<%=ar.retPath%>templates/ResponseModal.js"></script>  
<!-- end CommentView.jsp -->
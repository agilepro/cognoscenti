<!-- begin CommentView.jsp -->

  <td style="width:50px;vertical-align:top;padding:15px;">
    <img id="cmt{{cmt.time}}" class="img-circle" title="{{cmt.userName}} - {{cmt.user}}" style="height:35px;width:35px;" 
         ng-src="<%=ar.retPath%>/users/{{cmt.userKey}}.jpg" alt="{{cmt.user|limitTo : 8}}" >
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
            <li role="presentation" ng-show="cmt.user=='<%ar.writeJS(currentUser);%>'">
              <a role="menuitem" ng-click="openCommentEditor(item,cmt)">Edit Your {{commentTypeName(cmt)}}</a></li>
            <li role="presentation" ng-show="cmt.commentType==2 || cmt.commentType==3">
              <a role="menuitem" ng-click="openResponseEditor(cmt, '<%ar.writeJS(currentUser);%>')">
                Create/Edit Response:</a></li>
            <li role="presentation" ng-show="cmt.state==11 && cmt.user=='<%ar.writeJS(currentUser);%>'">
              <a role="menuitem" ng-click="postComment(item, cmt)">Post Your {{commentTypeName(cmt)}}</a></li>
            <li role="presentation" ng-show="cmt.user=='<%ar.writeJS(currentUser);%>'">
              <a role="menuitem" ng-click="deleteComment(item, cmt)">
              Delete Your {{commentTypeName(cmt)}}</a></li>
            <li role="presentation" ng-show="cmt.state==12">
              <a role="menuitem" ng-click="closeComment(item, cmt)">Close {{commentTypeName(cmt)}}</a></li>
            <li role="presentation" ng-show="cmt.commentType==1">
              <a role="menuitem" ng-click="openCommentCreator(item,1,cmt.time)">
              Reply</a></li>
            <li role="presentation" ng-show="cmt.commentType==2 || cmt.commentType==3">
              <a role="menuitem" ng-click="openCommentCreator(item,2,cmt.time,cmt.html)">
              Make Modified Proposal</a></li>
            <li role="presentation">
              <a role="menuitem" ng-click="openDecisionEditor(item, cmt)">
              Create New Decision</a></li>
            </ul>
          </div>

        <span ng-show="cmt.commentType==1" title="{{stateName(cmt)}} Comment">
          <i class="fa fa-comments-o" style="font-size:130%"></i></span>
        <span ng-show="cmt.commentType==2" title="{{stateName(cmt)}} Proposal">
          <i class="fa fa-star-o" style="font-size:130%"></i></span>
        <span ng-show="cmt.commentType==3" title="{{stateName(cmt)}} Round">
          <i class="fa fa-question-circle" style="font-size:130%"></i></span>
        <span ng-show="cmt.commentType==5" title="{{stateName(cmt)}} Minutes">
          <i class="fa fa-file-code-o" style="font-size:130%"></i></span>
               &nbsp; 
        <span title="Created {{cmt.dueDate|date:'medium'}}"
              ng-click="openCommentEditor(item,cmt)">{{cmt.time | date}}</span> -
        <a href="<%=ar.retPath%>v/{{cmt.userKey}}/userSettings.htm">
          <span class="red">{{cmt.userName}}</span>
        </a>
        <span ng-show="cmt.emailPending && !cmt.suppressEmail" 
              ng-click="openCommentEditor(item,cmt)">-email pending-</span>
        <span ng-show="cmt.replyTo">
          <span ng-show="cmt.commentType==1">
            In reply to                 
            <a style="border-color:white;" href="#cmt{{cmt.replyTo}}">
              <i class="fa fa-comments-o"></i> {{findComment(item,cmt.replyTo).userName}}</a>
          </span>
          <span ng-show="cmt.commentType>1">Based on
            <a style="border-color:white;" href="#cmt{{cmt.replyTo}}">
            <i class="fa fa-star-o"></i> {{findComment(item,cmt.replyTo).userName}}</a>
          </span>
        </span>
         <span ng-show="cmt.commentType==6" style="color:green">
             <i class="fa fa-arrow-right"></i> <b>{{showDiscussionPhase(cmt.newPhase)}}</b> Phase</span>
        <span style="float:right;color:green;" title="Due {{cmt.dueDate|date:'medium'}}">{{calcDueDisplay(cmt)}}</span>
        <div style="clear:both"></div>
      </div>
      <div ng-show="cmt.state==11">
        Draft {{commentTypeName(cmt)}} needs posting to be seen by others
      </div>
      <div class="leafContent comment-inner" ng-hide="cmt.meet || cmt.commentType==6">
        <div ng-bind-html="cmt.html"></div>
      </div>
      <div ng-show="cmt.meet" class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
           ng-click="navigateToMeeting(cmt.meet)">
        <i class="fa fa-gavel" style="font-size:130%"></i> {{cmt.meet.name}} @ {{cmt.meet.startTime | date}}
      </div>

      <table style="min-width:500px;overflow:hidden" ng-show="cmt.commentType==2 || cmt.commentType==3">
        <col style="width:120px">
        <col style="width:10px">
        <col width="width:1*">
        <tr ng-repeat="resp in cmt.responses">
          <td style="padding:5px;max-width:100px;overflow:hidden">
            <div ng-show="cmt.commentType==2">
              <b>{{resp.choice}}</b></div>
            <div>{{resp.userName}}</div>
          </td>
          <td>
            <span ng-show="cmt.state==12" ng-click="openResponseEditor(cmt, resp.user)" 
                  style="cursor:pointer;">
              <a href="#cmt{{cmt.time}}" title="Edit this response">
                <i class="fa fa-edit"></i></a>
            </span>
          </td>
          <td style="padding:5px;">
            <div class="leafContent comment-inner" ng-bind-html="resp.html"></div>
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
              <i>Click edit button to register a response to this {{commentTypeName(cmt)}}.</i></div>
          </td>
        </tr>
      </table>
      <div ng-show="cmt.docList">
          <span class="btn btn-sm btn-default btn-raised" ng-repeat="docId in cmt.docList" ng-click="navigateToDoc(docId)">
              <img src="<%=ar.retPath%>assets/images/iconFile.png"> {{getFullDoc(docId).name}} 
          </span>
      </div>
      <div class="leafContent comment-inner" ng-show="cmt.state==13 && (cmt.commentType==2 || cmt.commentType==3)">
        <div ng-bind-html="cmt.outcome"></div>
      </div>
      <div ng-show="cmt.replies.length>0 && cmt.commentType>1">
        See proposals:
        <span ng-repeat="reply in cmt.replies"><a href="#cmt{{reply}}" >
          <i class="fa fa-star-o"></i> {{findComment(item,reply).userName}}</a> </span>
      </div>
      <div ng-show="cmt.replies.length>0 && cmt.commentType==1">
        See replies:
        <span ng-repeat="reply in cmt.replies">
          <a href="#cmt{{reply}}" >
            <i class="fa fa-comments-o"></i> {{findComment(item,reply).userName}}
          </a>
        </span>
      </div>
      <div ng-show="cmt.decision">
        See Linked Decision: 
        <a href="decisionList.htm#DEC{{cmt.decision}}"> 
          #{{cmt.decision}}</a>
      </div>
    </div>
  </td>
   
<!-- end CommentView.jsp -->
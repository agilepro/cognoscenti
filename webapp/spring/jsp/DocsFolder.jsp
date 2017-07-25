<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%


    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();
    boolean isMember = ar.isMember();

    JSONArray attachments = new JSONArray();

    UserProfile up = ar.getUserProfile();

    List<AttachmentRecord> aList = ngp.getAccessibleAttachments(up);

    for (AttachmentRecord aDoc : aList) {
        attachments.put( aDoc.getJSON4Doc(ar, ngp) );
    }

    JSONArray allLabels = ngp.getJSONLabels();


/* DOC RECORD PROTOTYPE
    $scope.atts = [
      {
        "attType": "FILE",
        "comments": [],
        "deleted": false,
        "description": "Original Contract from the SEC to Fujitsu",
        "id": "1002",
        "labelMap": {},
        "modifiedtime": 1391185776500,
        "modifieduser": "cparker@us.fujitsu.com",
        "name": "Contract 13-C-0113-Fujitsu.pdf",
        "size": 409333,
        "universalid": "CSWSLRBRG@sec-inline-xbrl@0056",
        "upstream": true
      },
    $scope.allLabels = [
      {
        "color": "yellow",
        "name": "User Story"
      },
      {
        "color": "magenta",
        "description": "Members of a project can see and edit any of roles.",
        "expandedPlayers": [
          {
            "name": "Keith (local) Test",
            "uid": "kswenson@us.fujitsu.com"
          },
          {
            "name": "Jack Landry",
            "uid": "jack@landry.com"
          }
        ],
        "name": "Members",
        "players": [
          {
            "name": "Keith (local) Test",
            "uid": "kswenson@us.fujitsu.com"
          },
          {
            "name": "Jack Landry",
            "uid": "jack@landry.com"
          }
        ],
        "requirements": ""
      },

*/

%>

<style>
   .folderLine {
       margin:5px;
   }
</style>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Document Folders");
    $scope.atts = <%attachments.write(out,2,4);%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.filter = "";
    $scope.showVizPub = true;
    $scope.showVizMem = true;
    $scope.filterMap = {};
    $scope.folderPath = [];

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.allLabels.sort( function(a,b) {
        if (a.name < b.name) {
            return -1;
        }
        if (a.name > b.name) {
            return 1;
        }
        return 0;
    });

    $scope.sortDocs = function() {
        $scope.atts.sort( function(a,b) {
            return (b.modifiedtime - a.modifiedtime);
        });
    }
    $scope.sortDocs();

    $scope.getRows = function() {
        var lcfilter = $scope.filter.toLowerCase();
        var res = [];
        var last = $scope.atts.length;
        for (var i=0; i<last; i++) {
            var rec = $scope.atts[i];
            var hasLabel = true;
            $scope.allLabelFilters().map( function(val) {
                if (!rec.labelMap[val.name]) {
                    hasLabel=false;
                }
            });
            if (!hasLabel) {
                continue;
            }

            if (rec.name.toLowerCase().indexOf(lcfilter)>=0) {
                res.push(rec);
            }
            else if (rec.description.toLowerCase().indexOf(lcfilter)>=0) {
                res.push(rec);
            }
        }
        return res;
    }
    $scope.removeEntry = function(searchId) {
        var res = [];
        $scope.atts.map( function(rec) {
            if (searchId!=rec.id) {
                res.push(rec);
            }
        });
        $scope.atts = res;
    }
    $scope.deleteDoc = function(rec) {
        rec.deleted = true;
        var postURL = "docsUpdate.json?did="+rec.id;
        var postdata = angular.toJson(rec);
        $scope.showError=false;
        $http.post(postURL, postdata)
        .success( function(data) {
            $scope.removeEntry(rec.id);
            $scope.sortDocs();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.getAllLabels = function(doc) {
        var res = [];
        $scope.allLabels.map( function(val) {
            if (doc.labelMap[val.name]) {
                res.push(val);
            }
        });
        return res;
    }

    $scope.hasLabel = function(searchName) {
        return $scope.filterMap[searchName];
    }
    $scope.toggleLabel = function(label) {
        $scope.filterMap[label.name] = !$scope.filterMap[label.name];
    }
    $scope.addFolderPath = function(label) {
        $scope.folderPath.push(label);
        $scope.filterMap[label.name] = true;
    }
    $scope.removeFolderPath = function(label) {
        var res = [];
        $scope.folderPath.map( function(item) {
            if (label.name != item.name) {
                res.push(item);
            }
        });
        $scope.folderPath = res;
        $scope.filterMap[label.name] = false;
    }
    $scope.trimFolderPath = function(index) {
        var res = [];
        var count = 0;
        $scope.folderPath.map( function(item) {
            if (count<index) {
                res.push(item);
                $scope.filterMap[item.name] = true;
            }
            else {
                $scope.filterMap[item.name] = false;
            }
            count++;
        });
        $scope.folderPath = res;
    }
    $scope.allLabelFilters = function() {
        var res = [];
        $scope.allLabels.map( function(val) {
            if ($scope.filterMap[val.name]) {
                res.push(val);
            }
        });
        return res;
    }
    $scope.getAvailableFolders = function() {
        var currPool = $scope.getRows();
        var labelMap = {};
        currPool.map( function(doc) {
            $scope.allLabels.map( function(val) {
                if (doc.labelMap[val.name]) {
                    labelMap[val.name] = true;
                }
            });
        });
        $scope.folderPath.map( function(folder) {
            labelMap[folder.name] = false;
        });
        var labelList = [];
        $scope.allLabels.map( function(val) {
            if (labelMap[val.name]) {
                labelList.push(val);
            }
        });
        labelList.sort( function(a,b) {
            if (a.name>b.name) {
                return 1;
            }
            else {
                return -1;
            }
        })
        return labelList.sort();
    }
    $scope.getUnmarked = function() {
        var avail = $scope.getAvailableFolders();
        var doclist = $scope.getRows();
        var res = [];
        doclist.map( function(doc) {
            var ok = true;
            avail.map( function(folder) {
                if (doc.labelMap[folder.name]) {
                    ok = false;
                }
            });
            if (ok) {
                res.push(doc);
            }
        });
        return res;
    }
    $scope.folderPathList = function() {
        var res = "";
        var needComma = false;
        $scope.folderPath.map( function(item) {
            if (needComma) {
                res += "|";
            }
            res += item.name;
            needComma = true;
        });
        return encodeURI(res);
    }
});

</script>

<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="upRightOptions rightDivContent">
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" href="listAttachments.htm">
              Show Without Folders</a>
          </li>
          <li role="presentation"><a role="menuitem" tabindex="-1" href="docsAdd.htm?folder={{folderPathList()}}">
              <img src="<%= ar.retPath%>assets/iconUpload.png" width="13" height="15" alt="" /> Add Document</a>
          </li>
          <li role="presentation"><a role="menuitem" tabindex="-1" href="sendNote.htm">
              <img src="<%= ar.retPath%>assets/images/iconEmailNote.gif" width="13" height="15" alt="" /> Send Email</a>
          </li>
          <li role="presentation"><a role="menuitem" href="SyncAttachment.htm">
              <img src="<%= ar.retPath%>assets/iconSync.gif" width="13" height="15" alt="" /> Synchronize</a>
          </li>
        </ul>
      </span>
    </div>


    <div id="allthefolders" style="padding:30px">

        <div class="folderLine" style="cursor:pointer">
            <span ng-click="trimFolderPath(0)">
                <img src="<%=ar.retPath%>assets/iconFolder.gif">
                <img src="<%=ar.retPath%>assets/images/collapseIcon.gif"> Workspace
            </span>
        </div>
        <div class="folderLine" style="margin-left:{{$index*15+15}}px;cursor:pointer" ng-repeat="folder in folderPath">
            <span ng-click="trimFolderPath($index+1)">
                <img src="<%=ar.retPath%>assets/iconFolder.gif">
                <img src="<%=ar.retPath%>assets/images/collapseIcon.gif">
                <button class="labelButton"
                    style="background-color:{{folder.color}};">{{folder.name}}
                </button>
            </span>
        </div>
        <div class="well" ng-show="getAvailableFolders().length>0">
            Choose Folder: <span class="folderLine" style="cursor:pointer" ng-repeat="folder in getAvailableFolders()">
                <span ng-click="addFolderPath(folder)">
                    <button class="labelButton"
                        style="background-color:{{folder.color}};">{{folder.name}}
                    </button>
                </span>
            </span>
        </div>

    </div>

    <table class="gridTable2" width="100%">
        <tr class="gridTableHeader">
            <td width="50px">
              <div class="dropdown">
                <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                    data-toggle="dropdown"> <span class="caret"></span> </button>
                </button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="docsAdd.htm?folder={{folderPathList()}}">
                      <img src="<%= ar.retPath%>assets/iconUpload.png" width="13" height="15" alt="" />
                      Add Document</a>
                  </li>
                </ul>
              </div>
            </td>
            <td width="80px"></td>
            <td width="420px">Name ~ Description</td>
            <td width="80px">Date</td>
        </tr>
        <tr ng-repeat="rec in getUnmarked()">
            <td>
              <div class="dropdown">
                <button class="dropdown-toggle specCaretBtn" type="button"  d="menu" 
                    data-toggle="dropdown"> <span class="caret"></span> </button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="docinfo{{rec.id}}.htm">Access Document</a></li>
                  <li role="presentation" ng-show="rec.attType=='FILE'">
                      <a role="menuitem" tabindex="-1" href="docsRevise.htm?aid={{rec.id}}">Upload Revised Document</a></li>
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="editDetails{{rec.id}}.htm">Edit Document Details</a></li>
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="fileVersions.htm?aid={{rec.id}}">List Versions</a></li>
                  <li role="presentation" class="divider"></li>
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" ng-click="deleteDoc(rec)">Delete <i class="fa fa-trash"></i> Document</a></li>
                  <li role="presentation">
                      <a role="menuitem" tabindex="-1" href="sendNote.htm?att={{rec.id}}">Send Document By Email</a></li>
                </ul>
              </div>
            </td>
            <td>
                <a href="editDetails{{rec.id}}.htm">
                    <span ng-show="rec.deleted"><i class="fa fa-trash"></i></span>
                    <span ng-show="rec.upstream"><img src="<%=ar.retPath%>assets/images/iconUpstream.png"></span>
                    <span ng-show="rec.attType=='FILE'"><img src="<%=ar.retPath%>assets/images/iconFile.png"></span>
                    <span ng-show="rec.attType=='URL'"><img src="<%=ar.retPath%>assets/images/iconUrl.png"></span>
                </a>
            </td>
            <td>
                <b><a href="docinfo{{rec.id}}.htm" title="{{rec.name}}">{{rec.name}}</a></b>
                ~ {{rec.description}}
                <span ng-repeat="label in getAllLabels(rec)"><button class="labelButton"
                    style="background-color:{{label.color}};">{{label.name}}
                    </button>
                </span>
            </td>
            <td>{{rec.modifiedtime|date}}</td>
        </tr>
    </table>
    
    
    <div class="guideVocal" ng-show="atts.length==0" style="margin-top:80px">
    You have no attached documents in this workspace yet.
    You can add them using a option from the pull-down in the upper right of this page.
    They can be uploaded from your workstation, or linked from the web.
    </div>
    
</div>





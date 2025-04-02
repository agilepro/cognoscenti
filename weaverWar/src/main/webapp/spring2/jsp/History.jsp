<%@page errorPage="/spring2/jsp/error.jsp"
%><%@ include file="/include.jsp"
%><%
/*
Required parameters:

    1. pageId : This is the id of a Workspace and here it is used to retrieve NGWorkspace.

*/

    ar.assertLoggedIn("Must be logged in to see a list of meetings");

    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    int start = DOMFace.safeConvertInt(ar.defParam("start", "0"));
    if (start < 0) {
        start = 0;
    }
    int size = 50;
    int endRecord = 0;
    
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

    List<HistoryRecord> histRecs = ngp.getAllHistory();
    JSONArray allHistory = new JSONArray();
    for (HistoryRecord hist : histRecs) {
        endRecord++;
        if (endRecord < start) {
            continue;
        }
        if (endRecord >= start+size) {
            break;
        }
        AddressListEntry ale = AddressListEntry.findOrCreate(hist.getResponsible());
        JSONObject userObject = ale.getJSON();
        UserProfile responsible = ale.getUserProfile();
        if(responsible!=null && responsible.hasLoggedIn()) {
            userObject = responsible.getFullJSON();
        }
        else {
            userObject.put("image", "../assets/photoThumbnail.gif");
        }
        String objectKey = hist.getContext();
        int contextType = hist.getContextType();
        String key = hist.getCombinedKey();
        String url = hist.lookUpURL(ar, ngp);
        String objName = hist.lookUpObjectName(ngp);



        JSONObject jObj = hist.getJSON(ngp,ar);
        jObj.put("responsible", userObject);
        /*
        if (responsible!=null) {
            jObj.put("respUrl",     "v/"+responsible.getKey()+"/UserSettings.htm" );
        }
        else {
            jObj.put("respUrl",     "findUser.htm?id="+URLEncoder.encode(ale.getUniversalId(),"UTF-8") );
        }
        */
        jObj.put("respName",    ale.getName() );
        jObj.put("contextUrl",  url );
        allHistory.put(jObj);
    }

%>

<script src="../../../jscript/AllPeople.js"></script>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http, AllPeople, $modal) {
    setUpLearningMethods($scope, $modal, $http);
    $scope.allHistory = <%allHistory.write(out,2,4);%>;
    $scope.filter = "";
    
    // NOTE: filter was removed when pagination added.
    // should do server-side filtering

    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.processTemplate = function(hist) {
        return hist.template;
    }

    $scope.getHistory = function() {
        var filterlist = parseLCList($scope.filter);
        if (filterlist.length==0) {
            return $scope.allHistory;
        }
        var res = [];
        $scope.allHistory.forEach(  function(hItem) {
            if (containsOne(hItem.responsible.name, filterlist)) {
                res.push(hItem);
            }
            else if (containsOne(hItem.ctxName, filterlist)) {
                res.push(hItem);
            }
            else if (containsOne(hItem.comments, filterlist)) {
                res.push(hItem);
            }
            else if (containsOne(hItem.ctxType, filterlist)) {
                res.push(hItem);
            }
            else if (containsOne(hItem.event, filterlist)) {
                res.push(hItem);
            }
        });
        return res;
    }
    $scope.navigateToUser = function(player) {
        window.open("<%= ar.retPath%>v/"+encodeURIComponent(player.key)+"/PersonShow.htm","_blank");
    }

});
</script>
<div class="container-fluid override mb-4 mx-3 d-inline-flex">
    <span class="dropdown mt-1">
        <button class="btn btn-outline-secondary btn-tiny dropdown-toggle" type="button" id="dropdownInfoMenu"
            data-bs-toggle="dropdown" aria-expanded="false">
        </button>
        <ul class="dropdown-menu" aria-labelledby="dropdownInfoMenu">
            <li>
                <button class="dropdown-item" onclick="window.location.reload(true)">Refresh</button>
            </li>
        </ul>
    </span>
    <span>
        <h1 class="d-inline page-name" id="mainPageTitle">History Stream</h1>
    </span>
</div>
<!-- MAIN CONTENT SECTION START -->
<div ng-cloak>

<%@include file="ErrorPanel.jsp"%>

    <div class="container-fluid override mx-5">
        <div class="col-md-auto second-menu">              
                    <div class="col-md-auto">
                    <a class="no-btn mx-2" href="History.htm?start=<%=start-size%>" title="Back 50 records">
                    <i class="fa  fa-arrow-circle-left fa-2x"></i></a>
                    <span class="h5 "><%=start%> - <%=endRecord%> </span>
                    <a class="no-btn mx-2" href="History.htm?start=<%=start+size%>" title="Forward 50 records">
                    <i class="fa  fa-arrow-circle-right fa-2x"></i></a>
                    </div>
                </div>
            </div><hr>
                    <div class="container-fluid mx-5">
                        <div class="generalContent">
                            <span ng-repeat="hist in getHistory()" class="row d-flex my-2" >
                                <span class=" col-1 dropdown projectStreamIcons" >
                                    <ul class="navbar-btn p-0">
                            <li class="nav-item dropdown" id="user" data-toggle="dropdown" >
                                <img class="rounded-5" ng-src="<%=ar.retPath%>icon/{{hist.responsible.key}}.jpg"  title="{{hist.responsible.name}} - {{hist.responsible.uid}}" style="width: 32px; height: 32px; vertical-align: middle">
                                <ul class="dropdown-menu" role="menu" aria-labelledby="user">
                                    <li role="presentation"><a class="dropdown-item" role="menuitem" tabindex="0" style="text-decoration: none;text-align:center">{{hist.responsible.name}}<br/>{{hist.responsible.uid}}</a></li>
                                    <li role="presentation" style="cursor:pointer"><a class="dropdown-item" role="menuitem" tabindex="0" ng-click="navigateToUser(hist.responsible)">
                                        <span class="fa fa-user"></span> Visit Profile</a>
                                    </li>
                                </ul>
                            </li>
                                    </ul>
                                </span>
                                <span class="col-10">
                                    <span class="projectStreamText">{{hist.time|cdate}} -
                                        <a href="<%=ar.retPath%>{{hist.respUrl}}">
                                            <span class="red">{{hist.respName}}</span>
                                        </a><br/>
                                {{hist.ctxType}} "<a href="<%=ar.retPath%>{{hist.contextUrl}}">{{hist.ctxName}}</a>" was {{hist.event}}.
                <br/>
                                    <i>{{hist.comments}}</i>
                                    <hr>
                                    </span>
                                </span>
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

    </div>

</div>

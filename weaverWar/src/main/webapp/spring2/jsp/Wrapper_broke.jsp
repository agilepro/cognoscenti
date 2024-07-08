<!DOCTYPE html> 

  <!-- BEGIN Wrapper.jsp Layout wrapping (jsp/<%=wrappedJSP%>) -->
  <html>
    <head>
      <link rel="shortcut icon" href="<%=ar.baseURL%>bits/favicon.ico" />
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      <meta http-equiv="Content-Language" content="en-us" />
      <meta http-equiv="Content-Style-Type" content="text/css" />
      <meta http-equiv="imagetoolbar" content="no" />
      <meta
        name="viewport"
        content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0"
      />
      <meta
        name="google-signin-client_id"
        content="866856018924-boo9af1565ijlrsd0760b10lqdqlorkg.apps.googleusercontent.com"
      />

      <!-- INCLUDE the ANGULAR JS library -->
      <script src="<%=ar.baseURL%>jscript/angular.js"></script>
      <script src="<%=ar.baseURL%>jscript/angular-translate.js"></script>

      <script src="<%=ar.baseURL%>jscript/ui-bootstrap-tpls-2.5.0.min.js"></script>
      <!-- removed most of content when hidden -->
      <script src="<%=ar.baseURL%>jscript/jquery.min.js"></script>

      <script src="<%=ar.baseURL%>node_modules/bootstrap/dist/js/bootstrap.min.js"></script>
      <script src="<%=ar.baseURL%>jscript/slap.js"></script>

      <link
        href="<%=ar.baseURL%>/node_modules/bootstrap/dist/css/bootstrap.min.css"
        rel="stylesheet"
      />

      <script src="<%=ar.baseURL%>jscript/tinymce/tinymce.min.js"></script>
      <script src="<%=ar.baseURL%>jscript/tinymce/tinymce-ng.js"></script>
      <script src="<%=ar.baseURL%>jscript/textAngular-sanitize.min.js"></script>
      <script src="<%=ar.baseURL%>jscript/ng-tags-input.js"></script>
      <script src="<%=ar.baseURL%>jscript/MarkdownToHtml.js"></script>
      <script src="<%=ar.retPath%>jscript/HtmlParser.js"></script>
      <script src="<%=ar.baseURL%>jscript/TextMerger.js"></script>
      <script src="<%=ar.retPath%>jscript/HtmlToMarkdown.js"></script>

      <script src="<%=ar.baseURL%>jscript/common.js"></script>
      <link href="<%=ar.baseURL%>jscript/ng-tags-input.css" rel="stylesheet" />

      <!-- Bootstrap Material Design
      <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/ripples.min.js"></script>
      <script src="<%=ar.baseURL%>jscript/bootstrap-material-design/material.min.js"></script>
      <link
        rel="stylesheet"
        href="<%=ar.baseURL%>css/bootstrap-material-design/bootstrap-material-design.min.css"
        media="screen"
      />
      <link
        rel="stylesheet"
        href="<%=ar.baseURL%>css/bootstrap-material-design/ripples.min.css"
        media="screen"
      /> -->

      <!--New Bootstrap 5.0-->
      <!--<link
        rel="stylesheet"
        href="/node_modules/bootstrap/dist/css/bootstrap.css.map"
      />-->
   
      <link
        rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"
      />
      <link rel="stylesheet" href="/css/sidebar.css" />
   <link rel="stylesheet" href="/css/weaver.min.css" />
      <!-- INCLUDE web fonts 
      <link
        href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css"
        rel="stylesheet"
        data-semver="4.3.0"
        data-require="font-awesome@*"
      />
      <link
        href="<%=ar.retPath%>assets/google/css/PT_Sans-Web.css"
        rel="stylesheet"
      />

      <link
        href="<%=ar.retPath%>css/fixed-sidebar.min.css"
        rel="styleSheet"
        type="text/css"
        media="screen"
      />-->

      <!-- Date and Time Picker -->
      <link
        rel="stylesheet"
        href="<%=ar.retPath%>bits/angularjs-datetime-picker.css"
      />
      <script src="<%=ar.retPath%>bits/angularjs-datetime-picker.js"></script>
      <script src="<%=ar.retPath%>bits/moment.js"></script>
      <script>
        moment().format();
      </script>

      <!-- Weaver specific tweaks -->
      <link
        href="<%=ar.retPath%>bits/main.min.css"
        rel="styleSheet"
        type="text/css"
        media="screen"
      />

      <title><% ar.writeHtml(title); %></title>

      <script>
        /* NEW UI TEMPPORARY SCRIPTS */
        // TODO Remove this after removing the options dropdown
        $(document).ready(function() {
            $('.rightDivContent').insertAfter('.title').css({float:'right','margin-right':0});
            $('.rightDivContent .dropdown-menu').addClass('pull-right');
            /* INIT Bootstrap Material Design */
          //  $.material.init();
        });

        //Must initialize the app with all the right packages here, before the
        //individual pages create the controlles
        var myApp = angular.module('myApp', ['ui.bootstrap','ngTagsInput','ui.tinymce','angularjs-datetime-picker','pascalprecht.translate', 'ngSanitize']);

        myApp.filter('cdate', function() {
          return function(x) {
            if (!x || x<10000000) {
                return "Not Set";
            }
            let diff = new Date().getTime() - x;
            if (diff>860000000 || diff<-860000000) {
                return moment(x).format("DD-MMM-YYYY");
            }
            return moment(x).format("DD-MMM @ HH:mm");
          };
        });
        myApp.filter('encode', function() {
          return window.encodeURIComponent;
        });
        myApp.filter('wiki', function() {
          return function(x) {
            return convertMarkdownToHtml(x);
          };
        });

        console.log("LOADING WRAP LEARNING");
        function setUpLearningMethods($scope, $modal, $http) {
            console.log("setUpLearningMethods for <%=loggedKey%>");
            $scope.learningModes = <% learningModes.write(out, 2, 2); %>;
            $scope.learningMode = {done: true, mode:"standard"};

            $scope.findLearningMode = function() {
                $scope.learningMode = {done: true, mode:"standard"};
                $scope.learningModes.forEach(function(item) {
                    if (!item.done && $scope.learningMode.done) {
                        $scope.learningMode = item;
                    }
                });
                console.log("LEARNING MODE", $scope.learningMode);
            }

            $scope.findLearningMode();

            $scope.markLearningDone = function() {
                $scope.learningMode.done = true;
                $scope.findLearningMode();
            }

            $scope.openLearningEditor = function () {
                console.log("trying ot open it");
                var modalInstance = $modal.open({
                    animation: true,
                    templateUrl: '<%=ar.retPath%>templates/LearningEditModal.html?t=<%=System.currentTimeMillis()%>',
                    controller: 'LearningEditCtrl',
                    size: 'lg',
                    backdrop: "static",
                    resolve: {
                        wrappedJSP: function () {
                            return "<%=wrappedJSP%>";
                        }
                    }
                });
                modalInstance.result
                .then(function () {
                    window.location.reload();
                }, function () {
                    window.location.reload();
                });

            }

            $scope.setLearningDone = function(option) {
                console.log("MARK DONE", $scope.learningMode);
                var toPost = {}
                toPost.jsp = "<%=wrappedJSP%>";
                toPost.mode = $scope.learningMode.mode;
                toPost.done = option;
                var postdata = angular.toJson(toPost);
                var postURL = "MarkLearningDone.json";
                console.log(postURL,toPost);
                $http.post(postURL, postdata)
                .success( function(data) {
                    window.location.reload();
                })
                .error( function(data) {
                    errorPanelHandler($scope, data);
                });
            }
            $scope.toggleLearningDone = function() {
                $scope.setLearningDone(true);
            }

            mainScope = $scope;
        }

        var mainScope = null;
        function showLearningPath() {
            mainScope.setLearningDone(false);
        }
      </script>
      <style>
        .navbar.navbar-default.sidebar {
          margin-bottom: 0;
          background-color: #ab37c8;
          border: 0;
        }
      </style>
    </head>
    <body ng-app="myApp" ng-controller="myCtrl" <% if(isFrozen) {%>
      class="bodyFrozen"<%}%> <% if(isDeleted) {%>class="bodyDeleted"<%}%>>
      <div class="bodyWrapper align-items-start">
        <!-- Begin AppBar -->
        <%@ include file="AppBar.jsp" %>
        <!-- End AppBar -->

        <div class="container-fluid" ng-cloak>
          <div class="row">
            <!-- Begin SideBar  -->
            <div class="col-sm-1 col-lg-1">
              <%@ include file="SideBar.jsp" %>
            </div>
            <!-- End SideBar -->

            <!-- Begin mainContent -->
            <div class="col-10 col-lg-11 main-content">
              <%@ include file="WrapLearning.jsp" %>
              <script>
                console.log("loaded the LEARNING module");
              </script>

              <!-- BEGIN Title and Breadcrump -->
              <ol class="title">
                <% if(!ar.isLoggedIn()) { %>
                <!-- user is not logged in, don't display any breadcrumbs -->
                <% } else { %>
                <li class="link">
                  <a
                    href="<%=ar.retPath%>v/<%ar.writeURLData(ngb.getKey());%>/$/SiteWorkspaces.htm"
                    ><%ar.writeHtml(ngb.getFullName());%></a
                  >
                </li>
                <li class="link">
                  <a
                    href="<%=ar.retPath%>v/<%ar.writeURLData(ngb.getKey());%>/<%ar.writeURLData(ngw.getKey());%>/FrontPage.htm"
                  >
                    <%ar.writeHtml(ngw.getFullName());%></a
                  >
                  <span style="bg-weaverLight">
                    <%if (ngw.isDeleted()) {ar.write(" (DELETED) ");} else if
                    (ngw.isFrozen()) {ar.write(" (FROZEN) ");}%>
                  </span>
                </li>
                <% } %>
                <li class="page-name">
                  <h1 id="mainPageTitle">Untitled Page</h1>
                </li>
              </ol>
              <script>
                function setMainPageTitle(str) {
                  document.getElementById("mainPageTitle").innerHTML = str;
                  document.title =
                    str +
                    " - <%if (ngw!=null) { ar.writeJS(ngw.getFullName()); }%>";
                }
              </script>
              <!-- BEGIN Title and Breadcrumb -->

              <!-- Welcome Message -->
              <div id="welcomeMessage"></div>
              <script>



                var knowWeAreLoggedIn = <%= ar.isLoggedIn() %>;
                function displayWelcomeMessagexx(info) {
                    console.log('LOGGED IN', info);
                }
                function displayWelcomeMessage(info) {
                    //console.log("WELCOME:", knowWeAreLoggedIn, info)
                    var y = document.getElementById("welcomeMessage");
                    if (knowWeAreLoggedIn && info.verified) {
                        //nothing to do in this case
                    }
                    else if (knowWeAreLoggedIn && !info.verified) {
                        //this encountered only when logging out
                        window.location.reload(true);
                    }
                    else if (info.haveNotCheckedYet) {
                        y.innerHTML = 'Checking identity, please <a href="'
                            +SLAP.loginConfig.providerUrl
                            +'&go='+window.location+'"><span class="btn btn-primary btn-raised">Login</span></a>';
                    }
                    else if (!info.userId) {
                        y.innerHTML = 'Not logged in, please <a href="'
                            +SLAP.loginConfig.providerUrl
                            +'?openid.mode=quick&go='+window.location+'"><span class="btn btn-primary btn-raised">Login</span></a>';
                    }
                    else if (!info.verified) {
                        y.innerHTML = 'Hello <b>'+info.userName+'</b>.  Attempting Automatic Login.';
                    }
                    else {
                        y.innerHTML = 'Hello <b>'+info.userName+'</b>.  You are now logged in.  Refreshing page.';
                        window.location.reload();
                    }
                }

                SLAP.initLogin(<% loginConfigSetup.write(out, 2, 2); %>, <% loginInfoPrefetch.write(out, 2, 2); %>, displayWelcomeMessage);
              </script>

              <!-- -->
              <!-- -->
              <!-- -->
              <!-- -->
              <!-- -->
              <!-- -->
              <!-- -->

              <!-- Begin Template Content (compiled separately) -->
              <jsp:include page="<%=wrappedJSP%>" />
              <!-- End Template Content (compiled separately) -->
            </div>
          </div>
        </div>
        <!-- End mainContent -->
      </div>
      <!-- End body wrapper -->

      <script>
        //every 25 minutes, query the server to keep session alive
        window.setInterval(function () {
          if (!SLAP.loginInfo.verified) {
            console.log("Not logged in, no session.");
          } else {
            console.log(
              "Keeping the session alive for: " +
                SLAP.loginInfo.userName +
                " (" +
                SLAP.loginInfo.userId +
                ")."
            );
            SLAP.queryTheServer();
          }
          return 0;
        }, 1500000);
      </script>
      <script src="<%=ar.baseURL%>node_modules\bootstrap\dist\js\bootstrap.bundle.min.js"></script>
      <script src="<%=ar.baseURL%>jscript/translation.js"></script>
      <script src="<%=ar.retPath%>templates/LearningEditModal.js"></script>
      <script src="<%=ar.retPath%>jscript/AllPeople.js"></script>
      <script src="<%=ar.retPath%>jscript/HtmlToMarkdown.js"></script>
      <script src="<%=ar.retPath%>jscript/HtmlParser.js"></script>
      <script src="<%=ar.baseURL%>jscript/TextMerger.js"></script>
      <script src="<%=ar.retPath%>jscript/SimultaneousEdit.js"></script>
      <script src="<%=ar.retPath%>templates/AttachActionCtrl.js"></script>
      <script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>
      <script src="<%=ar.retPath%>templates/DecisionModal.js"></script>
      <script src="<%=ar.baseURL%>node_modules\@popperjs\core\dist\umd\popper.min.js"></script>
    </body>
  </html>

  <!-- END Wrapper.jsp Layout - - <%= (System.currentTimeMillis()-renderStart) %> ms -->
</WatchRecord>

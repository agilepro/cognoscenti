<!DOCTYPE html>
<script type="text/javascript">

  var app = angular.module('myApp');
  app.controller('myCtrl', function ($scope, $http, $modal) {

    $scope.user = embeddedData.user;
    $scope.userRelPath = embeddedData.userRelPath;
    $scope.ar = embeddedData.ar;
    $scope.workspaceInfo = embeddedData.workspaceInfo;

  });

</script>



          <!--toggle button for mobile nav -->
          <button class="navbar-toggler no-btn float-end" type="button" data-bs-toggle="collapse" data-bs-target="#topbar-nav"
            aria-controls="navbarNavAltMarkup" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
          </button>
          <!-- end toggle button for mobile nav -->
          
          <!-- Logo Brand -->
          
            <div class="bg-primary p-2 mx-3" >
              <a href="Front.wmf" >
              <img class="d-inline-block mx-2" alt="Weaver Logo" src="<%=ar.retPath%>new_assets/bits/header-icon.png">
<span class="fw-semibold fs-1 text-weaverbody">Weaver</span></a></div>
          <!-- Search Bar 
          <div class="row search">
            <form class="d-flex" role="search" action="searchAllNotes.htm">
              <div class="form-group specialweaver is-empty">
                <input type="text" class="form-control me-2" name="s" placeholder=" &#xF002; Search"
                  style="font-family:Arial, FontAwesome">
              </div>
            </form>
          </div>
         end Search Bar -->
          
          <!-- Start top navigation -->
          <div class="collapse navbar-collapse" id="topbar-nav">
            <ul class="navbar-nav pe-3">
                  <!-- Drop Down help -->

                  <!-- Drop Down Add -->

                  <!-- Drop Down Workspace -->


                    <!-- Drop Down User -->


                </ul>
          </div>

      <!-- END App Bar -->
      <!-- END AppBar.jsp -->
      <% out.flush(); %>
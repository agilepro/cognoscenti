<!-- BEGIN ErrorPanel -->
    <script type="text/javascript">
    function errorPanelHandler($scope, errorData) {
        if (errorData.exception) {
            var exception = errorData.exception;
            $scope.errorMsg = exception.msgs.join();
            $scope.errorTrace = exception.stack;
        }
        else {
            $scope.errorMsg = stripHtml(errorData);
            $scope.errorTrace = errorData;
        }
        $scope.showError=true;
        $scope.showTrace = false;
    }
    function stripHtml(src) {
        var dst = "";
        var showing=true;
        for (var i=0; i<src.length; i++) {
            var ch = src.charAt(i);
            if (ch=='<') {
                showing=false;
            }
            if (showing) {
                dst += ch;
            }
            if (ch=='>') {
                showing=true;
            }
        }
        return dst;
    }
    </script>

    <div id="ErrorPanel" style="border:2px solid red;display=none;background:LightYellow;margin:10px;"
         ng-show="showError" ng-cloak>
        <div class="rightDivContent" style="margin:10px;">
            <a href="#" ng-click="showError=false"><img src="<%= ar.retPath%>assets/iconBlackDelete.gif"/></a>
        </div>
        <div class="generalSettings">
            <table>
                <tr>
                    <td class="gridTableColummHeader">Error:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2">{{errorMsg}}</td>
                </tr>
                <tr ng-show="showTrace">
                    <td class="gridTableColummHeader">Trace:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2">{{errorTrace}}</td>
                </tr>
                <tr ng-hide="showTrace">
                    <td class="gridTableColummHeader">Trace:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2"><button ng-click="showTrace=true">Show The Details</button></td>
                </tr>
            </table>
        </div>
    </div>
<!-- END ErrorPanel -->

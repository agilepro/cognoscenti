<!-- BEGIN ErrorPanel -->
    <script type="text/javascript">
    function errorPanelHandler($scope, errorData) {
        console.log("ERROR PANEL", errorData);
        if (errorData.exception) {
            var exception = errorData.exception;
            $scope.errorMsgs = exception.msgs;
            $scope.errorTrace = exception.stack;
        }
        else if (errorData.error) {
            var error = errorData.error;
            $scope.errorMsgs = [];
            error.details.forEach( function(item) {
                $scope.errorMsgs.push(item.message);
            });
            $scope.errorTrace = error.stack;
        }
        else {
            $scope.errorMsgs = [];
            $scope.errorMsgs.push(stripHtml(errorData));
            $scope.errorTrace = errorData;
        }
        $scope.showError=true;
        $scope.showTrace = false;
        var msgStr = "ERROR OCCURRED: \n\n";
        $scope.errorMsgs.forEach( function(item) {
            msgStr = msgStr + item + "\n";
        });
        alert(msgStr);
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

    <div ng-show="siteInfo.siteMsg" ng-cloak>
        <div class="siteMsg">{{siteInfo.siteMsg}}</div>
    </div>
    <div id="ErrorPanel" style="border:2px solid red;display=none;background:LightYellow;margin:10px;"
         ng-show="showError" ng-cloak>
        <div style="margin:10px; float:right;">
            <a href="#" ng-click="showError=false"><img src="<%= ar.retPath%>assets/iconBlackDelete.gif"/></a>
        </div>
        <div>
            <table style="color:#888888;font-family:sans-serif;font-size:16px;">
                <tr>
                    <td class="gridTableColummHeader">Problem:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" style="padding:15px;">
                        <div ng-repeat="msg in errorMsgs">
                            {{msg}}
                        </div>
                    </td>
                </tr>
                <tr ng-show="showTrace">
                    <td class="gridTableColummHeader">Trace:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" style="padding:15px;">
                       <div>
                          <pre>{{errorTrace.join("\n")}}</pre>
                       </div>
                    </td>
                </tr>
                <tr>
                    <td class="gridTableColummHeader">Trace:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" style="padding:15px;">
                        <button ng-click="showTrace=!showTrace">Show The Details</button>
                    </td>
                </tr>
            </table>
        </div>
    </div>
<!-- END ErrorPanel -->

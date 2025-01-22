    <div ng-cloak>

        <div class="well" ng-show="meeting.state < 2">
            <h2 class="h5">Meeting is not in running state</h2>
            <button ng-click="changeMeetingState(2)" class="btn btn-primary btn-raised">Start Meeting</button>
        </div>
        <div class="panel panel-default" ng-repeat="sim in actionItemSims">
            <div class="h6 panel-heading" >{{sim.item.number}}. {{sim.item.subject}}
                <span ng-hide="sim.item.needMerge">
                    <span ng-hide="sim.item.timerRunning" style="padding:5px">
                        <button class="btn btn-comment btn-success " ng-click="agendaStartButton(sim.item)"><i class="fa fa-clock-o"></i> Start</button>
                        Elapsed: {{sim.item.timerTotal| minutes}}
                        Remaining: {{sim.item.duration - item.timerTotal| minutes}}
                    </span>
                    <span ng-show="sim.item.timerRunning" ng-style="timerStyleComplete(sim.item)">
                        <span>Running</span>
                        Elapsed: {{sim.item.timerTotal| minutes}}
                        Remaining: {{sim.item.duration - sim.item.timerTotal| minutes}}
                        <button class="btn btn-comment btn-danger " ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
                    </span>
                </span>
                <span ng-show="sim.needMerge">
                    <button ng-click="closeEditor()" style="background-color:red;color:white">
                        <i class="fa fa-exclamation-triangle"></i> Merge Changes from Others</button>
                </span>
            </div>
            <div class="panel-body" ng-show="sim.isEditing"  ng-style="editStyle(sim.item)">
                <div ui-tinymce="tinymceOptions" ng-model="sim.vHtml" 
                     class="leafContent" style="min-height:250px;" ></div>
                <button class="btn btn-default btn-raised" ng-click="openAttachAction(sim.item)">Add Action Item</button>
                <button class="btn btn-default btn-raised" ng-click="openAddDocument(sim.item)">Add Document</button>
                <button class="btn btn-default btn-raised" ng-click="openDecisionEditor(sim.item)">Add Decision</button>
                <button class="btn btn-warning btn-raised" ng-click="xxx(sim.item)" ng-show="sim.needsSaving()">Save</button>
                {{sim.needsSaving()}}
                <button class="btn btn-primary btn-raised" style="float:right" ng-click="sim.stopEdit()">Close</button>
            </div>
            <div class="panel-body" ng-hide="sim.isEditing" ng-dblclick="openNotesDialog(sim.itemRef)">
                <div ng-show="sim.vHtml" ng-bind-html="sim.vHtml" class="ms-5 comment-inner"></div>
                <div ng-hide="sim.vHtml" class="ms-5 guideVocal opacity-75 comment-inner"><i>Double click to start editing</i></div>
                <div>&nbsp;</div>
            </div>

        </div>
        
        <div class="h6">
            Meeting Duration: {{timerTotal|minutes}}  
            <button class="btn btn-secondary btn-comment btn-wide" ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
        </div>

        
        <div class="guideVocal" ng-hide="getSims().length > 0">
          No minutes to show . . .
        </div>
      </div>
    <div>

        <div class="panel panel-default" ng-repeat="sim in getSims()">
            <div class="panel-heading" >{{sim.item.number}}. {{sim.item.subject}}
                <span style="font-size:70%" ng-hide="sim.item.needMerge">
                    <span ng-hide="sim.item.timerRunning" style="padding:5px">
                        <button ng-click="agendaStartButton(sim.item)"><i class="fa fa-clock-o"></i> Start</button>
                        Elapsed: {{sim.item.timerTotal| minutes}}
                        Remaining: {{sim.item.duration - item.timerTotal| minutes}}
                    </span>
                    <span ng-show="sim.item.timerRunning" ng-style="timerStyleComplete(sim.item)">
                        <span>Running</span>
                        Elapsed: {{sim.item.timerTotal| minutes}}
                        Remaining: {{sim.item.duration - sim.item.timerTotal| minutes}}
                        <button ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
                    </span>
                </span>
                <span style="font-size:70%" ng-show="sim.needMerge">
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
            <div class="panel-body" ng-hide="sim.isEditing" ng-dblclick="sim.startEdit()">
                <div ng-bind-html="sim.vHtml"></div>
                <div ng-hide="sim.vHtml" style="color:#bbb">Double click to start editing</div>
                <div>&nbsp;</div>
            </div>

        </div>
        
        <div>
            Meeting Duration: {{timerTotal|minutes}}  
            <button ng-click="stopAgendaRunning()"><i class="fa fa-clock-o"></i> Stop</button>
        </div>

        
        <div class="guideVocal" ng-hide="getSims().length > 0">
          No minutes to show . . .
        </div>
      </div>
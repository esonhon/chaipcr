angular.module("canvasApp").service('stepHoldTimeService', [
    'editMode',
    'TimeService',
    'ExperimentLoader',
    'alerts',
    function(editMode, TimeService, ExperimentLoader, alerts) {

        this.formatHoldTime = function(hold_time) {

            return TimeService.newTimeFormatting(hold_time);
        };

        this.ifLastStep = function(step) {

            return step.parentStage.nextStage === null && step.nextStep === null;
        };

        this.isCyclingStage = function(step) {
            return step.parentStage.model.stage_type == 'cycling';
        };

        // Defrag this method.. 
        this.postEdit = function($scope, parent, textObject) {

            // There is some issues for, saving new hold_time for infinite hold, make sure uts corrected when new design comes.
            editMode.holdActive = false;
            editMode.currentActiveHold = null;
            var previousHoldTime = Number($scope.step.hold_time);
            var newHoldTime = Number(TimeService.convertToSeconds(textObject.text));

            if(! isNaN(newHoldTime) && (newHoldTime !== previousHoldTime)) { //Should unify this with step-hold-time-directives
                if(newHoldTime < 0) {
                    alerts.showMessage(alerts.noNegativeHold, $scope);
                } else if(newHoldTime === 0) {
                    this.manageZeroHoldTime($scope, parent, newHoldTime, previousHoldTime);
                } else if(newHoldTime >= 7200 && $scope.step.temperature < 20) {
                    alerts.showMessage(alerts.holdLess20DurationWarning, $scope);
                    $scope.step.hold_time = previousHoldTime;
                } else {
                    $scope.step.hold_time = newHoldTime;
                    this.saveHoldTime($scope);
                }
            }

            parent.model.hold_time = $scope.step.hold_time;
            parent.createNewStepDataGroup();            
            parent.canvas.renderAll();

        };

        this.manageZeroHoldTime = function($scope, parent, newHoldTime, previousHoldTime) {
            if($scope.step.temperature < 20){
                alerts.showMessage(alerts.holdLess20DurationZeroWarning, $scope);
                $scope.step.hold_time = previousHoldTime;
            } else if(this.ifLastStep(parent.parent) && !this.isCyclingStage(parent.parent) && ! $scope.step.collect_data) {
                $scope.step.hold_time = newHoldTime;
                parent.doThingsForLast(newHoldTime, previousHoldTime);
                this.saveHoldTime($scope);
            } else {
                alerts.showMessage(alerts.holdDurationZeroWarning, $scope);
                $scope.step.hold_time = previousHoldTime;
            }
        };

        this.saveHoldTime = function($scope) {

            ExperimentLoader.changeHoldDuration($scope).then(function(data) {
                console.log("saved", data);
            });
        };
    }
]);
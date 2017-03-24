###
Chai PCR - Software platform for Open qPCR and Chai's Real-Time PCR instruments.
For more information visit http://www.chaibio.com

Copyright 2016 Chai Biotechnologies Inc. <info@chaibio.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
###
window.ChaiBioTech.ngApp.controller 'AmplificationChartCtrl', [
  '$scope'
  '$stateParams'
  'Experiment'
  'AmplificationChartHelper'
  'expName'
  '$interval'
  'Device'
  '$timeout'
  '$rootScope'
  ($scope, $stateParams, Experiment, helper, expName, $interval, Device, $timeout, $rootScope ) ->

    Device.isDualChannel().then (is_dual_channel) ->
      $scope.is_dual_channel = is_dual_channel

      hasInit = false
      $scope.chartConfig = helper.chartConfig()
      $scope.chartConfig.channels = if is_dual_channel then 2 else 1
      $scope.chartConfig.axes.x.max = $stateParams.max_cycle || 1
      $scope.amplification_data = helper.paddData()
      $scope.COLORS = helper.COLORS
      AMPLI_DATA_CACHE = null
      retryInterval = null
      $scope.baseline_subtraction = true
      $scope.curve_type = 'linear'
      $scope.color_by = 'well'
      $scope.retrying = false
      $scope.retry = 0
      $scope.fetching = false
      $scope.channel_1 = true
      $scope.channel_2 = if is_dual_channel then true else false
      $scope.ampli_zoom = 0
      $scope.showOptions = true
      $scope.isError = false
      $scope.method = {name: 'Cy0'}
      $scope.minFl = {name: 'Min. Flouresence', desciption:'This is a test description', value:null}
      $scope.minCq = {name: 'Min. Cq', desciption:'This is a test description', value:null}
      $scope.minDf = {name: 'Min. dF/dC', desciption:'This is a test description', value:null}
      $scope.minD2f = {name: 'Min. d2F/dC', desciption:'This is a test description', value:null}
      $scope.baseline_sub = 'auto'
      $scope.cyclesFrom = null
      $scope.cyclesTo = null
      $scope.hoverName = 'Min. Flouresence'
      $scope.hoverDescription = 'This is a test description'
      $scope.samples = []

      modal = document.getElementById('myModal')
      span = document.getElementsByClassName("close")[0]

      $scope.$on 'expName:Updated', ->
        $scope.experiment?.name = expName.name

      $scope.openOptionsModal = ->
        #$scope.showOptions = true
        #Device.openOptionsModal()
        modal.style.display = "block"

      $scope.close = ->
        modal.style.display = "none"

      $scope.check = ->
        if $scope.minCq.value
          if $scope.minCq.value > 0
            $scope.close()
            if $scope.baseline_sub == 'auto'
              $scope.baseline_cycle_bounds = null
            else
              $scope.baseline_cycle_bounds = [parseInt($scope.cyclesFrom), parseInt($scope.cyclesTo)]
            Experiment.updateAmplificationOptions($stateParams.id,{'cq_method':$scope.method.name,'min_fluorescence': parseInt($scope.minFl.value), 'min_reliable_cycle': parseInt($scope.minCq.value), 'min_d1': parseInt($scope.minDf.value), 'min_d2': parseInt($scope.minD2f.value), 'baseline_cycle_bounds': $scope.baseline_cycle_bounds }).then (resp) ->
              $scope.amplification_data = helper.paddData()
              $scope.hasData = false
              fetchFluorescenceData()
          else
            $scope.hoverName = 'Error'
            $scope.hoverDescription = 'Min Cq should be greater than equal to 1'
            $scope.hoverOn = true
        else
          if $scope.baseline_sub == 'auto'
            $scope.baseline_cycle_bounds = null
          else
            $scope.baseline_cycle_bounds = [$scope.cyclesFrom, $scope.cyclesTo]
          Experiment.updateAmplificationOptions($stateParams.id,{'amplification_option':{'cq_method':$scope.method.name,'min_fluorescence': $scope.minFl.value, 'min_reliable_cycle': $scope.minCq.value, 'min_d1': $scope.minDf.value, 'min_d2': $scope.minD2f.value, 'baseline_cycle_bounds': $scope.baseline_cycle_bounds }}).then (resp) ->
            $scope.amplification_data = helper.paddData()
            $scope.hasData = false
            fetchFluorescenceData()

      $scope.hover = (model) ->
        $scope.hoverName = model.name
        $scope.hoverDescription = model.desciption
        $scope.hoverOn = true

      $scope.hoverLeave = ->
        $scope.hoverOn = false

      Experiment.getAmplificationOptions($stateParams.id).then (resp) ->
        console.log(resp.data)
        $scope.method.name = resp.data.amplification_option.cq_method
        $scope.minFl.value = resp.data.amplification_option.min_fluorescence
        $scope.minCq.value = resp.data.amplification_option.min_reliable_cycle
        $scope.minDf.value = resp.data.amplification_option.min_d1
        $scope.minD2f.value = resp.data.amplification_option.min_d2
        if resp.data.amplification_option.baseline_cycle_bounds is null
          $scope.baseline_sub = 'auto'
        else
          $scope.baseline_sub = 'cycles'

      $scope.setOptions = ->

      $scope.updateSampleName = (well_num, name) ->
        Experiment.updateWell($stateParams.id, well_num + 1, {'well_type':'sample','sample_name':name})

      Experiment.getWells($stateParams.id).then (resp) ->
        for i in [0...16]
          $scope.samples[i] = resp.data[i].well.sample_name

      Experiment.get(id: $stateParams.id).then (data) ->
        maxCycle = helper.getMaxExperimentCycle(data.experiment)
        console.log "max cycle: #{maxCycle}"
        $scope.chartConfig.axes.x.max = maxCycle
        $scope.experiment = data.experiment

      $scope.$on 'status:data:updated', (e, data, oldData) ->
        return if !data
        return if !data.experiment_controller
        $scope.statusData = data
        $scope.state = data.experiment_controller.machine.state
        $scope.thermal_state = data.experiment_controller.machine.thermal_state
        $scope.oldState = oldData?.experiment_controller?.machine?.state || 'NONE'
        $scope.isCurrentExp = parseInt(data.experiment_controller.experiment?.id) is parseInt($stateParams.id)
        if $scope.isCurrentExp is true
          $scope.enterState = $scope.isCurrentExp

      retry = ->
        $scope.retrying = true
        $scope.retry = 5
        retryInterval = $interval ->
          $scope.retry = $scope.retry - 1
          if $scope.retry is 0
            $interval.cancel(retryInterval)
            $scope.retrying = false
            $scope.error = null
            fetchFluorescenceData()
        , 1000

      fetchFluorescenceData = ->
        gofetch = true
        gofetch = false if $scope.fetching
        gofetch = false if $scope.$parent.chart isnt 'amplification'
        gofetch = false if $scope.retrying

        if gofetch
          hasInit = true
          $scope.fetching = true

          Experiment
          .getAmplificationData($stateParams.id)
          .then (resp) ->
            $scope.fetching = false
            $scope.error = null
            if (resp.status is 200 and resp.data?.partial and $scope.enterState) or (resp.status is 200 and !resp.data.partial)
              $scope.hasData = true
              $scope.amplification_data = helper.paddData()
            if resp.status is 200 and !resp.data.partial
              $rootScope.$broadcast 'complete'
            if (resp.data.steps?[0].amplification_data and resp.data.steps?[0].amplification_data?.length > 1 and $scope.enterState) or (resp.data.steps?[0].amplification_data and resp.data.steps?[0].amplification_data?.length > 1 and !resp.data.partial)
              $scope.chartConfig.axes.x.min = 1
              $scope.hasData = true
              data = resp.data.steps[0]
              data.amplification_data?.shift()
              data.cq?.shift()
              data.amplification_data = helper.neutralizeData(data.amplification_data, $scope.is_dual_channel)

              AMPLI_DATA_CACHE = angular.copy data
              $scope.amplification_data = data.amplification_data
              updateButtonCts()
              updateSeries()

            if ((resp.data?.partial is true) or (resp.status is 202)) and !$scope.retrying
              retry()

          .catch (resp) ->
            console.log resp
            if resp.status is 500
              $scope.error = resp.statusText || 'Unknown error'
              console.log '500 error!!'
            $scope.fetching = false
            return if $scope.retrying
            retry()
        else
          retry()

      updateButtonCts = ->
        for well_i in [0..15] by 1
          cts = _.filter AMPLI_DATA_CACHE.cq, (ct) ->
            ct[1] is well_i+1
          $scope.wellButtons["well_#{well_i}"].ct = [cts[0][2]]
          $scope.wellButtons["well_#{well_i}"].ct.push cts[1][2] if cts[1]

      updateSeries = (buttons) ->
        buttons = buttons || $scope.wellButtons || {}
        $scope.chartConfig.series = []
        subtraction_type = if $scope.baseline_subtraction then 'baseline' else 'background'
        channel_count = if $scope.is_dual_channel then 2 else 1
        channel_end = if $scope.channel_1 && $scope.channel_2 then 2 else if $scope.channel_1 && !$scope.channel_2 then 1 else if !$scope.channel_1 && $scope.channel_2 then 2
        channel_start = if $scope.channel_1 && $scope.channel_2 then 1 else if $scope.channel_1 && !$scope.channel_2 then 1 else if !$scope.channel_1 && $scope.channel_2 then 2
        for ch_i in [channel_start..channel_end] by 1
          for i in [0..15] by 1
            if buttons["well_#{i}"]?.selected
              $scope.chartConfig.series.push
                dataset: "channel_#{ch_i}"
                x: 'cycle_num'
                y: "well_#{i}_#{subtraction_type}#{if $scope.curve_type is 'log' then '_log' else ''}"
                color: if ($scope.color_by is 'well') then buttons["well_#{i}"].color else (if ch_i is 1 then '#00AEEF' else '#8FC742')
                cq: $scope.wellButtons["well_#{i}"]?.ct
                well: i
                channel: ch_i

      $scope.onZoom = (transform, w, h, scale_extent) ->
        $scope.ampli_scroll = {
          value: Math.abs(transform.x/(w*transform.k - w))
          width: w/(w*transform.k)
        }
        $scope.ampli_zoom = (transform.k - 1)/ (scale_extent-1)


      $scope.$watch 'baseline_subtraction', (val) ->
        updateSeries()

      $scope.$watch 'channel_1', (val) ->
        updateSeries()

      $scope.$watch 'channel_2', (val) ->
        updateSeries()

      $scope.$watch 'curve_type', (type) ->
        $scope.chartConfig.axes.y.scale = type
        updateSeries()

      $scope.$watchCollection 'wellButtons', ->
        updateSeries()

      $scope.$watch ->
        $scope.$parent.chart
      , (chart) ->
        if chart is 'amplification'
          fetchFluorescenceData()

          $timeout ->
            $scope.showAmpliChart = true
          , 1000
        else
          $scope.showAmpliChart = false

      $scope.$on '$destroy', ->
        $interval.cancel(retryInterval) if retryInterval


]

angular.module('ChaiBioTech').directive('wifiLock', [
  function() {
    return {
      templateUrl: 'app/views/directives/wifi-lock.html',
      restric: 'E',
      //replace: true,

      link: function(scope, element, attr) {
        //console.log("voila");
      }
    };
  }
]);

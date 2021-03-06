describe("Testing TimeService", function() {

  var _TimeService, _$rootScope;

  beforeEach(function() {

    module('ChaiBioTech', function($provide) {
      mockCommonServices($provide);
    });

    inject(function($injector) {

      _TimeService = $injector.get('TimeService');
      _$rootScope = $injector.get('$rootScope');
    });


  });

  it("It should test convertToSeconds method", function() {

    var timeString = "1:2:3";
    var rVal = _TimeService.convertToSeconds(timeString);
    expect(rVal).toEqual(3723);
  });

  it("It should test convertToSeconds method, when second is invalid", function() {

    var timeString = "1:2:xx";
    var rVal = _TimeService.convertToSeconds(timeString);
    expect(rVal).toEqual(false);
  });

  it("It should test convertToSeconds method, when minute is invalid", function() {

    var timeString = "1:xx:3";
    var rVal = _TimeService.convertToSeconds(timeString);
    expect(rVal).toEqual(false);
  });

  it("It should test convertToSeconds method, when hour is invalid", function() {

    var timeString = "xx:2:3";
    var rVal = _TimeService.convertToSeconds(timeString);
    expect(rVal).toEqual(false);
  });

  it("It should test convertToSeconds method, when time is invalid", function() {

    var timeString = "::";
    var rVal = _TimeService.convertToSeconds(timeString);
    expect(rVal).toEqual(false);
  });

  it("It should test convertToSeconds method, when only seconds provided", function() {

    var timeString = "100";
    var rVal = _TimeService.convertToSeconds(timeString);
    expect(rVal).toEqual("100");
  });

  it("It should test convertToSeconds method, when non-digit is provided", function() {

    var timeString = "1xx";
    spyOn(_$rootScope, "$broadcast");
    var rVal = _TimeService.convertToSeconds(timeString);
    expect(_$rootScope.$broadcast).toHaveBeenCalled();
  });

  it("It should test newTimeFormatting, when a negative value is passed", function() {

        var reading = -4000;
        var retVal = _TimeService.newTimeFormatting(reading);
        expect(retVal).toEqual("-1:06:40");
    });

    it("It should test newTimeFormatting, when 3600 is passed", function() {

        var reading = 4000;
        var retVal = _TimeService.newTimeFormatting(reading);
        expect(retVal).toEqual("1:06:40");
    });

    it("It should test newTimeFormatting, when 3600 is passed", function() {

        var reading = 3600;
        var retVal = _TimeService.newTimeFormatting(reading);
        expect(retVal).toEqual("1:00:00");
    });

    it("It should test newTimeFormatting method", function() {

        var reading = 100;
        var retVal = _TimeService.newTimeFormatting(reading);
        expect(retVal).toEqual("01:40");
    });

    it("It should test timeFormating method, when method return minute value that is less than 10", function() {

        var reading = -66;
        var retVal = _TimeService.timeFormating(reading);
        expect(retVal).toEqual("-01:06");
    });

    it("It should test timeFormating method, when a negative value is sent", function() {

        var reading = -100;
        var retVal = _TimeService.timeFormating(reading);
        expect(retVal).toEqual("-01:40");
    });
});

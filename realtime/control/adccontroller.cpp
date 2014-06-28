#include "pcrincludes.h"
#include "utilincludes.h"
#include "boostincludes.h"

#include "ltc2444.h"
#include "adcconsumer.h"
#include "adccontroller.h"

using namespace std;

////////////////////////////////////////////////////////////////////////////////
// Class ADCController
ADCController::ADCController(std::vector<std::shared_ptr<ADCConsumer>> consumers, unsigned int csPinNumber, SPIPort spiPort, unsigned int busyPinNumber):
    _consumers {consumers},
    _currentChannel {0} {

    _ltc2444 = make_shared<LTC2444>(csPinNumber, std::move(spiPort), busyPinNumber);
    _ltc2444->setup(0x4, false);

    //start first read
    _ltc2444->readADC(0, true);
}

ADCController::~ADCController() {
}

void ADCController::process() {
    if (_ltc2444->busy())
        return;

    //used for testing ADC speed
    //cout << boost::posix_time::microsec_clock::local_time() << endl;

    auto consumer = _consumers.at(_currentChannel);
    _currentChannel = (_currentChannel + 1) % _consumers.size();
    uint32_t value = _ltc2444->readADC(_currentChannel, true);

    consumer->setADCValue(value);
}

int ADCController::consumerChannel(const ADCConsumer *consumer) const {
    for (size_t i = 0; i < _consumers.size(); ++i) {
        if (_consumers.at(0).get() == consumer)
            return i;
    }

    return -1;
}

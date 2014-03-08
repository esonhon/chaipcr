#ifndef _QPCRSERVER_H_
#define _QPCRSERVER_H_

#include <Poco/Util/ServerApplication.h>

class IControl;

// Class QPCRServer
class QPCRApplication: public Poco::Util::ServerApplication
{
public:
    inline bool isWorking() const {return workState.load();}
    inline void close() {workState = false;}

protected:
	//from ServerApplication
    void initialize(Poco::Util::Application &self);
    int main(const std::vector<std::string> &args);

    //port accessors
    //inline SPIPort& spiPort0() { return *spiPort0_; }
    //inline GPIO& spiPort0DataInSensePin() { return *spiPort0DataInSensePin_; }

private:
    std::vector<std::shared_ptr<IControl>> controlUnits;

    std::atomic<bool> workState;

    //ports
    //SPIPort *spiPort0_;
    //GPIO *spiPort0DataInSensePin_;

};

#endif

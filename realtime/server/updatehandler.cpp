#include "updatehandler.h"
#include "qpcrapplication.h"
#include "updatemanager.h"

UpdateHandler::UpdateHandler(OperationType type)
{
    _type = type;
}

void UpdateHandler::processData(const boost::property_tree::ptree &requestPt, boost::property_tree::ptree &responsePt)
{
    std::shared_ptr<UpdateManager> updateManager = qpcrApp.updateManager();

    switch (_type)
    {
    case CheckUpdate:
        if (updateManager->checkUpdates())
        {
            UpdateManager::UpdateState state = updateManager->updateState();

            if (state != UpdateManager::Unknown)
            {
                switch (state)
                {
                case UpdateManager::Unavailable:
                    responsePt.put("device.update_available", "unavailable");
                    break;

                case UpdateManager::Available:
                    responsePt.put("device.update_available", "available");
                    break;

                case UpdateManager::Downloading:
                    responsePt.put("device.update_available", "downloading");
                    break;

                case UpdateManager::Updating:
                    responsePt.put("device.update_available", "updating");
                    break;

                default:
                    responsePt.put("device.update_available", "unknown");
                    break;
                }
            }
            else
            {
                setStatus(Poco::Net::HTTPResponse::HTTP_BAD_GATEWAY);
                setErrorString("Error");
            }
        }
        else
        {
            setStatus(Poco::Net::HTTPResponse::HTTP_GATEWAY_TIMEOUT);
            setErrorString("Timeout");
        }

        break;

    default:
        setStatus(Poco::Net::HTTPResponse::HTTP_BAD_REQUEST);
        setErrorString("Unknown opeation type");

        JSONHandler::processData(requestPt, responsePt);

        break;
    }
}

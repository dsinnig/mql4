//+------------------------------------------------------------------+
//|                LowestLowReceivedEstablishingEligibilityRange.mq4 |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

enum ErrorType {
   NO_ERROR,
   RETRIABLE_ERROR,
   NON_RETRIABLE_ERROR
};


class ErrorManager {
public:
   static int analzeAndProcessResult();
};

static int ErrorManager::analzeAndProcessResult() {
   int result=GetLastError();
   switch(result) {
      //No Error
      case 0: return(NO_ERROR);
      // Not crucial errors                  
      case  4:    Alert("Trade server is busy");
                  Sleep(3000);
                  return(RETRIABLE_ERROR);
      case 135:   Alert("Price changed. Refreshing Rates");
                  RefreshRates();
                  return(RETRIABLE_ERROR);
      case 136:   Alert("No prices. Refreshing Rates");
                  while(RefreshRates()==false)
                  Sleep(1);
                  return(RETRIABLE_ERROR);
      case 137:   Alert("Broker is busy");
                  Sleep(3000);
                  return(RefreshRates());
      case 146:   Alert("Trading subsystem is busy.");
                  Sleep(500);
                  return(RETRIABLE_ERROR);
      // Critical errors      
      case  2:    Alert("Common error.");
                  return(NON_RETRIABLE_ERROR);
      case  5:    Alert("Old terminal version.");
                  return(NON_RETRIABLE_ERROR);
      case 64:    Alert("Account blocked.");
                  return(NON_RETRIABLE_ERROR);
      case 133:   Alert("Trading forbidden.");
                  return(NON_RETRIABLE_ERROR);
      case 134:   Alert("Not enough money to execute operation.");
                  return(NON_RETRIABLE_ERROR);
      default:    Alert("Unknown error, error code: ",result);
                  return(NON_RETRIABLE_ERROR);
   } //end of switch
}

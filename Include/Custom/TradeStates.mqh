//+------------------------------------------------------------------+
//|                                                  TradeStates.mqh |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property strict

//forward declarations
class Trade;
class StopBuyOrderOpened;
class TradeClosed;

enum ErrorType {
   NO_ERROR, 
   RETRIABLE_ERROR, 
   NON_RETRIABLE_ERROR
};

class TradeState {
public: 
   void update (Trade* context) {
      Print("Abstract method - should never be called");
   }
};

class LowestLowReceivedWaiting10MoreBars : public TradeState {
public: 
   LowestLowReceivedWaiting10MoreBars() {
      this.barsElapsedSinceLowestLow = 0;
      this.entryTime = Time[0];
      this._10minHigh = -1;
      this._10minLow = 99999;
   }
   
   void update (Trade* context) {
      if (Close[0] < _10minLow) _10minLow = Close[0];
      if (Close[0] > _10minHigh) _10minHigh = Close[0];
      
      if (Time[0] - entryTime >= 60*10) {
         if ((_10minHigh - _10minLow) > 0.1 * context.getATR()) {
            context.setState(new TradeClosed());
            delete GetPointer(this);
         } 
         else {
            int ticket = OrderSend(Symbol(), OP_BUYSTOP, 1, _10minHigh + 0.00020, 0, _10minLow - 0.00020, 0, "10% of ATR", 0, 0, clrBlue);
            int result = ErrorManager::analzeAndProcessResult();
            if (result == NO_ERROR) {
               context.setOrderTicket(result);          
               context.setState(new StopBuyOrderOpened());
               Print ("BuyStop order placed @", _10minHigh + 0.00020);
               delete GetPointer(this);
            }
            if ((result == RETRIABLE_ERROR) && (ticket == -1)) {
               Print ("Retrying...");
            }
            
            if ((ticket == -1) && (RETRIABLE_ERROR || NON_RETRIABLE_ERROR)) {
               Print ("Error ocured but order is still open...continue with trade...");
               context.setOrderTicket(result);          
               context.setState(new StopBuyOrderOpened());
               delete GetPointer(this);
            }
            
            if ((result == NON_RETRIABLE_ERROR) && (ticket == -1)) {
               Print ("Close trade");
               context.setState(new TradeClosed());
               delete GetPointer(this);
            }
                     
         }
      }
   }
private: 
   int barsElapsedSinceLowestLow;
   datetime entryTime;
   double _10minLow;
   double _10minHigh;
};

class TradeClosed : public TradeState {
public:    
   void update (Trade* context) {
   //don't do anything    
   }
};


class StopBuyOrderOpened : public TradeState {
public: 
   void update(Trade* context) {
      //check if filled
      
      
      
   }

};


class Trade {
public: 
   Trade(TradeState* initialState, double anATR) {
      this.state = initialState;
      this.orderTicket = -1;
      this.atr = anATR;
   }
   
   void update() {
      state.update(GetPointer(this));
   }
   void setState(TradeState* aState) {
      this.state = aState;
   }
   double getATR() const {
      return atr;
   }
   void setOrderTicket(int aTicket) {
      this.orderTicket = aTicket;
   
   }

private: 
   TradeState* state;
   double atr;
   int orderTicket;
};




class ErrorManager {
public: 
   static int analzeAndProcessResult() {
      int result = GetLastError();
      switch (result) {
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
      default:    Alert("Unknown error, error code: ", result);
                  return(NON_RETRIABLE_ERROR);
                  
      } //end of switch
   
   }
};


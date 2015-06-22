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
class BuyOrderFilled;

enum ErrorType {
   NO_ERROR, 
   RETRIABLE_ERROR, 
   NON_RETRIABLE_ERROR
};

class TradeState {
public: 
   TradeState(Trade* aContext) {
      this.context = aContext;
   }
   virtual void update () {
      Print("Abstract method - should never be called");
   }
protected: 
   Trade* context;


};

class LowestLowReceivedWaitingEstablishingTradingChannel : public TradeState {
public: 
   LowestLowReceivedWaitingEstablishingTradingChannel(Trade* aContext):TradeState(aContext) {
      this.barsElapsedSinceLowestLow = 0;
      this.entryTime = Time[0];
      this.rangeHigh = -1;
      this.rangeLow = 99999;
      
      Print ("ID: ", context.getId(), " Lowest Low Received Waiting For Establishing Trading Channel");
      
   }
   
   virtual void update () {
      if (Low[0] < rangeLow) rangeLow = Low[0];
      if (High[0] > rangeHigh) rangeHigh = High[0];
      
      if (Time[0] - entryTime >= 60*(context.getLengthIn1MBarsOfWaitingPeriod() + 1)) {
         if ((rangeHigh - rangeLow) > ((context.getMaxTollarableATRPercentageForStopOrder() / 100.00) * context.getATR()) ) {
            //Print ("MaxPer: ", context.getMaxTollarableATRPercentageForStopOrder());
            Print ("Range high: ", rangeHigh, " Range low: ", rangeLow);
            string reason = "Range too big for (" + DoubleToStr(rangeHigh - rangeLow) + " - " + IntegerToString ((int) ((rangeHigh - rangeLow) * 100000)) + " micro pips)";
            
            
            context.setState(new TradeClosed(context, reason));
            delete GetPointer(this);
         } 
         else {
            Print ("Range high: ", rangeHigh, " Range low: ", rangeLow, " Range: ", int ((rangeHigh - rangeLow) * 100000));
            //Print ("Trying to open order with: Entry: ", NormalizeDouble(minHigh + 0.00020, Digits), "Stop Loss: ", NormalizeDouble(minLow - 0.00020, Digits));
            
            int ticket = OrderSend(Symbol(), OP_BUYSTOP, 1, NormalizeDouble(rangeHigh + 0.00020, Digits), 4, NormalizeDouble(rangeLow - 0.00020, Digits), 0, "BuyStopOrder", 0, 0, clrBlue);
            int result = ErrorManager::analzeAndProcessResult();
            if (result == NO_ERROR) {
               context.setOrderTicket(ticket);          
               context.setStopLoss(NormalizeDouble(rangeLow - 0.00020, Digits));
               context.setPlannedEntry(NormalizeDouble(rangeHigh + 0.00020, Digits));
               //Parametrize the 4
               context.setInitialProfitTarget (NormalizeDouble(context.getPlannedEntry() + ((context.getPlannedEntry() - context.getStopLoss()) * (context.getPercentageOfATRForMinProfitTarget() / 10)), Digits));
               context.setState(new StopBuyOrderOpened(context, rangeLow));
               //context.setState(new TradeClosed());
               
               Print ("BuyStop order placed @", rangeHigh + 0.00020, " Ticket number: ", ticket);
               delete GetPointer(this);
            }
            if ((result == RETRIABLE_ERROR) && (ticket == -1)) {
               Print ("Retrying...");
            }
            
            if ((ticket == -1) && (RETRIABLE_ERROR || NON_RETRIABLE_ERROR)) {
               Print ("Error ocured but order is still open...continue with trade...");
               context.setOrderTicket(result);          
               context.setState(new StopBuyOrderOpened(context, rangeLow));
               delete GetPointer(this);
            }
            
            if ((result == NON_RETRIABLE_ERROR) && (ticket == -1)) {
               Print ("Close trade");
               context.setState(new TradeClosed(context, "Fatal error occured"));
               delete GetPointer(this);
            }
                     
         }
      }
   }
private: 
   int barsElapsedSinceLowestLow;
   datetime entryTime;
   double rangeLow;
   double rangeHigh;
};


class HighestHighReceivedWaitingEstablishingTradingChannel : public TradeState {
public: 
   HighestHighReceivedWaitingEstablishingTradingChannel(Trade* aContext):TradeState(aContext) {
      this.barsElapsedSinceLowestLow = 0;
      this.entryTime = Time[0];
      this.rangeHigh = -1;
      this.rangeLow = 99999;
      
      Print ("ID: ", context.getId(), " Highest High Received Waiting For Establishing Trading Channel");
      
   }
   
   virtual void update () {
      if (Low[0] < rangeLow) rangeLow = Low[0];
      if (High[0] > rangeHigh) rangeHigh = High[0];
      
      if (Time[0] - entryTime >= 60*(context.getLengthIn1MBarsOfWaitingPeriod() + 1)) {
         if ((rangeHigh - rangeLow) > ((context.getMaxTollarableATRPercentageForStopOrder() / 100.00) * context.getATR()) ) {
            //Print ("MaxPer: ", context.getMaxTollarableATRPercentageForStopOrder());
            Print ("Range high: ", rangeHigh, " Range low: ", rangeLow);
            string reason = "Range too big (" + DoubleToStr(rangeHigh - rangeLow) + " - " + IntegerToString ((int) ((rangeHigh - rangeLow) * 100000)) + " micro pips)";
            
            
            context.setState(new TradeClosed(context, reason));
            delete GetPointer(this);
         } 
         else {
            Print ("Range high: ", rangeHigh, " Range low: ", rangeLow, " Range: ", int ((rangeHigh - rangeLow) * 100000));
            //Print ("Trying to open order with: Entry: ", NormalizeDouble(minHigh + 0.00020, Digits), "Stop Loss: ", NormalizeDouble(minLow - 0.00020, Digits));
            
            int ticket = OrderSend(Symbol(), OP_SELLSTOP, 1, NormalizeDouble(rangeLow - 0.00020, Digits), 4, NormalizeDouble(rangeHigh + 0.00020, Digits), 0, "SellStopOrder", 0, 0, clrBlue);
            int result = ErrorManager::analzeAndProcessResult();
            if (result == NO_ERROR) {
               context.setOrderTicket(ticket);          
               context.setStopLoss(NormalizeDouble(rangeHigh + 0.00020, Digits));
               context.setPlannedEntry(NormalizeDouble(rangeLow - 0.00020, Digits));
               //Parametrize the 4
               context.setInitialProfitTarget (NormalizeDouble(context.getPlannedEntry() - ((context.getStopLoss() - context.getPlannedEntry()) * (context.getPercentageOfATRForMinProfitTarget() / 10)), Digits));
               context.setState(new StopSellOrderOpened(context, rangeHigh));
               //context.setState(new TradeClosed());
               
               Print ("SellStop order placed @", rangeLow - 0.00020, " Ticket number: ", ticket);
               delete GetPointer(this);
            }
            if ((result == RETRIABLE_ERROR) && (ticket == -1)) {
               Print ("Retrying...");
            }
            
            if ((ticket == -1) && (RETRIABLE_ERROR || NON_RETRIABLE_ERROR)) {
               Print ("Error ocured but order is still open...continue with trade...");
               context.setOrderTicket(result);          
               context.setState(new StopBuyOrderOpened(context, rangeLow));
               delete GetPointer(this);
            }
            
            if ((result == NON_RETRIABLE_ERROR) && (ticket == -1)) {
               Print ("Close trade");
               context.setState(new TradeClosed(context, "Fatal error occured"));
               delete GetPointer(this);
            }
                     
         }
      }
   }
private: 
   int barsElapsedSinceLowestLow;
   datetime entryTime;
   double rangeLow;
   double rangeHigh;
};

class StopSellOrderOpened : public TradeState {
public: 
   StopSellOrderOpened(Trade* aContext, double aCancelLevel):TradeState(aContext) {
      this.cancelLevel = aCancelLevel;   
      Print("ID: ", context.getId(), " Stop Order Placed");
   }
   virtual void update() {
   
      if (Bid >= cancelLevel) {
         bool result = OrderDelete(context.getOrderTicket(),clrRed);
         ErrorManager::analzeAndProcessResult();
         //error checks missing
         context.setState(new TradeClosed(context, "Price went above 10min low"));
         delete GetPointer(this);
         return;
                   
      }
      
      
      if (OrderSelect(context.getOrderTicket(), SELECT_BY_TICKET, MODE_TRADES)) {
         if (OrderType() == OP_SELL) {
            context.setActualEntry(OrderOpenPrice());
            context.setState(new SellOrderFilledProfitTargetNotReached(context));
            delete GetPointer(this);
            return;
         }
      }
           
   }
private: 
   double cancelLevel;
};


class TradeClosed : public TradeState {
public:    
   TradeClosed(Trade* aContext, string aReason):TradeState(aContext) {
      this.reason = aReason;
      Print("ID: ", context.getId(), "Trade closed. Reason: ", reason);
   }
   virtual void update () {
      if (OrderSelect(context.getOrderTicket(), SELECT_BY_TICKET, MODE_TRADES)) {
         if (OrderType() == OP_BUY) {
            //int result = OrderClose(context.getOrderTicket(), 1, Ask - 0.00020, 10, clrRed);
            ErrorManager::analzeAndProcessResult();
         }
         if (OrderType() == OP_SELL) {
            //int result = OrderClose(context.getOrderTicket(), 1, Bid + 0.00020, 10, clrRed);
            ErrorManager::analzeAndProcessResult();
         }
         if ((OrderType() == OP_BUYLIMIT) || (OrderType() == OP_BUYSTOP) || (OrderType() == OP_SELLLIMIT) || (OrderType() == OP_SELLSTOP)) {
            //bool result = OrderDelete(context.getOrderTicket(),clrRed);
            ErrorManager::analzeAndProcessResult();       
         }  
       }
   }
   private: 
      string reason;
};


class StopBuyOrderOpened : public TradeState {
public: 
   StopBuyOrderOpened(Trade* aContext, double aCancelLevel):TradeState(aContext) {
      this.cancelLevel = aCancelLevel;   
      Print("ID: ", context.getId(), " Stop Order Placed");
   }
   virtual void update() {
   
      if (Ask <= cancelLevel) {
         bool result = OrderDelete(context.getOrderTicket(),clrRed);
         ErrorManager::analzeAndProcessResult();
         //error checks missing
         context.setState(new TradeClosed(context, "Price went below 10min low"));
         delete GetPointer(this);
         return;
                   
      }
      
      
      if (OrderSelect(context.getOrderTicket(), SELECT_BY_TICKET, MODE_TRADES)) {
         if (OrderType() == OP_BUY) {
            context.setActualEntry(OrderOpenPrice());
            context.setState(new BuyOrderFilledProfitTargetNotReached(context));
            delete GetPointer(this);
            return;
         }
      }
      
   
            
   }
private: 
   double cancelLevel;
};

class BuyOrderFilledProfitTargetNotReached : public TradeState {
public: 
   BuyOrderFilledProfitTargetNotReached(Trade* aContext):TradeState(aContext){
      Print("ID: ",context.getId(), " Order filled");
      Print("ID: ", context.getId(), " Planned entry: ", context.getPlannedEntry(), " Actual entry: ", context.getActualEntry(), " Stop loss: ", context.getStopLoss(), " Min profit target: ", context.getInitialProfitTarget());
   };
   virtual void update() {
      if (Bid > context.getInitialProfitTarget()) {
         context.setState(new ProfitTargetReachedLookForInitialHighestHigh(context, TimeCurrent()));
         delete GetPointer(this);   
      }   
   }

};

class SellOrderFilledProfitTargetNotReached : public TradeState {
public: 
   SellOrderFilledProfitTargetNotReached(Trade* aContext):TradeState(aContext){
      Print("ID: ",context.getId(), " Order filled");
      Print("ID: ", context.getId(), " Planned entry: ", context.getPlannedEntry(), " Actual entry: ", context.getActualEntry(), " Stop loss: ", context.getStopLoss(), " Min profit target: ", context.getInitialProfitTarget());
   };
   virtual void update() {
      if (Ask < context.getInitialProfitTarget()) {
         context.setState(new ProfitTargetReachedLookForInitialLowestLow(context, TimeCurrent()));
         delete GetPointer(this);   
      }   
   }
};


class ProfitTargetReachedLookForInitialLowestLow : public TradeState {
public: 
   ProfitTargetReachedLookForInitialLowestLow(Trade* aContext, datetime _timeWhenProfitTargetWasReached):TradeState(aContext){
      Print("ID: ",context.getId(), " Profit target reached - looking for initial lowest low", " Time: ", TimeCurrent());
      currentLL = 99999;
      this.timeWhenProfitTargetWasReached = _timeWhenProfitTargetWasReached;
      
   };
   virtual void update() {
      //check if order closed
      bool rs = OrderSelect(context.getOrderTicket(),SELECT_BY_TICKET);
      if (!rs) {
         Print ("Order not found");
         return;
      } 
      if (OrderCloseTime() != 0) {
         context.setState(new TradeClosed(context, "Stop loss triggered"));
         delete GetPointer(this);
         return;
      }
      
      //order still open...
      
      //if still in same bar that made the profit target -> wait for next bar. 
      if ((TimeMinute(TimeCurrent()) == TimeMinute(timeWhenProfitTargetWasReached)) &&
          (TimeHour(TimeCurrent()) == TimeHour(timeWhenProfitTargetWasReached)) &&
          (TimeDay(TimeCurrent()) == TimeDay(timeWhenProfitTargetWasReached))){return;}
      
      if (isNewBar()) {
         if (currentLL == 99999) {
            currentLL = Low[1];
            barStartTimeOfCurrentLL = Time[1]; 
            Print("ID: ", context.getId(), " Initial low established at: ", currentLL, " Bar start: ", barStartTimeOfCurrentLL, " Time: ", TimeCurrent());
         }
      
         if (currentLL != 99999) {
            if (Low[1] < currentLL) {
               //save info rel. to previous HH
               double previousLL = currentLL;
               datetime barStartTimeOfPreviousLL = barStartTimeOfCurrentLL;
               //set new info
               currentLL = Low[1];
               barStartTimeOfCurrentLL = Time[1];
            
               Print("ID: ", context.getId(), " Found new low at: ", currentLL, " Time: ", barStartTimeOfCurrentLL);
            
               //look if stop loss can be adjusted
               int shiftOfPreviousLL = iBarShift(Symbol(), PERIOD_M1, barStartTimeOfPreviousLL, true); 
               if (shiftOfPreviousLL == -1) {
                  Print("Could not fine start time of previous LL"); 
                  return;   
               }
               int i = shiftOfPreviousLL-1; //exclude bar that made the previous HH
               bool upBarFound = false;
               double high = -1;
               while (i > 1) {
                  if (Open[i] < Close[i]) upBarFound = true;
                  if (High[i] > high) high = High[i];
                  i--;
               }
               if (!upBarFound || (high == -1)) {
                  Print ("Coninuation bar - Do not adjust stop loss");
                  return;
               }
               
               
               
               if (high != -1) {
                  Print ("High point between lows is: ", high);
               }
               
               if (upBarFound && (high + 0.00020 < context.getInitialProfitTarget()) && (high +0.00020 < context.getStopLoss())) {
                  //adjust stop loss
                  bool orderSelectResult = OrderSelect(context.getOrderTicket(),SELECT_BY_TICKET);
                  if (!orderSelectResult) {
                     Print ("Order not found");
                     return;
                  } 
                  bool res = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(high+0.00020, Digits), 0, clrBlue);
                  int result = ErrorManager::analzeAndProcessResult();
                  if (result == NO_ERROR) {
                     context.setStopLoss(NormalizeDouble(high+0.00020, Digits));
                     Print ("ID: ", context.getId(), "Stop loss adjusted to: :", NormalizeDouble(high+0.00020, Digits));
                  }
               }
               
               if (high + 0.00020 >= context.getInitialProfitTarget()) {
                  Print ("High + 20 micro pips: ", high + 0.00020, " is above initial profit target of: ", context.getInitialProfitTarget(), " Do not adjust stop loss");
                  return;
               }
               
               if (high + 0.00020 > context.getStopLoss()) {
                  Print ("High + 20 micro pips: ", high + 0.00020, " is above previous stop loss: ", context.getStopLoss(), " Do not adjust stop loss");
                  return;
               }
            }         
         } 
      }          
   }
   
   
   
private:
   private: 
   datetime barStartTimeOfCurrentLL;
   double currentLL;
   datetime timeWhenProfitTargetWasReached;
   
   
   bool isNewBar()
      {
         static datetime lastbar = 0;
         datetime curbar = Time[0];
         if(lastbar!=curbar)
         {
            lastbar=curbar;
            return (true);
         }
         else
         {
            return(false);
         }
      }
};


class ProfitTargetReachedLookForInitialHighestHigh : public TradeState {
public: 
   ProfitTargetReachedLookForInitialHighestHigh(Trade* aContext, datetime _timeWhenProfitTargetWasReached):TradeState(aContext){
      Print("ID: ",context.getId(), " Profit target reached - looking for initial highest high", " Time: ", TimeCurrent());
      currentHH = 0;
      this.timeWhenProfitTargetWasReached = _timeWhenProfitTargetWasReached;
      
   };
   virtual void update() {
      //check if order closed
      bool rs = OrderSelect(context.getOrderTicket(),SELECT_BY_TICKET);
      if (!rs) {
         Print ("Order not found");
         return;
      } 
      if (OrderCloseTime() != 0) {
         context.setState(new TradeClosed(context, "Stop loss triggered"));
         delete GetPointer(this);
         return;
      }
      
      //order still open...
      
      //if still in the same minute that reached the target -> wait for next bar
      if ((TimeMinute(TimeCurrent()) == TimeMinute(timeWhenProfitTargetWasReached)) &&
          (TimeHour(TimeCurrent()) == TimeHour(timeWhenProfitTargetWasReached)) &&
          (TimeDay(TimeCurrent()) == TimeDay(timeWhenProfitTargetWasReached))){return;}
      
      if (isNewBar()) {
         if (currentHH == 0) {
            currentHH = High[1];
            barStartTimeOfCurrentHH = Time[1]; 
            Print("ID: ", context.getId(), " Initial high established at: ", currentHH, " Bar start: ", barStartTimeOfCurrentHH, " Time: ", TimeCurrent());
         }
      
         if (currentHH != 0) {
            if (High[1] > currentHH) {
               //save info rel. to previous HH
               double previousHH = currentHH;
               datetime barStartTimeOfPreviousHH = barStartTimeOfCurrentHH;
               //set new info
               currentHH = High[1];
               barStartTimeOfCurrentHH = Time[1];
            
               Print("ID: ", context.getId(), " Found new high at: ", currentHH, " Time: ", barStartTimeOfCurrentHH);
            
               //look if stop loss can be adjusted
               int shiftOfPreviousHH = iBarShift(Symbol(), PERIOD_M1, barStartTimeOfPreviousHH, true); 
               if (shiftOfPreviousHH == -1) {
                  Print("Could not fine start time of previous HH"); 
                  return;   
               }
               int i = shiftOfPreviousHH-1; //exclude bar that made the previous HH
               bool downBarFound = false;
               double low = 99999;
               while (i > 1) {
                  if (Open[i] > Close[i]) downBarFound = true;
                  if (Low[i] < low) low = Low[i];
                  i--;
               }
               if (!downBarFound || (low == 99999)) {
                  Print ("Coninuation bar - Do not adjust stop loss");
                  return;
               }
               
               
               
               if (low != 99999) {
                  Print ("Low point between highs is: ", low);
               }
               
               //factor in 20 micropips
               if (downBarFound && (low - 0.00020 > context.getInitialProfitTarget()) && (low -0.00020 > context.getStopLoss())) {
                  //adjust stop loss
                  bool orderSelectResult = OrderSelect(context.getOrderTicket(),SELECT_BY_TICKET);
                  if (!orderSelectResult) {
                     Print ("Order not found");
                     return;
                  } 
                  bool res = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(low-0.00020, Digits), 0, clrBlue);
                  int result = ErrorManager::analzeAndProcessResult();
                  if (result == NO_ERROR) {
                     context.setStopLoss(NormalizeDouble(low-0.00020, Digits));
                     Print ("ID: ", context.getId(), "Stop loss adjusted to: :", NormalizeDouble(low-0.00020, Digits));
                  }
               }
               
               if (low - 0.00020 <= context.getInitialProfitTarget()) {
                  Print ("Low - 20 micro pips: ", low - 0.00020, " is below initial profit target of: ", context.getInitialProfitTarget(), " Do not adjust stop loss");
                  return;
               }
               
               if (low -0.00020 < context.getStopLoss()) {
                  Print ("Low - 20 micro pips: ", low - 0.00020, " is below previous stop loss: ", context.getStopLoss(), " Do not adjust stop loss");
                  return;
               }
            }         
         } 
      }          
   }
   
   
   
private:
   private: 
   datetime barStartTimeOfCurrentHH;
   double currentHH;
   
   datetime timeWhenProfitTargetWasReached;
   
   
   bool isNewBar()
      {
         static datetime lastbar = 0;
         datetime curbar = Time[0];
         if(lastbar!=curbar)
         {
            lastbar=curbar;
            return (true);
         }
         else
         {
            return(false);
         }
      }
};


class Trade {
public: 
   Trade(double anATR, int _lengthIn1MBarsOfWaitingPeriod, double _maxTollarableATRPercentageForStopOrder, double _maxTollarableATRPercentageForLimitOrder, double _percentageOfATRForMinProfitTarget) {
      this.state = NULL;
      this.orderTicket = -1;
      this.atr = anATR;
      this.actualEntry = -1;
      this.initialProfitTarget = -1;
      this.plannedEntry = -1;
      this.stopLoss = -1;
      
      
     this.lengthIn1MBarsOfWaitingPeriod = _lengthIn1MBarsOfWaitingPeriod;
     this.percentageOfATRForMinProfitTarget = _percentageOfATRForMinProfitTarget;
     this.maxTollarableATRPercentageForStopOrder = _maxTollarableATRPercentageForStopOrder;
     this.maxTollarableATRPercentageForLimitOrder = _maxTollarableATRPercentageForLimitOrder;
     
      this.id = IntegerToString(TimeYear(TimeCurrent())) + 
                IntegerToString(TimeMonth(TimeCurrent())) + 
                IntegerToString(TimeDay(TimeCurrent())) + 
                IntegerToString(TimeHour(TimeCurrent())) + 
                IntegerToString(TimeMinute(TimeCurrent())) + 
                IntegerToString(TimeSeconds(TimeCurrent()));
      
      //this.id = TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);
      
  }
   ~Trade() {
      delete state;
   }
   
   void update() {
      if (state != NULL) 
         state.update();
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
   
   int getOrderTicket() const {
      return this.orderTicket;
   }
   
   string getId() const {
      return id;
   }
   
   void setPlannedEntry(double entry) {
      this.plannedEntry = entry;
   }
   
   double getPlannedEntry() const {
      return this.plannedEntry;
   }
   
   void setActualEntry(double entry) {
      this.actualEntry = entry;
   }
   
   double getActualEntry() const {
      return this.actualEntry;
   }
   
   void setStopLoss(double sL) {
      this.stopLoss = sL;
   }
   
   double getStopLoss() const {
      return this.stopLoss;
   }
   
   void setInitialProfitTarget(double target) {
      this.initialProfitTarget = target;
   }
   
   double getInitialProfitTarget() const {
      return this.initialProfitTarget;
   }

   int getLengthIn1MBarsOfWaitingPeriod() const {
      return this.lengthIn1MBarsOfWaitingPeriod;
   }
   
   double getMaxTollarableATRPercentageForStopOrder() const {
      return this.maxTollarableATRPercentageForStopOrder;
   }
   
   double getPercentageOfATRForMinProfitTarget() const {
      return percentageOfATRForMinProfitTarget;
   }
   
   double getMaxTollarableATRPercentageForLimitOrder() const {
      return this.maxTollarableATRPercentageForLimitOrder;
   }


private: 
   TradeState* state;
   double atr;
   int orderTicket;
   string id;
   double plannedEntry;
   double actualEntry;
   double stopLoss;
   double initialProfitTarget;
   
   int lengthIn1MBarsOfWaitingPeriod;
   double maxTollarableATRPercentageForStopOrder;
   double percentageOfATRForMinProfitTarget;
   double maxTollarableATRPercentageForLimitOrder;
   
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


//+------------------------------------------------------------------+
//|                                           StopBuyOrderOpened.mq4 |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "TradeState.mq4"
#include "ATRTrade.mq4"
#include "TradeClosed.mq4"
#include "BuyOrderFilledProfitTargetNotReached.mq4"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class StopBuyOrderOpened : public TradeState {
public:
   StopBuyOrderOpened(ATRTrade* aContext, double aCancelLevel);
   virtual void update(); 
     
private:
   double cancelLevel;
   ATRTrade* context; //hides conext in Trade
};

StopBuyOrderOpened::StopBuyOrderOpened(ATRTrade* aContext, double aCancelLevel) {
   this.cancelLevel=aCancelLevel;
   this.context = aContext;
}

void StopBuyOrderOpened::update() {
   if(Ask<=cancelLevel) {
      context.addLogEntry("Ask price went below cancel level. Attempting to delete order.", true);
      bool success=OrderDelete(context.getOrderTicket(),clrRed);
      if (success) {
         context.addLogEntry("Order deleted successfully", true);
         context.setState(new TradeClosed(context));
         delete GetPointer(this);
         return;
      } 
      else {
         context.addLogEntry("Order could not be deleted. Error code: " + IntegerToString(GetLastError()) + " Wil re-try at next tick.", true);
         return;
      }
   }
   
   if(OrderSelect(context.getOrderTicket(),SELECT_BY_TICKET,MODE_TRADES)) {
      if(OrderType()==OP_BUY) {
         context.addLogEntry("Order got filled at price: " + DoubleToStr(OrderOpenPrice(), Digits()), true);
         context.setActualEntry(OrderOpenPrice());
         context.setState(new BuyOrderFilledProfitTargetNotReached(context));
         delete GetPointer(this);
         return;
      }
   }
}
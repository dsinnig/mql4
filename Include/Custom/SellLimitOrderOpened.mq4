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

#include "TradeState.mq4"
#include "ATRTrade.mq4"
#include "TradeClosed.mq4"
#include "SellOrderFilledProfitTargetNotReached.mq4"

class SellLimitOrderOpened : public TradeState {
public: 
   SellLimitOrderOpened(ATRTrade* aContext); 
   virtual void update(); 
private: 
   ATRTrade* context;
};

SellLimitOrderOpened::SellLimitOrderOpened(ATRTrade* aContext) {
      this.context = aContext;
}

void SellLimitOrderOpened::update() {
   if(Bid < context.getCancelPrice()) {
      context.addLogEntry("Bid price went below cancel level. Attempting to delete order.", true);
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
      if(OrderType()==OP_SELL) {
         context.addLogEntry("Order got filled at price: " + DoubleToStr(OrderOpenPrice(), Digits()), true);
         context.setActualEntry(OrderOpenPrice());
         context.setState(new SellOrderFilledProfitTargetNotReached(context));
         delete GetPointer(this);
         return;
      }
   } 
}
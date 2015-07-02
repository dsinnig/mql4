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
#include "StopSellOrderOpened.mq4"
#include "SellLimitOrderOpened.mq4"



class HighestHighReceivedEstablishingEligibilityRange : public TradeState {
public:
   HighestHighReceivedEstablishingEligibilityRange(ATRTrade* aContext);
   virtual void update(); 
   
private:
   ATRTrade* context; //hides conext in Trade
   datetime  entryTime;
   double    rangeLow;
   double    rangeHigh;
};

HighestHighReceivedEstablishingEligibilityRange::HighestHighReceivedEstablishingEligibilityRange(ATRTrade *aContext) {
    this.context = aContext;
    this.entryTime = Time[0];
    this.rangeHigh = -1;
    this.rangeLow=99999;

    context.addLogEntry("Highest high found - establishing eligibility range. Highest high: " + DoubleToString(Close[0], Digits), true); 
}


void HighestHighReceivedEstablishingEligibilityRange::update()  {
    //update range lows and range highs
    if(Low[0]<rangeLow) rangeLow=Low[0];  {
      if(High[0]>rangeHigh) rangeHigh=High[0];
    }

    //Waiting Period over? (deault is 10mins + 1min)
    if(Time[0]-entryTime>=60*(context.getLengthIn1MBarsOfWaitingPeriod()+1))  {
         int rangePips = (int)((rangeHigh-rangeLow)*100000); ///Works for 5 Digts pairs. Verify that calculation is valid for 3 Digits pairs
         int ATRPips = (int) (context.getATR() * 100000); ///Works for 5 Digts pairs. Verify that calculation is valid for 3 Digits pairs
         
         context.addLogEntry("Range established at: " + IntegerToString(rangePips) + " micro pips. HH=" + DoubleToString(rangeHigh, Digits) + ", LL=" + DoubleToString(rangeLow, Digits), true);
         

         //Range too large for limit or stop order
         if((rangeHigh-rangeLow)>((context.getPercentageOfATRForMaxVolatility()/100.00)*context.getATR()))  {
            context.addLogEntry("Range (" + IntegerToString(rangePips) + " micro pips) greater than " + DoubleToString(context.getPercentageOfATRForMaxVolatility(), Digits) + "% of ATR (" + IntegerToString(ATRPips) + ")", true);
            context.setState(new TradeClosed(context));
            delete GetPointer(this);
         }
         else {
            double entryPrice =0.0;
            double stopLoss = 0.0;
            double cancelPrice = 0.0;
            int orderType = -1;
            TradeState* nextState = NULL;
            int orderTicket = -1;
            double buffer = context.getRangeBufferInMicroPips() / 100000.00; ///Works for 5 Digts pairs. Verify that calculation is valid for 3 Digits pairs
            //Range is less than max risk
            if ((rangeHigh-rangeLow)<((context.getPercentageOfATRForMaxRisk()/100.00)*context.getATR())) {
               entryPrice = NormalizeDouble(rangeLow - buffer, Digits);
               stopLoss = NormalizeDouble(rangeHigh + buffer, Digits);
               cancelPrice = rangeHigh;
               orderType = OP_SELLSTOP; 
               
               context.addLogEntry("Range (" + IntegerToString(rangePips) + "micropips) is less than max risk (" + DoubleToString(context.getPercentageOfATRForMaxRisk(), Digits) + "% of ATR (" + IntegerToString(ATRPips) + "))", true); 
               
               context.addLogEntry("Attempting to place SellStop Order @" + DoubleToString(entryPrice, Digits) + " with stop loss @" + DoubleToString(stopLoss, Digits) + " and cancel price @" + DoubleToString(cancelPrice, Digits), true);
               nextState = new StopSellOrderOpened(context, cancelPrice);
             
            }
            else 
            //Range is above risk level, but below max volatility level. Current Bid price is less than entry level.  
            if (((rangeHigh-rangeLow)<((context.getPercentageOfATRForMaxVolatility()/100.00)*context.getATR())) && 
                 (Bid < NormalizeDouble(rangeHigh - context.getATR() * context.getPercentageOfATRForMaxRisk()/100.00 - buffer, Digits))) {
               
               entryPrice = NormalizeDouble(rangeHigh - context.getATR() * (context.getPercentageOfATRForMaxRisk()/100.00) - buffer, Digits);
               stopLoss = NormalizeDouble(rangeHigh + buffer, Digits);
               cancelPrice = NormalizeDouble(rangeHigh - context.getATR() * (context.getPercentageOfATRForMaxVolatility() / 100.00), Digits); //cancel if above 20% of ATR
               orderType = OP_SELLLIMIT;
               nextState = new SellLimitOrderOpened(context, cancelPrice);
               context.addLogEntry("Range (" + IntegerToString(rangePips) + " micro pips) is greater than max risk (" + DoubleToString(context.getPercentageOfATRForMaxRisk(), 2) +  
                                   "% but less than max. volatility " + DoubleToString(context.getPercentageOfATRForMaxVolatility(), 2) + "%) of ATR (" + IntegerToString(ATRPips) + " micro pips). Bid price is less than entry price", true); 
               context.addLogEntry("Attempting to place SellLimit Order @" + DoubleToString(entryPrice, Digits) + " with stop loss @" + DoubleToString(stopLoss, Digits) + " and cancel price @" + DoubleToString(cancelPrice, Digits), Digits);
            } else 
            //Range is above risk level, but below max volatility level. Current Bid price is greater than entry level.  
            if (((rangeHigh-rangeLow)<((context.getPercentageOfATRForMaxVolatility()/100.00)*context.getATR())) && 
                 (Bid > NormalizeDouble(rangeHigh - context.getATR() * (context.getPercentageOfATRForMaxRisk()/100.00) - buffer, Digits))) {
                entryPrice = NormalizeDouble(rangeHigh - context.getATR() * (context.getPercentageOfATRForMaxRisk()/100.00) - buffer, Digits);
                stopLoss = NormalizeDouble(rangeHigh + buffer, Digits);
                cancelPrice = rangeHigh;
                orderType = OP_SELLSTOP; 
                nextState = new StopSellOrderOpened(context, cancelPrice);
                context.addLogEntry("Range (" + IntegerToString(rangePips) + " micro pips) is greater than max risk " + DoubleToString(context.getPercentageOfATRForMaxRisk(), 2) +  
                                   "% but less than max. volatility " + DoubleToString(context.getPercentageOfATRForMaxVolatility(), 2) + "% of ATR (" + IntegerToString(ATRPips) + "). Bid price is greater than entry price", true); 
                context.addLogEntry("Attempting to place SellStop Order @" + DoubleToString(entryPrice, Digits) + " with stop loss @" + DoubleToString(stopLoss, Digits) + " and cancel price @" + DoubleToString(cancelPrice, Digits), true);
             }
             ///parametrize slippage
             int ticket = OrderSend(Symbol(), orderType, 1, entryPrice, 4, stopLoss, 0, "BuyStopOrder", 0, 0, clrBlue);
             int result = ErrorManager::analzeAndProcessResult();
             if(result==NO_ERROR)  {
                 context.setOrderTicket(ticket);
                 context.setStopLoss(stopLoss);
                 context.setPlannedEntry(entryPrice);
                 context.setInitialProfitTarget (NormalizeDouble(context.getPlannedEntry() + ((context.getPlannedEntry() - context.getStopLoss()) * (context.getMinProfitTarget())), Digits));
                 context.setState(nextState);
                 context.addLogEntry("Order successfully placed", true);
                 delete GetPointer(this);
                 return;
             }
            if((result==RETRIABLE_ERROR) && (ticket==-1))  {
                 context.addLogEntry("Order entry failed. Error code: " + IntegerToString(GetLastError()) + ". Will re-try at next tick", true);
                 delete nextState;
                 return;
            }

            //this should never happen...
            if((ticket!=-1) && (RETRIABLE_ERROR || NON_RETRIABLE_ERROR))  {
                 context.addLogEntry("Error ocured but order is still open. Error code: " + IntegerToString(GetLastError()) + ". Continue with trade...", true);
                 context.setOrderTicket(result);
                 context.setStopLoss(stopLoss);
                 context.setPlannedEntry(entryPrice);
                 context.setInitialProfitTarget (NormalizeDouble(context.getPlannedEntry() + ((context.getPlannedEntry() - context.getStopLoss()) * (context.getMinProfitTarget())), Digits));
                 context.setState(nextState);
                 delete GetPointer(this);
                 return;
              }

            if((result==NON_RETRIABLE_ERROR) && (ticket==-1))  {
               context.addLogEntry("Non-recoverable error occurred. Errorcode: " + IntegerToString(GetLastError()) + ". Trade will be canceled", true);
               context.setState(new TradeClosed(context));
               delete nextState;
               delete GetPointer(this);
               return;
            }
        } //end else (that checks for general trade eligibility)
     } //end if for range delay check
} 

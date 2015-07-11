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
   datetime entryTime;
   double rangeLow;
   double rangeHigh;
   int barCounter;
   static bool isNewBar();
};

HighestHighReceivedEstablishingEligibilityRange::HighestHighReceivedEstablishingEligibilityRange(ATRTrade *aContext) {
    this.context = aContext;
    this.entryTime = Time[0];
    this.rangeHigh = -1;
    this.rangeLow=99999;
    this.barCounter=0;

    context.addLogEntry("Highest high found - establishing eligibility range. Highest high: " + DoubleToString(Close[0], Digits), true); 
}


void HighestHighReceivedEstablishingEligibilityRange::update()  {
    double factor = OrderManager::getPipConversionFactor(); 
    
    //update range lows and range highs
    if(Low[0]<rangeLow) rangeLow=Low[0];  {
      if(High[0]>rangeHigh) rangeHigh=High[0];
    }

    if(isNewBar()) barCounter++; 

    //Waiting Period over? (deault is 10mins + 1min)
    //if(Time[0]-entryTime>=60*(context.getLengthIn1MBarsOfWaitingPeriod()+1))  {
      if (barCounter > context.getLengthIn1MBarsOfWaitingPeriod() +1) {
         int rangePips = (int)((rangeHigh-rangeLow)* factor); 
         int ATRPips = (int) (context.getATR() * factor); 
         
         context.addLogEntry("Range established at: " + IntegerToString(rangePips) + " micro pips. HH=" + DoubleToString(rangeHigh, Digits) + ", LL=" + DoubleToString(rangeLow, Digits), true);
         

         //Range too large for limit or stop order
         if((rangeHigh-rangeLow)>((context.getPercentageOfATRForMaxVolatility()/100.00)*context.getATR()))  {
            context.addLogEntry("Range (" + IntegerToString(rangePips) + " micro pips) is greater than " + DoubleToString(context.getPercentageOfATRForMaxVolatility(), 2) + "% of ATR (" + IntegerToString(ATRPips) + " micro pips)", true);
            context.setState(new TradeClosed(context));
            delete GetPointer(this);
         }
         else {
            double entryPrice =0.0;
            double stopLoss = 0.0;
            double cancelPrice = 0.0;
            int orderType = -1;
            TradeState* nextState = NULL;
            double positionSize = 0;
            double buffer = context.getRangeBufferInMicroPips() / factor; ///Works for 5 Digts pairs. Verify that calculation is valid for 3 Digits pairs
            //Range is less than max risk
            if ((rangeHigh-rangeLow)<((context.getPercentageOfATRForMaxRisk()/100.00)*context.getATR())) {
               
               //write to log
               context.addLogEntry("Range (" + IntegerToString(rangePips) + " micro pips) is less than max risk " + DoubleToString(context.getPercentageOfATRForMaxRisk(), 2) + "% of ATR (" + IntegerToString(ATRPips) + " micro pips)", true); 
               
               entryPrice = rangeLow - buffer;
               stopLoss = rangeHigh + buffer;
               cancelPrice = rangeHigh;
               orderType = OP_SELLSTOP; 
               nextState = new StopSellOrderOpened(context);
            }
            else 
            //Range is above risk level, but below max volatility level. Current Bid price is less than entry level.  
            if (((rangeHigh-rangeLow)<((context.getPercentageOfATRForMaxVolatility()/100.00)*context.getATR())) && 
                 (Bid < rangeHigh - context.getATR() * context.getPercentageOfATRForMaxRisk()/100.00 - buffer)) {
               
               //write to log
               context.addLogEntry("Range (" + IntegerToString(rangePips) + " micro pips) is greater than max risk (" + DoubleToString(context.getPercentageOfATRForMaxRisk(), 2) +  
                                   "% but less than max. volatility " + DoubleToString(context.getPercentageOfATRForMaxVolatility(), 2) + "%) of ATR (" + IntegerToString(ATRPips) + " micro pips). Bid price is less than entry price", true); 
               
               
               entryPrice = rangeHigh - context.getATR() * (context.getPercentageOfATRForMaxRisk()/100.00) - buffer;
               stopLoss = rangeHigh + buffer;
               cancelPrice = rangeHigh - context.getATR() * (context.getPercentageOfATRForMaxVolatility() / 100.00); //cancel if above 20% of ATR
               orderType = OP_SELLLIMIT;
               nextState = new SellLimitOrderOpened(context);
              
            } else 
            //Range is above risk level, but below max volatility level. Current Bid price is greater than entry level.  
            if (((rangeHigh-rangeLow)<((context.getPercentageOfATRForMaxVolatility()/100.00)*context.getATR())) && 
                 (Bid > rangeHigh - context.getATR() * (context.getPercentageOfATRForMaxRisk()/100.00) - buffer)) {
                 
                 //write to log
                 context.addLogEntry("Range (" + IntegerToString(rangePips) + " micro pips) is greater than max risk " + DoubleToString(context.getPercentageOfATRForMaxRisk(), 2) +  
                                   "% but less than max. volatility " + DoubleToString(context.getPercentageOfATRForMaxVolatility(), 2) + "% of ATR (" + IntegerToString(ATRPips) + "). Bid price is greater than entry price", true); 
                
                 
                entryPrice = rangeHigh - context.getATR() * (context.getPercentageOfATRForMaxRisk()/100.00) - buffer;
                stopLoss = rangeHigh + buffer;
                cancelPrice = rangeHigh;
                orderType = OP_SELLSTOP; 
                nextState = new StopSellOrderOpened(context);
                
             }
             
             int riskPips = (int) (MathAbs(stopLoss - entryPrice) * factor);
             double riskCapital = AccountBalance() * 0.0075;
             positionSize = NormalizeDouble(OrderManager::getLotSize(riskCapital, riskPips), context.getLotDigits());
             
             context.addLogEntry("AccountBalance: $" + DoubleToString(AccountBalance(), 2) + "; Risk Capital: $" + DoubleToString(riskCapital, 2) + "; Risk pips: " + DoubleToString(riskPips, 2) + " micro pips; Position Size: " + DoubleToString(positionSize, 2) + " lots; Pip value: " + DoubleToString(OrderManager::getPipValue(),Digits), true);
             
             //place Order
             ErrorType result = OrderManager::submitNewOrder(orderType, entryPrice, stopLoss, 0, cancelPrice, positionSize, context);

             if(result==NO_ERROR)  {
                 context.setInitialProfitTarget (NormalizeDouble(context.getPlannedEntry() + ((context.getPlannedEntry() - context.getStopLoss()) * (context.getMinProfitTarget())), Digits));
                 context.setState(nextState);
                 context.addLogEntry("Order successfully placed. Initial Profit target is: " + DoubleToString(context.getInitialProfitTarget(), Digits) + " (" + IntegerToString((int) (MathAbs(context.getInitialProfitTarget() - context.getPlannedEntry()) * factor)) + " micro pips)" + " Risk is: " + IntegerToString((int) riskPips) + " micro pips" , true);
                 delete GetPointer(this);
                 return;
             }
            if((result==RETRIABLE_ERROR) && (context.getOrderTicket()==-1))  {
                 context.addLogEntry("Order entry failed. Error code: " + IntegerToString(GetLastError()) + ". Will re-try at next tick", true);
                 delete nextState;
                 return;
            }

            //this should never happen...
            if((context.getOrderTicket()!=-1) && (RETRIABLE_ERROR || NON_RETRIABLE_ERROR))  {
                 context.addLogEntry("Error ocured but order is still open. Error code: " + IntegerToString(GetLastError()) + ". Continue with trade. Initial Profit target is: " + DoubleToString(context.getInitialProfitTarget(), Digits) + " (" + IntegerToString((int) (MathAbs(context.getInitialProfitTarget() - context.getPlannedEntry()) * factor)) + " micro pips)" + " Risk is: " + IntegerToString((int) riskPips) + " micro pips" , true);
                 context.setInitialProfitTarget (NormalizeDouble(context.getPlannedEntry() + ((context.getPlannedEntry() - context.getStopLoss()) * (context.getMinProfitTarget())), Digits));
                 context.setState(nextState);
                 delete GetPointer(this);
                 return;
              }

            if((result==NON_RETRIABLE_ERROR) && (context.getOrderTicket()==-1))  {
               context.addLogEntry("Non-recoverable error occurred. Errorcode: " + IntegerToString(GetLastError()) + ". Trade will be canceled", true);
               context.setState(new TradeClosed(context));
               delete nextState;
               delete GetPointer(this);
               return;
            }
        } //end else (that checks for general trade eligibility)
     } //end if for range delay check
} 

bool HighestHighReceivedEstablishingEligibilityRange::isNewBar() {
   static datetime lastbar=0;
   datetime curbar=Time[0];
   if(lastbar!=curbar) {
      lastbar=curbar;
      return (true);
   }
   else {
      return(false);
   }
}

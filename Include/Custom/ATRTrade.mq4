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

#include "Trade.mq4"

class ATRTrade: public Trade {
public:
   ATRTrade(double anATR,int _lengthIn1MBarsOfWaitingPeriod,double _percentageOfATRForMaxRisk,double _percentageOfATRForMaxVolatility,double _percentageOfATRForMinProfitTarget, int _rangeBufferInMicroPips);

   double getATR() const;
   int getLengthIn1MBarsOfWaitingPeriod() const; 
   double getPercentageOfATRForMaxRisk() const; 
   double getPercentageOfATRForMaxVolatility() const; 
   double getPercentageOfATRForMinProfitTarget() const; 
   int getRangeBufferInMicroPips() const;
   

private: 
   double atr;
   int lengthIn1MBarsOfWaitingPeriod;
   double percentageOfATRForMaxRisk;
   double percentageOfATRForMaxVolatility;
   double percentageOfATRForMinProfitTarget;
   int rangeBufferInMicroPips;
};
      
ATRTrade::ATRTrade(double _ATR,int _lengthIn1MBarsOfWaitingPeriod,double _percentageOfATRForMaxRisk,double _percentageOfATRForMaxVolatility,double _percentageOfATRForMinProfitTarget, int _rangeBufferInMicroPips) : Trade() {
   this.atr=_ATR;
   this.lengthIn1MBarsOfWaitingPeriod=_lengthIn1MBarsOfWaitingPeriod;
   this.percentageOfATRForMaxRisk=_percentageOfATRForMaxRisk;
   this.percentageOfATRForMaxVolatility=_percentageOfATRForMaxVolatility;
   this.percentageOfATRForMinProfitTarget = _percentageOfATRForMinProfitTarget;
   this.rangeBufferInMicroPips = _rangeBufferInMicroPips;
}

double ATRTrade::getATR() const {
    return atr;
}

int ATRTrade::getLengthIn1MBarsOfWaitingPeriod() const {
   return this.lengthIn1MBarsOfWaitingPeriod;
}

double ATRTrade::getPercentageOfATRForMaxRisk() const {
   return this.percentageOfATRForMaxRisk;
}

double ATRTrade::getPercentageOfATRForMaxVolatility() const {
   return this.percentageOfATRForMaxVolatility;
}

double ATRTrade::getPercentageOfATRForMinProfitTarget() const {
   return percentageOfATRForMinProfitTarget;
}

int ATRTrade::getRangeBufferInMicroPips() const {
   return rangeBufferInMicroPips;
}





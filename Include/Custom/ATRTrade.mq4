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
#include "OrderManager.mq4"

class ATRTrade: public Trade {
public:
   ATRTrade(int _lotDigits, string _logFileName, double _newHHLL, double anATR,int _lengthIn1MBarsOfWaitingPeriod,double _percentageOfATRForMaxRisk,double _percentageOfATRForMaxVolatility,
            double _percentageOfATRForMinProfitTarget, int _rangeBufferInMicroPips);

   double getATR() const;
   int getLengthIn1MBarsOfWaitingPeriod() const; 
   double getPercentageOfATRForMaxRisk() const; 
   double getPercentageOfATRForMaxVolatility() const; 
   double getMinProfitTarget() const; 
   int getRangeBufferInMicroPips() const;
   
   void setRangeHigh(double _high);
   double getRangeHigh() const;
   void setRangeLow(double _low);
   double getRangeLow() const;
   void setRangePips(int _pips);
   int getRangePips() const;
   void setNewHHLL(double _newHHLL);
   double getNewHHLL() const;
   
   
   virtual void writeLogToCSV() const;
   

private: 
   double rangeHigh;
   double rangeLow;
   int rangePips;
   double newHHLL;
   double atr;
   int lengthIn1MBarsOfWaitingPeriod;
   double percentageOfATRForMaxRisk;
   double percentageOfATRForMaxVolatility;
   double minProfitTarget;
   int rangeBufferInMicroPips;
   
};
      
ATRTrade::ATRTrade(int _lotDigits, string _logFileName, double _newHHLL, double _ATR,int _lengthIn1MBarsOfWaitingPeriod,double _percentageOfATRForMaxRisk,double _percentageOfATRForMaxVolatility,double _minProfitTarget, int _rangeBufferInMicroPips) : Trade(_lotDigits, _logFileName) {
   this.newHHLL=_newHHLL;
   this.atr=_ATR;
   this.lengthIn1MBarsOfWaitingPeriod=_lengthIn1MBarsOfWaitingPeriod;
   this.percentageOfATRForMaxRisk=_percentageOfATRForMaxRisk;
   this.percentageOfATRForMaxVolatility=_percentageOfATRForMaxVolatility;
   this.minProfitTarget = _minProfitTarget;
   this.rangeBufferInMicroPips = _rangeBufferInMicroPips;
   
   this.rangeHigh=0;
   this.rangeLow=0;
   this.rangePips=0;
   this.newHHLL=_newHHLL;
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

double ATRTrade::getMinProfitTarget() const {
   return minProfitTarget;
}

int ATRTrade::getRangeBufferInMicroPips() const {
   return rangeBufferInMicroPips;
}

void ATRTrade::setRangeHigh(double _high) {
   this.rangeHigh = _high;
}
double ATRTrade::getRangeHigh() const {
   return this.rangeHigh;
}
void ATRTrade::setRangeLow(double _low) {
   this.rangeLow = _low;
}
double ATRTrade::getRangeLow() const {
   return this.rangeLow;
}
void ATRTrade::setNewHHLL(double _newHHLL) {
   this.newHHLL = _newHHLL;
}
double ATRTrade::getNewHHLL() const {
   return this.newHHLL;
}

void ATRTrade::setRangePips(int _pips) {
   this.rangePips = _pips;
}

int ATRTrade::getRangePips() const {
   return this.rangePips;
}

void ATRTrade::writeLogToCSV() const {
   ResetLastError();
   int openFlags;
   openFlags = FILE_WRITE | FILE_READ | FILE_CSV;
   int filehandle=FileOpen(this.logFileName, openFlags, ",");
   if(filehandle!=INVALID_HANDLE) {
      FileSeek(filehandle, 0, SEEK_END); //go to the end of the file
        
      //if first entry, write column headers
      if (FileTell(filehandle)==0) {
         FileWrite(filehandle, "TRADE_ID", "ORDER_TICKET", "TRADE_TYPE","SYMBOL", "ATR", "HH/LL", "TRADE_OPENED_DATE", "RANGE_HIGH", "RANGE_LOW", "RANGE_PIPS", "ORDER_PLACED_DATE", "STARTING_BALANCE", "PLANNED_ENTRY", "ORDER_FILLED_DATE", "ACTUAL_ENTRY", "SPREAD_ORDER_OPEN", "INITIAL_STOP_LOSS", "REVISED_STOP_LOSS", "INITIAL_TAKE_PROFIT", "REVISED TAKE_PROFIT", "CANCEL_PRICE", "ACTUAL_CLOSE", "SPREAD_ORDER_CLOSE", "POSITION_SIZE", "REALIZED PL", "COMMISSION", "SWAP", "ENDING_BALANCE", "TRADE_CLOSED_DATE");
      }
            
      FileWrite(filehandle, this.id, this.orderTicket, tradeTypeToString(this.tradeType), Symbol(), this.atr*OrderManager::getPipConversionFactor(), this.newHHLL, datetimeToExcelDate(this.tradeOpenedDate), this.rangeHigh, this.rangeLow, this.rangePips, datetimeToExcelDate(this.orderPlacedDate), this.startingBalance, this.plannedEntry, datetimeToExcelDate(this.orderFilledDate), this.actualEntry, this.spreadOrderOpen, this.originalStopLoss, this.stopLoss, this.initialProfitTarget, this.takeProfit, this.cancelPrice, this.actualClose, this.spreadOrderClose, this.positionSize, this.realizedPL, this.commission, this.swap, this.endingBalance, datetimeToExcelDate(this.tradeClosedDate));
    }
    
    FileClose(filehandle);
}




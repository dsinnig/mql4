//+------------------------------------------------------------------+
//|                                                       ATR_EA.mq4 |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/Custom/SessionFactory.mq4"
#include "../Include/Custom/Session.mq4"
#include "../Include/Custom/LowestLowReceivedEstablishingEligibilityRange.mq4"
#include "../Include/Custom/HighestHighReceivedEstablishingEligibilityRange.mq4"

//Cradden2015


Session *currSession;
input int sundayLengthInHours=7; //Length of Sunday session in hours
input int HHLL_Threshold=60; //Time in minutes after last HH / LL before a tradeable HH/LL can occur
input int lengthOfGracePeriod=10; //Length in 1M bars of Grace Period after a tradeable HH/LL occured
input double maxRisk=10; //Max risk (in percent of ATR)
input double maxVolatility=20; //Max volatility (in percent of ATR)
input double minProfitTarget=4; //Min Profit Target (in factors of the risk e.g., 3 = 3* Risk)
input int rangeBuffer=20; //Buffer in micropips for order opening and closing
input int lotDigits=1; //Lot size granularity (0 = full lots, 1 = mini lots, 2 = micro lots, etc).
input string logFileName="tradeLog.csv"; //path and filename for CSV trade log

//check for 1M charts
//check for LimitOrderPercentage > StopOrderPercentage


datetime sundayLengthInSeconds=60*60*sundayLengthInHours;

datetime bartime;
const int maxNumberOfTrades=10000;
int tradesInArray=0;
Trade *trades[10000];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void addTrade(Trade *aTrade) 
  {
   for(int i=0; i<=tradesInArray;++i) 
     {
      if(trades[i]==NULL) 
        {
         trades[i]= aTrade;
        }
     }
   tradesInArray++;
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   
   if (IsTesting()) {
      //delete log file
      FileDelete("ATR_EA.log");
      FileDelete(logFileName);
   }
   
   
   //initialize trades array
   for(int i=0; i<maxNumberOfTrades;++i) {
      trades[i]=NULL;
   }
   


//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) 
  {
   //printLog to file
   for (int i = 0; i < tradesInArray; ++i) {
         trades[i].writeLogToFile("ATR_EA.log", true);
         trades[i].writeLogToHTML("ATR_EA.html", true);
         //trades[i].printLog();
   }
      
   SessionFactory::cleanup();

   for(int i=0; i<tradesInArray;++i) 
     {
      if(trades[i]!=NULL)
         delete trades[i];
     }

//--- destroy timer
   //EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() 
  {
   if(bartime!=Time[0]) 
   {
      bartime = Time[0];

      Session *newSession=SessionFactory::getCurrentSession(sundayLengthInSeconds, HHLL_Threshold);
      if(currSession!=newSession) {
         currSession=newSession;;
         
         if (!currSession.tradingAllowed()) {
            Print (TimeCurrent(), " Start session: ", currSession.getName(), " NO NEW TRADES ALLOWED.");
         } else {
         
         /*Print(TimeCurrent()," Start session: ", currSession.getName()," Start: ",currSession.getSessionStartTime()," End: ",currSession.getSessionEndTime()," ATR: ",currSession.getATR(), " (", (int) (currSession.getATR() * 100000), ") micro pips");
         Print (" Ref: ",currSession.getHHLL_ReferenceDateTime(), " HH: ", currSession.getHighestHigh(), "@ ", currSession.getHighestHighTime(),
                " LL: ", currSession.getLowestLow(), "@ ", currSession.getLowestLowTime());
        
         */
         
         Print(TimeCurrent()," Start session: ", currSession.getName(), " ATR: ",NormalizeDouble(currSession.getATR(), Digits), " (", (int) (currSession.getATR() * 100000), " micro pips)", ", HH: ", currSession.getHighestHigh(), ", LL: ", currSession.getLowestLow());
         
         Print ("Reference date: ", currSession.getHHLL_ReferenceDateTime());
         
         }
      }
   }

   for(int i=0; i<=tradesInArray; i++) {
      if(trades[i]!=NULL) trades[i].update();
   }

   int updateResult=currSession.update(Close[0]);

   if (currSession.tradingAllowed()) {
      if (updateResult == 1) {
         Print("Tradeable Highest High found: ", currSession.getHighestHigh(), " Time: ", currSession.getHighestHighTime());
         Trade* trade = new ATRTrade(lotDigits, logFileName, currSession.getHighestHigh(), currSession.getATR(), lengthOfGracePeriod, maxRisk, maxVolatility, minProfitTarget, rangeBuffer);
         trade.setState (new HighestHighReceivedEstablishingEligibilityRange(trade));
         addTrade(trade);
     }
      
      
      if(updateResult==-1) 
        {
         Print("Tradeable Lowest Low found: ",currSession.getLowestLow()," Time: ",currSession.getLowestLowTime());
         Trade* trade = new ATRTrade(lotDigits, logFileName, currSession.getLowestLow(), currSession.getATR(), lengthOfGracePeriod, maxRisk, maxVolatility, minProfitTarget, rangeBuffer);
         trade.setState (new LowestLowReceivedEstablishingEligibilityRange(trade));
         addTrade(trade);
        }
   }

  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---

  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---

  }
//+------------------------------------------------------------------+

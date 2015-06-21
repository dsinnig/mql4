//+------------------------------------------------------------------+
//|                                                       ATR_EA.mq4 |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/Custom/SessionFactory.mqh"
#include "../Include/Custom/Session.mqh"
#include "../Include/Custom/TradeStates.mqh"

Session *currSession;
datetime sundayLength=60*60*7;
input int HHLL_Threshold=100; //Time in minutes to wait before a new HH/LL can occur

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
int OnInit()
  {
//--- create timer
   //EventSetTimer(60);
   for(int i=0; i<maxNumberOfTrades;++i)
      trades[i]=NULL;



//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) 
  {
   SessionFactory::cleanup();

   for(int i=0; i<=tradesInArray;++i) 
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

      Session *newSession=SessionFactory::getCurrentSession(sundayLength,HHLL_Threshold);
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
         
         
         }
      }
   }

   for(int i=0; i<=tradesInArray; i++) {
      if(trades[i]!=NULL) trades[i].update();
   }

   int updateResult=currSession.update(Close[0]);

   if (currSession.tradingAllowed()) {
      //if (updateResult == 1) Print("Tradeable Highest High found: ", currSession.getHighestHigh(), " Time: ", currSession.getHighestHighTime());
      if(updateResult==-1) 
        {
         Print("Tradeable Lowest Low found: ",currSession.getLowestLow()," Time: ",currSession.getLowestLowTime());
         Trade* trade = new Trade(currSession.getATR());
         trade.setState (new LowestLowReceivedWaiting10MoreBars(trade));
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

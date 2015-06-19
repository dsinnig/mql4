//+------------------------------------------------------------------+
//|                                              testSessionInfo.mq4 |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 1   

input int HHLL_Threshold=100; //Time in minutes to wait before a new HH/LL can occur

#include "../Include/Custom/SessionFactory.mqh"
#include "../Include/Custom/Session.mqh"

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

Session* currSession;  
datetime sundayLength = 60*60*7;


int OnInit()
  { 
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if (rates_total != prev_calculated) {
      Session* newSession = SessionFactory::getCurrentSession(sundayLength, HHLL_Threshold);
      if (currSession != newSession) {
         delete currSession;
         currSession = newSession;;
         
         Print (TimeCurrent(), currSession.getName(), " Start: ",currSession.getSessionStartTime(), " End: ", currSession.getSessionEndTime(), " ATR: ", currSession.getATR());
         Print (" Ref: ", currSession.getHHLL_ReferenceDateTime(), " HH: ", currSession.getHighestHigh(), "@ ", currSession.getHighestHighTime(), 
                " LL: ", currSession.getLowestLow(), "@ ", currSession.getLowestLowTime());
      }
    }
      
    int updateResult = currSession.update(Close[0]);
    
    if (updateResult == 1) Print("Tradeable Highest High found: ", currSession.getHighestHigh(), " Time: ", currSession.getHighestHighTime());
    if (updateResult == -1) Print("Tradeable Lowest Low found: ", currSession.getLowestLow(), " Time: ", currSession.getLowestLowTime());
 
    return(rates_total);
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }

void OnDeinit(const int reason) {
   SessionFactory::cleanup();
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

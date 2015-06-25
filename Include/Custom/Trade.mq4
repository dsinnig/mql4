

//+------------------------------------------------------------------+
//|                                                        Trade.mqh |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property strict

#include "TradeState.mq4"

class Trade {
public: 
    Trade();
    ~Trade(); 
    void update(); 
    void setState(TradeState *aState); 
     
    void setOrderTicket(int aTicket); 
    int getOrderTicket() const; 
    string getId() const; 
    void setPlannedEntry(double entry); 
    double getPlannedEntry() const; 
    void setActualEntry(double entry); 
    double getActualEntry() const; 
    void setStopLoss(double sL); 
    double getStopLoss() const; 
    void setInitialProfitTarget(double target); 
    double getInitialProfitTarget() const; 
    void setActualClose (double close);
    double getActualClose() const;
    void addLogEntry(string entry, bool print);
    void printLog() const;
    void writeLogToFile(string filename, bool append) const;

private:
    TradeState* state;
    int orderTicket;
    string id;
    double plannedEntry;
    double actualEntry;
    double stopLoss;
    double actualClose;
    double initialProfitTarget;
    string log[1000];
    int logSize;      
    double positionSize;
    
};

Trade::Trade() {
    this.state=NULL;
    this.orderTicket=-1;
    this.actualEntry=-1;
    this.actualClose=-1;
    this.initialProfitTarget=-1;
    this.plannedEntry=-1;
    this.stopLoss=-1;
    this.positionSize=0;
    this.logSize=0;

    this.id=Symbol() + 
            IntegerToString(TimeYear(TimeCurrent()))+ "-" +
            IntegerToString(TimeMonth(TimeCurrent()), 2, '0')+ "-" +
            IntegerToString(TimeDay(TimeCurrent()), 2, '0')+ "::" +
            IntegerToString(TimeHour(TimeCurrent()), 2, '0')+ ":" +
            IntegerToString(TimeMinute(TimeCurrent()), 2, '0')+ ":" +
            IntegerToString(TimeSeconds(TimeCurrent()), 2, '0');
}

Trade::~Trade() {
    delete state;
}

void Trade::update() {
    if(state!=NULL)
       state.update();
}

void Trade::addLogEntry(string entry, bool print) {
    this.log[logSize] = TimeToStr(TimeCurrent(), TIME_DATE | TIME_SECONDS) + ": " + entry;
    logSize++;
    if (print) 
        Print(TimeToStr(TimeCurrent(), TIME_DATE | TIME_SECONDS) + ": TradeID: " + this.id + " " + entry);
}

void Trade::printLog() const {
    Print ("****Trade: ", this.id, " ****");
    for (int i = 0; i < logSize; ++i) {
        Print(log[i]);
    }
}

void Trade::writeLogToFile(string filename, bool append) const {
    ResetLastError();
    int openFlags;
    if (append)
        openFlags = FILE_WRITE | FILE_READ | FILE_TXT;
    else 
        openFlags = FILE_WRITE | FILE_TXT;
    
    int filehandle=FileOpen(filename, openFlags);
    if (append)
        FileSeek(filehandle, 0, SEEK_END);
    if(filehandle!=INVALID_HANDLE) {
        FileWrite(filehandle, "****Trade: ", this.id, " ****");
        for (int i = 0; i < logSize; ++i) {
            FileWrite(filehandle, log[i]);
        }
        FileClose(filehandle);
    }
    else Print("Operation FileOpen failed, error ",GetLastError());
}

void Trade::setState(TradeState *aState) {
    this.state=aState;
}

void Trade::setOrderTicket(int aTicket) {
    this.orderTicket=aTicket;
}

int Trade::getOrderTicket() const {
    return this.orderTicket;
}

string Trade::getId() const {
    return id;
}

void Trade::setPlannedEntry(double entry) {
    this.plannedEntry=entry;
}

double Trade::getPlannedEntry() const {
    return this.plannedEntry;
}

void Trade::setActualEntry(double entry) {
    this.actualEntry=entry;
}

double Trade::getActualEntry() const {
    return this.actualEntry;
}

void Trade::setStopLoss(double sL) {
    this.stopLoss=sL;
}

double Trade::getStopLoss() const {
    return this.stopLoss;
}

void Trade::setInitialProfitTarget(double target) {
   this.initialProfitTarget=target;
}

double Trade::getInitialProfitTarget() const {
   return this.initialProfitTarget;
}

void Trade::setActualClose (double close) {
    this.actualClose = close;
}

double Trade::getActualClose() const {
    return this.actualClose;
}

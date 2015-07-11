

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
    Trade(int _lotDigits);
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
    void setOriginalStopLoss(double sL); 
    double getOriginalStopLoss() const; 
    void setTakeProfit(double tP); 
    double getTakeProfit() const; 
    void setCancelPrice(double cP); 
    double getCancelPrice() const; 
    void setPositionSize(double p); 
    double getPositionSize() const; 
    void setInitialProfitTarget(double target); 
    double getInitialProfitTarget() const; 
    void setActualClose (double close);
    double getActualClose() const;
    void setLotDigits (int _lotDigits);
    int getLotDigits() const;
    void addLogEntry(string entry, bool print);
    void printLog() const;
    void writeLogToFile(string filename, bool append) const;
    void writeLogToHTML(string filename, bool append) const;

private:
    TradeState* state;
    int orderTicket;
    string id;
    double plannedEntry;
    double actualEntry;
    double stopLoss;
    double originalStopLoss;
    double takeProfit;
    double cancelPrice;
    double actualClose;
    double initialProfitTarget;
    int lotDigits;
    string log[1000];
    int logSize;      
    double positionSize;
    static const int OFFSET;
    
};

const int Trade::OFFSET = (-7) *60*60;

Trade::Trade(int _lotDigits) {
    this.lotDigits = lotDigits;
    this.state=NULL;
    this.orderTicket=-1;
    this.actualEntry=-1;
    this.actualClose=-1;
    this.takeProfit = 0;
    this.cancelPrice = 0;
    this.initialProfitTarget=0;
    this.plannedEntry=0;
    this.stopLoss=0;
    this.originalStopLoss=0;
    this.positionSize=0;
    this.logSize=0;

    this.id=Symbol() + 
            IntegerToString(TimeYear(TimeCurrent()+OFFSET))+ "-" +
            IntegerToString(TimeMonth(TimeCurrent()+OFFSET), 2, '0')+ "-" +
            IntegerToString(TimeDay(TimeCurrent()+OFFSET), 2, '0')+ "::" +
            IntegerToString(TimeHour(TimeCurrent()+OFFSET), 2, '0')+ ":" +
            IntegerToString(TimeMinute(TimeCurrent()+OFFSET), 2, '0')+ ":" +
            IntegerToString(TimeSeconds(TimeCurrent()+OFFSET), 2, '0');
            
    if (!IsTesting()) {
        string filename = Symbol() + "_" + TimeToStr(TimeCurrent(), TIME_DATE);
        int filehandle=FileOpen(filename, FILE_WRITE | FILE_READ | FILE_TXT);
        if(filehandle!=INVALID_HANDLE) {
            FileSeek(filehandle, 0, SEEK_END);
            FileWrite(filehandle, "****Trade: ", this.id, " ****");
            FileClose(filehandle);
        }
        else Print("Operation FileOpen failed, error ",GetLastError());
    }
}

Trade::~Trade() {
    delete state;
}

void Trade::update() {
    if(state!=NULL)
       state.update();
}

void Trade::addLogEntry(string entry, bool print) {
    this.log[logSize] = TimeToStr(TimeCurrent()+OFFSET, TIME_DATE | TIME_SECONDS) + ": " + entry;
    logSize++;
    
    if (!IsTesting()) {
        //write to file
        string filename = Symbol() + "_" + TimeToStr(TimeCurrent(), TIME_DATE);
        int filehandle=FileOpen(filename, FILE_WRITE | FILE_READ | FILE_TXT);
        if(filehandle!=INVALID_HANDLE) {
            FileSeek(filehandle, 0, SEEK_END);
            FileWrite(filehandle, TimeToStr(TimeCurrent()+OFFSET, TIME_DATE | TIME_SECONDS) + ": " + entry);
            FileClose(filehandle);
        }
        else Print("Operation FileOpen failed, error ",GetLastError());
    }
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

void Trade::writeLogToHTML(string filename, bool append) const {
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
        FileWrite(filehandle, "<b>****Trade: ", this.id, " **** </b>");
        FileWrite(filehandle, "<ul>");
        for (int i = 0; i < logSize; ++i) {
            FileWrite(filehandle, "<li>" + log[i] + "</li>");
        }
        FileWrite(filehandle, "</ul>");
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

void Trade::setOriginalStopLoss(double sL) {
    this.originalStopLoss=sL;
}

double Trade::getOriginalStopLoss() const {
    return this.originalStopLoss;
}

void Trade::setTakeProfit(double tP) {
    this.takeProfit=tP;
}

double Trade::getTakeProfit() const {
    return this.takeProfit;
}

void Trade::setCancelPrice(double cP) {
    this.cancelPrice=cP;
}

double Trade::getCancelPrice() const {
    return this.cancelPrice;
}

void Trade::setPositionSize(double p) {
    this.positionSize=p;
}

double Trade::getPositionSize() const {
    return this.positionSize;
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

void Trade::setLotDigits (int _lotDigits) {
    this.lotDigits = _lotDigits;
}

int Trade::getLotDigits() const {
    return lotDigits;
}
    

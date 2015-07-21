

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

enum TradeType { 
   FLAT,
   LONG, 
   SHORT
};

class Trade {
public: 
    Trade(int _lotDigits, string _logFileName);
    ~Trade(); 
    void update(); 
    void setState(TradeState *aState); 
        
    void setTradeType(TradeType _type);
    TradeType getTradeType() const;
    
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
    void setRealizedPL (double _realizedPL);
    double getRealizedPL() const;
    void setOrderCommission (double _commission);
    double getOrderCommission() const ;
    void setOrderSwap (double _swap);
    double getOrderSwap() const;    
    void setStartingBalance (double _balance);
    double getStartingBalance() const;
    void setEndingBalance (double _balance);
    double getEndingBalance() const;   
    void setTradeOpenedDate(datetime _date); 
    datetime getTradeOpenedDate() const;
    void setOrderPlacedDate(datetime _date); 
    datetime getOrderPlacedDate() const;
    void setOrderFilledDate(datetime _date); 
    datetime getOrderFilledDate() const;
    void setTradeClosedDate(datetime _date); 
    datetime getTradeClosedDate() const;
    void setSpreadOrderOpen(int _spread);
    int getSpreadOrderOpen() const;
    void setSpreadOrderClose(int _spread);
    int getSpreadOrderClose() const;
    
    
    
    void addLogEntry(string entry, bool print);
    void printLog() const;
    void writeLogToFile(string filename, bool append) const;
    void writeLogToHTML(string filename, bool append) const;
    virtual void writeLogToCSV() const;


protected: 
    int orderTicket;
    string id;
    double startingBalance;
    double endingBalance;
    double plannedEntry;
    double actualEntry;
    double stopLoss;
    double originalStopLoss;
    double takeProfit;
    double cancelPrice;
    double actualClose;
    double initialProfitTarget;
    double positionSize;
    int lotDigits;
    double realizedPL;
    double commission;
    double swap;
    int spreadOrderOpen;
    int spreadOrderClose;
    TradeType tradeType;
        
    datetime tradeOpenedDate;
    datetime orderPlacedDate;
    datetime orderFilledDate;
    datetime tradeClosedDate;
    
    string logFileName;
    string datetimeToExcelDate(datetime _date) const;
    string tradeTypeToString(TradeType _type) const;

private:
    TradeState* state;
    string log[1000];
    int logSize;  
    static const int OFFSET;
};

const int Trade::OFFSET = (-7) *60*60;

Trade::Trade(int _lotDigits, string _logFileName) {
    this.logFileName = _logFileName;
    this.tradeType = FLAT;
    this.startingBalance = AccountBalance();
    this.endingBalance = 0;
    this.lotDigits = _lotDigits;
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
    this.realizedPL=0.0;
    this.commission=0.0;
    this.swap=0.0;
    this.spreadOrderOpen = -1;
    this.spreadOrderClose = -1;
    
    this.tradeOpenedDate = TimeCurrent();
    this.orderPlacedDate = -1;
    this.orderFilledDate = -1;
    this.tradeClosedDate = -1;

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

void Trade::writeLogToCSV() const {
    ResetLastError();
    int openFlags;
    openFlags = FILE_WRITE | FILE_READ | FILE_CSV;
    int filehandle=FileOpen(this.logFileName, openFlags, ",");
  if(filehandle!=INVALID_HANDLE) {
        FileSeek(filehandle, 0, SEEK_END); //go to the end of the file
        
        //if first entry, write column headers
        if (FileTell(filehandle)==0) {
            FileWrite(filehandle, "TRADE_ID", "ORDER_TICKET", "TRADE_TYPE", "SYMBOL", "TRADE_OPENED_DATE", "ORDER_PLACED_DATE", "STARTING_BALANCE", "PLANNED_ENTRY", "ORDER_FILLED_DATE", "ACTUAL_ENTRY", "SPREAD_ORDER_OPEN", "INITIAL_STOP_LOSS", "REVISED_STOP_LOSS", "INITIAL_TAKE_PROFIT", "REVISED TAKE_PROFIT", "CANCEL_PRICE", "ACTUAL_CLOSE", "SPREAD_ORDER_CLOSE", "POSITION_SIZE", "REALIZED PL", "COMMISSION", "SWAP", "ENDING_BALANCE", "TRADE_CLOSED_DATE");
        
        }
            
        FileWrite(filehandle, this.id, this.orderTicket, tradeTypeToString(this.tradeType), Symbol(), datetimeToExcelDate(this.tradeOpenedDate), datetimeToExcelDate(this.orderPlacedDate), this.startingBalance, this.plannedEntry, datetimeToExcelDate(this.orderFilledDate), this.actualEntry, this.spreadOrderOpen, this.originalStopLoss, this.stopLoss, this.initialProfitTarget, this.takeProfit, this.cancelPrice, this.actualClose, this.spreadOrderClose, this.positionSize, this.realizedPL, this.commission, this.swap, this.endingBalance, datetimeToExcelDate(this.tradeClosedDate));
    }
    FileClose(filehandle);
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
    
void Trade::setRealizedPL (double _realizedPL) {
    this.realizedPL = _realizedPL;
}
double Trade::getRealizedPL() const {
    return this.realizedPL;
}

void Trade::setOrderCommission (double _commission) {
    this.commission = _commission;
}
double Trade::getOrderCommission() const {
    return this.commission;
}

void Trade::setOrderSwap (double _swap) {
    this.swap = _swap;
}
double Trade::getOrderSwap() const {
    return this.swap;
}

void Trade::setStartingBalance (double _balance) {
    this.startingBalance = _balance;
}

double Trade::getStartingBalance() const {
    return startingBalance;
}

void Trade::setEndingBalance (double _balance) {
    this.endingBalance = _balance;
}

double Trade::getEndingBalance() const {
    return endingBalance;
}

void Trade::setTradeOpenedDate(datetime _date) {
    this.tradeOpenedDate = _date;
}

datetime Trade::getTradeOpenedDate() const {
    return this.tradeOpenedDate;
}

void Trade::setOrderPlacedDate(datetime _date) {
    this.orderPlacedDate = _date;
}

datetime Trade::getOrderPlacedDate() const {
    return this.orderPlacedDate;
}

void Trade::setOrderFilledDate(datetime _date) {
    this.orderFilledDate = _date;
}

datetime Trade::getOrderFilledDate() const {
    return this.orderFilledDate;
}

void Trade::setTradeClosedDate(datetime _date) {
    this.tradeClosedDate = _date;
}

datetime Trade::getTradeClosedDate() const {
    return this.tradeClosedDate;
}

void Trade::setSpreadOrderOpen(int _spread) {
    this.spreadOrderOpen = _spread;
}

int Trade::getSpreadOrderOpen() const {
    return this.spreadOrderOpen;
}

void Trade::setSpreadOrderClose(int _spread) {
    this.spreadOrderClose = _spread;
}

int Trade::getSpreadOrderClose() const {
    return this.spreadOrderClose;
}

void Trade::setTradeType(TradeType _type) {
    this.tradeType = _type;
}
TradeType Trade::getTradeType() const {
    return this.tradeType;
}

string Trade::datetimeToExcelDate(datetime _date) const {
    if (_date == -1) return "";
    else return IntegerToString(TimeYear(_date),4,'0') + "-" + 
                IntegerToString(TimeMonth(_date),2,'0') + "-" + 
                IntegerToString(TimeDay(_date),2,'0') + " " + 
                IntegerToString(TimeHour(_date),2,'0') + ":" + 
                IntegerToString(TimeMinute(_date),2,'0') + ":" + 
                IntegerToString(TimeSeconds(_date),2,'0');
    
}

string Trade::tradeTypeToString(TradeType _type) const {
    switch (_type) {
        case LONG: return "LONG";
        case SHORT: return "SHORT";
        case FLAT: return "FLAT";
    }
    return "FLAT";
}

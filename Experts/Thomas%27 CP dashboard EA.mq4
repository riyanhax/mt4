//+------------------------------------------------------------------+
//|                                      Thomas´ CP dashboard EA.mq4 |
//|                                           Steve Hopwood + Tomele |
//|                                https://www.stevehopwoodforex.com |
//+------------------------------------------------------------------+
#property copyright "Steve Hopwood"
#property link      "https://www.stevehopwoodforex.com"
#property version   "1.00"
#property strict


//#include <WinUser32.mqh>
#include <stdlib.mqh>

//Code to minimise charts provided by Rene. Many thanks again, Rene.
#import "user32.dll"
int GetParent(int hWnd);
bool ShowWindow(int hWnd, int nCmdShow);
#import

#define  SW_FORCEMINIMIZE   11
#define  SW_MAXIMIZE         3

#define  up "Up"
#define  down "Down"
#define  NL    "\n"

//Using hgi_lib
//The HGI library functionality was added by tomele. Many thanks Thomas.
#import "hgi_lib.ex4"
   enum SIGNAL {NONE=0,TRENDUP=1,TRENDDN=2,RANGEUP=3,RANGEDN=4,RADUP=5,RADDN=6};
   enum SLOPE {UNDEFINED=0,RANGEABOVE=1,RANGEBELOW=2,TRENDABOVE=3,TRENDBELOW=4};
   SIGNAL getHGISignal(string symbol,int timeframe,int shift);
   SLOPE getHGISlope (string symbol,int timeframe,int shift);
#import

//HGI constants
#define  hginoarrow "No signal"
#define  hgiuparrowtradable "Up arrow"
#define  hgidownarrowtradable "Dn arrow"
#define  hgibluewavylong "Up wave"
#define  hgibluewavyshort "Dn wave"
//Yellow wavy
#define  hgiyellowwavy "Yellow range wave"

//SuperSlope colours
#define  red "Red"
#define  blue "Blue"
//Changed by tomele
#define white "White"

//Peaky status
#define  longdirection "Long"
#define  shortdirection "Short"

//Trading status
#define  tradablelong "Tradable long"
#define  tradableshort "Tradable short"
#define  untradable "Not tradable"

extern string  cau="---- Chart automation ----";
//These inputs tell the ea to automate opening/closing of charts and
//what to load onto them
extern   bool  AutomateChartOpeningAndClosing=true;
extern bool    MinimiseChartsAfterOpening=false;
extern string  ReservedPair="XAUUSD";
extern string  TemplateName="CP M5";
extern int     MagicNumber=0;
extern string  s1="================================================================";
extern string  oad               ="---- Other stuff ----";
extern string  PairsToTrade   = "AUDCAD,AUDCHF,AUDNZD,AUDJPY,AUDUSD,CADCHF,CADJPY,CHFJPY,EURAUD,EURCAD,EURCHF,EURGBP,EURNZD,EURJPY,EURUSD,GBPCHF,GBPJPY,GBPUSD,NZDUSD,NZDJPY,USDCAD,USDCHF,USDJPY";
extern ENUM_TIMEFRAMES TradingTimeFrame=PERIOD_M5;
extern int     EventTimerIntervalSeconds=60;
extern int     ChartCloseTimerMultiple=15;
////////////////////////////////////////////////////////////////////////////////
int            NoOfPairs;// Holds the number of pairs passed by the user via the inputs screen
string         TradePair[]; //Array to hold the pairs traded by the user
string         tradingStatus[];//One of the trading status constants
datetime       ttfCandleTime[];
double         ask=0, bid=0, spread=0;//Replaces Ask. Bid, Digits. factor replaces Point
int            digits;//Replaces Digits.
double         longSwap=0, shortSwap=0;
int            OpenTrades=0, OpenLongTrades=0, OpenShortTrades=0;
bool           BuySignal=false, SellSignal=false;
string         TradingTimeFrameDisplay="";
int            TimerCount=0;//Count timer events for closing charts
////////////////////////////////////////////////////////////////////////////////

extern string  ads1="================================================================";
//Additional strategies. These can be used in conjunction with all the original Candle Power
//features. 
extern string  DirectionalTrading="---- Directional trade filters ----";
extern string  thgi="-- HGI --";
extern bool    UseHgiTrendFilter=true;
extern ENUM_TIMEFRAMES HgiTradeFilterTimeFrame=PERIOD_H4;
extern bool    TradeTrendArrows=true;
extern bool    TradeBlueWavyLines=true;
////////////////////////////////////////////////////////////////////////////////////////
string         HgiStatus[];//Constants defined at top of file//Amended HGI code
string         TradeHgiTimeFrameDisplay="";
datetime       OldHgiBarTime[];//Hold the open time of each candle.
////////////////////////////////////////////////////////////////////////////////////////

extern string  asep1="----";
extern string  ssl="-- Super Slope --";
extern bool    UseSuperSlope=true;
extern ENUM_TIMEFRAMES SsTimeFrame=PERIOD_D1;
extern int     SsTradingMaxBars              = 0;
extern bool    SsTradingAutoTimeFrame        = true;
extern double  SsTradingDifferenceThreshold  = 0.0;
extern double  SsTradingLevelCrossValue      = 2.0;
extern int     SsTradingSlopeMAPeriod        = 5; 
extern int     SsTradingSlopeATRPeriod       = 50; 
////////////////////////////////////////////////////////////////////////////////////////
string         SsStatus[];//For shifts 0 to 2. Colours defined at top of file
string         SsTimeFrameDisplay="";
datetime       OldSsBarTime[];//Hold the open time of each candle.
////////////////////////////////////////////////////////////////////////////////////////

extern string  asep2="----";
//Bob's H4 240 trend filter. Market above the ma = buy only; below ma = sell only
extern string  mai="---- Moving average ----";
extern bool    UseBobMovingAverage=false;
extern ENUM_TIMEFRAMES MaTimeFrame=PERIOD_H4;//Defaults to Bob's favourite
 int     MaShift=0;
extern int     MaPeriod=240;
extern ENUM_MA_METHOD MaMethod= MODE_EMA;
extern ENUM_APPLIED_PRICE MaAppliedPrice=PRICE_CLOSE;
////////////////////////////////////////////////////////////////////////////////////////
string         MaStatus[];//up, down or none constants
string         MaTimeFrameDisplay="";
datetime       OldMaBarTime[];//Hold the open time of each candle.
////////////////////////////////////////////////////////////////////////////////////////

extern string  asep3="----";
extern string  pea="-- Peaky --";
extern bool    UsePeaky = true;
extern ENUM_TIMEFRAMES PeakyTimeFrame=PERIOD_M5;
extern int     NoOfBarsOnChart=1682;
////////////////////////////////////////////////////////////////////////////////////////
string         PeakyStatus[];// One of the longdirection/shortdirection constants
string         PeakyTimeFrameDisplay="";
datetime       OldPeakyBarTime[];//Hold the open time of each candle.
////////////////////////////////////////////////////////////////////////////////////////


extern string  s2="================================================================";
//Enhanced screen feedback display code provided by Paul Batchelor (lifesys). Thanks Paul; this is fantastic.
extern string  chf               ="---- Chart feedback display ----";
int     ChartRefreshDelaySeconds=0;
int     DisplayGapSize    = 30; // if using Comments
// ****************************** added to make screen Text more readable
bool    DisplayAsText     = true;  // replaces Comment() with OBJ_LABEL text
bool    KeepTextOnTop     = true;//Disable the chart in foreground CrapTx setting so the candles do not obscure the text
extern int     DisplayX          = 100;
extern int     DisplayY          = 0;
extern int     fontSise          = 10;
extern double  RowDistance       = 2.5;
extern string  fontName          = "Arial";
extern color   colour            = Yellow;

extern color   UpColor           = Lime;
extern color   DnColor           = Red;
extern color   NoColor           = Gray;

////////////////////////////////////////////////////////////////////////////////////////
int            DisplayCount;
string         Gap,ScreenMessage,WhatToShow="All";

////////////////////////////////////////////////////////////////////////////////////////

//Calculating the factor needed to turn pip values into their correct points value to accommodate different Digit size.
//Thanks to Tommaso for coding the function.
double         factor;//For pips/points stuff.


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

   //create timer
   EventSetTimer(EventTimerIntervalSeconds);

   //Extract the pairs traded by the user
   ExtractPairs();

   Gap="";
   if (DisplayGapSize >0)
   {
      for (int cc=0; cc< DisplayGapSize; cc++)
      {
         Gap = StringConcatenate(Gap, " ");
      }   
   }//if (DisplayGapSize >0)

   
   ReadIndicatorValues();//Initial read

   if (MinimiseChartsAfterOpening)
      ShrinkCharts();

   TradeHgiTimeFrameDisplay = GetTimeFrameDisplay(HgiTradeFilterTimeFrame);
   SsTimeFrameDisplay = GetTimeFrameDisplay(SsTimeFrame);
   MaTimeFrameDisplay = GetTimeFrameDisplay(MaTimeFrame);
   PeakyTimeFrameDisplay = GetTimeFrameDisplay(PeakyTimeFrame);
   TradingTimeFrameDisplay = GetTimeFrameDisplay(TradingTimeFrame);
   

   DisplayUserFeedback();

   
   return(INIT_SUCCEEDED);
}

void ExtractPairs()
{
   
   StringSplit(PairsToTrade,',',TradePair);
   NoOfPairs = ArraySize(TradePair);
   
   
   string AddChar = StringSubstr(Symbol(),6,4);
   
   // Resize the arrays appropriately
   ArrayResize(TradePair, NoOfPairs);
   ArrayResize(tradingStatus, NoOfPairs);
   ArrayResize(ttfCandleTime, NoOfPairs);
   ArrayResize(HgiStatus, NoOfPairs);
   ArrayResize(OldHgiBarTime, NoOfPairs);
   ArrayResize(SsStatus, NoOfPairs);
   ArrayResize(OldSsBarTime, NoOfPairs);
   ArrayResize(OldPeakyBarTime, NoOfPairs);
   ArrayResize(PeakyStatus, NoOfPairs);
   ArrayResize(OldMaBarTime, NoOfPairs);
   ArrayResize(MaStatus, NoOfPairs);
   
   

 
   
   for (int cc = 0; cc < NoOfPairs; cc ++)
   {
      TradePair[cc] = StringTrimLeft(TradePair[cc]);
      TradePair[cc] = StringTrimRight(TradePair[cc]);
      TradePair[cc] = StringConcatenate(TradePair[cc], AddChar);
   }//for (int cc; cc<NoOfPairs; cc ++)

}//End void ExtractPairs()


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    
   ArrayFree(TradePair);
   ArrayResize(TradePair, 0);
   ArrayFree(tradingStatus);
   ArrayResize(tradingStatus, 0);
   ArrayFree(ttfCandleTime);
   ArrayResize(ttfCandleTime, 0);
   ArrayFree(HgiStatus);
   ArrayResize(HgiStatus, 0);
   ArrayFree(OldHgiBarTime);
   ArrayResize(OldHgiBarTime, 0);
   ArrayFree(SsStatus);
   ArrayResize(SsStatus, 0);
   ArrayFree(OldSsBarTime);
   ArrayResize(OldSsBarTime, 0);
   ArrayFree(OldPeakyBarTime);
   ArrayResize(OldPeakyBarTime, 0);
   ArrayFree(PeakyStatus);
   ArrayResize(PeakyStatus, 0);
   ArrayFree(MaStatus);
   ArrayResize(OldMaBarTime, 0);
   

   removeAllObjects();
   
   //--- destroy timer
   EventKillTimer();
       
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   
}

string GetTimeFrameDisplay(int tf)
{

   if (tf == 0)
      tf = Period();
      
   
   if (tf == PERIOD_M1)
      return "M1";
      
   if (tf == PERIOD_M5)
      return "M5";
      
   if (tf == PERIOD_M15)
      return "M15";
      
   if (tf == PERIOD_M30)
      return "M30";
      
   if (tf == PERIOD_H1)
      return "H1";
      
   if (tf == PERIOD_H4)
      return "H4";
      
   if (tf == PERIOD_D1)
      return "D1";
      
   if (tf == PERIOD_W1)
      return "W1";
      
   if (tf == PERIOD_MN1)
      return "Monthly";
      
   return("No recognisable time frame selected");

}//string GetTimeFrameDisplay()

//+--------------------------------------------------------------------+
//| Paul Bachelor's (lifesys) text display module to replace Comment()|
//+--------------------------------------------------------------------+
void SM(string message)
{
   if (DisplayAsText) 
   {
      DisplayCount++;
      Display(message);
   }
   else
      ScreenMessage = StringConcatenate(ScreenMessage,Gap, message);
      
}//End void SM()

//   ************************* added for OBJ_LABEL
void removeAllObjects()
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   if (StringFind(ObjectName(i),"OAM-",0) > -1) 
      ObjectDelete(ObjectName(i));
}//End void removeAllObjects()
//   ************************* added for OBJ_LABEL

void Display(string text)
{
   string lab_str = "OAM-" + IntegerToString(DisplayCount);  
   double ofset = 0;
   string textpart[5];
   uint w,h;
   
   for (int cc = 0; cc < 5; cc++)
   {
      textpart[cc] = StringSubstr(text,cc*63,64);
      if (StringLen(textpart[cc]) ==0) continue;
      lab_str = lab_str + IntegerToString(cc);
      
      ObjectCreate(lab_str, OBJ_LABEL, 0, 0, 0);
      ObjectSet(lab_str, OBJPROP_CORNER, 0);
      ObjectSet(lab_str, OBJPROP_XDISTANCE, DisplayX + ofset);
      ObjectSet(lab_str, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(int)(fontSise*1.5));
      ObjectSet(lab_str, OBJPROP_BACK, false);
      ObjectSetText(lab_str, textpart[cc], fontSise, fontName, colour);
      
      /////////////////////////////////////////////////
      //Calculate label size
      //Tomele supplied this code to eliminate the gaps in the text.
      //Thanks Thomas.
      TextSetFont(fontName,-fontSise*10,0,0);
      TextGetSize(textpart[cc],w,h);
      
      //Trim trailing space
      if (StringSubstr(textpart[cc],63,1)==" ")
         ofset+=(int)(w-fontSise*0.3);
      else
         ofset+=(int)(w-fontSise*0.7);
      /////////////////////////////////////////////////
         
   }//for (int cc = 0; cc < 5; cc++)
}

void DisplayUserFeedback()
{
   string text = "";
   int cc = 0;
   
 
   //   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   removeAllObjects();
   //   *************************

 
   ScreenMessage = "";
   //ScreenMessage = StringConcatenate(ScreenMessage,Gap + NL);
   //SM(NL);
   
   SM("Updates for this EA are to be found at http://www.stevehopwoodforex.com"+NL);
   SM("Feeling generous? Help keep the coder going with a small Paypal donation to pianodoodler@hotmail.com"+NL);

   SM(NL);
   
   SM("HG = Holy Graily Bob Indicator, SS = Super Slope, PK = Peaky, MA = Bobs Moving Averages, TS = Trading Status"+NL);
   SM("Click a pair to open its chart. Click the cyan table name to switch between all pairs, tradable pairs and pairs with open trades"+NL);

   SM(NL);
   
   DisplayMatrix();
 
   //Comment(ScreenMessage);

}//End void DisplayUserFeedback()

void DisplayMatrix()
{
   int TextXPos=0;
   int TextYPos=DisplayY+DisplayCount*(int)(fontSise*1.5)+(int)(fontSise*3);
   
   int TPLength=(int)(fontSise*7);
   int HGLength=(int)(fontSise*4);
   int SSLength=(int)(fontSise*4);
   int PKLength=(int)(fontSise*4);
   int MALength=(int)(fontSise*4);
   int TSLength=(int)(fontSise*7.5);
   int TRLength=(int)(fontSise*7);
   int SWLength=(int)(fontSise*5);
   int SPLength=(int)(fontSise*7);
   
   //Display Headers
   
   TextXPos=DisplayX;
   
   string text1,text2;
   
   if (WhatToShow=="All")
   {
      text1="All";
      text2="Pairs";
   }
   else if (WhatToShow=="Tradables")
   {
      text1="Tradable";
      text2="Pairs";
   }
   else if (WhatToShow=="OpenTrades")
   {
      text1="Open";
      text2="Trades";
   }
   
   DisplayTextLabel(text1,TextXPos,TextYPos,ANCHOR_LEFT_UPPER,"SWITCH", 0, Cyan);
   DisplayTextLabel(text2,TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_LEFT_UPPER,"SWITCH", 0, Cyan);
   
   TextXPos+=TPLength;
   TextXPos+=fontSise*2;
      
   if (UseHgiTrendFilter)
   {
      DisplayTextLabel("HG",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=HGLength;
   }
   
   if (UseSuperSlope)
   {
      DisplayTextLabel("SS",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=HGLength;
   }
   
   if (UsePeaky)
   {
      DisplayTextLabel("PK",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=PKLength;
   }
   
   if (UseBobMovingAverage)
   {
      DisplayTextLabel("MA",TextXPos,TextYPos+(int)(fontSise*1.5));
      TextXPos+=MALength;
   }
   
   DisplayTextLabel("TS",TextXPos,TextYPos+(int)(fontSise*1.5));
   TextXPos+=TSLength;
   
   DisplayTextLabel("Open",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   DisplayTextLabel("Trades",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);
   TextXPos+=TRLength;
   
   DisplayTextLabel(" Long",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   DisplayTextLabel("Swap",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);
   TextXPos+=SWLength;
   
   DisplayTextLabel(" Short",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   DisplayTextLabel("Swap",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);
   TextXPos+=SWLength;
   
   TextXPos+=fontSise*3;
   
   DisplayTextLabel("Actual",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   DisplayTextLabel("Spread",TextXPos,TextYPos+(int)(fontSise*1.5),ANCHOR_RIGHT_UPPER);

   TextYPos+=3*(int)(fontSise*1.5);
   
   //Display trade pairs 
        
   for (int cc = 0; cc <= ArraySize(TradePair) - 1; cc++)
   {
      CountOpenTrades(TradePair[cc]);
      
      if (WhatToShow=="Tradables")
         if (tradingStatus[cc]==untradable)
            continue;
         
      if (WhatToShow=="OpenTrades")
         if (OpenTrades==0)
           continue;

      GetBasics(TradePair[cc]);
      
      TextXPos=DisplayX;
      DisplayTextLabel(TradePair[cc],TextXPos,TextYPos, ANCHOR_LEFT_UPPER,TradePair[cc]);
      TextXPos+=TPLength;

      TextXPos+=fontSise*2;
      
      if (UseHgiTrendFilter)
      {
         DisplayTextLabel(HgiStatus[cc],TextXPos,TextYPos);
         TextXPos+=HGLength;
      }
      
      if (UseSuperSlope)
      {
         DisplayTextLabel(SsStatus[cc],TextXPos,TextYPos);
         TextXPos+=SSLength;
      }
      
      if (UsePeaky)
      {
         DisplayTextLabel(PeakyStatus[cc],TextXPos,TextYPos);
         TextXPos+=PKLength;
      }
      
      if (UseBobMovingAverage)
      {
         DisplayTextLabel(MaStatus[cc],TextXPos,TextYPos);
         TextXPos+=MALength;
      }
      
      DisplayTextLabel(tradingStatus[cc],TextXPos,TextYPos);
      TextXPos+=TSLength;

      string trades="";
      if (OpenLongTrades==0 && OpenShortTrades==0)
         trades="----";
      else if (OpenLongTrades>0 && OpenShortTrades>0)
         trades=StringConcatenate(IntegerToString(OpenLongTrades),"B,",IntegerToString(OpenShortTrades),"S");
      else if (OpenLongTrades>0)
         trades=StringConcatenate(IntegerToString(OpenLongTrades),"B");
      else if (OpenShortTrades>0)
         trades=StringConcatenate(IntegerToString(OpenShortTrades),"S");
         
      color tcolor=NoColor;
      if (OpenLongTrades>OpenShortTrades)
         tcolor=UpColor;
      else if (OpenLongTrades<OpenShortTrades)
         tcolor=DnColor;
      
      DisplayTextLabel(trades,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER, "", 0, tcolor);
      TextXPos+=TRLength;
      
      DisplayTextLabel(DoubleToStr(longSwap, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      TextXPos+=SWLength;
      
      DisplayTextLabel(DoubleToStr(shortSwap, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      TextXPos+=SWLength;
      
      TextXPos+=fontSise*3;
      
      DisplayTextLabel(DoubleToStr(spread, 1) + " pips",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);

      TextYPos+=(int)(fontSise*RowDistance);
      
   }//for (cc = 0; cc <= ArraySize(TradePair) -1; cc++)
   
}//End void DisplayMatrix()

void DisplayTextLabel(string text, int xpos, int ypos, ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, string pair="", int tf=0, color scol=NONE)
{

   if (scol==NONE)
      scol=colour;
      
   if (text=="Long"||text=="Blue"||text=="Up arrow"||text=="Up wave"||text=="Up"||text=="Tradable long") scol=UpColor;
   else if (text=="Short"||text=="Red"||text=="Dn arrow"||text=="Dn wave"||text=="Down"||text=="Tradable short") scol=DnColor;
   else if (text=="No signal"||text=="White"||text=="Not tradable")scol=NoColor;
   else if (text=="Yellow range wave")scol=Yellow;
   
   if (text=="Long"||text=="Blue"||text=="Up arrow"||text=="Up") text="á";
   else if (text=="Short"||text=="Red"||text=="Dn arrow"||text=="Down") text="â";
   else if (text=="Up wave"||text=="Dn wave"||text=="Yellow range wave") text="h";
   else if (text=="Tradable long"||text=="Tradable short") text="ü";
   else if (text=="No signal"||text=="White"||text=="Not tradable")text="û";
   
   string font=fontName;
   int sise=fontSise;
   if (text=="á"||text=="â"||text=="h"||text=="ü"||text=="û")
   {
      font="Wingdings";
      sise=(int)MathRound(fontSise*1.2);
   }
   
   string lab_str;
   if (pair=="") 
      //Text label
      lab_str = "OAM-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else if (pair=="CLOSE") 
      //Close other charts button
      lab_str = "OAM-CLOSE-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else if (pair=="SWITCH") 
      //Switch displays button
      lab_str = "OAM-SWITCH-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else 
      //Clickable label needs pair and timeframe for OpenChart()
      lab_str = "OAM-BTN-" + pair + "-" + IntegerToString(tf)+"-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   

   ObjectCreate(lab_str, OBJ_LABEL, 0, 0, 0); 
   ObjectSet(lab_str, OBJPROP_CORNER, 0);
   ObjectSet(lab_str, OBJPROP_XDISTANCE, xpos); 
   ObjectSet(lab_str, OBJPROP_YDISTANCE, ypos); 
   ObjectSet(lab_str, OBJPROP_BACK, false);
   ObjectSetText(lab_str, text, sise, font, scol);
   ObjectSetInteger(0,lab_str,OBJPROP_ANCHOR,anchor); 
   
}//End void DisplayTextLabel(string text, int xpos, int ypos, ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)

void GetBasics(string symbol)
{
   //Sets up bid, ask, digits, factor for the passed pair
   bid = MarketInfo(symbol, MODE_BID);
   ask = MarketInfo(symbol, MODE_ASK);
   digits = (int)MarketInfo(symbol, MODE_DIGITS);
   factor = GetPipFactor(symbol);
   spread = (ask - bid) * factor;
   longSwap = MarketInfo(symbol, MODE_SWAPLONG);
   shortSwap = MarketInfo(symbol, MODE_SWAPSHORT);
   
      
}//End void GetBasics(string symbol)

int GetPipFactor(string Xsymbol)
{
   //Code from Tommaso's APTM
   
   static const string factor1000[]={"SEK","TRY","ZAR","MXN"};
   static const string factor100[]         = {"JPY","XAG","SILVER","BRENT","WTI"};
   static const string factor10[]          = {"XAU","GOLD","SP500","US500Cash","US500","Bund"};
   static const string factor1[]           = {"UK100","WS30","DAX30","NAS100","CAC40","FRA40","GER30","ITA40","EUSTX50","JPN225","US30Cash","US30"};
   int j = 0;
   
   int xFactor=10000;       // correct xFactor for most pairs
   if(MarketInfo(Xsymbol,MODE_DIGITS)<=1) xFactor=1;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==2) xFactor=10;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==3) xFactor=100;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==4) xFactor=1000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==5) xFactor=10000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==6) xFactor=100000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==7) xFactor=1000000;
   for(j=0; j<ArraySize(factor1000); j++)
   {
      if(StringFind(Xsymbol,factor1000[j])!=-1) xFactor=1000;
   }
   for(j=0; j<ArraySize(factor100); j++)
   {
      if(StringFind(Xsymbol,factor100[j])!=-1) xFactor=100;
   }
   for(j=0; j<ArraySize(factor10); j++)
   {
      if(StringFind(Xsymbol,factor10[j])!=-1) xFactor=10;
   }
   for(j=0; j<ArraySize(factor1); j++)
   {
      if(StringFind(Xsymbol,factor1[j])!=-1) xFactor=1;
   }

   return (xFactor);
}//End int GetPipFactor(string Xsymbol)


void ChartAutomation(string symbol, int index)
{
   long currChart = 0, prevChart = ChartFirst();
   int cc = 0, limit = ArraySize(TradePair) -1;
   
   //We want to close charts that are not tradable
   if (TimerCount==0)//We do this only every ChartCloseTimerMultiple cycle
      if (tradingStatus[index] == untradable)
      {
         //We cannot close charts with open trades
         CountOpenTrades(symbol);
         if (OpenTrades > 0)
            return;
            
         while (cc < limit)
         {
            currChart = ChartNext(prevChart); // Get the new chart ID by using the previous chart 
            if(currChart < 0) 
               return;// Have reached the end of the chart list 
         
            //We do not want to close the reserved chart
            if (ChartSymbol(currChart) == ReservedPair)
            {
               prevChart=currChart;// let's save the current chart ID for the ChartNext() 
               cc++;
               continue;
            }//if (ChartSymbol() == ReservedPair)
               
            if (ChartSymbol(currChart) == symbol)
               ChartClose(currChart);   
            
            prevChart=currChart;// let's save the current chart ID for the ChartNext() 
            cc++;
         }//while (cc < limit)
         
         return;   
      }//if (tradingStatus[cc] == untradable)
   
   //Now open a new chart if there is not one already open.
   //First check that the chart is a tradable chart
   if (tradingStatus[index] != tradablelong)
      if (tradingStatus[index] != tradableshort)
         return;
         
   bool found = false;
   prevChart = ChartFirst();
   //Look for a chart already opened
   while (cc < limit)
   {
      currChart = ChartNext(prevChart); // Get the new chart ID by using the previous chart 
      if(currChart < 0) 
         break;// Have reached the end of the chart list 
   
      
      if (ChartSymbol(currChart) !=ReservedPair)
         if (ChartSymbol(currChart) == symbol)
         {
            found = true;
            break;
         }//if (ChartSymbol(currChart) == symbol)
            
      prevChart=currChart;// let's save the current chart ID for the ChartNext() 
      cc++;
   }//while (cc < limit)
   
   if (!found)
   {
      //Chart not found, so open one
      long newChartId = ChartOpen(symbol, TradingTimeFrame);
      //Alert(symbol, "  ", TemplateName);
      ChartApplyTemplate(newChartId, TemplateName);
      ChartRedraw(newChartId);
   }//if (!found)
   
   
}//End void ChartAutomation(string symbol)

double GetSuperSlope(string symbol, int tf, int maperiod, int atrperiod, int pShift )
{
   double dblTma, dblPrev;
   int shiftWithoutSunday = pShift;
   
   double atr = iATR( symbol, tf, atrperiod, shiftWithoutSunday + 10 ) / 10;
   double result = 0.0;
   if ( atr != 0 )
   {
      dblTma = iMA( symbol, tf, maperiod, 0, MODE_LWMA, PRICE_CLOSE, shiftWithoutSunday );
      dblPrev = ( iMA( symbol, tf, maperiod, 0, MODE_LWMA, PRICE_CLOSE, shiftWithoutSunday + 1 ) * 231 + iClose( symbol, tf, shiftWithoutSunday ) * 20 ) / 251;

      result = ( dblTma - dblPrev ) / atr;
   }
   
   return ( result );
   
}//GetSuperSlope(}

void GetPeakyTradeDirection(string symbol, int tf, int bars, int index)
{
   //Set PeakyStatus to the direction implied by the chart peak hilo
   
   int Highest = iHighest(symbol, tf, MODE_CLOSE, bars);
   int Lowest = iLowest(symbol, tf, MODE_CLOSE, bars);
   
   PeakyStatus[index] = longdirection;//Default
   if (Highest < Lowest)
      PeakyStatus[index] = shortdirection;

}//End void GetPeakyTradeDirection(string symbol, int tf, int bars)

double GetMa(string symbol, int tf, int period, int mashift, int method, int ap, int shift)
{
   return(iMA(symbol, tf, period, mashift, method, ap, shift) );
}//End double GetMa(int tf, int period, int mashift, int method, int ap, int shift)

void ReadIndicatorValues()
{

   removeAllObjects();
   //Comment(Gap, "******************** DOING THE CALCULATIONS ********************");
   
   for (int PairIndex = 0; PairIndex <= ArraySize(TradePair) - 1; PairIndex++)
   {
      double val = 0;
      int cc = 0;
      
      string symbol = TradePair[PairIndex];//Makes typing easier
      GetBasics(symbol);//Bid etc
      
      tradingStatus[PairIndex] = untradable;
      
      //HGI
      if (UseHgiTrendFilter)
      {
         if (OldHgiBarTime[PairIndex] != iTime(symbol, HgiTradeFilterTimeFrame, 0) )
         {
            OldHgiBarTime[PairIndex] = iTime(symbol, HgiTradeFilterTimeFrame, 0);
            
            //Using hgi_lib
            //The HGI library functionality was added by tomele. Many thanks Thomas.
            SIGNAL signal = 0;
            SLOPE  slope  = 0;

            cc = 1;   
            HgiStatus[PairIndex] = hginoarrow;
            
            while(HgiStatus[PairIndex] == hginoarrow)
            {
               signal = getHGISignal(symbol, HgiTradeFilterTimeFrame, cc);//This library function looks for arrows.
               slope  = getHGISlope (symbol, HgiTradeFilterTimeFrame, cc);//This library function looks for wavy lines.
            
               if (signal==TRENDUP)
               {
                  if (TradeTrendArrows)
                  HgiStatus[PairIndex] = hgiuparrowtradable;
               }
               else 
               if (signal==TRENDDN)
               {
                  if (TradeTrendArrows)
                     HgiStatus[PairIndex] = hgidownarrowtradable;
               }
               else 
               if (slope==TRENDBELOW)
               {
                  if (TradeBlueWavyLines)
                     HgiStatus[PairIndex] = hgibluewavylong;
               }
               else 
               if (slope==TRENDABOVE)
               {
                  if (TradeBlueWavyLines)
                     HgiStatus[PairIndex] = hgibluewavyshort;
               }
               //Yellow wavy
               else
               if (slope == RANGEABOVE || slope == RANGEBELOW)
               {
                  HgiStatus[PairIndex] = hgiyellowwavy;
               }

               /*else
               if (signal==RADUP)
               {
                  if (RadTradingAllowed)
                  HgiStatus[PairIndex] = hgiuparrowtradable;
               }
               else 
               if (signal==RADDN)
               {
                  if (RadTradingAllowed)
                     HgiStatus[PairIndex] = hgiuparrowtradable;
               */
               
               cc++;
            }//while(HgiStatus[PairIndex] == hginoarrow)
         
         }//if (OldHgiBarTime != iTime(symbol, HgiTradeFilterTimeFrame, 0) )
         
      
      }//if (UseHgiTrendFilter)
      
      //Read SuperSlope at the open of each new trading time frame candle
      if (UseSuperSlope)
      {   
         if (OldSsBarTime[PairIndex] != iTime(symbol, TradingTimeFrame, 0) )
         {  
            OldSsBarTime[PairIndex] = iTime(symbol, TradingTimeFrame, 0);
            
            val = GetSuperSlope(symbol, SsTimeFrame,SsTradingSlopeMAPeriod,SsTradingSlopeATRPeriod,0);
               
            //Changed by tomele. Many thanks Thomas.
            //Set the colours
            SsStatus[PairIndex] = white;
            
            if (val > 0)  //buy
               if (val - SsTradingDifferenceThreshold/2 > 0) //blue
                  SsStatus[PairIndex] = blue;
   
            if (val < 0)  //sell
               if (val + SsTradingDifferenceThreshold/2 < 0) //red
                  SsStatus[PairIndex] = red;
                                                     
         }//if (OldSsBarTime != iTime(symbol, TradingTimeFrame, 0) )
         
      }//if (UseSuperSlope)


      //Peaky
      if (UsePeaky)
      {
         if (OldPeakyBarTime[PairIndex] != iTime(symbol, PeakyTimeFrame, 0) )
         {
            OldPeakyBarTime[PairIndex] = iTime(symbol, PeakyTimeFrame, 0);
            GetPeakyTradeDirection(symbol, PeakyTimeFrame, NoOfBarsOnChart, PairIndex);
         }//if (OldPeakyBarTime[PairIndex] != iTime(symbol, PeakyTimeFrame, 0) )
         
      
      }//if (UsePeaky)
      
      
      //Bob's moving average. Read once a minute so it is up to dayt
      if (UseBobMovingAverage)
      {
         if (OldMaBarTime[PairIndex] != iTime(symbol, PERIOD_M1, 0) )
         {
            OldMaBarTime[PairIndex] = iTime(symbol, PERIOD_M1, 0);
            val = GetMa(symbol, MaTimeFrame, MaPeriod, MaShift, MaMethod, MaAppliedPrice, 0);
            if (bid > val) 
            {
               MaStatus[PairIndex] = up;
            }//if (Bid > val) 
            
            if (bid < val) 
            {
               MaStatus[PairIndex] = down;
            }//if (Bid < val) 

         }//if (OldMaBarTime[PairIndex] != iTime(symbol, PERIOD_M1, 0) )
      
      
      }//if (UseBobMovingAverage)
      
      
      
      //Code to compare all the indi values and generate a signal if they all pass
      if (!UseBobMovingAverage || MaStatus[PairIndex] == up)
         if (!UseSuperSlope || SsStatus[PairIndex] == blue)
            if (!UseHgiTrendFilter || (HgiStatus[PairIndex] == hgiuparrowtradable || HgiStatus[PairIndex] == hgibluewavylong) )
               if (!UsePeaky || PeakyStatus[PairIndex] == longdirection)
                  tradingStatus[PairIndex] = tradablelong;
      
      if (!UseBobMovingAverage || MaStatus[PairIndex] == down)
         if (!UseSuperSlope || SsStatus[PairIndex] == red)
            if (!UseHgiTrendFilter || (HgiStatus[PairIndex] == hgidownarrowtradable || HgiStatus[PairIndex] == hgibluewavyshort) )
               if (!UsePeaky || PeakyStatus[PairIndex] == shortdirection)
                  tradingStatus[PairIndex] = tradableshort;

      //Yellow wavy
      if (UseHgiTrendFilter)
         if (HgiStatus[PairIndex] == hgiyellowwavy)
            tradingStatus[PairIndex] = untradable;

     //Chart automation
     // if (tradingStatus[PairIndex] == tradablelong || tradingStatus[PairIndex] == tradableshort)
         if (AutomateChartOpeningAndClosing)
            ChartAutomation(symbol, PairIndex);
            
      
   }//for (int cc = 0; cc <= ArraySize(TradePair); cc++)

   Comment("");
   
}//void ReadIndicatorValues()


void CountOpenTrades(string symbol)
{

   OpenTrades=0;
   OpenLongTrades=0;
   OpenShortTrades=0;
   
   if (OrdersTotal() == 0)
      return;
      
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      
      //Ensure the trade is still open
      if (!OrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      //Ensure the EA 'owns' this trade
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      
      OpenTrades++;
      
      if (OrderType()==OP_BUY)
         OpenLongTrades++;
         
      if (OrderType()==OP_SELL)
         OpenShortTrades++;
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
}//End void CountOpenTrades()

bool chartMinimize(long chartID = 0) 
{

   //This code was provided by Rene. Many thanks Rene.
   
   if (chartID == 0) chartID = ChartID();
   
   int chartHandle = (int)ChartGetInteger( chartID, CHART_WINDOW_HANDLE, 0 );
   int chartParent = GetParent(chartHandle);
   
   return( ShowWindow( chartParent, SW_FORCEMINIMIZE ) );
}//End bool chartMinimize(long chartID = 0) 

void ShrinkCharts()
{
   //Code provided by Rene. Many thanks, Rene
   
   long chartID = ChartFirst();
   
   while( chartID >= 0 ) {
      if ( !chartMinimize( chartID ) ) {
         PrintFormat("Couldn't minimize %I64d (Symbol: %s, Timeframe: %s)", chartID, ChartSymbol(chartID), EnumToString(ChartPeriod(chartID)) );
         //break;
      }
      chartID = ChartNext( chartID );
   }
   
   //PrintFormat("Waiting 10 seconds");
   //Sleep(10000);

}//End void ShrinkCharts()

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---

   if (!IsTradeAllowed() )
   {
      Comment("                          THIS EXPERT HAS LIVE TRADING DISABLED");
      return;
   }//if (!IsTradeAllowed() )
   
   //Remove the comment now it is no longer needed
   if(ChartGetString(ChartID(),CHART_COMMENT) != "")
      Comment("");

   TimerCount++;
   if (TimerCount>=ChartCloseTimerMultiple)//Now we have a chort closing cycle
      TimerCount=0;

   ReadIndicatorValues();
   
   if (MinimiseChartsAfterOpening)
      ShrinkCharts();
   
   DisplayUserFeedback();
   
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Chart Event function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id==CHARTEVENT_OBJECT_CLICK)
      if(StringFind(sparam,"OAM-BTN")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         string result[];
         int tokens=StringSplit(sparam,StringGetCharacter("-",0),result);
         string pair=result[2];
         int tf=TradingTimeFrame;
         
         OpenChart(pair,tf);
         return;
      }
      
      else if(StringFind(sparam,"OAM-SWITCH")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         SwitchDisplays();
         return;
      }
      
}//End void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)

void OpenChart(string pair,int tf)
{
   //If chart is already open, bring it to top
   long nextchart=ChartFirst();
   do
   {
      string symbol=ChartSymbol(nextchart);
      int period=ChartPeriod(nextchart);
      
      if(symbol==pair && period==tf && nextchart!=ChartID())
      {
         ChartSetInteger(nextchart,CHART_BRING_TO_TOP,true);
         return;
      }
   }
   while((nextchart=ChartNext(nextchart))!=-1);
   
   //Chart not found, so open a new one
   long newchartid=ChartOpen(pair,tf);
   ChartApplyTemplate(newchartid,TemplateName);
   
   TimerCount=1;//Restart timer to keep it from closing too early
  
}//End void OpenChart(string pair,int tf)
 

void SwitchDisplays()
{
   if (WhatToShow=="All")
      WhatToShow="Tradables";
   else if (WhatToShow=="Tradables")
      WhatToShow="OpenTrades";
   else if (WhatToShow=="OpenTrades")
      WhatToShow="All";
   DisplayUserFeedback();
}//End void SwitchDisplays()

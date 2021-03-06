//+------------------------------------------------------------------+
//|                   TDI Red Green Alerts mod. 2015.fxdaytrader.mq4 | 
//|                   this is a mod. one of the famous TDI indicator |
//|                                    Traders Dynamic Index.mq4     |
//|                                    Copyright © 2006, Dean Malone |
//|                                    www.compassfx.com             |
//|          mod. 01.2015, Marc (fxdaytrader), http://ForexBaron.net |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//|                     Traders Dynamic Index                        |
//|                                                                  |
//|  This hybrid indicator is developed to assist traders in their   |
//|  ability to decipher and monitor market conditions related to    |
//|  trend direction, market strength, and market volatility.        |
//|                                                                  | 
//|  Even though comprehensive, the T.D.I. is easy to read and use.  |
//|                                                                  |
//|  Green line  = RSI Price line                                    |
//|  Red line    = Trade Signal line                                 |
//|  Blue lines  = Volatility Band                                   | 
//|  Yellow line = Market Base Line                                  |  
//|                                                                  |
//|  Trend Direction - Immediate and Overall                         |
//|   Immediate = Green over Red...price action is moving up.        |
//|               Red over Green...price action is moving down.      |
//|                                                                  |   
//|   Overall = Yellow line trends up and down generally between the |
//|             lines 32 & 68. Watch for Yellow line to bounces off  |
//|             these lines for market reversal. Trade long when     |
//|             price is above the Yellow line, and trade short when |
//|             price is below.                                      |        
//|                                                                  |
//|  Market Strength & Volatility - Immediate and Overall            |
//|   Immediate = Green Line - Strong = Steep slope up or down.      | 
//|                            Weak = Moderate to Flat slope.        |
//|                                                                  |               
//|   Overall = Blue Lines - When expanding, market is strong and    |
//|             trending. When constricting, market is weak and      |
//|             in a range. When the Blue lines are extremely tight  |                                                       
//|             in a narrow range, expect an economic announcement   | 
//|             or other market condition to spike the market.       |
//|                                                                  |               
//|                                                                  |
//|  Entry conditions                                                |
//|   Scalping  - Long = Green over Red, Short = Red over Green      |
//|   Active - Long = Green over Red & Yellow lines                  |
//|            Short = Red over Green & Yellow lines                 |    
//|   Moderate - Long = Green over Red, Yellow, & 50 lines           |
//|              Short= Red over Green, Green below Yellow & 50 line |
//|                                                                  |
//|  Exit conditions*                                                |   
//|   Long = Green crosses below Red                                 |
//|   Short = Green crosses above Red                                |
//|   * If Green crosses either Blue lines, consider exiting when    |
//|     when the Green line crosses back over the Blue line.         |
//|                                                                  |
//|                                                                  |
//|  IMPORTANT: The default settings are well tested and proven.     |
//|             But, you can change the settings to fit your         |
//|             trading style.                                       |
//|                                                                  |
//|                                                                  |
//|  Price & Line Type settings:                                     |                
//|   RSI Price settings                                             |               
//|   0 = Close price     [DEFAULT]                                  |               
//|   1 = Open price.                                                |               
//|   2 = High price.                                                |               
//|   3 = Low price.                                                 |               
//|   4 = Median price, (high+low)/2.                                |               
//|   5 = Typical price, (high+low+close)/3.                         |               
//|   6 = Weighted close price, (high+low+close+close)/4.            |               
//|                                                                  |               
//|   RSI Price Line & Signal Line Type settings                     |               
//|   0 = Simple moving average       [DEFAULT]                      |               
//|   1 = Exponential moving average                                 |               
//|   2 = Smoothed moving average                                    |               
//|   3 = Linear weighted moving average                             |               
//|                                                                  |
//|   Good trading,                                                  |   
//|                                                                  |
//|   Dean                                                           |                              
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Dean Malone // Alerts mod. 01.2015 fxdaytrader, http://ForexBaron.net"
#property link      "http://www.compassfx.com"
#property link      "http://ForexBaron.net"

#property description "  The TDI (Traders Dynamic Index) indicator by Dean Malone (2006) "
#property description "  This hybrid indicator is developed to assist traders in their   "
#property description "  ability to decipher and monitor market conditions related to    "
#property description "  trend direction, market strength, and market volatility.        "
#property description "  Even though comprehensive, the T.D.I. is easy to read and use.  "
#property description "    learn more at http://www.forexfactory.com/showthread.php?p=7992491#post7992491 "

#property indicator_buffers 6
#property indicator_color1 clrBlack
#property indicator_color2 clrDodgerBlue //0XFFFFFFFF    //VB high line   //clrDodgerBlue //0XFFFFFFFF
#property indicator_color3 clrYellow     //0xFFFFFFFF   //MarketBaseLine //clrYellow     //0XFFFFFFFF
#property indicator_color4 clrDodgerBlue //0XFFFFFFFF   //VB low line    //clrDodgerBlue //0XFFFFFFFF
#property indicator_color5 clrLimeGreen //RsiPrice line  //clrGreen
#property indicator_color6 clrRed       //TradeSignal line
#property indicator_separate_window

extern int RSI_Period               = 13;//8-25
extern ENUM_APPLIED_PRICE RSI_Price = 0; //0-6
//
extern int Volatility_Bands_Period      = 34;//20-40
extern int RSI_Price_Line_Period        = 2;
extern ENUM_MA_METHOD RSI_Price_Type    = 0;//0-3
extern int Trade_Signal_Line_Period     = 7;
extern ENUM_MA_METHOD Trade_Signal_Type = 0;//0-3

//fxdaytrader:
 extern bool ShowVolatilityBands = TRUE;//default:false
 extern bool ShowMarketBaseLine  = FALSE;//default:false
 extern bool ShowRsiPriceLine    = TRUE;//default:true
 extern bool ShowTradeSignalLine = TRUE;//default:true
//

//alerts, fxdaytrader:
extern string sep00__________________Alert_settings = "";
extern bool   RsiTradeSignalLineCrossAlerts = TRUE;//default:true
extern bool   RsiMarketBaseLineCrossAlerts  = FALSE;//default:false
extern bool   RsiVolatilityBandsCrossAlerts = TRUE;
//
extern int    SignalCandle           = 1;//0:current candle, 1:previous candle, etc.
extern bool   PopupAlerts            = TRUE;
extern bool   EmailAlerts            = FALSE;
extern bool   PushNotificationAlerts = FALSE;
extern bool   SoundAlerts            = FALSE;
extern string SoundFileNameLong      = "alert.wav";
extern string SoundFileNameShort     = "alert2.wav";
int lastrsitsalert=3,lastrsimbalert=3,lastrsivbhalert=3,lastrsivblalert=3;
//end alerts

double RSIBuf[],UpZone[],MdZone[],DnZone[],MaBuf[],MbBuf[];

int init() {
   IndicatorShortName("(TDI Alerts mod. 2015 fxdaytrader) :: ");
   SetIndexBuffer(0,RSIBuf);
   SetIndexBuffer(1,UpZone);//Vb high
   SetIndexBuffer(2,MdZone);//MarketBaseLine
   SetIndexBuffer(3,DnZone);//Vb low
   SetIndexBuffer(4,MaBuf);//RsiPriceLine
   SetIndexBuffer(5,MbBuf);//TradeSignalLine
   
   SetIndexStyle(0,DRAW_NONE); 
   SetIndexStyle(1,DRAW_LINE); 
   SetIndexStyle(2,DRAW_LINE);   //,0,2
   SetIndexStyle(3,DRAW_LINE);
   SetIndexStyle(4,DRAW_LINE);   //,0,2
   SetIndexStyle(5,DRAW_LINE);   //,0,2
   
   SetIndexLabel(0,NULL); 
   SetIndexLabel(1,"VB High"); 
   SetIndexLabel(2,"Market Base Line"); 
   SetIndexLabel(3,"VB Low"); 
   SetIndexLabel(4,"RSI Price Line");
   SetIndexLabel(5,"Trade Signal Line");
 
   SetLevelValue(0,50);
   SetLevelValue(1,68);
   SetLevelValue(2,32);
   SetLevelStyle(STYLE_DOT,1,DimGray);
   
   //fxdaytrader, switch on/off the lines
    if (!ShowVolatilityBands) {
     SetIndexStyle(1,DRAW_NONE);
     SetIndexStyle(3,DRAW_NONE);
    }
    if (!ShowMarketBaseLine)  SetIndexStyle(2,DRAW_NONE);
    if (!ShowRsiPriceLine)    SetIndexStyle(4,DRAW_NONE);
    if (!ShowTradeSignalLine) SetIndexStyle(5,DRAW_NONE);
   //end fxdaytrader
   
   return(0);
}//int init() {

int start() {
   double MA,RSI[];
   ArrayResize(RSI,Volatility_Bands_Period);
   int counted_bars=IndicatorCounted();
   int limit = Bars-counted_bars-1;
   for(int i=limit; i>=0; i--) {
      RSIBuf[i] = (iRSI(NULL,0,RSI_Period,RSI_Price,i)); 
      MA = 0;
      for(int x=i; x<i+Volatility_Bands_Period; x++) {
         RSI[x-i] = RSIBuf[x];
         MA += RSIBuf[x]/Volatility_Bands_Period;
      }//for(int x=i; x<i+Volatility_Bands_Period; x++) {
      UpZone[i] = (MA + (1.6185 * StDev(RSI,Volatility_Bands_Period)));
      DnZone[i] = (MA - (1.6185 * StDev(RSI,Volatility_Bands_Period)));  
      MdZone[i] = ((UpZone[i] + DnZone[i])/2.0);
   }//for(int i=limit; i>=0; i--) {

   for (i=limit-1;i>=0;i--) {
       MaBuf[i] = (iMAOnArray(RSIBuf,0,RSI_Price_Line_Period,0,RSI_Price_Type,i));
       MbBuf[i] = (iMAOnArray(RSIBuf,0,Trade_Signal_Line_Period,0,Trade_Signal_Type,i));   
   }//for (i=limit-1;i>=0;i--) {
//--- alerts:
 if (RsiTradeSignalLineCrossAlerts) {
  if (lastrsitsalert!=1 && MaBuf[SignalCandle]>MbBuf[SignalCandle] && MaBuf[SignalCandle+1]<=MbBuf[SignalCandle+1]) {
   lastrsitsalert=1;
   doAlerts("UP -> RSI TradeSignal",SoundFileNameLong);
  }
  if (lastrsitsalert!=2 && MaBuf[SignalCandle]<MbBuf[SignalCandle] && MaBuf[SignalCandle+1]>=MbBuf[SignalCandle+1]) {
   lastrsitsalert=2;
   doAlerts("DN -> RSI TradeSignal",SoundFileNameShort);
  }
 }//if (RsiTradeSignalLineCrossAlerts) {
 //
 if (RsiMarketBaseLineCrossAlerts) {
  if (lastrsimbalert!=1 && MaBuf[SignalCandle]>MdZone[SignalCandle] && MaBuf[SignalCandle+1]<=MdZone[SignalCandle+1]) {
   lastrsimbalert=1;
   doAlerts("UP -> RSI MarketBaseLine",SoundFileNameLong);
  }
  if (lastrsimbalert!=2 && MaBuf[SignalCandle]<MdZone[SignalCandle] && MaBuf[SignalCandle+1]>=MdZone[SignalCandle+1]) {
   lastrsimbalert=2;
   doAlerts("DN -> RSI MarketBaseLine",SoundFileNameShort);
  }
 }//if (RsiMarketBaseLineCrossAlerts) {
 //
 if (RsiVolatilityBandsCrossAlerts) {
  //Vb high
  if (lastrsivbhalert!=1 && MaBuf[SignalCandle]>UpZone[SignalCandle] && MaBuf[SignalCandle+1]<=UpZone[SignalCandle+1]) {
   lastrsivbhalert=1;
   doAlerts("UP -> RSI Vb high",SoundFileNameLong);
  }
  if (lastrsivbhalert!=2 && MaBuf[SignalCandle]<UpZone[SignalCandle] && MaBuf[SignalCandle+1]>=UpZone[SignalCandle+1]) {
   lastrsivbhalert=2;
   doAlerts("DN -> RSI Vb low",SoundFileNameShort);
  }
  //vblow
  if (lastrsivblalert!=1 && MaBuf[SignalCandle]>DnZone[SignalCandle] && MaBuf[SignalCandle+1]<=DnZone[SignalCandle+1]) {
   lastrsivblalert=1;
   doAlerts("UP -> RSI Vb low",SoundFileNameLong);
  }
  if (lastrsivblalert!=2 && MaBuf[SignalCandle]<DnZone[SignalCandle] && MaBuf[SignalCandle+1]>=DnZone[SignalCandle+1]) {
   lastrsivblalert=2;
   doAlerts("DN -> RSI Vb low",SoundFileNameShort);
  }
 }//if (RsiVolatilityBandsCrossAlerts) {
//----
   return(0);
}//int start() {
  
double StDev(double& Data[], int Per) {
 return(MathSqrt(Variance(Data,Per)));
}

double Variance(double& Data[], int Per) {
  double sum, ssum;
  for (int i=0; i<Per; i++)
  {sum += Data[i];
   ssum += MathPow(Data[i],2);
  }
  return((ssum*Per - sum*sum)/(Per*(Per-1)));
}
//+------------------------------------------------------------------+
void doAlerts(string msg,string SoundFile) {//fxdaytrader:
  msg="TDI Alert on "+Symbol()+", period "+TFtoStr(Period())+": "+msg;//+", bid = "+DoubleToStr(MarketInfo(Symbol(),MODE_BID),Digits)+", servertime: "+TimeToStr(TimeCurrent());
 string emailsubject="MT4 alert on acc. "+AccountNumber()+", "+WindowExpertName()+" - Alert on "+Symbol()+", period "+TFtoStr(Period());
  if (PopupAlerts)            Alert(msg);
  if (EmailAlerts)            SendMail(emailsubject,msg);
  if (PushNotificationAlerts) SendNotification(msg);
  if (SoundAlerts)            PlaySound(SoundFile);
}//void doAlerts(string msg,string SoundFile) {

string TFtoStr(int period) {//fxdaytrader
 if (period==0) period=Period();
 switch(period) {
  case 1     : return("M1");  break;
  case 5     : return("M5");  break;
  case 15    : return("M15"); break;
  case 30    : return("M30"); break;
  case 60    : return("H1");  break;
  case 240   : return("H4");  break;
  case 1440  : return("D1");  break;
  case 10080 : return("W1");  break;
  case 43200 : return("MN1"); break;
  default    : return(DoubleToStr(period,0));
 }
 return("UNKNOWN");
}//string TFtoStr(int period) {


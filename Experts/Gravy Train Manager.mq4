//+------------------------------------------------------------------+
//|                                          Gravy Train Manager.mq4 |
//|                                                    Steve Hopwood |
//|                                https://www.stevehopwoodforex.com |
//+------------------------------------------------------------------+
#property copyright "Steve Hopwood"
#property link      "https://www.stevehopwoodforex.com"
#property version   "1.00"
#property strict
#define   version "Version 1"


#include <WinUser32.mqh>
#include <stdlib.mqh>
#define  NL    "\n"

//Error reporting
#define  slm " stop loss modification failed with error "
#define  tpm " take profit modification failed with error "
#define  ocm " order close failed with error "
#define  odm " order delete failed with error "
#define  pcm " part close failed with error "
#define  spm " shirt-protection close failed with error "
#define  slim " stop loss insertion failed with error "
#define  tpim " take profit insertion failed with error "


extern string  gen="---- Event timer ----";
extern int     EventTimerSeconds=1;//Seconds in between calculation loops

extern string  sep1="================================================================";
extern string  ManagementStyle1              = "Select management style -You can select more than one option";
extern bool    ManageByMagicNumber           = true;                     //Manage trades by magic number,
extern int     MagicNumber                   = 5001;                                 //so long as they have this Magic Number.
extern bool    ManageByTradeComment          = true;                  //Manage trades by order comment,
extern string  TradeComment                  = "m";                          //so long as they have this comment.
extern string  OverRide                      = "Managing this pair only will override all previous";
extern string  OverRide2                     = "can be used in combination with any of the choices above";
extern bool    ManageThisPairOnly            = false;                       //Manage only this pair.
extern string  OverRide1                     = "Managing all trades will override single pair choices"; // This allows the ea to manage all existing trades
extern bool    ManageAllTrades               = true;                            //Manage all pairs traded on the account.
////////////////////////////////////////////////////////////////////////////////////////
//Position variables for CountOpenTrades
int            OpenTrades=0;

//For FIFO
int            FifoTicket[];                                                                 //Array to store trade ticket numbers in FIFO mode. Catersr for
                                                                                                 //US citizens makes iterating through the trade closure loop quicker
                                                                                                                         
//Communication with my trading EA's or EA's coded using my shells
string         GvName="Under management flag";//The name of the GV that tells trading EA's not to send trades whilst the manager is closing them.

//Replacements for Bid, Ask etc
double         bid=0, ask=0, factor=0;
int            digits=0;

//Global variable name etc for picking up failed part closures.
// string         TicketName                    = "GlobalVariableTicketNo";// For storing ticket numbers in global vars for picking up failed part-closes
// bool           GlobalVariablesExist          = false;

////////////////////////////////////////////////////////////////////////////////////////

extern string  sep2="====================================================================";
extern string  gti="---- Gravy Train Weather Vane Inputs ----";
extern bool    AllowGTWVTrades=true;                                            //The manager is allowed to send new trades?
extern int     MaxOpenTrades=10;                                                          //If so, up to what maximum number of trades in either direction?
extern double  Lot=0.01;                                                                     //And at how many lots per trade?
////////////////////////////////////////////////////////////////////////////////////////
int            BuysOpenThisPair=0, SellsOpenThisPair=0;
////////////////////////////////////////////////////////////////////////////////////////

// Now give user a variety of facilities
extern string  bl1 = "====================================================================";
extern string  ManagementFacilities          = "Select the management facilities you want";
extern string  slf                           = "Stop Loss & Take Profit Manipulation";
extern string  BE                            = "---- Break even settings ----";
extern bool    UseBreakEven                  = true;                                                   //Use Break Even.
extern int     BreakEvenPips                 = 5;                                                        //Pips to break even.
extern int     BreakEvenProfitPips           = 2;                                                      //Pips profit to lock in.
////////////////////////////////////////////////////////////////////////////////////////
double  BreakEven=0, BreakEvenProfit=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  z2                            = "----------------";
extern string  JSL                           = "---- Jumping stop loss settings ----";
extern bool    UseJumpingStop                = true;                                                //Use a jumping stop loss.
extern int     JumpingStopPips               = 6;                                                      //Jump in this pips increment.
extern bool    JumpAfterBreakevenOnly        = true;                                            //Only jump after break even has been achieved.
////////////////////////////////////////////////////////////////////////////////////////
double         JumpingStop=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  z4                            = "----------------";
extern string  TSL                           = "---- Trailing stop loss settings. Use standard trail. ----";
//If using TS, the user has the option of a normal trail or a candlestick trail.
extern bool    UseStandardTrail              = false;                                                //Use a standard trail.
extern int     TrailingStopPips              = 6;                                                        //Number of pips to trail.
bool    StopTrailAtProfitPips         = false;                                                         //RP Commented out - Not necessary for GTWV.
int     StopTrailPips                 = 0;                                                                 //Stop the trail when the profit reaches your target. The target in pips to stop the trail.
////////////////////////////////////////////////////////////////////////////////////////
double         TrailingStop=0, StopTrailAtProfit=0, StopTrail=0;
////////////////////////////////////////////////////////////////////////////////////////
string  z5                            = "----------------";
bool    UseCandlestickTrail           = false;                                                         //RP GTWV does not use candlestick trailing stop
ENUM_TIMEFRAMES CandlestickTrailTimeFrame = PERIOD_H1;                      //Candlestick time frame
int     CandleShift                   = 1;                                                                   //How many candles back to trail the stop.

string  rtb                           = "----------------";
extern bool    TrailAfterBreakevenOnly       = true;                                            //Only trail after break even has been achieved.
int     StopTrailPipsTarget           = 0;                                                              //RP - leave as 0 not required in GTWV - Stop trailing at this pips profit target. Zero to disable.

extern string  z9                            = "----------------";
extern string  sli                           = "---- Stop loss Inputs ----";
extern string  MSLA                          = "---- Add a missing Stop Loss ----";
extern bool    AddMissingStopLoss            = false;                                           //Add a stop loss to trades that do not have one.
extern int     MissingStopLossPips           = 100;                                              //Stop loss size in pips. RP - set this to a loss of 100 pips = 10 USD
extern bool    UseSlAtr                      = false;                                                  //Use ATR to calculate the stop loss.
extern int     AtrSlPeriod                   = 20;                                                      //ATR stop loss period.
extern ENUM_TIMEFRAMES AtrSlTimeFrame        = PERIOD_CURRENT;        //ATR stop loss time frame.
extern double  AtrSlMultiplier               = 2;                                                      //ATR stop loss multiplier.
////////////////////////////////////////////////////////////////////////////////////////
double         MissingStopLoss=0;
double         AtrVal=0;
////////////////////////////////////////////////////////////////////////////////////////
string  z9a                           = "----------------";                                                 //RP Not required for GTWV - Let the broker see us !!
string  hsl                           = "---- Hidden stop loss settings ----";
bool    UseHiddenStopLoss             = false;                                                  //Hide your stop loss from the broker.
int     HiddenStopLossPips            = 200;                                                     //'Real' pips stop loss.
////////////////////////////////////////////////////////////////////////////////////////
double         HiddenStopLoss=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  z10                           = "----------------";
extern string  tpi                           = "---- Take profit Inputs ----";
extern string  MTPA                          = "-- Add a missing Take Profit --";
extern bool    AddMissingTakeProfit          = true;                                           //Add a take profit to trades that do not have one.
extern int     MissingTakeProfitPips         = 0;                                                //Take profit size in pips.
extern bool    UseTpAtr                      = true;                                                //Use ATR to calculate the take profit.
extern int     AtrTpPeriod                   = 8;                                                      //ATR Take Profit period. RP
extern ENUM_TIMEFRAMES AtrTpTimeFrame        = PERIOD_CURRENT;     //ATR take profit time frame.
extern double  AtrTpMultiplier               =1.5;                                                  //ATR take profit multiplier. RP make the target realistic
////////////////////////////////////////////////////////////////////////////////////////
double         MissingTakeProfit=0;
////////////////////////////////////////////////////////////////////////////////////////
string  htp                           = "-- Hidden take profit settings --";                       //RP - Not required for GTWV - Let the broker see us !!
bool    UseHiddenTakeProfit           = false;                                                    //Hide your take profit from the broker.
int     HiddenTakeProfitPips          = 200;                                                       //'Real' pips take profit.
////////////////////////////////////////////////////////////////////////////////////////
double         HiddenTakeProfit=0;
////////////////////////////////////////////////////////////////////////////////////////

string  bl11 = "===================================";                     //RP GTWV works 24/7 unless switched of above !!!
string  dc1                           = "---- Daily order close hour ----"; 
string  dc2                           = "Use local time, 24 hour clock";
bool    DailyCloseEnabled             = false;//Use the Daily Close function.
bool    CloseMarketTrades             = false;//Closes all market trades, subject to next two inputs.
bool    CloseOnlyWinners              = false;//Only close profitable trades.
bool    CloseOnlyLosers               = false;//Only close losing trades.
bool    DeletePendingTrades           = false;//Delete pending trades.
int     SundayCloseHour               = 25;//Sunday close hour. >23 or <0 to cancel.
int     MondayCloseHour               = 25;//Monday close hour. >23 or <0 to cancel.
int     TuesdayCloseHour              = 25;//Tuesday close hour. >23 or <0 to cancel.
int     WednesdayCloseHour            = 25;//Wednesday close hour. >23 or <0 to cancel.
int     ThursdayCloseHour             = 25;//Thuysday close hour. >23 or <0 to cancel.
int     FridayCloseHour               = 25;//Friday close hour. >23 or <0 to cancel.
int     SaturdayCloseHour             = 25;//Satday close hour. >23 or <0 to cancel.
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
int            DayHourClose[8];//Array to hold the close hour choices, set up in OnInit
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

extern string  bl6 = "====================================================================";
extern string  OtherStuff                    = "----Alerts and Comments----";
extern bool    ShowAlerts                    = false;
// Added by Robert for those who do not want the comments.
extern bool    ShowComments            = true;

// RP no need to show this display code to users of GTWV

//Enhanced screen feedback display code provided by Paul Batchelor (lifesys). Thanks Paul; this is fantastic.
string  se52  ="================================================================";
string  oad               ="----Odds and ends----";
//extern int     ChartRefreshDelaySeconds=3;
int     DisplayGapSize    = 30; //Left margin size if displaying text as Comments
// ****************************** added to make screen Text more readable
// replaces Comment() with OBJ_LABEL text
bool    DisplayAsText     = true;
//Disable the chart in foreground CrapTx setting so the candles do not obscure the text
bool    KeepTextOnTop     = true;
int     DisplayX          = 100;
int     DisplayY          = 0;
int     fontSise          = 10;
string  fontName          = "Arial";
color   colour            = Yellow;
double  spacingtweek      = 0.6; // adjustment to reform lines for different font size
////////////////////////////////////////////////////////////////////////////////////////
int            DisplayCount;
string         Gap,ScreenMessage;
////////////////////////////////////////////////////////////////////////////////////////

//Matt's O-R stuff
int            O_R_Setting_max_retries=10;
double         O_R_Setting_sleep_time=4.0; /* seconds */
double         O_R_Setting_sleep_max=15.0; /* seconds */
int            RetryCount=10;//Will make this number of attempts to get around the trade context busy error.
int            TicketNo=0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//--- create timer
   EventSetTimer(EventTimerSeconds);
   
   //Initialise the double variables
   BreakEven = BreakEvenPips;
   BreakEvenProfit = BreakEvenProfitPips;
   JumpingStop = JumpingStopPips;
   TrailingStop = TrailingStopPips;
   StopTrailPips = StopTrailPipsTarget;
   MissingStopLoss = MissingStopLossPips;
   MissingTakeProfit = MissingTakeProfitPips;
   HiddenTakeProfit = HiddenTakeProfitPips;
   HiddenStopLoss = HiddenStopLossPips;
   
  
   Gap="";
   if (DisplayGapSize >0)
      StringInit(Gap, DisplayGapSize, ' ');
         

   //Set up the daily close hour array
   DayHourClose[0] = SundayCloseHour;
   DayHourClose[1] = MondayCloseHour;
   DayHourClose[2] = TuesdayCloseHour;
   DayHourClose[3] = WednesdayCloseHour;
   DayHourClose[4] = ThursdayCloseHour;
   DayHourClose[5] = FridayCloseHour;
   DayHourClose[6] = SaturdayCloseHour;
   
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//--- destroy timer
   EventKillTimer();
   removeAllObjects();
      
}
/** RP Commented out ==>

/+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   
}
RP Commented out <==
*/ 

void DisplayUserFeedback()
{

   string text = "";
   
//   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   removeAllObjects();
//   *************************

   if(!IsExpertEnabled())
   {
      Comment("GTWV Experts Disabled");
      return;
   }//if (!IsExpertEnabled() )

   ScreenMessage="";
   //ScreenMessage = StringConcatenate(ScreenMessage,Gap + NL);
   SM(NL);
   
   SM(" © http://www.stevehopwoodforex.com"+NL);
   SM("Donations for this EA via Paypal to pianodoodler@hotmail.com"+NL);
  // RP comented out the time info below - Not adding anything to GTWV
  // SM("Broker time = "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS)+": Local time = "+TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS)+NL);
  
   SM(version+NL);
  
  if (!ShowComments)
   return;
   
  SM(NL); 
   
   //Gravy train and weather vane settings
   if (AllowGTWVTrades)
      SM("Sending GTWV trades. Maximum buy or sell trades allowed " + IntegerToString(MaxOpenTrades)
          + " Each trade size is " + DoubleToStr(Lot, 2) + " lots" + NL);
   
   //Display management style info
   if (!ManageAllTrades)
   {
      if (ManageByMagicNumber)
         SM("Managing Magic Number = " + IntegerToString(MagicNumber) + NL);
      if (ManageByTradeComment)
         SM("Managing Comment = " + TradeComment + NL);
      if (ManageThisPairOnly)
         SM("Managing this pair only" + Symbol() + NL);
  }//if (!ManageAllTrades)
   
   if (ManageAllTrades)
      SM("Managing all trades on the account. " + NL);     
   
   text = " trades.";
   if (OpenTrades == 0)
      text = " trades. Hell's Bells, but I am bored.";
   if (OpenTrades == 1)
      text = " trade";
   SM("Managing " + IntegerToString(OpenTrades) + text + NL);  
   
   SM(NL);
   if (UseBreakEven)
   {
      text = "Break even is " + IntegerToString(BreakEvenPips) + " pips. ";
      if (BreakEvenProfitPips > 0)
         text = text + "Locking in " + IntegerToString(BreakEvenProfitPips) + " pips profit at BE.";
      SM(text + NL);   
   }//if (UseBreakEven)
   
   if (UseJumpingStop)
   {
      text = "Jumping stop set to jump every " + IntegerToString(JumpingStopPips) + " pips. ";
      SM(text + NL);   
   }//if (UseJumpingStop)
   
if (UseStandardTrail)
  {
      text = "Using a standard trail, stop is " + IntegerToString(TrailingStopPips) + " pips. ";
      SM(text + NL);   
   }//if (UseTrailingStop)
   
   
   /** RP commented out GTWV does not need candlestick trails or information on them ! ==>
   
   if (UseCandlestickTrail)
   {
      text = "Using a candlestick trail stop set to the hilo of " + IntegerToString(CandleShift) + " candle ago.";
      if (CandleShift != 1)
         text = "Using a candlestick trailing stop set to the hilo of " + IntegerToString(CandleShift) + " candles ago.";
      SM(text + NL);   
   }//if (UseJumpingStop)
   
   RP - information on these variables is known to user - no additional info is being provided.
   
//   if (AddMissingStopLoss)
//      SM(ScreenMessage + NL + "Add missing Stop Loss at " + IntegerToString(MissingStopLossPips) + " pips.");      

//   if (AddMissingTakeProfit)
 //     SM (ScreenMessage + NL + "Add missing Take Profit at " + IntegerToString(MissingTakeProfitPips) + " pips.");      
   
   if (UseHiddenStopLoss)
      SM(ScreenMessage + NL + "Hidden stop loss is enabled. Hidden stop = " + IntegerToString(HiddenStopLossPips) + " pips");
     
   if (UseHiddenTakeProfit)
      SM(ScreenMessage + NL + "Hidden take profit is enabled. Hidden stop = " + IntegerToString(HiddenTakeProfitPips) + " pips");

 RP - information on these variables is known to user - no additional info is being provided. <==

*/

/** RP - Daily closures not required. GTWV EA is either on or off as per setting above ! ==>

   //Daily closure
   if (DailyCloseEnabled)
   {
     int day = TimeDayOfWeek((TimeLocal()));
     ScreenMessage = StringConcatenate(ScreenMessage, "DailyCloseEnabled is enabled. Not closing trades today - close hour is ", DayHourClose[day], NL);
     if (DayHourClose[day] > -1)
     if (DayHourClose[day] < 24)
     {
         ScreenMessage = "DailyCloseEnabled is enabled. Today's close hour is " + IntegerToString(DayHourClose[day]);
     }//if (DayHourClose[day] < 24)
      
     SM(ScreenMessage + NL); 
   }//if (DailyCloseEnabled)

     
   Comment(ScreenMessage);
   
RP Commented out <==

*/

}//void DisplayUserFeedback()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
   for (int cc = 0; cc < 5; cc++) 
   {
      textpart[cc] = StringSubstr(text,cc*63,64);
      if (StringLen(textpart[cc]) ==0) continue;
      ofset = cc * 63 * fontSise * spacingtweek;
      lab_str = lab_str + IntegerToString(cc);
      ObjectCreate(lab_str, OBJ_LABEL, 0, 0, 0); 
      ObjectSet(lab_str, OBJPROP_CORNER, 0);
      ObjectSet(lab_str, OBJPROP_XDISTANCE, DisplayX + ofset); 
      ObjectSet(lab_str, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(fontSise+4)); 
      ObjectSet(lab_str, OBJPROP_BACK, false);
      ObjectSetText(lab_str, textpart[cc], fontSise, fontName, colour);
   }//for (int cc = 0; cc < 5; cc++) 
}

bool AreWeManagingThisTrade(int ticket)
{

   //Returns 'true' if GTWV is managing the trade indexed by ticket,
   //else returns 'false'.
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return(false);//Somehow, the trade was closed.
      
   int cc = 0;
   
   //Managing all trades
   if (ManageAllTrades)
      return(true);
   
       
   //This pair only
   if (ManageThisPairOnly)
      if (OrderSymbol() == Symbol() )
         return(true);
         
   //Magic number
   if (ManageByMagicNumber)
      if (OrderMagicNumber() == MagicNumber )
         return(true);
         
   //Order comment
   if (ManageByTradeComment)
      if (OrderComment() == TradeComment)
         return(true);
         
            
   
   //Got this far, so we are not managing the trade
   return(false);

}//bool AreWeManagingThisTrade()


void CountOpenTrades()
{
   OpenTrades = 0;
   ArrayResize(FifoTicket, 0);
   //Some variables for keeping track of the most recent trade,
   //so we can check that a new order has been sent after break even.
   datetime LatestBuyTime = 0, LatestSellTime = 0;
   int LatestBuyTicket = 0, LatestSellTicket = 0;
   
   
   
   if (OrdersTotal() == 0)
      return;//O open trades, so nothing to do
   
   int as = 0;
      
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES))
         continue;//Just in case.
      
      //Are we managing the trades in the orders list
      int ticket = OrderTicket();   
      if (!AreWeManagingThisTrade(ticket))   
         continue;

      OpenTrades++;
               
      //Yes we are, so store the order ticket number
      ArrayResize(FifoTicket, as + 1);
      FifoTicket[as] = ticket;
      as++;  
      
      //Most recent order tickets
      if (OrderType() == OP_BUY)
      {
         if (OrderOpenTime() > LatestBuyTime)
         {
            LatestBuyTime = OrderOpenTime();
            LatestBuyTicket = ticket;
         }//if (OrderOpenTime() > LatestBuyTime)
         
      }//if (OrderType() == OP_BUY)
      
      if (OrderType() == OP_SELL)
      {
         if (OrderOpenTime() > LatestSellTime)
         {
            LatestSellTime = OrderOpenTime();
            LatestSellTicket = ticket;
         }//if (OrderOpenTime() > LatestSellTime)
         
      }//if (OrderType() == OP_SELL)
      
   
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
      
   //Sort ticket numbers for FIFO
   if (ArraySize(FifoTicket) > 0)
      ArraySort(FifoTicket, WHOLE_ARRAY, 0, MODE_DESCEND);



// RP GTWV specific code here


   //Check that a new trade has been sent following a SL move to break even
   string symbol = OrderSymbol();
   GetBasics(symbol);
   if (LatestBuyTicket > 0)
   {
      if (BetterOrderSelect(LatestBuyTicket, SELECT_BY_TICKET, MODE_TRADES))
         if (OrderStopLoss() >= OrderOpenPrice() )
            SendGravyTrade(symbol, OP_BUY, ask);//SendGravyTrade() has all the required tests
   }//if (LatestBuyTicket > 0)

   if (LatestSellTicket > 0)
   {
      if (BetterOrderSelect(LatestSellTicket, SELECT_BY_TICKET, MODE_TRADES))
         if (OrderStopLoss() <= OrderOpenPrice() && !CloseEnough(OrderStopLoss(), 0) )
            SendGravyTrade(symbol, OP_SELL, bid);//SendGravyTrade() has all the required tests
   }//if (LatestSellTicket > 0)
   
   
}//End void CountOpenTrades()

//For OrderSelect() Craptrader documentation states:
//   The pool parameter is ignored if the order is selected by the ticket number. The ticket number is a unique order identifier. 
//   To find out from what list the order has been selected, its close time must be analyzed. If the order close time equals to 0, 
//   the order is open or pending and taken from the terminal open orders list.
//This function heals this and allows use of pool parameter when selecting orders by ticket number.


bool BetterOrderSelect(int index,int select,int pool=-1)
{
   if (select==SELECT_BY_POS)
   {
      if (pool==-1) //No pool given, so take default
         pool=MODE_TRADES;
         
      return(OrderSelect(index,select,pool));
   }
   
   if (select==SELECT_BY_TICKET)
   {
      if (pool==-1) //No pool given, so submit as is
         return(OrderSelect(index,select));
         
      if (pool==MODE_TRADES) //Only return true for existing open trades
         if(OrderSelect(index,select))
            if(OrderCloseTime()==0)
               return(true);
               
      if (pool==MODE_HISTORY) //Only return true for existing closed trades
         if(OrderSelect(index,select))
            if(OrderCloseTime()>0)
               return(true);
   }
   
   return(false);
}//End bool BetterOrderSelect(int index,int select,int pool=-1)

void GetBasics(string symbol)
{
   //Sets up bid, ask, digits, factor for the passed pair
   bid = MarketInfo(symbol, MODE_BID);
   ask = MarketInfo(symbol, MODE_ASK);
   digits = (int)MarketInfo(symbol, MODE_DIGITS);
   factor = GetPipFactor(symbol);
       
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

bool CloseEnough(double num1, double num2)
{
   /*
   This function addresses the problem of the way in which mql4 compares doubles. It often messes up the 8th
   decimal point.
   For example, if A = 1.5 and B = 1.5, then these numbers are clearly equal. Unseen by the coder, mql4 may
   actually be giving B the value of 1.50000001, and so the variable are not equal, even though they are.
   This nice little quirk explains some of the problems I have endured in the past when comparing doubles. This
   is common to a lot of program languages, so watch out for it if you program elsewhere.
   Gary (garyfritz) offered this solution, so our thanks to him.
   */
   
   if (num1 == 0 && num2 == 0) return(true); //0==0
   if (MathAbs(num1 - num2) / (MathAbs(num1) + MathAbs(num2)) < 0.00000001) return(true);
   
   //Doubles are unequal
   return(false);

}//End bool CloseEnough(double num1, double num2)

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//START OF TRADE MANAGEMENT MODULE
void ReportError(string function, string message)
{
   //All purpose sl mod error reporter. Called when a sl mod fails
   
   int err=GetLastError();
   if (err == 1) return;//That bloody 'error but no error' report is a nuisance
   
      
   if (ShowAlerts)
      Alert(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   Print(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));//Log the result just in case
   
}//void ReportError()

bool ModifyOrder(int ticket, double price, double stop, double take, datetime expiration, color col, string function, string reason)
{
   //Multi-purpose order modify function
   
   bool result = OrderModify(ticket, price ,stop , take, expiration, col);

   //Actions when trade close succeeds
   if (result)
   {
      return(true);
   }//if (result)
   
   //Actions when trade close fails
   if (!result)
      ReportError(function, reason);

   //Got this far, so modify failed
   return(false);
   
}// End bool ModifyOrder()

/** RP - In GTWV open orders are closed at SL - period ! ==>

bool CloseOrder(int ticket, string function, double CloseLots, string reason)
{   
   //Closes open market trades. Deletes pending trades
   
   while(IsTradeContextBusy()) Sleep(100);
   bool orderselect=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if (!orderselect) return(false);

   bool result = false;
   
   //Market orders
   if (OrderType() < 2) 
   {
      result = OrderClose(ticket, CloseLots, OrderClosePrice(), 1000, clrBlue);
   }//if (OrderType() < 2) 
   
   //Pending trades
   if (OrderType() > 1) 
   {
      result = OrderDelete(ticket, clrNONE);
   }//if (OrderType() < 2) 
   
   //Actions when trade close succeeds
   if (result)
   {
      return(true);
   }//if (result)
   
   //Actions when trade close fails
   if (!result)
      ReportError(function, reason);
   
   //Got this far, so the order close failed. Leave it to the calling function to report the failure
   return(false);
   
}//End bool CloseOrder(ticket)

RP - Order close not required in GTWV <==

*/ 

/** RP - Hide stop loss not used in GTWV==>

bool HideStopLoss(int ticket)
{
   //Checks to see if the market has hit the hidden sl and attempts to close the trade if so. 
   //Returns true if trade closure is successful, else returns false
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return(false);//Order has closed, so nothing to do.    

   int err = 0;
   bool CloseThisTrade = false, result = false;
   double stop = OrderStopLoss();
   
   //Check buy trade
   if (OrderType() == OP_BUY)
   {
      stop = NormalizeDouble(stop + (HiddenStopLoss / factor), digits);
      if (bid <= stop)
         CloseThisTrade = true;

   }//if (OrderType() = OP_BUY)
   
   //Check buy trade
   if (OrderType() == OP_SELL)
   {
      stop = NormalizeDouble(stop - (HiddenStopLoss / factor), digits);
      if (bid >= stop)
         CloseThisTrade = true;
   }//if (OrderType() = OP_SELL)
   
   //Should the trade close?
   if (CloseThisTrade)
   {
      result = CloseOrder(OrderTicket(), __FUNCTION__,  OrderLots(), ocm );
      
   }//if (CloseThisTrade)
   
   
   //Return the result of this function
   return(result);


}//End bool HideStopLoss(int type, int iPipsAboveVisual, double stop )

RP - Hide stop loss not used in GTWV <==
*/

void BreakEvenStopLoss(int ticket) 
{

   // Move stop loss to breakeven
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    

   //No need to continue if already at BE
   if (OrderType() == OP_BUY)
      if (OrderStopLoss() >= OrderOpenPrice() )
         return;
         
   if (OrderType() == OP_SELL)
      if (!CloseEnough(OrderStopLoss(), 0) )//Sell stops need this extra conditional to cater for no stop loss trades
         if (OrderStopLoss() <= OrderOpenPrice() )
            return;
             

   int err = 0;
   bool modify = false;
   double stop = 0;
   
  //Can we move the stop loss to breakeven?        
   if (OrderType()==OP_BUY)
      if (OrderStopLoss() < OrderOpenPrice() )
         if (bid >= OrderOpenPrice() + (BreakEven / factor) )
            if (OrderStopLoss() < OrderOpenPrice() )
            {
               modify = true;
               stop = NormalizeDouble(OrderOpenPrice() + (BreakEvenProfit / factor), digits);
            }//if (OrderStopLoss()<OrderOpenPrice())
   	                  			         
          
   if (OrderType()==OP_SELL)
      if (OrderStopLoss() > OrderOpenPrice() || CloseEnough(OrderStopLoss(), 0) )
         if (ask <= OrderOpenPrice() - (BreakEven / factor) )
         {
            modify = true;
            stop = NormalizeDouble(OrderOpenPrice() - (BreakEvenProfit / factor), digits);
         }//if (OrderStopLoss()>OrderOpenPrice()) 
         
   //Modify the order stop loss if BE has been achieved
   if (modify)
   {
      bool result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), 
                                OrderExpiration(), clrNONE, __FUNCTION__, slm);
                              
                                //Send a new trade
     
      if(result)
            SendGravyTrade(OrderSymbol(), OrderType(), OrderOpenPrice() );
      
   }//if (modify)
   
     
   

}//End void BreakEvenStopLoss(int ticket)

void JumpingStopLoss(int ticket) 
{
   // Jump stop loss by pips intervals chosen by user.
   // Also carry out partial closure if the user requires this

   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    


   // Abort the routine if JumpAfterBreakevenOnly is set to true and be stop is not yet set
   if (JumpAfterBreakevenOnly) 
   {
      if (OrderType()==OP_BUY)
         if(OrderStopLoss() < OrderOpenPrice() ) 
            return;
   
      if (OrderType()==OP_SELL)
         if(OrderStopLoss() > OrderOpenPrice() )  // RP do we not need a closeEnough check here ? 
            return;
   }//if (JumpAfterBreakevenOnly)
   
  
   double stop = OrderStopLoss(); //Stop loss
   bool result = false, modify = false, TradeClosed = false;
   bool PartCloseSuccess = false;
   int err = 0;
   
   if (OrderType()==OP_BUY)
   {
      // First check if stop needs setting to breakeven
      if (CloseEnough(stop, 0) || stop < OrderOpenPrice() )
      {
         if (bid >= OrderOpenPrice() + (JumpingStop / factor))
         {
            stop = OrderOpenPrice();
            modify = true;
         }//if (bid >= OrderOpenPrice() + (JumpingStop / factor))
      }//if (CloseEnough(stop, 0) || stop<OrderOpenPrice())

      // Increment stop by stop + JumpingStop.
      // This will happen when market price >= (stop + JumpingStop)
      if (!modify)  
         if (stop >= OrderOpenPrice())      
            if (bid >= stop + ((JumpingStop * 2) / factor) ) 
            {
               stop+= (JumpingStop / factor);
               modify = true;
            }// if (bid>= stop + (JumpingStop / factor) && stop>= OrderOpenPrice())      
      
   
   }//if (OrderType()==OP_BUY)
   
   if (OrderType()==OP_SELL)
   {
      // First check if stop needs setting to breakeven
      if (CloseEnough(stop, 0) || stop > OrderOpenPrice())
      {
         if (ask <= OrderOpenPrice() - (JumpingStop / factor))
         {
            stop = OrderOpenPrice();
            modify = true;
         }//if (ask <= OrderOpenPrice() - (JumpingStop / factor))
      } // if (stop==0 || stop>OrderOpenPrice()

      // Decrement stop by stop - JumpingStop.
      // This will happen when market price <= (stop - JumpingStop)
      if (!modify)  
         if (stop <= OrderOpenPrice())      
            if (ask <= stop - ((JumpingStop * 2) / factor) ) 
            {
               stop-= (JumpingStop / factor);
               modify = true;
            }// if (bid>= stop + (JumpingStop / factor) && stop>= OrderOpenPrice())      
        
   }//if (OrderType()==OP_SELL)

   //Modify the order stop loss if a jump has been achieved
   if (modify)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), 
                                OrderExpiration(), clrNONE, __FUNCTION__, slm);

   }//if (modify)


} //End void JumpingStopLoss(int ticket) 

void TrailingStopLoss(int ticket)
{
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    
 
   
   // Abort the routine if TrailAfterBreakevenOnly is set to true and be stop is not yet set
   if (TrailAfterBreakevenOnly)
   {
      if (OrderType()==OP_BUY)
         if(OrderStopLoss() < OrderOpenPrice() )
            return;
   
      if (OrderType()==OP_SELL)
         if(OrderStopLoss() > OrderOpenPrice() )
            if (!CloseEnough(OrderStopLoss(), 0) )
               return;
   }//if (TrailAfterBreakevenOnly)
     
   
   bool result;
   double stop=OrderStopLoss(); //Stop loss
   if (CloseEnough(OrderStopLoss(), 0) )
      stop = OrderOpenPrice();
   bool modify = false, TradeClosed = false;
   
   
   if (OrderType()==OP_BUY)
   {
     
     if (bid > stop +  (TrailingStop / factor))
     {
        stop = bid - (TrailingStop / factor);
        // Exit routine if user has chosen StopTrailPips and
        // stop is past the profit point already
        if (!CloseEnough(StopTrailPips, 0) )
            if (stop >= OrderOpenPrice() + (StopTrailPips / factor)) return;
       
        //Stop loss needs moving.
        modify = true;  
     }//if (bid > stop +  (TrailingStop / factor))
   }//if (OrderType()==OP_BUY)
 
   if (OrderType()==OP_SELL)
   {
       
     if (bid < stop - (TrailingStop / factor))
     {
          stop = bid + (TrailingStop / factor);
          // Exit routine if user has chosen StopTrailPips and
          // stop is past the profit point already
          if (!CloseEnough(StopTrailPips, 0) )
            if (stop <= OrderOpenPrice() - (StopTrailPips / factor))
                return;
         
         //Stop loss needs moving.
         modify = true;
     }//if (bid < stop -  (TrailingStop / factor))
   }//if (OrderType()==OP_SELL)
 
   //Modify the order stop loss if a jump has been achieved
   if (modify)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(),
                                OrderExpiration(), clrNONE, __FUNCTION__, slm);
 
     
   }//if (modify)
     
}//End void TrailingStopLoss(int ticket)

/** RP - Candlestick trailing not used in GTWV

void CandlestickTrailingStop(int ticket)
{


   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    

   // Abort the routine if JumpAfterBreakevenOnly is set to true and be stop is not yet set
   if (TrailAfterBreakevenOnly) 
   {
      if (OrderType()==OP_BUY)
         if(OrderStopLoss() < OrderOpenPrice() ) 
            return;
   
      if (OrderType()==OP_SELL)
         if(OrderStopLoss() > OrderOpenPrice() ) 
            if (!CloseEnough(OrderStopLoss(), 0) )
               return;
   }//if (TrailAfterBreakevenOnly)
     
   
   bool result;
   double stop=OrderStopLoss(); //Stop loss
   if (CloseEnough(OrderStopLoss(), 0) )
      stop = OrderOpenPrice();
   bool modify = false, TradeClosed = false;
   double ClosePrice = 0;
   double StopLevel = MarketInfo(OrderSymbol(), MODE_STOPLEVEL);//Min stop
   
   
   if (OrderType()==OP_BUY) 
      {
          
	   
		   if (UseCandlestickTrail)
		   {
		       ClosePrice = NormalizeDouble(iLow(OrderSymbol(), CandlestickTrailTimeFrame, CandleShift), digits);
		       if (ClosePrice >= OrderOpenPrice())
   		       if (ClosePrice > OrderStopLoss() )
   		       {
   		          //Min stop check
   		          if (ClosePrice - OrderStopLoss() >= (StopLevel  / factor) )
   		          {
   		             stop = ClosePrice;
   		             
   		             //Stop loss needs moving.
   		              modify = true;  
   		          }//if (ClosePrice - OrderStopLoss() >= (StopLevel  / factor) )		          
   		       }//if (ClosePrice > OrderStopLoss() )
		   }//if (UseCandlestickTrail)
		   
		   
      }//if (OrderType()==OP_BUY) 

      if (OrderType()==OP_SELL) 
      {
		   
		   if (UseCandlestickTrail)
		   {
		       ClosePrice = NormalizeDouble(iHigh(OrderSymbol(), CandlestickTrailTimeFrame, CandleShift), digits);
		       if (ClosePrice <= OrderOpenPrice())
   		       if (ClosePrice < OrderStopLoss() || OrderStopLoss() == 0)
   		       {
   		          if (MathAbs(OrderStopLoss() - ClosePrice) >= (StopLevel / factor) )
   		          {
   		             stop = ClosePrice;
   		             
   		             //Stop loss needs moving.
   		              modify = true;  
   		          }//if (OrderStopLoss() - ClosePrice >= (StopLevel / factor) )
   		       }//if (ClosePrice < OrderStopLoss())
		   }//if (UseCandlestickTrail)
		   
      }//if (OrderType()==OP_SELL) 

   //Modify the order stop loss if a jump has been achieved
   if (modify)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), 
                                OrderExpiration(), clrNONE, __FUNCTION__, slm);
      
   }//if (modify)


}//End void CandlestickTrailingStop(int ticket)

/** RP - Candlestick trails not used in GTWV

*/

void InsertStopLoss(int ticket)
{
   //Inserts a stop los into a trade that lacks one.

   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    
   
   if (!CloseEnough(OrderStopLoss(), 0) || (MissingStopLossPips == 0 && !UseSlAtr) ) 
      return; //Nothing to do
   
   double stop = 0;
   bool result = false;
  
   //There is the option for the user to use Atr to calculate the stop. RP If they use this option we apply the lesser of the calculation and the fixed pips SL
   if (UseSlAtr) 
      AtrVal = iATR(OrderSymbol(), AtrSlTimeFrame, AtrSlPeriod, 0) * AtrSlMultiplier;
   
   // Buy trade
   if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP)
   {
      stop = NormalizeDouble(OrderOpenPrice() - (MissingStopLoss / factor), digits);    
      if (UseSlAtr) // Changed by RisklessPips if SLATR selected then the SL applied is the lesser of the fixed pips SL and the calculated ATR stop
      {
         if (NormalizeDouble(OrderOpenPrice() - AtrVal, digits) > NormalizeDouble(OrderOpenPrice() - (MissingStopLoss / factor), digits))
              stop = NormalizeDouble(OrderOpenPrice() - AtrVal, digits);
         else                  
              stop = NormalizeDouble(OrderOpenPrice() - (MissingStopLoss / factor), digits);
       }    //if (UseSlAtr) // Changed by RisklessPips if SLATR selected then the SL applied is the lesser of the fixed pips SL and the calculated ATR stop
   }//if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP)
   
   
   // Sell trade
   if (OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP)
   {
      stop = NormalizeDouble(OrderOpenPrice() + (MissingStopLoss / factor), digits); 
      if (UseSlAtr) // Changed by by RP if SLATR selected then the SL applied is the lesser of the fixed pips SL and the calculated ATR stop
      {
         if ((NormalizeDouble(OrderOpenPrice() + AtrVal, digits)) > (NormalizeDouble(OrderOpenPrice() + (MissingStopLoss / factor), digits)))
            stop = NormalizeDouble(OrderOpenPrice() + (MissingStopLoss / factor), digits);
         else
           stop = NormalizeDouble(OrderOpenPrice() + AtrVal, digits);            
       } //if (UseSlAtr) // Changed RP if SLATR selected then the SL applied is the lesser of the fixed pips SL and the calculated ATR stop
   }//if (OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP)
   
   result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), 
                        OrderExpiration(), clrNONE, __FUNCTION__, slim);
   
   
}// End void InsertStopLoss(int ticket)

void InsertTakeProfit(int ticket)
{
 
    //Inserts a take profit into a trade that lacks one.

   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    
  
   if (!CloseEnough(OrderTakeProfit(), 0) || (MissingTakeProfitPips == 0 && !UseTpAtr) ) 
      return; //Nothing to do

   double take = 0;
   bool result = false;
   
   //There is the option for the user to use Atr to calculate the stop
   if (UseTpAtr) 
      AtrVal = iATR(OrderSymbol(), AtrTpTimeFrame, AtrTpPeriod, 0) * AtrTpMultiplier;
   
   // Buy trade
   if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP)
   {
      take = NormalizeDouble(ask + (MissingTakeProfit / factor), digits);
      if (UseTpAtr) 
         take = NormalizeDouble(OrderOpenPrice() + AtrVal, digits);
   }//if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP)
   
   
   // Sell trade
   if (OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP)
   {
      take = NormalizeDouble(bid - (MissingTakeProfit / factor), digits);
      if (UseTpAtr) 
         take = NormalizeDouble(OrderOpenPrice() - AtrVal, digits);
   }//if (OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP)
   
   result = ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), take,
                        OrderExpiration(), clrNONE, __FUNCTION__, tpim);
   
   
}// End void InsertTakeProfit(int ticket)

/**
RP - Hide take profit not used in GTWV ==>

bool HideTakeProfit(int ticket)
{
   //Calculate whether a hidden take profit has been hit.
   //Returns 'true' if so, else 'false'.

   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return(true);//Order has closed, so nothing to do.    

   double take = 0;
   bool result = false;
   int err = 0;
   
   //Should the order close because the stop has been passed?
   //Buy trade
   if (OrderType() == OP_BUY)
   {
      take = NormalizeDouble(OrderOpenPrice() + (HiddenTakeProfit / factor), digits);
      if (bid >= take)
      {
         result = CloseOrder(OrderTicket(), __FUNCTION__,  OrderLots(), ocm );
         if (result)
         {
            if (ShowAlerts) 
               Alert("Take profit hit. Close of ", OrderSymbol(), " ticket no ", OrderTicket());      
            Print("Take profit hit. Close of ", OrderSymbol(), " ticket no ", OrderTicket());
         }//if (result)
         
      }//if (bid >= take)      
   }//if (OrderType() == OP_BUY)
   
   //Sell trade
   if (OrderType() == OP_SELL)
   {
      take = NormalizeDouble(OrderOpenPrice() - (HiddenTakeProfit / factor), digits);
      if (ask <= take)
      {
         result = CloseOrder(OrderTicket(), __FUNCTION__,  OrderLots(), ocm );
         if (result)
         {
            if (ShowAlerts==true) 
               Alert("Take profit hit. Close of ", OrderSymbol(), " ticket no ", OrderTicket());
            Print("Take profit hit. Close of ", OrderSymbol(), " ticket no ", OrderTicket());         
         }//if (result)
        
      }//if (bid <= take)   
   }//if (OrderType() == OP_SELL)
   
   return(result);

}//End bool HideTakeProfit(int ticket)

RP - Hide take profit not used in GTWV <==
*/

/** 
RP - Close order at chosen hour not used in GTWV==>

void CloseOrderAtChosenHour(int ticket)
{
   //Close trade if we are past the daily close hour.

   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    
   
   //Which day is it today?
   int day = TimeDayOfWeek(TimeLocal() );
   if (DayHourClose[day] < 0 || DayHourClose[day] > 23)
      return;//Close hour not enabled for this day
      
   //Are we at or past the close hour? We are using the computer's local time, so all values will be 0 - 23
   int hour = TimeHour(TimeLocal() );
   if (hour >= DayHourClose[day])
   {
      bool CloseOrder = true;
      
      //User choice of order closures
      //Market orders
      if (OrderType() < 2)
      {
         //Profitable trades
         if (CloseOnlyWinners)
            if (OrderProfit() + OrderCommission() + OrderSwap() < 0)
               return;
         
         //Losing trades
         if (CloseOnlyWinners)
            if (OrderProfit() + OrderCommission() + OrderSwap() >= 0)
               return;         
               
      }//if (OrderType() < 2)
      
      //Pending trades
      if (OrderType() > 1)
         if (!DeletePendingTrades)
            return;
      
      if (CloseOrder)
         bool result = CloseOrder(OrderTicket(), __FUNCTION__,  OrderLots(), ocm );
      
   }//if (hour >= DayHourClose[day])



}//void CloseOrderAtChosenHourint ticket()

RP -close order at chosen hour not used in GTWV==>

*/

bool SendSingleTrade(string symbol,int type,string comment,double lotsize,double price,double stop,double take, int magic)
{

   int ticket = -1;


   
   datetime expiry=0;
   //if (SendPendingTrades) expiry = TimeCurrent() + (PendingExpiryMinutes * 60);

   //RetryCount is declared as 10 in the Trading variables section at the top of this file
   for(int cc=0; cc<RetryCount; cc++)
     {
      //for (int d = 0; (d < RetryCount) && IsTradeContextBusy(); d++) Sleep(100);

      while(IsTradeContextBusy()) Sleep(100);   //Put here so that excess slippage will cancel the trade if the ea has to wait for some time. RP CLEVER !!
      
      ticket=OrderSend(symbol,type,lotsize,price,0,stop,take,comment,magic,expiry,clrNONE);

      if(ticket>-1) break;//Exit the trade send loop
      if(cc == RetryCount - 1) return(false);

      //Error trapping for both
      if(ticket<0)
      {
         string stype;
         if(type == OP_BUY) stype = "OP_BUY";
         if(type == OP_SELL) stype = "OP_SELL";
         if(type == OP_BUYLIMIT) stype = "OP_BUYLIMIT";
         if(type == OP_SELLLIMIT) stype = "OP_SELLLIMIT";
         if(type == OP_BUYSTOP) stype = "OP_BUYSTOP";
         if(type == OP_SELLSTOP) stype = "OP_SELLSTOP";
         int err=GetLastError();
         Alert(symbol," ",WindowExpertName()," ",stype," order send failed with error(",err,"): ",ErrorDescription(err), " TF = ", comment, ": bid = " 
               + DoubleToStr(bid, digits) + "  Price = " + DoubleToStr(price, digits));
         Print(symbol," ",WindowExpertName()," ",stype," order send failed with error(",err,"): ",ErrorDescription(err));
         return(false);
        }//if (ticket < 0)  
     }//for (int cc = 0; cc < RetryCount; cc++);

   TicketNo=ticket;
   //Make sure the trade has appeared in the platform's history to avoid duplicate trades.
   //My mod of Matt's code attempts to overcome the bastard crim's attempts to overcome Matt's code. RP - LOL
   bool TradeReturnedFromCriminal=false;
   while(!TradeReturnedFromCriminal)
     {
      TradeReturnedFromCriminal=O_R_CheckForHistory(ticket);
      if(!TradeReturnedFromCriminal)
        {
         Alert(symbol," sent trade not in your trade history yet. Turn this ea OFF NOW.");
        }//if (!TradeReturnedFromCriminal)
     }//while (!TradeReturnedFromCriminal)

   //Got this far, so trade send succeeded
   return(true);

}//End bool SendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//=============================================================================
//                           O_R_CheckForHistory()
//
//  This function is to work around a very annoying and dangerous bug in MT4:
//      immediately after you send a trade, the trade may NOT show up in the
//      order history, even though it exists according to ticket number.
//      As a result, EA's which count history to check for trade entries
//      may give many multiple entries, possibly blowing your account!
//
//  This function will take a ticket number and loop until
//  it is seen in the history.
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Matt Kennel, 2010
//
//=============================================================================
bool O_R_CheckForHistory(int ticket)
  {
//My thanks to Matt for this code. He also has the undying gratitude of all users of my trading robots

   int lastTicket=OrderTicket();

   int cnt =0;
   int err=GetLastError(); // so we clear the global variable.
   err=0;
   bool exit_loop=false;
   bool success=false;
   int c = 0;

   while(!exit_loop) 
     {
/* loop through open trades */
      int total=OrdersTotal();
      for(c=0; c<total; c++) 
        {
         if(OrderSelect(c,SELECT_BY_POS,MODE_TRADES)==true) 
           {
            if(OrderTicket()==ticket) 
              {
               success=true;
               exit_loop=true;
              }
           }
        }
      if(cnt>3) 
        {
/* look through history too, as order may have opened and closed immediately */
         total=OrdersHistoryTotal();
         for(c=0; c<total; c++) 
           {
            if(OrderSelect(c,SELECT_BY_POS,MODE_HISTORY)==true) 
              {
               if(OrderTicket()==ticket) 
                 {
                  success=true;
                  exit_loop=true;
                 }
              }
           }
        }

      cnt=cnt+1;
      if(cnt>O_R_Setting_max_retries) 
        {
         exit_loop=true;
        }
      if(!(success || exit_loop)) 
        {
         Print("Did not find #" + IntegerToString(ticket) + " in history, sleeping, then doing retry #" + IntegerToString(cnt));
         O_R_Sleep(O_R_Setting_sleep_time,O_R_Setting_sleep_max);
        }
     }
// Select back the prior ticket num in case caller was using it.
   if(lastTicket>=0) 
     {
      bool s = OrderSelect(lastTicket,SELECT_BY_TICKET,MODE_TRADES);
     }
   if(!success) 
     {
      Print("Never found #" + IntegerToString(ticket) + " in history! crap!");
     }
   return(success);
  }//End bool O_R_CheckForHistory(int ticket)
//=============================================================================
//                              O_R_Sleep()
//
//  This sleeps a random amount of time defined by an exponential
//  probability distribution. The mean time, in Seconds is given
//  in 'mean_time'.
//  This returns immediately if we are backtesting
//  and does not sleep.
//
//=============================================================================
void O_R_Sleep(double mean_time, double max_time)
{
   if (IsTesting()) 
   {
      return;   // return immediately if backtesting.
   }

   double p = (MathRand()+1) / 32768.0;
   double t = -MathLog(p)*mean_time;
   t = MathMin(t,max_time);
   int ms = (int)t*1000;
   if (ms < 10) {
      ms=10;
   }//if (ms < 10) {
   
   Sleep(ms);
}//End void O_R_Sleep(double mean_time, double max_time)

void SendGravyTrade(string symbol, int type, double price)
{

   //Sends a new trade if the latest is at break even. RP key to GTWV processing
   
   //Check extra trading is allowed.
   if (!AllowGTWVTrades)
      return;
      
   
   //Check that there is not already an open trade.
   if (type == OP_BUY)
   {
      if (DoesTradeExist(symbol, OP_BUY, price) )
         return;
      
      SendSingleTrade(symbol, OP_BUY, TradeComment, Lot, ask, 0, 0, MagicNumber);
   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (DoesTradeExist(symbol, OP_SELL, price) )
         return;

      SendSingleTrade(symbol, OP_SELL, TradeComment, Lot, bid, 0, 0, MagicNumber);
   }//if (type == OP_SELL)
   
}//void SendGravyTrade(string symbol, int type)

bool DoesTradeExist(string symbol, int type, double price)
{

   //Checks for the existence of a trade higher (buy) or lower (sell) than the price param.
   //Also tests for max trades already open.

   BuysOpenThisPair = 0;
   SellsOpenThisPair = 0;

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES))
         continue;//Just in case.
      if (OrderSymbol() != symbol)
         continue;
      if (ManageByMagicNumber)
         if (OrderMagicNumber() != MagicNumber)
            continue;
      if (ManageByTradeComment)
         if (OrderComment() != TradeComment)
            continue;
              

      if (type == OP_BUY)
      {
         if (OrderOpenPrice() > price)
            return(true);//There is already an open order      
         BuysOpenThisPair++;
         if (BuysOpenThisPair >= MaxOpenTrades)
            return(true);//We are at the maximum no of BUY trades allowed.   
      }//if (type == OP_BUY)
      
      if (type == OP_SELL)
      {
         if (OrderOpenPrice() < price)
            return(true);//There is already an open order      
         SellsOpenThisPair++;
         if (SellsOpenThisPair >= MaxOpenTrades)
            return(true);//We are at the maximum no of SELL trades allowed.   
      }//if (type == OP_SELL)
      
   
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
   //Got this far, so no trade exists
   return(false);
   
}//End bool DoesTradeExist(string symbol, int type, double price)


void DoTradeManagement()
{

   //Trades being managed by mptm are stored in an array. The user's choice of
   //management facilities does not matter here, only the type of management required.
   for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(FifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) )
         continue;//Trade has closed.
      
      int ticket = FifoTicket[cc];
      
      GetBasics(OrderSymbol() );
      
/**      

RP - Hiden stop loss and TP not used in GTWV==>

		//Has a hidden SL been hit?
		if (UseHiddenStopLoss)
		   if (OrderType() < 2)//Only applies to market trades
		      if (HideStopLoss(ticket) )
		         continue;//Trade has closed, so no need to go further.   
		
 		//Has a hidden tp been hit?
		if (UseHiddenTakeProfit)
		   if (OrderType() < 2)//Only applies to market trades
		      if (HideTakeProfit(ticket) )
		         continue;//Trade has closed, so no need to go further.   
		   
    */

      //Break even stop loss
      if (UseBreakEven)
         BreakEvenStopLoss(ticket);
   
		//Jumping stop loss
		if (UseJumpingStop)
		   JumpingStopLoss(ticket);
		
		//Standard trailing stop loss
		if (UseStandardTrail)
		   TrailingStopLoss(ticket);
		   
/** RP - Candlestick trails not used in GTWV ==>
		
		//Candlestick trailing stop loss
		if (UseCandlestickTrail)
		   CandlestickTrailingStop(ticket);
		   
RP - Candlestick trails not used in GTWV <==		
*/  
		
		//Add a missing stop loss
		if (AddMissingStopLoss)
		   InsertStopLoss(ticket);
		   
		//Add a missing take profit
		if (AddMissingTakeProfit)
		   InsertTakeProfit(ticket);
		   
/** RP -EOD closure not used in GTWV ==>		   
		   
      //End of day closure
      if (DailyCloseEnabled)
         CloseOrderAtChosenHour(ticket);
 RP - EOD closure not used in GTWV <==
 */  
		
   }//for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   
   
      

}//End void DoTradeManagement()


//END OF TRADE MANAGEMENT MODULE
//////////////////////////////////////////////////////////////////////////////////////////////////////////

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---
   
   if(!IsExpertEnabled())
   {
      removeAllObjects();
      Comment("GTWV EA Disabled");
      return;
   }//if (!IsExpertEnabled() )
   
   //Build a picture of the position.
   CountOpenTrades();
   
   //Any trades to manage?
   if (OpenTrades > 0)
   {
      DoTradeManagement();
   }//if (OpenTrades > 0)
   
   
   DisplayUserFeedback();
   
}
//+------------------------------------------------------------------+

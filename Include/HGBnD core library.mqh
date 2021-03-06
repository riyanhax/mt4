//+------------------------------------------------------------------+
//|                                           HGBnD core library.mqh |
//|                                                 Thomas and Steve |
//|                                https://www.stevehopwoodforex.com |
//+------------------------------------------------------------------+
#property copyright "Thomas and Steve"
#property link      "https://www.stevehopwoodforex.com"

#include <WinUser32.mqh>
#include <stdlib.mqh>

//#include <hgi_lib.mqh>
//Instead of including we declare everything here to avoid #property strict
#import "hgi_lib.ex4"
   enum SIGNAL {NONE=0,TRENDUP=1,TRENDDN=2,RANGEUP=3,RANGEDN=4,RADUP=5,RADDN=6};
   enum SLOPE {UNDEFINED=0,RANGEABOVE=1,RANGEBELOW=2,TRENDABOVE=3,TRENDBELOW=4};
   SIGNAL getHGISignal(string symbol,int timeframe,int shift);
   SLOPE getHGISlope (string symbol,int timeframe,int shift);
#import
//End //#include <hgi_lib.mqh>

#define  NL    "\n"
#define  up ": Up"
#define  down ": Down"
#define  flat ": Flat"
#define  ranging ": Ranging"
#define  none "None"
#define  both "Both"
#define  buy "Buy"
#define  sell "Sell"

#define  AllTrades 10 //Tells CloseAllTrades() to close/delete everything
#define  million 1000000;

//Define the GridBuy/SellTicket fields
#define  TradeOpenPrice 0
#define  TradeTicket 1

//Code provided by Radar. Many thanks Radar.
//Global Variable for HGBnD - MultiSymbol - Controller
#define  EnableTrading                            "EnableTrading"
static   const string GvEnableTrading = StringFormat("%s:%s", EnableTrading, _Symbol);

//Old trend types
enum OldTrendTypes
{
   notrend = 0,
   shorttrend = 1,
   longtrend = 2,
};


//Chandelier colour status
#define  orange " Orange"
#define  magenta " Magenta"
#define  blank " Blank"


//HGI signal status
#define  hginotrend ": No trend signal within HgiTrendTimeFrameCandlesLookBack"
#define  hginosignal ": No trade signal or trading time frame or HGI not read"
#define  hgibuysignal ": Buy signal"
#define  hgisellsignal ": Sell signal"


//Trend Arrow constants
#define  Trendnoarrow " No trend arrow "
#define  Trenduparrow " Big green up Trend arrow "
#define  Trenddownarrow " Big red down Trend arrow "

//Rad Arrow constants
#define  Radnoarrow " No RAD arrow "
#define  Raduparrow " Small up RAD arrow "
#define  Raddownarrow " Small down RAD arrow "


//Wavy line constants
#define  Wavenone " No wave "
#define  Waverange " Yellow Range wave "
#define  Wavebuytrend " Blue wave buy trend"
#define  Waveselltrend " Blue wave sell trend"

#define  millions 10000000 //For phpl stuff

//Sixths trading status
#define  untradable ": not tradable"
#define  tradablelong ": tradable long"
#define  tradableshort ": tradable short"
#define  tradableboth ": tradable both long and short"


//Trading direction
#define        longdirection "Long"
#define        shortdirection "Short"

//Currency status
#define  upaccelerating "Up, and accelerating"
#define  updecelerating "Up, but slowing"
#define  downaccelerating "Down, and accelerating"
#define  downdecelerating "Down, but slowing"

//Pending trade price line
#define  pendingpriceline "Pending price line"
//Hidden sl and tp lines. If used, the bot will close trades on a touch/break of these lines.
//Each line is named with its appropriate prefix and the ticket number of the relevant trade
#define  TpPrefix "Tp"
#define  SlPrefix "Sl"


//Error reporting
#define  slm " stop loss modification failed with error "
#define  tpm " take profit modification failed with error "
#define  ocm " order close failed with error "
#define  odm " order delete failed with error "
#define  pcm " part close failed with error "
#define  spm " shirt-protection close failed with error "
#define  slim " stop loss insertion failed with error "
#define  tpim " take profit insertion failed with error "
#define  tpsl " take profit or stop loss insertion failed with error "
#define  oop " pending order price modification failed with error "

////////////////////////////////////////////////////////////////////////////////////////

//Hedging and the grid are linked. If using hedging and using the grid, then the ea
//will send grids in both directions when an initial trade trigger arises. If only using
//the grid, then only the grid in the direction of the initial trade will be sent.
extern string  sep1d="================================================================";
extern string  hed="---- Hedging ----";
extern bool    UseHedgingWithGrid=false;
//Pips profit target at which to close a hedged position. Zero value to disable
extern int     HedgeProfitPips=30;
//Cash profit target at which to close a hedged position. Zero value to disable
extern int     HedgeProfitCash=30;
////////////////////////////////////////////////////////////////////////////////////////
bool           Hedged=true;//Set to true if there are both market buys and sells open,
                            //to prevent closure on an opposite direction signal. Initialised
                            //as true to avoid closure first time around CountOpenTrades
bool           FullyHedged=false;//Set when CountOpenTrades() finds a fully hedged trade comment.)
double         HedgeProfit=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1b="================================================================";
extern string  gri="---- Grid inputs ----";
extern bool    UseGrid=false;
//x orders above market and x below.
extern int     GridSize=10;
extern int     DistanceBetweenTradesPips=0;
extern bool    DeletePendingsDuringWideSpread=true;//Deletes the pendings during a wide spread event, then replaces them
extern bool    DeletePendingsOnNewSignal=false;
////////////////////////////////////////////////////////////////////////////////////////
double         DistanceBetweenTrades=0;
int            GridTradesTotal=0;//Total of market, stop and limit trades
int            PendingTradesTotal=0;//Total of stop and limit trades
int            MarketTradesTotal=0;//Total of open market trades
bool           GridSent=false;//true if CountOpenTrades finds a trade
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1g="================================================================";
extern string  off="---- Offsetting ----";
//Simple offset and double-sided complex offset
extern bool    UseOffsetting=false;
extern bool    AllowOffsettingWhenHedged=false;
extern bool    AllowComplexSingleSidedOffsets=true;//Allow complex single-sided offset. Not allowed if UseOffsetting = false
extern int     MinOpenTradesToStartOffset=4;//Only use offsetting if there are at least this number of trades in the group
extern bool    FillInGaps=true;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
extern string  sep1c="================================================================";
extern string  atri="---- ATR for grid trading inputs ----";
extern string  grz="-- Grid size --";
extern bool    UseAtrForGrid=false;
extern ENUM_TIMEFRAMES GridAtrTimeFrame=PERIOD_D1;
extern int     GridAtrPeriod=10;
extern double  GridAtrMultiplier=1;
extern int     MinimumDistanceBetweenTradesPips=5;
////////////////////////////////////////////////////////////////////////////////////////////
double         AtrVal=0, GridAtrVal=0;
/////////////////////////////////////////////////////////////////////////////////////////////

extern string  sep2a="================================================================";
extern string  btp="---- Basket take profit ----";
//Included in case anybody wants it
extern int     BasketTakeProfitPips=0;
extern bool    UseAtrForBasketTP=false;
extern double  TpPercentOfAtrToUse=0;
extern bool    RestockGridAfterTP=false;
extern bool    UseDydynamicClosure=false;
extern color   RectColor=Silver;
/////////////////////////////////////////////////////////////////////////////////////////////
double         BasketTakeProfit=0;
/////////////////////////////////////////////////////////////////////////////////////////////

extern string  sep2c="================================================================";
/*
This is based on ideas presented at https://www.doubleinadayforex.com/ and described in
the youtube video at https://www.youtube.com/watch?v=1iul8paae-M
*/
extern string  daid="---- DIAD style trading ----";
extern bool    UseDiadStyleTrading=true;
extern color   TakeProfitLineColour=Yellow;
extern color   BreakEven1LineColour=Blue;
extern color   BreakEven2LineColour=Salmon;
extern int     DiadBreakevenProfitPips=2;
extern string  t1="-- Trade 1 --";
extern string  Trade1TradeComment="Trade 1";
extern string  t2="-- Trade 2 --";
extern string  Trade2TradeComment="Trade 2";
//Pips away from the first market trade for the first stop order
extern int     Trade2AtPips=30;  
extern color   Trade2LineColour=Turquoise;
extern string  t3="-- Trade 3 --";
extern string  Trade3TradeComment="Trade 3";
//Pips away from the first market trade for the second stop order
extern int     Trade3AtPips=60;  
extern color   Trade3LineColour=Magenta;
////////////////////////////////////////////////////////////////////////////////////////
double         Trade2At=0, Trade3At=0;
string         TradeLine2Name = "Diad_Trade line 2";
ENUM_LINE_STYLE Trade2BuyLineStyle=STYLE_DASH;
ENUM_LINE_STYLE Trade2SellLineStyle=STYLE_DOT;
string         TradeLine3Name = "Diad_Trade line 3";
ENUM_LINE_STYLE Trade3BuyLineStyle=STYLE_DASH;
ENUM_LINE_STYLE Trade3SellLineStyle=STYLE_DOT;
string         BeLine1Name = "Diad_Breakeven line 1";
string         BeLine2Name = "Diad_Breakeven line 2";
ENUM_LINE_STYLE BeLineStyle=STYLE_DASHDOT;
string         TakeProfitLineName="Diad_Take Profit Line";
double         DiadBreakevenProfit=0;
//Some variables for storing price line values
double         Trade1Price = 0, Trade2Price=0, Trade3Price = 0, Be1Price=0, Be2Price = 0, TpPrice = 0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep2b="================================================================";
extern string  sfs="----SafetyFeature----";
//Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Use the next input 
//in combination with TooClose() to abort the trade if the previous one closed within the time limit.
//For spotting possible rogue trades
extern int     MinMinutesBetweenTradeOpenClose=0;
//Minimum time to pass after a trade closes, until the ea can open another.
extern int     MinMinutesBetweenTrades=0;
////////////////////////////////////////////////////////////////////////////////////////
bool           SafetyViolation;//For chart display
bool           RobotSuspended=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep2="================================================================";
//Hidden tp/sl inputs.
extern string  hts="----Stealth stop loss and take profit inputs----";
//Added to the 'hard' sl and tp and used for closure calculations
extern int     PipsHiddenFromCriminal=0;
////////////////////////////////////////////////////////////////////////////////////////
double         HiddenStopLoss, HiddenTakeProfit;
double         HiddenPips=0;//Added to the 'hard' sl and tp and used for closure calculations
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep5="================================================================";
extern string	CSS_Input="----CCS inputs----";
extern bool    UseCSS=false;
extern int     maxBars           = 100;
extern int     CssTf=0;
// extern bool    ignoreFuture      = true;
string         CurrNames[8]  = { "USD", "EUR", "GBP", "CHF", "JPY", "AUD", "CAD", "NZD" };
////////////////////////////////////////////////////////////////////////////////////////
string         Curr1, Curr2;//First and second currency in the pair
int            CurrIndex1, CurrIndex2;//Index of the currencies that form the pair to point to the correct one in currencyNames
double         CurrVal1[3], CurrVal2[3];//Hold the values of the two currencies, alloing me to look back in time to see if the currency is rising or falling.
string         CurrDirection1, CurrDirection2;//One of the Currency ststus constants
////////////////////////////////////////////////////////////////////////////////////////


extern string  sep7="================================================================";
//CheckTradingTimes. Baluda has provided all the code for this. Mny thanks Paul; you are a star.
extern string	trh				= "----Trading hours----";
extern string	tr1				= "tradingHours is a comma delimited list";
extern string  tr1a            = "of start and stop times.";
extern string	tr2				= "Prefix start with '+', stop with '-'";
extern string  tr2a            = "Use 24H format, local time.";
extern string	tr3				= "Example: '+07.00,-10.30,+14.15,-16.00'";
extern string	tr3a			= "Do not leave spaces";
extern string	tr4				= "Blank input means 24 hour trading.";
extern string	tradingHours="";

extern string  sep7a="================================================================";
extern string  ss="---- Start/Stop time ----";
extern string  ss1 = "Use 24H format, SERVER time.";
extern string  ss2 = "Example: '01.30'";
extern string  SundayStartTradingTime="24.00";
extern string  MondayStartTradingTime="02.00";
extern string  FridayStopTradingTime="12.00";
extern string  SaturdayStopTradingTime="00.00";
////////////////////////////////////////////////////////////////////////////////////////
double	      TradeTimeOn[];
double	      TradeTimeOff[];
// trading hours variables
int 	         tradeHours[];
string         tradingHoursDisplay;//tradingHours is reduced to "" on initTradingHours, so this variable saves it for screen display.
bool           TradeTimeOk;
////////////////////////////////////////////////////////////////////////////////////////
//This code by tomele. Thank you Thomas. Wonderful stuff.
extern string  sep7b="================================================================";
extern string  roll="---- Rollover time ----";
extern bool    DisableDottyDuringRollover=true;
extern string  ro1 = "Use 24H format, SERVER time.";
extern string  ro2 = "Example: '23.55'";
extern string  RollOverStarts="23.55";
extern string  RollOverEnds="00.15";
////////////////////////////////////////////////////////////////////////////////////////
bool           RolloverInProgress=false;//Tells DisplayUserFeedback() to display the rollover message
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep8="================================================================";
extern string  bf="----Trading balance filters----";
extern bool    UseZeljko=false;
extern bool    OnlyTradeCurrencyTwice=false;
////////////////////////////////////////////////////////////////////////////////////////
bool           CanTradeThisPair;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep9="================================================================";
extern string  pts="----Swap filter----";
extern bool    CadPairsPositiveOnly=false;
extern bool    AudPairsPositiveOnly=false;
extern bool    NzdPairsPositiveOnly=false;
extern bool    OnlyTradePositiveSwap=false;
////////////////////////////////////////////////////////////////////////////////////////
double         LongSwap, ShortSwap;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep10="================================================================";
extern string  amc="----Available Margin checks----";
extern string  sco="Scoobs";
extern bool    UseScoobsMarginCheck=false;
extern string  fk="ForexKiwi";
extern bool    UseForexKiwi=false;
extern int     FkMinimumMarginPercent=1500;
////////////////////////////////////////////////////////////////////////////////////////
bool           EnoughMargin;
string         MarginMessage;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep11="================================================================";
extern string  asi="----Average spread inputs----";
//The ticks to count whilst canculating the av spread
extern int     TicksToCount=5;
extern double  MultiplierToDetectStopHunt=4;
////////////////////////////////////////////////////////////////////////////////////////
double         AverageSpread=0;

double         ShortAverageSpread=0;
string         SpreadGvName;//A GV will hold the calculated average spread
int            CountedTicks=0;//For status display whilst calculating the spread
double         BiggestSpread=0;//Holds a record of the widest spread since the EA was loaded
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep11a="================================================================";
extern string  ccs="---- Chart snapshots ----";
//Tells ea to take snaps when it opens and closes a trade
extern bool    TakeSnapshots=false;
extern int     PictureWidth=800;
extern int     PictureHeight=600;

extern string  sep12="================================================================";
extern string  ems="----Email thingies----";
extern bool    EmailTradeNotification=false;
extern bool    SendAlertNotTrade=false;
// Enable to send push notification on alert
extern bool    AlertPush=false;
////////////////////////////////////////////////////////////////////////////////////////
bool           AlertSent;//To alert to a trade trigger without actually sending the trade
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep13="================================================================";
extern string  tmm="----Trade management module----";

extern string  sep1f="================================================================";
extern string  cex="---- Chandelier exit ----";
extern bool    UseChandelierExit=false;
extern int     cRange=22;
extern int     cShift=0;
extern int     cATRPeriod=22;
extern double  cATRMultipl=3;
/////////////////////////////////////////////////////////////////////////////////////////////
string         ChanColour="";//Constants defined above
double         ChanVal=0;
/////////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1h="================================================================";
//Breakeven has to be enabled for JS and TS to work.
extern string  BE="Break even settings";
extern bool    BreakEven=false;
extern int     BreakEvenTargetPips=10;
extern int     BreakEvenTargetProfit=5;
extern bool    PartCloseEnabled=false;
//Percentage of the trade lots to close
extern double  PartClosePercent=50;
////////////////////////////////////////////////////////////////////////////////////////
double         BreakEvenPips, BreakEvenProfit;
bool           TradeHasPartClosed=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep14="================================================================";
extern string  JSL="Jumping stop loss settings";
extern bool    JumpingStop=false;
extern int     JumpingStopTargetPips=10;
extern bool    AddBEP=true;
////////////////////////////////////////////////////////////////////////////////////////
double         JumpingStopPips;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep15="================================================================";
extern string  cts="----Candlestick jumping stop----";
extern bool    UseCandlestickTrailingStop=false;
extern int     CstTimeFrame=0;
extern int     CstTrailCandles=1;
extern bool    TrailMustLockInProfit=true;
////////////////////////////////////////////////////////////////////////////////////////
int            OldCstBars;//For candlestick ts
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep16="================================================================";
extern string  TSL="Trailing stop loss settings";
extern bool    TrailingStop=false;
extern int     TrailingStopTargetPips=20;
////////////////////////////////////////////////////////////////////////////////////////
double         TrailingStopPips;
////////////////////////////////////////////////////////////////////////////////////////

//Enhanced screen feedback display code provided by Paul Batchelor (lifesys). Thanks Paul; this is fantastic.
extern string  se52  ="================================================================";
extern string  oad               ="----Odds and ends----";
extern int     ChartRefreshDelaySeconds=3;
// if using Comments
extern int     DisplayGapSize    = 30; 
// ****************************** added to make screen Text more readable
// replaces Comment() with OBJ_LABEL text
extern bool    DisplayAsText     = true;  
//Disable the chart in foreground CrapTx setting so the candles do not obscure the text
extern bool    KeepTextOnTop     = true;
extern int     DisplayX          = 100;
extern int     DisplayY          = 0;
extern int     fontSise          = 10;
extern string  fontName          = "Arial";
extern color   colour            = Yellow;
// adjustment to reform lines for different font size
extern double  spacingtweek      = 0.6; 
////////////////////////////////////////////////////////////////////////////////////////
int            DisplayCount;
string         Gap,ScreenMessage;
////////////////////////////////////////////////////////////////////////////////////////

int            PendingExpiryMinutes=0;//This needs setting up in the OnInit of the EA code

//Calculating the factor needed to turn pip values into their correct points value to accommodate different Digit size.
//Thanks to Lifesys for providing this code. Coders, you need to briefly turn of Wrap and turn on a mono-spaced font to view this properly and see how easy it is to make changes.

//string         pipFactor[]  = {"NOK","SEK","ZAR","MXN","JPY","XAG","SILVER","BRENT","WTI","XTI","UKOIL","XAU","GOLD","XPT","SP500","US500","S&P","ESTX50","UK100","WS30","DAX30","GER30","DJ30","US30","NAS100","CAC400","FRA40","AUS200","JPN225","HK50"};
//double         pipFactors[] = { 1000, 1000, 1000, 1000, 100,  100,  100,     100,    100,  100,  100,    10,   10,    10,   10,     10,     10,   10,      1,      1,     1,      1,      1,     1,     1,       1,       1,      1,       1,       1};
//And by Steve. I have pinched Tomasso's APTM function for returning the value of factor.
double         factor;//For pips/points stuff. Set up in int init()
////////////////////////////////////////////////////////////////////////////////////////

int ClosureTicketsSellSide[];
      
//Matt's O-R stuff
int 	         O_R_Setting_max_retries 	= 10;
double 	      O_R_Setting_sleep_time 		= 4.0; /* seconds */
double 	      O_R_Setting_sleep_max 		= 15.0; /* seconds */
int            RetryCount = 10;//Will make this number of attempts to get around the trade context busy error.

//Running total of trades
int            LossTrades, WinTrades;
double         OverallProfit;

//Misc
int            OldBars;
string         PipDescription=" pips";
bool           ForceTradeClosure;
int            TurnOff=0;//For turning off functions without removing their code


//Variables for building a picture of the open position
//Market Buy trades
bool           BuyOpen=false;
int            MarketBuysCount=0;
double         LatestBuyPrice=0, EarliestBuyPrice=0, HighestBuyPrice=0, LowestBuyPrice=0;
int            BuyTicketNo=-1, HighestBuyTicketNo=-1, LowestBuyTicketNo=-1, LatestBuyTicketNo=-1, EarliestBuyTicketNo=-1;
double         BuyPipsUpl=0;
double         BuyCashUpl=0;
datetime       LatestBuyTradeTime=0;
datetime       EarliestBuyTradeTime=0;
double         BuyLotsTotal=0;

//Market Sell trades
bool           SellOpen=false;
int            MarketSellsCount=0;
double         LatestSellPrice=0, EarliestSellPrice=0, HighestSellPrice=0, LowestSellPrice=0;
int            SellTicketNo=-1, HighestSellTicketNo=-1, LowestSellTicketNo=-1, LatestSellTicketNo=-1, EarliestSellTicketNo=-1;;
double         SellPipsUpl=0;
double         SellCashUpl=0;
datetime       LatestSellTradeTime=0;
datetime       EarliestSellTradeTime=0;
double         SellLotsTotal=0;

//BuyStop trades
bool           BuyStopOpen=false;
int            BuyStopsCount=0;
double         LatestBuyStopPrice=0, EarliestBuyStopPrice=0, HighestBuyStopPrice=0, LowestBuyStopPrice=0;
int            BuyStopTicketNo=-1, HighestBuyStopTicketNo=-1, LowestBuyStopTicketNo=-1, LatestBuyStopTicketNo=-1, EarliestBuyStopTicketNo=-1;;
datetime       LatestBuyStopTradeTime=0;
datetime       EarliestBuyStopTradeTime=0;

//BuyLimit trades
bool           BuyLimitOpen=false;
int            BuyLimitsCount=0;
double         LatestBuyLimitPrice=0, EarliestBuyLimitPrice=0, HighestBuyLimitPrice=0, LowestBuyLimitPrice=0;
int            BuyLimitTicketNo=-1, HighestBuyLimitTicketNo=-1, LowestBuyLimitTicketNo=-1, LatestBuyLimitTicketNo=-1, EarliestBuyLimitTicketNo=-1;;
datetime       LatestBuyLimitTradeTime=0;
datetime       EarliestBuyLimitTradeTime=0;

/////SellStop trades
bool           SellStopOpen=false;
int            SellStopsCount=0;
double         LatestSellStopPrice=0, EarliestSellStopPrice=0, HighestSellStopPrice=0, LowestSellStopPrice=0;
int            SellStopTicketNo=-1, HighestSellStopTicketNo=-1, LowestSellStopTicketNo=-1, LatestSellStopTicketNo=-1, EarliestSellStopTicketNo=-1;;
datetime       LatestSellStopTradeTime=0;
datetime       EarliestSellStopTradeTime=0;

//SellLimit trades
bool           SellLimitOpen=false;
int            SellLimitsCount=0;
double         LatestSellLimitPrice=0, EarliestSellLimitPrice=0, HighestSellLimitPrice=0, LowestSellLimitPrice=0;
int            SellLimitTicketNo=-1, HighestSellLimitTicketNo=-1, LowestSellLimitTicketNo=-1, LatestSellLimitTicketNo=-1, EarliestSellLimitTicketNo=-1;;
datetime       LatestSellLimitTradeTime=0;
datetime       EarliestSellLimitTradeTime=0;

//Not related to specific order types
int            TicketNo=-1,OpenTrades,OldOpenTrades;
//Variables to tell the ea that it has a trading signal
bool           BuySignal=false, SellSignal=false;
//Variables to tell the ea that it has a trading closure signal
bool           BuyCloseSignal=false, SellCloseSignal=false;
//Variables for storing market trade ticket numbers
datetime       LatestTradeTime=0, EarliestTradeTime=0;//More specific times are in each individual section
int            LatestTradeTicketNo=-1, EarliestTradeTicketNo=-1;
double         PipsUpl;//For keeping track of the pips PipsUpl of multi-trade/hedged positions
double         CashUpl;//For keeping track of the cash PipsUpl of multi-trade/hedged positions
//Variable for the hedging code to tell if there are tp's and sl's set
bool           TpSet=false, SlSet=false;


void UsualOnInit()
{


   if (UseSixths || UseBuyLowSellHigh)
   {
      //Zoom the chart out as soon as possible
      //Idiot check. Guess how I know it is necessary?
      if (NoOfBarsOnChart == 0)
         NoOfBarsOnChart = 1680;
      int scale = ChartScaleGet();
      if (scale != Zoom_Level)
      {
         ChartScaleSet(Zoom_Level);
         //A quick time frame change to force accurate display
         per = ChartPeriod(0);
         int nextPer = GetNextPeriod(per);
         ChartSetSymbolPeriod(0, Symbol(), nextPer);//Change time frame
         ChartSetSymbolPeriod(0, Symbol(), per);//reset time frame      
      }//if (scale != Zoom_Level)
         
      //Adjust the right side margin
      double mar = ChartShiftSizeGet(0);
      if (!CloseEnough(mar, 10))
         ChartShiftSizeSet(10, 0);
      }//if (UseSixths  || UseBuyLowSellHigh)

   if (UseChandelierExit)
      if (!indiExists( "chandelier-exit" ))
      {
         Alert("");
         Alert("Download the indi from the Dottybot thread");
         Alert("The required indicator 'chandelier-exit' does not exist on your platform. I am removing myself from your chart.");
         RemoveExpert = true;
         ExpertRemove();
         return;
      }//if (! indiExists( "chandelier-exit" ))
      
      
      //Adapt this to suit the indi you are using
      /*if (!indiExists( "IndiName" ))
      {
         Alert("");
         Alert("Download the indi from the thread");
         Alert("The required indicator 'IndiName' does not exist on your platform. I am removing myself from your chart.");
         RemoveExpert = true;
         ExpertRemove();
         return(0);
      }//if (! indiExists( "IndiName" ))
      */

   
   //~ Set up the pips factor. tp and sl etc.
   //~ The EA uses doubles and assume the value of the integer user inputs. This: 
   //~    1) minimises the danger of the inputs becoming corrupted by restarts; 
   //~    2) the integer inputs cannot be divided by factor - doing so results in zero.
   
   factor = GetPipFactor(Symbol());
   StopLoss = StopLossPips;
   TakeProfit = TakeProfitPips;
   BreakEvenPips = BreakEvenTargetPips;
   BreakEvenProfit = BreakEvenTargetProfit;
   JumpingStopPips = JumpingStopTargetPips;
   TrailingStopPips = TrailingStopTargetPips;
   HiddenPips = PipsHiddenFromCriminal;
   BasketTakeProfit = BasketTakeProfitPips;
   Trade2At = Trade2AtPips;
   Trade3At = Trade3AtPips;
   DiadBreakevenProfit = DiadBreakevenProfitPips;
   
   
   //Idiot check
   if (UseDiadStyleTrading)
      if (TakeProfitPips == 0)
      {
         TakeProfitPips = 100;
         TakeProfit = 100;
      }//if (TakeProfitPips = 0)
      
   
   //Adjust the right side margin
   double mar = ChartShiftSizeGet(0);
   if (!CloseEnough(mar, 10))
      ChartShiftSizeSet(10, 0);
   

   
   if (DistanceBetweenTradesPips > 0)
      DistanceBetweenTrades = DistanceBetweenTradesPips;
   else
      ReadIndicatorValues();
   
   while (IsConnected()==false)
   {
      Comment("Waiting for MT4 connection...");
      Sleep(1000);
   }//while (IsConnected()==false)

   //MaxTradesAllowed needs to be 1 if we are using the grid and
   //ImmediateMarketOrders is enabled to avoid sending a new trade
   //on every new signal.
   if (UseGrid)
      MaxTradesAllowed = 1;

   

   //Lot size and part-close idiot check for the cretins. Code provided by phil_trade. Many thanks, Philippe.
   //adjust Min_lot
   if (CloseEnough(RiskPercent, 0) )
      if(Lot<MarketInfo(Symbol(),MODE_MINLOT))
      {
         Alert(Symbol()+" Lot was adjusted to Minlot = "+DoubleToStr(MarketInfo(Symbol(),MODE_MINLOT),Digits));
         Lot=MarketInfo(Symbol(),MODE_MINLOT);
      }//if (Lot < MarketInfo(Symbol(), MODE_MINLOT)) 
   /*
   //check Partial close parameters
   if (PartCloseEnabled == true)
   {
      if (Lot < Close_Lots + Preserve_Lots || Lot < MarketInfo(Symbol(), MODE_MINLOT) + Close_Lots )
      {
         Alert(Symbol()+" PartCloseEnabled is disabled because Lot < Close_Lots + Preserve_Lots or Lot < MarketInfo(Symbol(), MODE_MINLOT) + Close_Lots !");
         PartCloseEnabled = false;
      }//if (Lot < Close_Lots + Preserve_Lots || Lot < MarketInfo(Symbol(), MODE_MINLOT) + Close_Lots )
   }//if (PartCloseEnabled == true)
   */

   //Jumping/trailing stops need breakeven set before they work properly
   if ((JumpingStop || TrailingStop) && !BreakEven) 
   {
      BreakEven = true;
      if (JumpingStop) BreakEvenPips = JumpingStopPips;
      if (TrailingStop) BreakEvenPips = TrailingStopPips;
   }//if (JumpingStop || TrailingStop) 
   
   Gap="";
   if (DisplayGapSize >0)
   {
      for (int cc=0; cc< DisplayGapSize; cc++)
      {
         Gap = StringConcatenate(Gap, " ");
      }   
   }//if (DisplayGapSize >0)
   
   //Reset CriminIsECN if crim is IBFX and the punter does not know or, like me, keeps on forgetting
   string name = TerminalCompany();
   int ispart = StringFind(name, "IBFX", 0);
   if (ispart < 0) ispart = StringFind(name, "Interbank FX", 0);
   if (ispart > -1) IsGlobalPrimeOrECNCriminal = true;   
   ispart = StringFind(name, "Global Prime", 0);
   if (ispart > -1) IsGlobalPrimeOrECNCriminal = true;   
   
   //Set up the trading hours
   tradingHoursDisplay = tradingHours;//For display
   initTradingHours();//Sets up the trading hours array

   // Initialize libCSS
   if (UseCSS) libCSSinit();

   if (TradeComment == "") TradeComment = " ";
   OldBars = Bars;
   TicketNo = -1;
   if (DistanceBetweenTradesPips == 0)//RIV is called higher up if DistanceBetweenTradesPips > 0
      ReadIndicatorValues();//For initial display in case user has turned of constant re-display
   GetSwap(Symbol());//This will need editing/removing in a multi-pair ea.
   TradeDirectionBySwap();
   TooClose();
   CountOpenTrades();
   OldOpenTrades = OpenTrades;
   TradeTimeOk = CheckTradingTimes();   
   
   if (!IsTesting() )
   {   
      
      //The spread global variable
      SpreadGvName = Symbol() + " average spread";
      AverageSpread = GlobalVariableGet(SpreadGvName);//If no gv, then the value will be left at zero.
   }//if (!IsTesting() )
   
    
   //Chart display
   if (DisplayAsText)
      if (KeepTextOnTop)
         ChartForegroundSet(false,0);// change chart to background

   //Ensure that an ea depending on Close[1] for its values does not immediately fire a trade.
   if (!EveryTickMode) OldBarsTime = iTime(Symbol(), TradingTimeFrame, 0);

   //Lot size based on account size
   if (!CloseEnough(LotsPerDollopOfCash, 0))
      CalculateLotAsAmountPerCashDollops();

   //Time frame display
   TradingTimeFrameDisplay = GetTimeFrameDisplay(TradingTimeFrame);
   TrendTimeFrameDisplay = GetTimeFrameDisplay(HgiTrendTimeFrame);
   
   //Detect the previous trend
   TrendGvName = "HGBnD " + Symbol() + " trend ";
   if(!GlobalVariableCheck(TrendGvName) )
   {
      GlobalVariableSet(TrendGvName, notrend);
   }//if(!GlobalVariableCheck(TrendGvName) )
   OldLongTrendDetected = false;
   OldShortTrendDetected = false;
   int t = (OldTrendTypes)GlobalVariableGet(TrendGvName);
   if (t == longtrend)
      OldLongTrendDetected = true;
   if (t == shorttrend)
      OldShortTrendDetected = true;
      
   if (UseDiadStyleTrading)
      DoDiadTrading();
      
   DisplayUserFeedback();

   //Create the labels
   string tfDisplay = "";
   DisplayCount = 1;
   
   if (UseBuyLowSellHigh)
   {
      if (UseBlshHighestTimeFrame)
      {
         if (ObjectFind(highestTimeFrameLabelName) < 0)
         {
            ObjectCreate(highestTimeFrameLabelName, OBJ_LABEL, 0, 0, 0); 
            ObjectSet(highestTimeFrameLabelName, OBJPROP_CORNER, 0);
            //ObjectSet(highestTimeFrameLabelName, OBJPROP_XDISTANCE, BlshDisplayX + ofset); 
            ObjectSet(highestTimeFrameLabelName, OBJPROP_XDISTANCE, BlshDisplayX); 
            ObjectSet(highestTimeFrameLabelName, OBJPROP_YDISTANCE, BlshDisplayY+DisplayCount*(BlshfontSise+4)); 
            ObjectSet(highestTimeFrameLabelName, OBJPROP_BACK, false);
            tfDisplay = GetTimeFrameDisplay(BlshHighestTimeFrame);
            ObjectSetText(highestTimeFrameLabelName, tfDisplay, BlshfontSise, BlshfontName, BlshHighestTimeFrameLineColour);
         }//if (ObjectFind(highestTimeFrameLabelName) < 0)
         
         
         if (ObjectFind(highestTimeFrameLabelDirection) < 0)
         {
            ObjectCreate(highestTimeFrameLabelDirection, OBJ_LABEL, 0, 0, 0); 
            ObjectSet(highestTimeFrameLabelDirection, OBJPROP_CORNER, 0);
            ObjectSet(highestTimeFrameLabelDirection, OBJPROP_XDISTANCE, BlshDisplayX + 50); 
            ObjectSet(highestTimeFrameLabelDirection, OBJPROP_YDISTANCE, BlshDisplayY+DisplayCount*(BlshfontSise+4)); 
            ObjectSet(highestTimeFrameLabelDirection, OBJPROP_BACK, false);
            ObjectSetText(highestTimeFrameLabelDirection, highestBlshStatus, BlshfontSise, BlshfontName, BuyColour);
         }//if (ObjectFind(highestTimeFrameLabelDirection) < 0)
         
         DisplayCount++;     
         
      }//if (UseBlshHighestTimeFrame)
      
      if (UseBlshHighTimeFrame)
      {
         if (ObjectFind(highTimeFrameLabelName) < 0)
         {
            ObjectCreate(highTimeFrameLabelName, OBJ_LABEL, 0, 0, 0); 
            ObjectSet(highTimeFrameLabelName, OBJPROP_CORNER, 0);
            //ObjectSet(highTimeFrameLabelName, OBJPROP_XDISTANCE, BlshDisplayX + ofset); 
            ObjectSet(highTimeFrameLabelName, OBJPROP_XDISTANCE, BlshDisplayX); 
            ObjectSet(highTimeFrameLabelName, OBJPROP_YDISTANCE, BlshDisplayY+DisplayCount*(BlshfontSise+10)); 
            ObjectSet(highTimeFrameLabelName, OBJPROP_BACK, false);
            tfDisplay = GetTimeFrameDisplay(BlshHighTimeFrame);
            ObjectSetText(highTimeFrameLabelName, tfDisplay, BlshfontSise, BlshfontName, BlshHighTimeFrameLineColour);
         }//if (ObjectFind(highTimeFrameLabelName) < 0)
         
         
         if (ObjectFind(highTimeFrameLabelDirection) < 0)
         {
            ObjectCreate(highTimeFrameLabelDirection, OBJ_LABEL, 0, 0, 0); 
            ObjectSet(highTimeFrameLabelDirection, OBJPROP_CORNER, 0);
            //ObjectSet(highTimeFrameLabelDirection, OBJPROP_XDISTANCE, BlshDisplayX + ofset); 
            ObjectSet(highTimeFrameLabelDirection, OBJPROP_XDISTANCE, BlshDisplayX + 50); 
            ObjectSet(highTimeFrameLabelDirection, OBJPROP_YDISTANCE, BlshDisplayY+DisplayCount*(BlshfontSise+10)); 
            ObjectSet(highTimeFrameLabelDirection, OBJPROP_BACK, false);
            ObjectSetText(highTimeFrameLabelDirection, highBlshStatus, BlshfontSise, BlshfontName, BuyColour);
         }//if (ObjectFind(highestTimeFrameLabelDirection) < 0)
         
         DisplayCount++;     
         
      }//if (UseBlshHighTimeFrame)
      
      if (UseBlshMediumTimeFrame)
      {
         if (ObjectFind(mediumTimeFrameLabelName) < 0)
         {
            ObjectCreate(mediumTimeFrameLabelName, OBJ_LABEL, 0, 0, 0); 
            ObjectSet(mediumTimeFrameLabelName, OBJPROP_CORNER, 0);
            //ObjectSet(mediumTimeFrameLabelName, OBJPROP_XDISTANCE, BlshDisplayX + ofset); 
            ObjectSet(mediumTimeFrameLabelName, OBJPROP_XDISTANCE, BlshDisplayX); 
            ObjectSet(mediumTimeFrameLabelName, OBJPROP_YDISTANCE, BlshDisplayY+DisplayCount*(BlshfontSise+10)); 
            ObjectSet(mediumTimeFrameLabelName, OBJPROP_BACK, false);
            tfDisplay = GetTimeFrameDisplay(BlshMediumTimeFrame);
            ObjectSetText(mediumTimeFrameLabelName, tfDisplay, BlshfontSise, BlshfontName, BlshMediumTimeFrameLineColour);
         }//if (ObjectFind(mediumTimeFrameLabelName) < 0)
         
         
         if (ObjectFind(mediumTimeFrameLabelDirection) < 0)
         {
            ObjectCreate(mediumTimeFrameLabelDirection, OBJ_LABEL, 0, 0, 0); 
            ObjectSet(mediumTimeFrameLabelDirection, OBJPROP_CORNER, 0);
            //ObjectSet(mediumTimeFrameLabelDirection, OBJPROP_XDISTANCE, BlshDisplayX + ofset); 
            ObjectSet(mediumTimeFrameLabelDirection, OBJPROP_XDISTANCE, BlshDisplayX + 50); 
            ObjectSet(mediumTimeFrameLabelDirection, OBJPROP_YDISTANCE, BlshDisplayY+DisplayCount*(BlshfontSise+10)); 
            ObjectSet(mediumTimeFrameLabelDirection, OBJPROP_BACK, false);
            ObjectSetText(mediumTimeFrameLabelDirection, mediumBlshStatus, BlshfontSise, BlshfontName, BuyColour);
         }//if (ObjectFind(mediumestTimeFrameLabelDirection) < 0)
         
         DisplayCount++;     
         
      }//if (UseBlshHighTimeFrame)
      
      if (ObjectFind(tradingTimeFrameLabelName) < 0)
      {
         ObjectCreate(tradingTimeFrameLabelName, OBJ_LABEL, 0, 0, 0); 
         ObjectSet(tradingTimeFrameLabelName, OBJPROP_CORNER, 0);
         //ObjectSet(tradingTimeFrameLabelName, OBJPROP_XDISTANCE, BlshDisplayX + ofset); 
         ObjectSet(tradingTimeFrameLabelName, OBJPROP_XDISTANCE, BlshDisplayX); 
         ObjectSet(tradingTimeFrameLabelName, OBJPROP_YDISTANCE, BlshDisplayY+DisplayCount*(BlshfontSise+10)); 
         ObjectSet(tradingTimeFrameLabelName, OBJPROP_BACK, false);
         tfDisplay = GetTimeFrameDisplay(TradingTimeFrame);
         ObjectSetText(tradingTimeFrameLabelName, tfDisplay, BlshfontSise, BlshfontName, BlshTradingTimeFrameLineColour);
      }//if (ObjectFind(tradingTimeFrameLabelName) < 0)
      
      
      if (ObjectFind(tradingTimeFrameLabelDirection) < 0)
      {
         ObjectCreate(tradingTimeFrameLabelDirection, OBJ_LABEL, 0, 0, 0); 
         ObjectSet(tradingTimeFrameLabelDirection, OBJPROP_CORNER, 0);
         //ObjectSet(tradingTimeFrameLabelDirection, OBJPROP_XDISTANCE, BlshDisplayX + ofset); 
         ObjectSet(tradingTimeFrameLabelDirection, OBJPROP_XDISTANCE, BlshDisplayX + 50); 
         ObjectSet(tradingTimeFrameLabelDirection, OBJPROP_YDISTANCE, BlshDisplayY+DisplayCount*(BlshfontSise+10)); 
         ObjectSet(tradingTimeFrameLabelDirection, OBJPROP_BACK, false);
         ObjectSetText(tradingTimeFrameLabelDirection, tradingBlshStatus, BlshfontSise, BlshfontName, BuyColour);
      }//if (ObjectFind(tradingestTimeFrameLabelDirection) < 0)
         
   }//if (UseBuyLowSellHigh)
   
   //Call sq's show trades indi
   //iCustom(NULL, 0, "SQ_showTrades",Magic, 0,0);


}//End void UsualOnInit()

void UsualOnDeinit()
{

   Comment("");
   removeAllObjects();
   removePhlLines();
   removeDaidLines();
   
   // Free/empty the arrays
   ArrayFree(FifoTicket);
   ArrayResize(FifoTicket, 0);
   ArrayFree(GridOrderBuyTickets);
   ArrayResize(GridOrderBuyTickets, 0);
   ArrayFree(GridOrderSellTickets);
   ArrayResize(GridOrderSellTickets, 0);
   ArrayFree(ForceCloseTickets);
   ArrayResize(ForceCloseTickets, 0);
   ArrayFree(BuyCloseTicket);
   ArrayResize(BuyCloseTicket, 0);
   ArrayFree(SellCloseTicket);
   ArrayResize(SellCloseTicket, 0);
   ArrayFree(BuyPrices);
   ArrayResize(BuyPrices, 0);
   ArrayFree(SellPrices);
   ArrayResize(SellPrices, 0);
   ArrayFree(BuyHedgeTickets);
   ArrayResize(BuyHedgeTickets, 0);
   ArrayFree(SellHedgeTickets);
   ArrayResize(SellHedgeTickets, 0);
   

}//End void UsualOnDeinit{}



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

void Display(string text)
{
   string lab_str = "OAM-" + (string)DisplayCount;   
   int ofset = 0;
   string textpart[5];
   for (int cc = 0; cc < 5; cc++) 
   {
      textpart[cc] = StringSubstr(text,cc*63,64);
      if (StringLen(textpart[cc]) ==0) continue;
      ofset = cc * 63 * (int)(fontSise * spacingtweek);
      lab_str = lab_str + (string)cc;
      ObjectCreate(lab_str, OBJ_LABEL, 0, 0, 0); 
      ObjectSet(lab_str, OBJPROP_CORNER, 0);
      ObjectSet(lab_str, OBJPROP_XDISTANCE, DisplayX + ofset); 
      ObjectSet(lab_str, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(fontSise+4)); 
      ObjectSet(lab_str, OBJPROP_BACK, false);
      ObjectSetText(lab_str, textpart[cc], fontSise, fontName, colour);
   }//for (int cc = 0; cc < 5; cc++) 
}

string FormatNumber(double x, int width, int precision)
{
   string p = DoubleToStr(x, precision);   
   while(StringLen(p) < width)
      p = "  " + p;
   return(p);
}//End void Display(string text)

bool ChartForegroundSet(const bool value,const long chart_ID=0)
{
//--- reset the error value
   ResetLastError();
//--- set property value
   if(!ChartSetInteger(chart_ID,CHART_FOREGROUND,0,value))
   {
      //--- display the error message in Experts journal
      Print(__FUNCTION__+", Error Code = ",GetLastError());
      return(false);
   }//if(!ChartSetInteger(chart_ID,CHART_FOREGROUND,0,value))
//--- successful execution
   return(true);
}//End bool ChartForegroundSet(const bool value,const long chart_ID=0)
//+--------------------------------------------------------------------+
//| End of Paul's text display module to replace Comment()             |
//+--------------------------------------------------------------------+


//   ************************* added for OBJ_LABEL
void removeAllObjects()
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
      if (StringFind(ObjectName(i),"OAM-",0) > -1) 
         ObjectDelete(ObjectName(i));
}//End void removeAllObjects()

void removePhlLines()
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
      if (StringFind(ObjectName(i),"phl_",0) > -1) 
         ObjectDelete(ObjectName(i));
}//End void removePhlLines()

void removeDaidLines()
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
      if (StringFind(ObjectName(i),"Diad_",0) > -1) 
         ObjectDelete(ObjectName(i));
}//End void removeDaidLines()

//////////////////////////////////////////////////////////////////////////////////////////////////////
//Price ceiling and floor module. Code generously provided by Elixe. Thanks Elixe

double priceFloor(double price, int pipfloor)
{
   if (pipfloor != 1 && pipfloor != 10 && pipfloor != 100 && pipfloor != 1000 && pipfloor != 10000) return price;
   
   // will handle the 2/4 digits broker if there are still any. Will obviously not work for CFDs as the digits can be "exotic"
   int pipMultiplier = 1;
   if (Digits == 3 || Digits == 5) pipMultiplier = 10;
   
   // Divide te price by point value, resulting in a integer of our price (eg : 1.69532 will return 169532)
   double pricetoInt = price / Point;
   
   // Get the remainder of the division of our pricetoInt by the pipfloor requested (eg : 169532 mod 100 = 32)
   double priceMod = MathMod(pricetoInt, pipfloor*pipMultiplier);

   // substract that remainder of our priceToInt, we get a floored integer (eg : 169500);
   double flooredPriceInt = pricetoInt - priceMod;
   
   // convert back our flooredPriceInt to a usable price (eg: 169500 will return 1.69500)
   double flooredPrice = flooredPriceInt * Point;
   
   return(NormalizeDouble(flooredPrice, Digits));
}

double priceCeiling(double price, int pipfloor)
{
   // not commenting the whole process again
   if (pipfloor != 1 && pipfloor != 10 && pipfloor != 100 && pipfloor != 1000 && pipfloor != 10000) return price;
   
   int pipMultiplier = 1;
   if (Digits == 3 || Digits == 5) pipMultiplier = 10;
   
   double pricetoInt = price / Point;
   double priceMod = MathMod(pricetoInt, pipfloor*pipMultiplier);
   
   // but just this piece, we are adding our pipfloor request to the already floored price, that will return the ceiling :)
   double ceiledPriceInt = (pricetoInt - priceMod) + (pipfloor*pipMultiplier);
   
   double ceiledPrice = ceiledPriceInt * Point;
   
   return(NormalizeDouble(ceiledPrice, Digits));
}

//End price ceiling and floor module
//////////////////////////////////////////////////////////////////////////////////////////////////////

void CalculateLotAsAmountPerCashDollops()
{

   double lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);
   double decimal = 0;
   if (CloseEnough(lotstep, 0.1) )
      decimal = 1;
   if (CloseEnough(lotstep, 0.01) )
      decimal = 2;
      
   double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
   double minlot = MarketInfo(Symbol(), MODE_MINLOT);
   double DoshDollop = AccountInfoDouble(ACCOUNT_BALANCE); 
   
   if (UseEquity)
      DoshDollop = AccountInfoDouble(ACCOUNT_EQUITY); 

   
   //Initial lot size
   Lot = NormalizeDouble((DoshDollop / SizeOfDollop) * LotsPerDollopOfCash, (int)decimal);
     
   //Min/max size check
   if (Lot > maxlot)
      Lot = maxlot;
      
   if (Lot < minlot)
      Lot = minlot;      


}//void CalculateLotAsAmountPerCashDollops()

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

bool SendSingleTrade(string symbol, int type, string comment, double lotsize, double price, double stop, double take)
{
   
   if (type == OP_BUYSTOP && price <= MarketInfo(symbol, MODE_ASK)) //Would cause an invalid stop error
      return(False);
      
   
   double slippage = MaxSlippagePips * MathPow(10, Digits) / factor;
   int ticket = -1;
   
   color col = Red;
   if (type == OP_BUY || type == OP_BUYSTOP || type == OP_BUYLIMIT) col = Green;
   
   datetime expiry = 0;
   if (OrderType() > 1)
      expiry = TimeCurrent() + (PendingExpiryMinutes * 60);

   //RetryCount is declared as 10 in the Trading variables section at the top of this file
   for (int cc = 0; cc < RetryCount; cc++)
   {
      //for (int d = 0; (d < RetryCount) && IsTradeContextBusy(); d++) Sleep(100);

      RefreshRates();
      if (type == OP_BUY) price = MarketInfo(symbol, MODE_ASK);
      if (type == OP_SELL) price = MarketInfo(symbol, MODE_BID);
      
      while(IsTradeContextBusy()) Sleep(100);//Put here so that excess slippage will cancel the trade if the ea has to wait for some time.
      
      if (!IsGlobalPrimeOrECNCriminal)
         ticket = OrderSend(symbol,type, lotsize, price, (int)slippage, stop, take, comment, MagicNumber, expiry, col);
   
   
      //Is a 2 stage criminal
      if (IsGlobalPrimeOrECNCriminal)
      {
         ticket = OrderSend(symbol, type, lotsize, price, (int)slippage, 0, 0, comment, MagicNumber, expiry, col);
         if (ticket > -1)
         {
	           ModifyOrderTpSl(ticket, stop, take);
         }//if (ticket > 0)}
      }//if (IsGlobalPrimeOrECNCriminal)
      
      if (ticket > -1) break;//Exit the trade send loop
      if (cc == RetryCount - 1) return(false);
   
      //Error trapping for both
      if (ticket < 0)
      {
         string stype;
         if (type == OP_BUY) stype = "OP_BUY";
         if (type == OP_SELL) stype = "OP_SELL";
         if (type == OP_BUYLIMIT) stype = "OP_BUYLIMIT";
         if (type == OP_SELLLIMIT) stype = "OP_SELLLIMIT";
         if (type == OP_BUYSTOP) stype = "OP_BUYSTOP";
         if (type == OP_SELLSTOP) stype = "OP_SELLSTOP";
         int err=GetLastError();
         Alert(symbol, " ", WindowExpertName(), " ", stype," order send failed with error(",err,"): ",ErrorDescription(err), 
               " Bid = ", DoubleToStr(Bid, Digits), ": Price = ", DoubleToStr(price, Digits));
         Print(symbol, " ", WindowExpertName(), " ", stype," order send failed with error(",err,"): ",ErrorDescription(err),
               " Bid = ", DoubleToStr(Bid, Digits), ": Price = ", DoubleToStr(price, Digits));
         return(false);
      }//if (ticket < 0)  
   }//for (int cc = 0; cc < RetryCount; cc++);
   
   
   TicketNo = ticket;
   //Make sure the trade has appeared in the platform's history to avoid duplicate trades.
   //My mod of Matt's code attempts to overcome the bastard crim's attempts to overcome Matt's code.
   bool TradeReturnedFromCriminal = false;
   while (!TradeReturnedFromCriminal)
   {
      TradeReturnedFromCriminal = O_R_CheckForHistory(ticket);
      if (!TradeReturnedFromCriminal)
      {
         Alert(Symbol(), " sent trade not in your trade history yet. Turn of this ea NOW.");
      }//if (!TradeReturnedFromCriminal)
   }//while (!TradeReturnedFromCriminal)
   
   //Got this far, so trade send succeeded
   return(true);
   
}//End bool SendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)

void ModifyOrderTpSl(int ticket, double stop, double take)
{
   //Modifies an order already sent if the crim is ECN.

   if (CloseEnough(stop, 0) && CloseEnough(take, 0) ) return; //nothing to do

   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET) ) return;//Trade does not exist, so no mod needed
   
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   
   //In case some errant behaviour/code creates a tp the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && take < OrderOpenPrice() && !CloseEnough(take, 0) ) 
   {
      take = 0;
      ReportError(" ModifyOrder()", " take profit < market ");
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   {
      take = 0;
      ReportError(" ModifyOrder()", " take profit < market ");
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   //In case some errant behaviour/code creates a sl the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && stop > OrderOpenPrice() ) 
   {
      stop = 0;
      ReportError(" ModifyOrder()", " stop loss > market ");
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && stop < OrderOpenPrice()  && !CloseEnough(stop, 0) ) 
   {
      stop = 0;
      ReportError(" ModifyOrder()", " stop loss < market ");
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   string Reason;
   //RetryCount is declared as 10 in the Trading variables section at the top of this file   
   for (int cc = 0; cc < RetryCount; cc++)
   {
      for (int d = 0; (d < RetryCount) && IsTradeContextBusy(); d++) Sleep(100);
        if (!CloseEnough(take, 0) && !CloseEnough(stop, 0) )
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (ModifyOrder(ticket, OrderOpenPrice(), stop, take, OrderExpiration(), clrNONE, __FUNCTION__, tpsl)) return;
        }//if (take > 0 && stop > 0)
   
        if (!CloseEnough(take, 0) && CloseEnough(stop, 0))
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (ModifyOrder(ticket, OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, tpm)) return;
        }//if (take == 0 && stop != 0)

        if (CloseEnough(take, 0) && !CloseEnough(stop, 0))
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (ModifyOrder(ticket, OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm)) return;
        }//if (take == 0 && stop != 0)
   }//for (int cc = 0; cc < RetryCount; cc++)
   
   
   
}//void ModifyOrderTpSl(int ticket, double tp, double sl)

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
         if(BetterOrderSelect(c,SELECT_BY_POS,MODE_TRADES)==true) 
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
            if(BetterOrderSelect(c,SELECT_BY_POS,MODE_HISTORY)==true) 
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
         Print("Did not find #"+(string)ticket+" in history, sleeping, then doing retry #"+(string)cnt);
         O_R_Sleep(O_R_Setting_sleep_time,O_R_Setting_sleep_max);
        }
     }
// Select back the prior ticket num in case caller was using it.
   if(lastTicket>=0) 
     {
      bool s = BetterOrderSelect(lastTicket,SELECT_BY_TICKET,MODE_TRADES);
     }
   if(!success) 
     {
      Print("Never found #"+(string)ticket+" in history! crap!");
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
   int ms = (int)(t*1000);
   if (ms < 10) {
      ms=10;
   }//if (ms < 10) {
   
   Sleep(ms);
}//End void O_R_Sleep(double mean_time, double max_time)


////////////////////////////////////////////////////////////////////////////////////////


bool IsTradingAllowed()
{
   //Returns false if any of the filters should cancel trading, else returns true to allow trading
   
      
   //Maximum spread
   if (!IsTesting() )
   {
      double spread = (Ask - Bid) * factor;
      if (spread > AverageSpread * MultiplierToDetectStopHunt) return(false);
   }//if (!IsTesting() )
   
   if (!IsTradeAllowed())
      return(false);

    
   //An individual currency can only be traded twice, so check for this
   CanTradeThisPair = true;
   if (OnlyTradeCurrencyTwice && OpenTrades == 0)
   {
      IsThisPairTradable();      
   }//if (OnlyTradeCurrencyTwice)
   if (!CanTradeThisPair) return(false);
   
   //Swap filter
   if (OpenTrades == 0) TradeDirectionBySwap();
   
   //Order close time safety feature
   if (TooClose()) return(false);

   return(true);


}//End bool IsTradingAllowed()

////////////////////////////////////////////////////////////////////////////////////////
//Balance/swap filters module
void TradeDirectionBySwap()
{

   //Sets TradeLong & TradeShort according to the positive/negative swap it attracts

   //Swap is read in init() and start()


   if (CadPairsPositiveOnly)
   {
      if (StringSubstrOld(Symbol(), 0, 3) == "CAD" || StringSubstrOld(Symbol(), 0, 3) == "cad" || StringSubstrOld(Symbol(), 3, 3) == "CAD" || StringSubstrOld(Symbol(), 3, 3) == "cad" )      
      {
         if (LongSwap > 0) TradeLong = true;
         else TradeLong = false;
         if (ShortSwap > 0) TradeShort = true;
         else TradeShort = false;         
      }//if (StringSubstrOld()      
   }//if (CadPairsPositiveOnly)
   
   if (AudPairsPositiveOnly)
   {
      if (StringSubstrOld(Symbol(), 0, 3) == "AUD" || StringSubstrOld(Symbol(), 0, 3) == "aud" || StringSubstrOld(Symbol(), 3, 3) == "AUD" || StringSubstrOld(Symbol(), 3, 3) == "aud" )      
      {
         if (LongSwap > 0) TradeLong = true;
         else TradeLong = false;
         if (ShortSwap > 0) TradeShort = true;
         else TradeShort = false;         
      }//if (StringSubstrOld()      
   }//if (AudPairsPositiveOnly)
   
   
   if (NzdPairsPositiveOnly)
   {
      if (StringSubstrOld(Symbol(), 0, 3) == "NZD" || StringSubstrOld(Symbol(), 0, 3) == "nzd" || StringSubstrOld(Symbol(), 3, 3) == "NZD" || StringSubstrOld(Symbol(), 3, 3) == "nzd" )      
      {
         if (LongSwap > 0) TradeLong = true;
         else TradeLong = false;
         if (ShortSwap > 0) TradeShort = true;
         else TradeShort = false;         
      }//if (StringSubstrOld()      
   }//if (AudPairsPositiveOnly)
   
   //OnlyTradePositiveSwap filter
   if (OnlyTradePositiveSwap)
   {
      if (LongSwap < 0) TradeLong = false;
      if (ShortSwap < 0) TradeShort = false;      
   }//if (OnlyTradePositiveSwap)
   

}//void TradeDirectionBySwap()

bool IsThisPairTradable()
{
   //Checks to see if either of the currencies in the pair is already being traded twice.
   //If not, then return true to show that the pair can be traded, else return false
   
   string c1 = StringSubstrOld(Symbol(), 0, 3);//First currency in the pair
   string c2 = StringSubstrOld(Symbol(), 3, 3);//Second currency in the pair
   int c1open = 0, c2open = 0;
   CanTradeThisPair = true;
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      int index = StringFind(OrderSymbol(), c1);
      if (index > -1)
      {
         c1open++;         
      }//if (index > -1)
   
      index = StringFind(OrderSymbol(), c2);
      if (index > -1)
      {
         c2open++;         
      }//if (index > -1)
   
      if (c1open == 1 && c2open == 1) 
      {
         CanTradeThisPair = false;
         return(false);   
      }//if (c1open == 1 && c2open == 1) 
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

   //Got this far, so ok to trade
   return(true);
   
}//End bool IsThisPairTradable()

bool BalancedPair(int type)
{

   //Only allow an individual currency to trade if it is a balanced trade
   //e.g. UJ Buy open, so only allow Sell xxxJPY.
   //The passed parameter is the proposed trade, so an existing one must balance that

   //This code courtesy of Zeljko (zkucera) who has my grateful appreciation.
   
   string BuyCcy1, SellCcy1, BuyCcy2, SellCcy2;

   if (type == OP_BUY || type == OP_BUYSTOP)
   {
      BuyCcy1 = StringSubstrOld(Symbol(), 0, 3);
      SellCcy1 = StringSubstrOld(Symbol(), 3, 3);
   }//if (type == OP_BUY || type == OP_BUYSTOP)
   else
   {
      BuyCcy1 = StringSubstrOld(Symbol(), 3, 3);
      SellCcy1 = StringSubstrOld(Symbol(), 0, 3);
   }//else

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS)) continue;
      if (OrderSymbol() == Symbol()) continue;
      if (OrderMagicNumber() != MagicNumber) continue;      
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP)
      {
         BuyCcy2 = StringSubstrOld(OrderSymbol(), 0, 3);
         SellCcy2 = StringSubstrOld(OrderSymbol(), 3, 3);
      }//if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP)
      else
      {
         BuyCcy2 = StringSubstrOld(OrderSymbol(), 3, 3);
         SellCcy2 = StringSubstrOld(OrderSymbol(), 0, 3);
      }//else
      if (BuyCcy1 == BuyCcy2 || SellCcy1 == SellCcy2) return(false);
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

   //Got this far, so it is ok to send the trade
   return(true);

}//End bool BalancedPair(int type)



//End Balance/swap filters module
////////////////////////////////////////////////////////////////////////////////////////
double CalculateLotSize(double price1, double price2)
{
   //Calculate the lot size by risk. Code kindly supplied by jmw1970. Nice one jmw.
   
   if (price1 == 0 || price2 == 0) return(Lot);//Just in case
   
   double FreeMargin = AccountFreeMargin();
   double TickValue = MarketInfo(Symbol(),MODE_TICKVALUE) ;
   double LotStep = MarketInfo(Symbol(),MODE_LOTSTEP);


   double SLPts = MathAbs(price1 - price2);
   //SLPts/= Point;//No idea why *= factor does not work here, but it doesn't
   SLPts = int(SLPts * factor * 10);//Code from Radar. Thanks Radar; much appreciated
   
   double Exposure = SLPts * TickValue; // Exposure based on 1 full lot

   double AllowedExposure = (FreeMargin * RiskPercent) / 100;
   
   int TotalSteps = (int)((AllowedExposure / Exposure) / LotStep);
   double LotSize = TotalSteps * LotStep;

   double MinLots = MarketInfo(Symbol(), MODE_MINLOT);
   double MaxLots = MarketInfo(Symbol(), MODE_MAXLOT);
   
   if (LotSize < MinLots) LotSize = MinLots;
   if (LotSize > MaxLots) LotSize = MaxLots;
   return(LotSize);

}//double CalculateLotSize(double price1, double price1)

double CalculateStopLoss(int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double stop=0;

   
   //RefreshRates();
   //double StopLevel=MarketInfo(Symbol(),MODE_STOPLEVEL)+MarketInfo(Symbol(),MODE_SPREAD);
   //double spread=(Ask-Bid)*factor;
   
   if (type == OP_BUY)
   {
      if (!CloseEnough(StopLoss, 0) ) 
      {
         
         //if(StopLoss<StopLevel)
         //   if(StopLossPips>0)
         //      StopLoss=StopLevel;
         stop = price - (StopLoss / factor);
         HiddenStopLoss = stop;
      }//if (!CloseEnough(StopLoss, 0) ) 

      if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop - (HiddenPips / factor), Digits);
   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(StopLoss, 0) ) 
      {
         
         //if(StopLoss<StopLevel)
         //   if(StopLossPips>0)
         //      StopLoss=StopLevel;
         stop = price + (StopLoss / factor);
         HiddenStopLoss = stop;         
      }//if (!CloseEnough(StopLoss, 0) ) 
      
      if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop + (HiddenPips / factor), Digits);

   }//if (type == OP_SELL)
   
   return(stop);
   
}//End double CalculateStopLoss(int type)

double CalculateTakeProfit(int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double take=0;

   
   //RefreshRates();
   //double StopLevel=MarketInfo(Symbol(),MODE_STOPLEVEL)+MarketInfo(Symbol(),MODE_SPREAD);
   //double spread=(Ask-Bid)*factor;
   
   if (type == OP_BUY)
   {
      if (!CloseEnough(TakeProfit, 0) )
      {
         
         //if(TakeProfit<StopLevel)
         //   if(TakeProfitPips>0)
         //      TakeProfit=StopLevel;
         take = price + (TakeProfit / factor);
         HiddenTakeProfit = take;
      }//if (!CloseEnough(TakeProfit, 0) )

               
      if (HiddenPips > 0 && !CloseEnough(take, 0) ) take = NormalizeDouble(take + (HiddenPips / factor), Digits);

   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(TakeProfit, 0) )
      {
         
         //if(TakeProfit<StopLevel)
         //   if(TakeProfitPips>0)
         //      TakeProfit=StopLevel;
         take = price - (TakeProfit / factor);
         HiddenTakeProfit = take;         
      }//if (!CloseEnough(TakeProfit, 0) )
      
      
      if (HiddenPips > 0 && !CloseEnough(take, 0) ) take = NormalizeDouble(take - (HiddenPips / factor), Digits);

   }//if (type == OP_SELL)
   
   return(take);
   
}//End double CalculateTakeProfit(int type)

void LookForTradingOpportunities()
{
   RefreshRates();
   double take=0, stop=0, price=0;
   int type=0;
   string stype;//For the alert
   bool SendTrade = false, result = false;

   double SendLots = Lot;
   //Check filters
   if (!IsTradingAllowed() ) return;
   
   
   /////////////////////////////////////////////////////////////////////////////////////
   
   //Trading decision.
   bool SendLong = false, SendShort = false;

   //Long trade
   
   //Specific system filters
   if (BuySignal) 
      SendLong = true;
   
   //Usual filters
   if (SendLong)
   {
      //User choice of trade direction
      if (!TradeLong) return;

      
      //CSS.         
      if (UseCSS)
      {
         //We are buying the first in the pair ans selling the second, so ensure they are moving in the correct direction and on the right side of 0
         if (CurrDirection1 == downaccelerating || CurrDirection1 == downdecelerating) return;
         if (CurrDirection2 == upaccelerating || CurrDirection2 == updecelerating) return;
      }//if (UseCSS)
      
      //Other filters
       if (UseZeljko && !BalancedPair(OP_BUY) ) return;
      
      //Change of market state - explanation at the end of start()
      //if (OldAsk <= some_condition) SendLong = false;   
   }//if (SendLong)
   
   /////////////////////////////////////////////////////////////////////////////////////

   if (!SendLong)
   {
      //Short trade
      //Specific system filters
      if (SellSignal) 
         SendShort = true;
      
      if (SendShort)
      {      
         //Usual filters

         //User choice of trade direction
         if (!TradeShort) return;

         //Other filters
         
         
         //CSS.         
         if (UseCSS)
         {
            //We are selling the first in the pair ans buying the second, so ensure they are moving in the correct direction and on the right side of 0        
            if (CurrDirection1 == upaccelerating || CurrDirection1 == updecelerating) return;
            if (CurrDirection2 == downaccelerating || CurrDirection2 == downdecelerating) return;
         }//if (UseCSS)

         //Slope must be in the sell area
         if (UseZeljko && !BalancedPair(OP_SELL) ) return;
         
         //Change of market state - explanation at the end of start()
         //if (OldBid += some_condition) SendShort = false;   
      }//if (SendShort)
      
   }//if (!SendLong)
     

////////////////////////////////////////////////////////////////////////////////////////
   
   
   //Long 
   if (SendLong)
   {
       
      type=OP_BUY;
      stype = " Buy ";
      price = Ask;//Change this to whatever the price needs to be
      
      
         
      if (!SendAlertNotTrade)
      {
         
         stop = CalculateStopLoss(OP_BUY, price);
         
         
         take = CalculateTakeProfit(OP_BUY, price);
         
         
         //Lot size calculated by risk
         if (RiskPercent > 0) SendLots = CalculateLotSize(price, NormalizeDouble(stop + (HiddenPips / factor), Digits) );

               
      }//if (!SendAlertNotTrade)
      
      SendTrade = true;
      
   }//if (SendLong)
   
   //Short
   if (SendShort)
   {
      
      type=OP_SELL;
      stype = " Sell ";
      price = Bid;//Change this to whatever the price needs to be
      
      

      if (!SendAlertNotTrade)
      {
         
         stop = CalculateStopLoss(OP_SELL, price);
         
         take = CalculateTakeProfit(OP_SELL, price);
         
         
         //Lot size calculated by risk
         if (RiskPercent > 0) SendLots = CalculateLotSize(price, NormalizeDouble(stop - (HiddenPips / factor), Digits) );

         
      }//if (!SendAlertNotTrade)
         
      SendTrade = true;      
   
      
   }//if (SendShort)
   

   if (SendTrade)
   {
      if (!SendAlertNotTrade) 
      { 
         if (ImmediateMarketOrders)
         {
            result = SendSingleTrade(Symbol(), type, TradeComment, SendLots, price, stop, take);
            //The latest garbage from the morons at Crapperquotes appears to occasionally break Matt's OR code, so tell the
            //ea not to trade for a while, to give time for the trade receipt to return from the server.
            TimeToStartTrading = TimeCurrent() + PostTradeAttemptWaitSeconds;
            if (result) 
            {
               if (EmailTradeNotification) SendMail("Trade sent", Symbol() + " @ " + DoubleToStr(Ask, Digits) + " - " + stype + " trade at " + TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
               if (AlertPush) AlertNow(WindowExpertName() + " " + Symbol() + " " + stype + " " + DoubleToStr(price, Digits) );
               bool s = BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES);
               CheckTpSlAreCorrect(type);
              if (TakeSnapshots)
               {
                  DisplayUserFeedback();
                  TakeChartSnapshot(TicketNo, " open");
               }//if (TakeSnapshots)
            }//if (result) 
            if (!result)
            {
               OldBarsTime = 0;//Force a retry on the next tick
               TimeToStartTrading = 0;
               return;
            }//if (!result)
         }//if (ImmediateMarketOrders)
         
         //Are we grid trading?
         if (UseGrid)
         {
            if (type == OP_BUY)
            {
               SendBuyGrid(Symbol(), OP_BUYSTOP, NormalizeDouble(Ask + (DistanceBetweenTrades / factor), Digits), Lot);
               if (UseHedgingWithGrid)
                  SendSellGrid(Symbol(), OP_SELLSTOP, NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits), Lot);  
            }//if (type == OP_BUY)
            
            if (type == OP_SELL)
            {
               SendSellGrid(Symbol(), OP_SELLSTOP, NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits), Lot);    
               if (UseHedgingWithGrid)
                  SendBuyGrid(Symbol(), OP_BUYSTOP, NormalizeDouble(Ask + (DistanceBetweenTrades / factor), Digits), Lot);           
            }//if (type == OP_SELL)
            
         }//if (UseGrid)
           
      }//if (!SendAlertNotTrade) 
      
      if (SendAlertNotTrade && !AlertSent)
      {
         Alert(WindowExpertName(), " ", Symbol(), " ", stype, "trade has triggered. ",  TimeToStr(TimeLocal(), TIME_DATE|TIME_MINUTES|TIME_SECONDS) );
         SendMail("Trade Alert", Symbol() + " @ " + DoubleToStr(Ask, Digits) + " - " + stype + " trade has triggered. " + TimeToStr(TimeLocal(), TIME_DATE|TIME_MINUTES|TIME_SECONDS ));
         if (AlertPush) AlertNow(WindowExpertName() + " " + Symbol() + " " + stype + " " + DoubleToStr(price, Digits) );         
         AlertSent=true;
       }//if (SendAlertNotTrade && !AlertSent)
   }//if (SendTrade)
   
   //Actions when trade send succeeds
   if (SendTrade && result)
   {      
      if (!SendAlertNotTrade && !CloseEnough(HiddenPips, 0) ) ReplaceMissingSlTpLines();
   }//if (result)
   
   //Actions when trade send fails
   if (SendTrade && !result)
   {
      OldBarsTime = 0;
   }//if (!result)
   
   
   

}//void LookForTradingOpportunities()

void AlertNow(string sAlertMsg) 
{
  
  if (AlertPush) 
  {
    if ( IsTesting() ) Print("Message to Push: ", TimeToStr(Time[0],TIME_DATE|TIME_SECONDS )+" "+sAlertMsg );
    SendNotification( StringConcatenate(TimeToStr(Time[0],TIME_DATE|TIME_SECONDS )," "+sAlertMsg));
  }//if (AlertPush) 
  return;
}//End void AlertNow(string sAlertMsg) 

bool CloseOrder(int ticket)
{   
   
   while(!MarketInfo(Symbol(),MODE_TRADEALLOWED)) Sleep(5000); //Market is closed

   while(IsTradeContextBusy()) Sleep(100);
   bool orderselect=BetterOrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if (!orderselect) return(false);
   
   bool result =true;
   
   //Market trades
   if (OrderType() < 2)
   {
      result = OrderClose(ticket, OrderLots(), OrderClosePrice(), 1000, clrBlue);
   
      //Actions when trade send succeeds
      if (result)
      {
         if (TakeSnapshots)
         {
            DisplayUserFeedback();
            TakeChartSnapshot(TicketNo, " close");
         }//if (TakeSnapshots)
         
         return(true);
      }//if (result)
   }//if (OrderType() < 2)
   
   //Pending orders
   if (OrderType() > 1)
   {
      result = OrderDelete(ticket);
      if (result)
         return(true);
   }//if (OrderType() > 1)
   
    
   //Actions when trade send fails
   if (!result)
   {
      if (OrderType() < 2)
         ReportError(__FUNCTION__, ocm);
      if (OrderType() > 1)
         ReportError(__FUNCTION__, odm);
         
      return(false);
   }//if (!result)
   
   return(0);
}//End bool CloseOrder(ticket)

////////////////////////////////////////////////////////////////////////////////////////
//Indicator module


void CheckForSpreadWidening()
{
   if(CloseEnough(AverageSpread, 0)) return;
   //Detect a dramatic widening of the spread and pause the ea until this passes
   double TargetSpread=AverageSpread*MultiplierToDetectStopHunt;
   
   if(ShortAverageSpread>=TargetSpread)
     {
      Print("Spread Event Started. ShortAverageSpread:",ShortAverageSpread,", AverageSpread:",AverageSpread,", TargetSpread:",TargetSpread);
      if(OpenTrades==0) Comment(Gap+"PAUSED DURING A MASSIVE SPREAD EVENT");
      if(OpenTrades>0) Comment(Gap+"PAUSED DURING A MASSIVE SPREAD EVENT. STILL MONITORING TRADES.");
      
      while(ShortAverageSpread>=TargetSpread)
        {
         if(DeletePendingsDuringWideSpread)
           {
            if(BuyStopOpen)
               CloseAllTrades(OP_BUYSTOP);

            if(SellStopOpen)
               CloseAllTrades(OP_SELLSTOP);

           }//if (DeletePendingsDuringWideSpread)

         RefreshRates();
         double spread=(Ask-Bid)*factor;

         static double ShortSpreadTotal=0;
         static int ShortCounter=0;
      
         if (NormalizeDouble(spread,1)>0)
           {
            ShortSpreadTotal+=spread;
            ShortCounter++;
           }
        
         if(ShortCounter>=TicksToCount)
           {
            ShortAverageSpread=NormalizeDouble(ShortSpreadTotal/ShortCounter,1);
            ShortSpreadTotal=0;
            ShortCounter=0;
           }//if(ShortCounter>=TicksToCount)
        
         //Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Detect a closed trade and check that is was not a rogue.
         if(OldOpenTrades!=OpenTrades)
           {
            if(IsClosedTradeRogue())
              {
               RobotSuspended=true;
               return;
              }//if (IsClosedTradeRogue() )      
           }//if (OldOpenTrades != OpenTrades)

         if(ForceTradeClosure) return;//Emergency measure to force a retry at the next tick

         OldOpenTrades=OpenTrades;

         Sleep(1000);

        }//while (spread >= TargetSpread)      

      Print("Spread Event Ended. ShortAverageSpread:",ShortAverageSpread,", AverageSpread:",AverageSpread,", TargetSpread:",TargetSpread);
      Comment("");

      //Replace pendings
      if(UseGrid)
        {
         CountOpenTrades();
         RefreshRates();
         
         //Hedged position
         if(Hedged)
           {
            SendBuyGrid(Symbol(),OP_BUYSTOP,NormalizeDouble(Ask+(DistanceBetweenTrades/factor),Digits),Lot);
            SendSellGrid(Symbol(),OP_SELLSTOP,NormalizeDouble(Bid-(DistanceBetweenTrades/factor),Digits),Lot);
            return;
           }//if (Hedged)

         //Non-hedged
         if(BuyOpen)
           {
            SendBuyGrid(Symbol(),OP_BUYSTOP,NormalizeDouble(Ask+(DistanceBetweenTrades/factor),Digits),Lot);
            if(UseHedgingWithGrid)
               SendSellGrid(Symbol(),OP_SELLSTOP,NormalizeDouble(Bid-(DistanceBetweenTrades/factor),Digits),Lot);
            return;
           }//if (BuyOpen)

         if(SellOpen)
           {
            SendSellGrid(Symbol(),OP_SELLSTOP,NormalizeDouble(Bid -(DistanceBetweenTrades/factor),Digits),Lot);
            if(UseHedgingWithGrid)
               SendBuyGrid(Symbol(),OP_BUYSTOP,NormalizeDouble(Ask+(DistanceBetweenTrades/factor),Digits),Lot);
            return;
           }//if (SellOpen)

        }//if (UseGrid)

     }//if(ShortAverageSpread>=TargetSpread)
     
}//End void CheckForSpreadWidening()

void CalculateDailyResult()
{
   //Calculate the no of winners and losers from today's trading. These are held in the history tab.

   LossTrades = 0;
   WinTrades = 0;
   OverallProfit = 0;
   
   
   for (int cc = 0; cc <= OrdersHistoryTotal(); cc++)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (TimeDayOfWeek(OrderCloseTime()) != TimeDayOfWeek(TimeCurrent()) ) continue;
      if (OrderCloseTime() < iTime(Symbol(), PERIOD_D1, 0) ) continue;
      
      OverallProfit+= (OrderProfit() + OrderSwap() + OrderCommission() );
      if (OrderProfit() > 0) WinTrades++;
      if (OrderProfit() < 0) LossTrades++;
   }//for (int cc = 0; cc <= tot -1; cc++)
   
   

}//End void CalculateDailyResult()

//+------------------------------------------------------------------+
//| GetSlope()                                                       |
//+------------------------------------------------------------------+
double GetSlope(string symbol, int tf, int shift)
{
 double atr = iATR(symbol, tf, 100, shift + 10) / 10;
 double gadblSlope = 0.0;
 if ( atr != 0 )
 {
    double dblTma = calcTma( symbol, tf, shift );
    double dblPrev = calcTma( symbol, tf, shift + 1 );
    gadblSlope = ( dblTma - dblPrev ) / atr;
 }
 
 return ( gadblSlope );

}

//+------------------------------------------------------------------+
//| calcTma()                                                        |
//+------------------------------------------------------------------+
double calcTma( string symbol, int tf,  int shift )
{
 double dblSum  = iClose(symbol, tf, shift) * 21;
 double dblSumw = 21;
 int jnx, knx;
       
 for ( jnx = 1, knx = 20; jnx <= 20; jnx++, knx-- )
 {
    dblSum  += ( knx * iClose(symbol, tf, shift + jnx) );
    dblSumw += knx;

    if ( jnx <= shift )
    {
       dblSum  += ( knx * iClose(symbol, tf, shift - jnx) );
       dblSumw += knx;
    }
 }
 
 return( dblSum / dblSumw );

}

void GetAverageSpread()
{

//   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   removeAllObjects();
//   *************************
 
   static double SpreadTotal = 0;
   AverageSpread = 0;
   
   //Add spread to total and keep track of the ticks
   double Spread = (Ask - Bid) * factor;
   
   
   if (NormalizeDouble(Spread,1)>0)
     {
      SpreadTotal+=Spread;
      CountedTicks++;
     }
     
   //All ticks counted?
   if (CountedTicks >= TicksToCount)
   {
      AverageSpread = NormalizeDouble(SpreadTotal / TicksToCount, 1);
      //Save the average for restarts.
      GlobalVariableSet(SpreadGvName, AverageSpread);
   }//if (CountedTicks >= TicksToCount)
   
   
}//void GetAverageSpread()


void SplitSymbol()
{
   Curr1 = StringSubstrOld(Symbol(), 0, 3);
   Curr2 = StringSubstrOld(Symbol(), 3, 3);
   
   //Calculate the index to pass to CSS
   int cc;
   for (cc = 0; cc < ArraySize(CurrNames); cc++)
   {
      if (Curr1 == CurrNames[cc])
      {
         CurrIndex1 = cc;
         break;
      }//if (Curr1 == CurrNames[cc])
   }//for (cc = 0; cc < ArraySize(CurrNames); cc++)
   
   for (cc = 0; cc < ArraySize(CurrNames); cc++)
   {
      if (Curr2 == CurrNames[cc])
      {
         CurrIndex2 = cc;
         break;
      }//if (Curr1 == CurrNames[cc])
   }//for (cc = 0; cc < ArraySize(CurrNames); cc++)

}//End void SplitSymbol()


double GetCSS(double index, int shift)
{

   // return(iCustom(NULL, 0, "10.5 CSS 4H 1.0.8 modified for automation", autoSymbols, symbolsToWeigh, maxBars, addSundayToMonday, timeFrame, ignoreFuture, index, shift));
   
   // Initialize
   double myCSS[];
   // Call libary
   // Do not care about multiple calls, libCCS caches its values internally
   libCSSgetCSS( myCSS, CssTf, shift, true );
   
   int currencyIndex = (int)NormalizeDouble( index, 0 );
   
   return ( myCSS[currencyIndex] );

}//End double GetCSS(int index, int shift)

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



double GetAtr(string symbol, int tf, int period, int shift)
{
   //Returns the value of atr
   
   return(iATR(symbol, tf, period, shift) );   

}//End double GetAtr()

/*double GetSemaphor(string symbol, int tf, double p1, double p2, double p3, string d1,
                   string d2, string d3, int buffer, int shift)
{

   return(iCustom(symbol, tf, "3 Level", p1, p2, p3, d1, d2, d3, buffer, shift) );

}//double GetSemaphor(string symbol, int tf, double p1, double p2, double p3, string d1
*/
double GetNonLagDot(string symbol, int tf, int nlp, int nll, int nldi, int nlf, int nlc, int nlcb, double nlde, int buffer, int shift)
{

   return(iCustom(symbol, tf, "nonlagdot", nlp, nll, nldi, nlf, nlc, nlcb, nlde, buffer, shift) );

}//End double GetNonLagDot()

string GetPreviousCandleDirection()
{

   double copen = iOpen(Symbol(), TradingTimeFrame, 1);
   double cclose = iClose(Symbol(), TradingTimeFrame, 1);
   
   if (cclose > copen)
      return(up);
      
   if (cclose < copen)
      return(down);
      
   return(flat);   
   
}//string GetPreviousCandleDirection()

double GetChandelier(string symbol, int buffer, int shift)
{

   ChanColour = magenta;
   
   return(iCustom(symbol, TradingTimeFrame, "chandelier-exit", cRange, cShift, cATRPeriod, cATRMultipl, buffer, shift));

}//End void GetChandelierColour(string symbol, int shift)

//Add a Getxxxxxx function here

void ReadUsualIndicatorValues()
{

   int cc;
   
   //Declare a shift for use with indicators.
   int shift = 0;
   if (!EveryTickMode)
   {
      shift = 1;
   }//if (!EveryTickMode)
   
   //Sixths
   if (UseSixths || UseBuyLowSellHigh)
      GetSixths();
   
   
   SIGNAL signal = 0;
   SLOPE  slope  = 0;
  
   //Allow easy experimentation.
   //shift = 2;

   /////////////////////////////////////////////////////////////////////////////////////
   //Declare a datetime variable to force cca reading only at the open of a new candle.
   static datetime OldCcaReadTime = 0;
   //Accommodate every tick mode
   if (EveryTickMode)
      OldCcaReadTime = 0;
   
   //Allow easy experimentation.
   //shift = 2;
   //Close trades on an opposite direction signal
   BuyCloseSignal = false;
   SellCloseSignal = false;
     
   /////////////////////////////////////////////////////////////////////////////////////
   //Read indicators for the system being coded and put them together into a trade signal
   
   //Read ATR if it is being used
   if (UseAtrForGrid || UseAtrForBasketTP)
   {
      static datetime OldGridReadTime = 0;
      if (OldGridReadTime != iTime(Symbol(), GridAtrTimeFrame, 0) )
      {
         OldGridReadTime = iTime(Symbol(), GridAtrTimeFrame, 0);
         AtrVal = GetAtr(Symbol(), GridAtrTimeFrame, GridAtrPeriod, 1);
         AtrVal*= factor;
      
         //ATR for grid size
         if (UseAtrForGrid)
         {         
            GridAtrVal = AtrVal;
            GridAtrVal = NormalizeDouble(GridAtrVal * GridAtrMultiplier, 0);
            DistanceBetweenTrades = NormalizeDouble(GridAtrVal / GridSize, 0);
            if (DistanceBetweenTrades < MinimumDistanceBetweenTradesPips)
               DistanceBetweenTrades = MinimumDistanceBetweenTradesPips;//Minimum pips distancer
         }//if (UseAtrForGrid)
         
         //ATR for basket tp
         if (UseAtrForBasketTP)
         {
            BasketTakeProfit = AtrVal * (TpPercentOfAtrToUse / 100);
         }//if (UseAtrForBasketTP)

         
      }//if (OldGridReadTime != iTime(Symbol(), GridAtrTimeFrame, 0) )         
      
   }//if (UseAtrForGrid || UseAtrForBasketTP || UseAtrForBasketSL)

   
      //Chandelier exit
      if (UseChandelierExit)
      {
         static datetime OldM1ChanTime = 0;
         if (OldM1ChanTime != iTime(Symbol(), PERIOD_M1, 0))
         {
            OldM1ChanTime = iTime(Symbol(), PERIOD_M1, 0);
            
            ChanVal = EMPTY_VALUE;
            
            ChanColour = blank;//Default, because the indi can leave a gap
            //Buffer 0 holds orange
            ChanVal = GetChandelier(Symbol(), 0, 0);
            if (!CloseEnough(ChanVal, EMPTY_VALUE))
               ChanColour = orange;
            
            //Buffer 1 holds magenta
            ChanVal = GetChandelier(Symbol(), 1, 0);
            if (!CloseEnough(ChanVal, EMPTY_VALUE))
               ChanColour = magenta;
            
            //Repeat the process for shift 1 if the cca has left a blank space
            if (ChanColour == blank)
            {
                //Buffer 0 holds orange
               ChanVal = GetChandelier(Symbol(), 0, 1);
               if (!CloseEnough(ChanVal, EMPTY_VALUE))
                  ChanColour = orange;
               
               //Buffer 1 holds magenta
               ChanVal = GetChandelier(Symbol(), 1, 1);
               if (!CloseEnough(ChanVal, EMPTY_VALUE))
                  ChanColour = magenta;
            }//if (ChanColour == blank)
            
            if (ChanColour == magenta)
               BuyCloseSignal = true;
               
            if (ChanColour == orange)
               SellCloseSignal = true;
               
               
         }//if (OldM1ChanTime != iTime(Symbol(), PERIOD_M1, 0))
          
      }//if (UseChandelierExit)

   
   //Get the trading direction. We aare looking for large trend arrows
   //and blue wavy lines.
   if (UseTrendHGI)
   {
      static datetime OldHtfHgiTime = 0;
      if (OldHtfHgiTime != iTime(Symbol(), HgiTrendTimeFrame, 0) )
      {
          
         OldHtfHgiTime = iTime(Symbol(), HgiTrendTimeFrame, 0);
         HgiTrendTimeFrameStatus = hginotrend;
         HgiLongTrendDetected =  false;
         HgiShortTrendDetected = false;
         HgiTrendTimeFrameCandlesBack = 0;
         
         for (cc = 1; cc <= HgiTrendTimeFrameCandlesLookBack; cc++)
         {
   
            //The HGI library functionality was added by tomele. Many thanks Thomas.
            signal = getHGISignal(Symbol(), HgiTrendTimeFrame, cc);//This library function looks for arrows.
            slope  = getHGISlope (Symbol(), HgiTrendTimeFrame, cc);//This library function looks for wavy lines.
            
            if (signal==TRENDUP)
            {
               HgiTrendTimeFrameStatus = Trenduparrow;
               HgiTrendTimeFrameCandlesBack = cc;//For chart display
               HgiLongTrendDetected = true;
               break;
            }
            else 
            if (signal==TRENDDN)
            {
               HgiTrendTimeFrameStatus = Trenddownarrow;
               HgiTrendTimeFrameCandlesBack = cc;//For chart display
               HgiShortTrendDetected = true;
               break;
            }
            else 
            if (slope==TRENDBELOW)
            {
               HgiTrendTimeFrameStatus = Wavebuytrend;
               HgiTrendTimeFrameCandlesBack = cc;//For chart display
               HgiLongTrendDetected = true;
               break;
            }
            else 
            if (slope==TRENDABOVE)
            {
               HgiTrendTimeFrameStatus = Waveselltrend;   
               HgiTrendTimeFrameCandlesBack = cc;//For chart display
               HgiShortTrendDetected = true;
               break;
            }
            else 
            if (slope==RANGEBELOW || slope==RANGEABOVE)
            {
               HgiTrendTimeFrameStatus = Waverange;
               HgiTrendTimeFrameCandlesBack = cc;//For chart display
               break;
            }
            
         }//for (cc = 1; cc < iBars(Symbol(), HgiTrendTimeFrame); cc++)
         
         //Has the trend direction changed
         NewLongTrendDetected=false;
         NewShortTrendDetected=false;
         if (HgiLongTrendDetected && !OldLongTrendDetected)
            NewLongTrendDetected=true;
         else if (HgiShortTrendDetected && !OldShortTrendDetected)
            NewShortTrendDetected=true;
   
         //Store the actual state
         OldLongTrendDetected=HgiLongTrendDetected;
         OldShortTrendDetected=HgiShortTrendDetected;
         
         //Save the state of old trend to cater for a restart
         if (OldLongTrendDetected)
         {
            GlobalVariableSet(TrendGvName, longtrend);
         }//if (OldLongTrendDetected)
         else
         if (OldShortTrendDetected)
         {
            GlobalVariableSet(TrendGvName, shorttrend);
         }//if (OldShortTrendDetected)
         else
         {
            GlobalVariableSet(TrendGvName, notrend);
         }//else
         
         
         
      }//if (OldHtfHgiTime != iTime(Symbol(), HgiTrendTimeFrame, 0) )
      
   }//if (UseTrendHGI)
         
   
   if (OldCcaReadTime != iTime(Symbol(), TradingTimeFrame, 0) )
   {
      OldCcaReadTime = iTime(Symbol(), TradingTimeFrame, 0);
    
      ///////////////////////////////////////
      //Indi reading code goes here.

      if (UseTradingTimeFrameHGI)
      {
         if (!UseTrendHGI || HgiTrendTimeFrameStatus != hginotrend)
         {
            HgiLongTradeTrigger = false;
            HgiShortTradeTrigger = false;
            HgiTradingTimeFrameStatus = hginosignal;
            
            signal = getHGISignal(Symbol(), TradingTimeFrame, shift);
            slope  = getHGISlope (Symbol(), TradingTimeFrame, shift);
            
            if (HgiTrendTradingAllowed && signal==TRENDUP)
            {
               HgiLongTradeTrigger = true;
               HgiTradingTimeFrameStatus = Trenduparrow;
            }
            else if (HgiTrendTradingAllowed && signal==TRENDDN)
            {
               HgiShortTradeTrigger = true;
               HgiTradingTimeFrameStatus = Trenddownarrow;
            }
            else if (HgiWaveTradingAllowed && slope==TRENDBELOW)
            {
               HgiLongTradeTrigger = true;
               HgiTradingTimeFrameStatus = Wavebuytrend;
            }
            else if (HgiWaveTradingAllowed && slope==TRENDABOVE)
            {
               HgiShortTradeTrigger = true;
               HgiTradingTimeFrameStatus = Waveselltrend;
            }
            else if (HgiRadTradingAllowed && signal==RADUP)
            {
               HgiLongTradeTrigger = true;
               HgiTradingTimeFrameStatus = Raduparrow;
            }
            else if (HgiRadTradingAllowed && signal==RADDN)
            {
               HgiShortTradeTrigger = true;
               HgiTradingTimeFrameStatus = Raddownarrow;
            }
            
         }//if (!UseTrendHGI || HgiTrendTimeFrameStatus != hginotrend)
         
      }//if (UseTradingTimeFrameHGI)
      
      
      ///////////////////////////////////////
      //Anything else?
      
      
      ///////////////////////////////////////
      
           
      
       
   }//if (OldCcaReadTime != iTime(Symbol(), TradingTimeFrame, 0) )
   
   /////////////////////////////////////////////////////////////////////////////////////
      
   
   
   //CCS
   if (UseCSS)
   {
      static datetime OldCssBarsTime, OldShiftedBarTime;
      int TimeFrame = 1;
      if (EveryTickMode) 
      {

      }//if (EveryTickMode) 
      
      shift=0;
      if (!EveryTickMode) 
      {
         shift = 1;
         TimeFrame = CssTf;
      }//if (!EveryTickMode) 
      
      if (OldCssBarsTime != iTime(NULL, TimeFrame, 0) )
      {
         OldCssBarsTime = iTime(NULL, TimeFrame, 0);
         SplitSymbol();//Split the Symbol into its constituent currencies. Also finds their index for passing to CSS
         CurrVal1[1] = GetCSS(CurrIndex1, shift);
         CurrVal2[1] = GetCSS(CurrIndex2, shift);
         if (OldShiftedBarTime != iTime(NULL, TimeFrame, shift + 1) )
         {
            OldShiftedBarTime = iTime(NULL, TimeFrame, shift + 1);
            CurrVal1[2] = GetCSS(CurrIndex1, shift + 1);
            CurrVal2[2] = GetCSS(CurrIndex2, shift + 1);         
         }//if (OldShiftedBarTime != iTime(NULL, TimeFrame, shift + 1) )         
      
         //Define direction
         //Currency 1
         if (CurrVal1[1] > 0 && CurrVal1[1] > CurrVal1[2])  CurrDirection1 = upaccelerating;
         if (CurrVal1[1] > 0 && CurrVal1[1] <= CurrVal1[2])  CurrDirection1 = updecelerating;
         
         if (CurrVal1[1] < 0 && CurrVal1[1] < CurrVal1[2])  CurrDirection1 = downaccelerating;
         if (CurrVal1[1] < 0 && CurrVal1[1] >= CurrVal1[2])  CurrDirection1 = downdecelerating;
         
         //Currency 2
         if (CurrVal2[1] > 0 && CurrVal2[1] > CurrVal2[2])  CurrDirection2 = upaccelerating;
         if (CurrVal2[1] > 0 && CurrVal2[1] <= CurrVal2[2])  CurrDirection2 = updecelerating;
         
         if (CurrVal2[1] < 0 && CurrVal2[1] < CurrVal2[2])  CurrDirection2 = downaccelerating;
         if (CurrVal2[1] < 0 && CurrVal2[1] >= CurrVal2[2])  CurrDirection2 = downdecelerating;
      
      }//if (OldCssBarsTime != iTime(NULL, PERIOD_M1, 0) )
      
      
   }//if (UseCSS)

      
}//End void ReadUsualIndicatorValues()

//End Indicator module
////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////
//Sixths module

void GetSixths()
{

   //Zoom the chart out as soon as possible
   int scale = ChartScaleGet();
   if (scale != 0)
   {
      ChartScaleSet(0);
      //A quick time frame change to force accurate display
      per = ChartPeriod(0);
      int nextPer = GetNextPeriod(per);
      ChartSetSymbolPeriod(0, Symbol(), nextPer);//Change time frame
      ChartSetSymbolPeriod(0, Symbol(), per);//reset time frame      
   }//if (scale != 0)
   
   
   //Draw the trading time frame
   static datetime oldTradingTimeFrameBarTime = 0;
   if (oldTradingTimeFrameBarTime != iTime(Symbol(), TradingTimeFrame, 0))
   {
      oldTradingTimeFrameBarTime = iTime(Symbol(), TradingTimeFrame, 0);
      DrawPeaks(TradingTimeFrame, blshTradingPeakHighLineName, blshTradingPeakLowLineName, BlshTradingTimeFrameLineColour, BlshTradingTimeFrameLineSize, tradingTimeFrameLabelDirection);
      if (UseSixths)
      {
         //Calculate the distance between ph and pl and divide that by the divisor
         double linesDistance = (blshTradingPeakHigh - blshTradingPeakLow) / ChartDivisor;
         phTradeLine = blshTradingPeakHigh - linesDistance;
         plTradeLine = blshTradingPeakLow + linesDistance;
      }//if (UseSixths)
      
   }//if (oldTradingTimeFrameBarTime != iTime(Symbol(), TradingTimeFrame, 0))
      
   //Draw the medium time frame
   if (UseBlshMediumTimeFrame)
   {
      static datetime oldBlshMediumTimeFrameBarTime = 0;
      if (oldBlshMediumTimeFrameBarTime != iTime(Symbol(), BlshMediumTimeFrame, 0))
      {
         oldBlshMediumTimeFrameBarTime = iTime(Symbol(), BlshMediumTimeFrame, 0);
         DrawPeaks(BlshMediumTimeFrame, blshMediumPeakHighLineName, blshMediumPeakLowLineName, BlshMediumTimeFrameLineColour, BlshMediumTimeFrameLineSize, mediumTimeFrameLabelDirection);
      }//if (oldBlshMediumTimeFrameBarTime != iTime(Symbol(), BlshMediumTimeFrame, 0))
   }//if (UseBlshMediumTimeFrame)
      
   //Draw the high time frame
   if (UseBlshHighTimeFrame)
   {
      static datetime oldBlshHighTimeFrameBarTime = 0;
      if (oldBlshHighTimeFrameBarTime != iTime(Symbol(), BlshHighTimeFrame, 0))
      {
         oldBlshHighTimeFrameBarTime = iTime(Symbol(), BlshHighTimeFrame, 0);
         DrawPeaks(BlshHighTimeFrame, blshHighPeakHighLineName, blshHighPeakLowLineName, BlshHighTimeFrameLineColour, BlshHighTimeFrameLineSize, highTimeFrameLabelDirection);
      }//if (oldBlshHighTimeFrameBarTime != iTime(Symbol(), BlshHighTimeFrame, 0))
   }//if (UseBlshHighTimeFrame)
      
   //Draw the highest time frame
   if (UseBlshHighestTimeFrame)
   {
      static datetime oldBlshHighestTimeFrameBarTime = 0;
      if (oldBlshHighestTimeFrameBarTime != iTime(Symbol(), BlshHighestTimeFrame, 0))
      {
         oldBlshHighestTimeFrameBarTime = iTime(Symbol(), BlshHighestTimeFrame, 0);
         DrawPeaks(BlshHighestTimeFrame, blshHighestPeakHighLineName, blshHighestPeakLowLineName, BlshHighestTimeFrameLineColour, BlshHighestTimeFrameLineSize, highestTimeFrameLabelDirection);
      }//if (oldBlshHighestTimeFrameBarTime != iTime(Symbol(), BlshHighestTimeFrame, 0))
   }//if (UseBlshHighestTimeFrame)
   
   
}//End void GetSixths()



int ChartVisibleBars(const long chart_ID=0) 
{ 
//--- prepare the variable to get the property value 
   long result=-1; 
//--- reset the error value 
   ResetLastError(); 
//--- receive the property value 
   if(!ChartGetInteger(chart_ID,CHART_VISIBLE_BARS,0,result)) 
   { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
   } 
//--- return the value of the chart property 
   return((int)result); 
}//int ChartVisibleBars(const long chart_ID=0) 

//+------------------------------------------------------------------+ 
//| Get chart scale (from 0 to 5).                                   | 
//+------------------------------------------------------------------+ 
int ChartScaleGet(const long chart_ID=0) 
{ 
//--- prepare the variable to get the property value 
   long result=-1; 
//--- reset the error value 
   ResetLastError(); 
//--- receive the property value 
   if(!ChartGetInteger(chart_ID,CHART_SCALE,0,result)) 
   { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
   } 
//--- return the value of the chart property 
   return((int)result); 
}//int ChartScaleGet(const long chart_ID=0) 
 

//+------------------------------------------------------------------+ 
//| Set chart scale (from 0 to 5).                                   | 
//+------------------------------------------------------------------+ 
bool ChartScaleSet(const long value,const long chart_ID=0) 
{ 
//--- reset the error value 
   ResetLastError(); 
//--- set property value 
   if(!ChartSetInteger(chart_ID,CHART_SCALE,0,value)) 
   { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
      return(false); 
   } 
//--- successful execution 
   return(true); 
}//bool ChartScaleSet(const long value,const long chart_ID=0) 


int GetNextPeriod(int currentPeriod)
{
   
   if (currentPeriod == PERIOD_M1)
   {
      return(PERIOD_M5);
   }//if (currentPeriod == PERIOD_M1)
   
   if (currentPeriod == PERIOD_M5)
   {
      return(PERIOD_M15);
   }//if (currentPeriod == PERIOD_M5)
   
   if (currentPeriod == PERIOD_M15)
   {
      return(PERIOD_M30);
   }//if (currentPeriod == PERIOD_M15)
   
   if (currentPeriod == PERIOD_M30)
   {
      return(PERIOD_H1);
   }//if (currentPeriod == PERIOD_M30)
   
   if (currentPeriod == PERIOD_H1)
   {
      return(PERIOD_H4);
   }//if (currentPeriod == PERIOD_H1)
   
   if (currentPeriod == PERIOD_H4)
   {
      return(PERIOD_D1);
   }//if (currentPeriod == PERIOD_H1)
   
   if (currentPeriod == PERIOD_D1)
   {
      return(PERIOD_W1);
   }//if (currentPeriod == PERIOD_D1)
   
   if (currentPeriod == PERIOD_W1)
   {
      return(PERIOD_MN1);
   }//if (currentPeriod == PERIOD_W1)
   
   if (currentPeriod == PERIOD_MN1)
   {
      return(PERIOD_H4);
   }//if (currentPeriod == PERIOD_MN1)
   
   
   
   return(Period());

}//End int GetNextPeriod(int currentPeriod)

//+---------------------------------------------------------------------------+ 
//| The function receives shift size of the zero bar from the right border    | 
//| of the chart in percentage values (from 10% up to 50%).                   | 
//+---------------------------------------------------------------------------+ 
double ChartShiftSizeGet(const long chart_ID=0) 
{ 
//--- prepare the variable to get the result 
   double result=EMPTY_VALUE; 
//--- reset the error value 
   ResetLastError(); 
//--- receive the property value 
   if(!ChartGetDouble(chart_ID,CHART_SHIFT_SIZE,0,result)) 
   { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
   } 
//--- return the value of the chart property 
   return(result); 
}//End double ChartShiftSizeGet(const long chart_ID=0) 

//+--------------------------------------------------------------------------------------+ 
//| The function sets the shift size of the zero bar from the right                      | 
//| border of the chart in percentage values (from 10% up to 50%). To enable the shift   | 
//| mode, CHART_SHIFT property value should be set to                                    | 
//| true.                                                                                | 
//+--------------------------------------------------------------------------------------+ 
bool ChartShiftSizeSet(const double value,const long chart_ID=0) 
{ 
//--- reset the error value 
   ResetLastError(); 
//--- set property value 
   if(!ChartSetDouble(chart_ID,CHART_SHIFT_SIZE,value)) 
   { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
      return(false); 
   } 
//--- successful execution 
   return(true); 
}//End bool ChartShiftSizeSet(const double value,const long chart_ID=0) 


void DrawPeaks(int tf, string hiname, string loname, color col, int size, string labelName)
{

   int top = millions;
   double currentPeakHigh=0, currentPeakLow=0;//PH and PL
   int    currentPeakHighBar=0, currentPeakLowBar=0;//How far back the hilo were found
   string text = "";
   
   //Iterate back through the bars to get the chart hilo
   currentPeakHigh = 0;
   currentPeakLow = 1000000;
   currentPeakHighBar = 0;
   currentPeakLowBar = 0;
   
   
   
   //Starting point for the lines and bar shift for the peaks
   currentPeakHighBar = iHighest(Symbol(), tf, MODE_CLOSE, NoOfBarsOnChart, 1);
   currentPeakLowBar = iLowest(Symbol(), tf, MODE_CLOSE, NoOfBarsOnChart, 1);
   //Read the peak prices
   currentPeakHigh = iClose(Symbol(), tf, currentPeakHighBar);
   currentPeakLow = iClose(Symbol(), tf, currentPeakLowBar);
  
  
   //Adapt them if they are too short to be visible on the chart
   if (currentPeakHighBar < 4)
      currentPeakHighBar = 4;
   if (currentPeakLowBar < 4)
      currentPeakLowBar = 4;
      

   //Calculate the distance between ph and pl and divide that by the divisor
   double linesDistance = (currentPeakHigh - currentPeakLow) / ChartDivisor;
     
   //Draw the lines
   if (currentPeakHighBar > -1)
   {
      DrawTrendLine(hiname, iTime(Symbol(), tf, currentPeakHighBar), currentPeakHigh, iTime(Symbol(), tf, 0), currentPeakHigh, col, size, STYLE_SOLID, false);
      //Adapt the labels
      text = longdirection;
      colour = BuyColour;
      if (currentPeakHighBar < currentPeakLowBar)
      {
         text = shortdirection;
         colour = SellColour;
      }//if (currentPeakHighBar < currentPeakLowBar)
      ObjectSetText(labelName, text, fontSise, fontName, colour);
      
      if (hiname == blshTradingPeakHighLineName)
         if (ShowTradingArea)    
            DrawTrendLine(phTradeLineName, iTime(Symbol(), tf, currentPeakHighBar), currentPeakHigh - linesDistance, Time[0], currentPeakHigh - linesDistance, col, size, STYLE_DOT, false);
   }//if (currentPeakHighBar > 0)
   
   if (currentPeakLowBar < top)
   {
      DrawTrendLine(loname, iTime(Symbol(), tf, currentPeakLowBar), currentPeakLow, Time[0], currentPeakLow, col, size, STYLE_SOLID, false);
      if (loname == blshTradingPeakLowLineName)
         if (ShowTradingArea)    
            DrawTrendLine(plTradeLineName,iTime(Symbol(), tf, currentPeakLowBar), currentPeakLow + linesDistance, iTime(Symbol(), tf, 0), currentPeakLow + linesDistance, col, size, STYLE_DOT, false);
   }//if (currentPeakHighBar > 0)
   
   //The TradingTimeFrame applies to both sixths and blsh
   if (tf == TradingTimeFrame)
   {
      blshTradingPeakHigh = currentPeakHigh;
      blshTradingPeakLow = currentPeakLow;
   }//if (tf == TradingTimeFrame)
   
   //Define the trading direction for use in the trading decision
   if (UseBuyLowSellHigh)
   {
      //Highest tf
      if (tf == BlshHighestTimeFrame)
      {
         blshHighestPeakHigh = currentPeakHigh;
         blshHighestPeakLow = currentPeakLow;
         highestBlshStatus = longdirection;
         if (currentPeakHighBar < currentPeakLowBar)
            highestBlshStatus = shortdirection;
      }//if (tf == BlshHighestTimeFrame)
         
      //High tf
      if (tf == BlshHighTimeFrame)
      {
         blshHighPeakHigh = currentPeakHigh;
         blshHighPeakLow = currentPeakLow;
         highBlshStatus = longdirection;
         if (currentPeakHighBar < currentPeakLowBar)
            highBlshStatus = shortdirection;
      }//if (tf == BlshHighTimeFrame)
         
      //Medium tf
      if (tf == BlshMediumTimeFrame)
      {
         blshMediumPeakHigh = currentPeakHigh;
         blshMediumPeakLow = currentPeakLow;
         mediumBlshStatus = longdirection;
         if (currentPeakHighBar < currentPeakLowBar)
            mediumBlshStatus = shortdirection;
      }//if (tf == BlshMediumTimeFrame)
         
      //Trading tf
      if (tf == TradingTimeFrame)
      {
         tradingBlshStatus = longdirection;
         if (currentPeakHighBar < currentPeakLowBar)
            tradingBlshStatus = shortdirection;
      }//if (tf == TradingTimeFrame)
      
      //Now the combined trading direction.
      
      //Are all the tf's going long?
      combinedBlshStatus = tradablelong;
      if (UseBlshHighestTimeFrame)
         if (highestBlshStatus == shortdirection)
            combinedBlshStatus = untradable;
            
      if (UseBlshHighTimeFrame)
         if (highBlshStatus == shortdirection)
            combinedBlshStatus = untradable;
            
      if (UseBlshMediumTimeFrame)
         if (mediumBlshStatus == shortdirection)
            combinedBlshStatus = untradable;
            
      if (tradingBlshStatus == shortdirection)
         combinedBlshStatus = untradable;
         
      //Nope. So short?
      if (combinedBlshStatus == untradable)
      {
         combinedBlshStatus = tradableshort;
         if (UseBlshHighestTimeFrame)
            if (highestBlshStatus == longdirection)
               combinedBlshStatus = untradable;
               
         if (UseBlshHighTimeFrame)
            if (highBlshStatus == longdirection)
               combinedBlshStatus = untradable;
               
         if (UseBlshMediumTimeFrame)
            if (mediumBlshStatus == longdirection)
               combinedBlshStatus = untradable;
               
         if (tradingBlshStatus == longdirection)
            combinedBlshStatus = untradable;
            
      }//if (combinedBlshStatus == untradable)
            
   }//if (UseBuyLowSellHigh)
   
}//void DrawPeaks(int tf)



//End sixths module
////////////////////////////////////////////////////////////////////////////////////////

bool LookForFullHedgeTradeClosure(int ticket)
{
   //The parameter is the ticket no of a trade identified as a full hedge.
   //Close it if there is an opposite direction signal.

   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET) ) return(true);
   if (BetterOrderSelect(ticket, SELECT_BY_TICKET) && OrderCloseTime() > 0) return(true);
   
   bool CloseThisTrade = false;
   int ClosureType = 0;
   
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   //Change of HGI trend
   if (UseTrendHGI)
   {
      if (OrderType() == OP_BUY)
      {
         //Can we close a hedge trade? We will want to close it if there
         //is an opposite direction Trend signal and it is in profit.
         if (HgiShortTrendDetected || (CloseProfitableFullHedgeOnYellowWave && HgiTrendTimeFrameStatus == Waverange))
            if (!OnlyCloseFullHedgeWhenInProfit || (OrderProfit() + OrderSwap() + OrderCommission()) > 0)
            {
               CloseThisTrade = true;
               ClosedHedgeProfit = (OrderProfit() + OrderSwap() + OrderCommission());
               ClosureType = OP_SELL;//For offsetting opposite direction losers.
            }//if (!OnlyCloseFullHedgeWhenInProfit || (OrderProfit() + OrderSwap() + OrderCommission()) > 0)
            
      }//if (OrderType() == OP_BUY)
      
      
      ///////////////////////////////////////////////////////////////////////////////////////////////////////////
      if (OrderType() == OP_SELL)
      {
         //Can we close a hedge trade? We will want to close it if there
         //is an opposite direction Trend signal and it is in profit.
         if (HgiLongTrendDetected || (CloseProfitableFullHedgeOnYellowWave && HgiTrendTimeFrameStatus == Waverange))
            if (!OnlyCloseFullHedgeWhenInProfit || (OrderProfit() + OrderSwap() + OrderCommission()) > 0)
            {
               CloseThisTrade = true;
               ClosedHedgeProfit = (OrderProfit() + OrderSwap() + OrderCommission());
               ClosureType = OP_BUY;//For offsetting opposite direction losers.
            }//if (!OnlyCloseFullHedgeWhenInProfit || (OrderProfit() + OrderSwap() + OrderCommission()) > 0)
            
      
      }//if (OrderType() == OP_SELL)

   }//if (UseTrendHGI)
   

   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (CloseThisTrade)
   {
      bool result = false;
      
      result = CloseOrder(ticket);
      
            
      //Actions when trade close succeeds
      if (result)
      {
         FullyHedged = false;
         if (OffsetOppositeLosersAgainstProfit)
         {
            CloseOppositeDirectionLosers(ClosureType);
            if (ArraySize(ForceCloseTickets) > 0)//Try again
               MopUpTradeClosureFailures();
            if (ArraySize(ForceCloseTickets) > 0)//And again
               MopUpTradeClosureFailures();
         }//if (OffsetOppositeLosersAgainstProfit)
         
         return(true);//Makes CountOpenTrades increment cc to avoid missing out ccounting a trade
      }//if (result)
   
      //Actions when trade close fails
      if (!result)
      {
         return(false);//Do not increment cc
      }//if (!result)
   }//if (CloseThisTrade)
   
   //Got this far, so no trade closure
   return(false);//Do not increment cc



}//bool LookForFullHedgeTradeClosure(int ticket)

void CloseOppositeDirectionLosers(int type)
{
   //Called when a full hedge trade has been closed and OffsetOppositeLosersAgainstProfit is 'true'.
   //type is the OrderType() to close.
   //I am using the ForceCloseTickets[] array and MopUpTradeClosureFailures() for the closures.
   
   int cc = 0;
   double LossThisTrade = 0;
   double TotalLossSoFar = 0;
   ArrayResize(ForceCloseTickets, 0);
   int as = 0;
   
   if (type == OP_BUY)
   {
      for (cc = ArraySize(BuyCloseTicket) - 1; cc >= 0; cc--)
      {
         if (!BetterOrderSelect(BuyCloseTicket[cc], SELECT_BY_TICKET, MODE_TRADES))
            continue;
         
         LossThisTrade = OrderSwap() + OrderProfit() + OrderCommission();
         if (LossThisTrade < 0)
         {
            LossThisTrade*= -1;//Needs to be a positive number for the comparison            
            if (TotalLossSoFar + LossThisTrade <= ClosedHedgeProfit)
               TotalLossSoFar+= LossThisTrade;
            //The loss on this trade may take the total loss until now over the
            //threshhold for closure, but we want to continue through the loop
            //to examine all the remaining trades.   
            if (TotalLossSoFar > ClosedHedgeProfit)
            {
               TotalLossSoFar-= LossThisTrade;
               continue;
            }//if (TotalLossSoFar > ClosedHedgeProfit)
            
            if (TotalLossSoFar <= ClosedHedgeProfit)
            {
               as = ArraySize(ForceCloseTickets);
               ArrayResize(ForceCloseTickets, as + 1);
               ForceCloseTickets[as] = OrderTicket();         
            }//if (TotalLossSoFar <= ClosedHedgeProfit)
         }//if (LossThisTrade < 0)
      }//for (cc = ArraySize(GridOrderBuyTickets) - 1; cc >= 0; cc--)
   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      for (cc = ArraySize(SellCloseTicket) - 1; cc >= 0; cc--)
      {
         if (!BetterOrderSelect(SellCloseTicket[cc], SELECT_BY_TICKET, MODE_TRADES))
            continue;
         
         LossThisTrade = OrderSwap() + OrderProfit() + OrderCommission();
         if (LossThisTrade < 0)
         {
            LossThisTrade*= -1;//Needs to be a positive number for the comparison            
            if (TotalLossSoFar + LossThisTrade <= ClosedHedgeProfit)
               TotalLossSoFar+= LossThisTrade;
            //The loss on this trade may take the total loss so far over the
            //threshhold for closure, but we want to continue through the loop
            //to examine all the remaining trades.   
            if (TotalLossSoFar > ClosedHedgeProfit)
            {
               TotalLossSoFar-= LossThisTrade;
               continue;
            }//if (TotalLossSoFar > ClosedHedgeProfit)
            
            if (TotalLossSoFar <= ClosedHedgeProfit)
            {
               as = ArraySize(ForceCloseTickets);
               ArrayResize(ForceCloseTickets, as + 1);
               ForceCloseTickets[as] = OrderTicket();               
            }//if (TotalLossSoFar <= ClosedHedgeProfit)
         }//if (LossThisTrade < 0)
      }//for (cc = ArraySize(BuyCloseTicket) - 1; cc >= 0; cc--)
   }//if (type == OP_SELL)
   

   
   
   
   //Now do the closures
   int tries = 0;
   if (ArraySize(ForceCloseTickets) > 0)
   {
      while (ArraySize(ForceCloseTickets) > 0)
      {
         MopUpTradeClosureFailures();
         CheckThatForceCloseArrayStillValid();
         if (ArraySize(ForceCloseTickets) == 0)
           return;
         tries++;
         if (tries >= 100)
            return;   
      }//while (ArraySize(ForceCloseTickets) > 0)      
   }//if (ArraySize(ForceCloseTickets) > 0)      
   

}//End void CloseOppositeDirectionLosers(int type)


bool LookForUsualTradeClosure(int ticket)
{
   //Close the trade if the close conditions are met.
   //Called from within CountOpenTrades(). Returns true if a close is needed and succeeds, so that COT can increment cc,
   //else returns false
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET) ) return(true);
   if (BetterOrderSelect(ticket, SELECT_BY_TICKET) && OrderCloseTime() > 0) return(true);
   
   
   string LineName = TpPrefix + DoubleToStr(ticket, 0);
   //Work with the lines on the chart that represent the hidden tp/sl
   double take = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(take, 0) ) take = OrderTakeProfit();
   LineName = SlPrefix + DoubleToStr(ticket, 0);
   double stop = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(stop, 0) ) stop = OrderStopLoss();
   
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
   {
      //TP
      if (Bid >= take && !CloseEnough(take, 0) && !CloseEnough(take, OrderTakeProfit()) ) return(true);
      //SL
      if (Bid <= stop && !CloseEnough(stop, 0)  && !CloseEnough(stop, OrderStopLoss())) return(true);

      
      //Close trade on opposite direction signal
      if (BuyCloseSignal)
         return(true);

      
      //Delete pendings on a new signal.
      //You may need to make changes here.
      if (SellSignal)
         if (DeletePendingsOnNewSignal)
            if (MarketTradesTotal == 0)
               return(true);
   
      
      //Add consideration of your CCA here
                    
    
   }//if (OrderType() == OP_BUY)
   
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
   {
      //TP
      if (Bid <= take && !CloseEnough(take, 0) && !CloseEnough(take, OrderTakeProfit()) ) return(true);
      //SL
      if (Bid >= stop && !CloseEnough(stop, 0)  && !CloseEnough(stop, OrderStopLoss())) return(true);



      
      //Close trade on opposite direction signal
      if (SellCloseSignal)
         return(true);

      //Delete pendings on a new signal
      //You may need to make changes here.
      if (BuySignal)
         if (DeletePendingsOnNewSignal)
            if (MarketTradesTotal == 0)
               return(true);
            
      
      //Add consideration of your CCA here

      
   }//if (OrderType() == OP_SELL)


   
   //Got this far, so no trade closure
   return(false);//Do not increment cc
   
}//End bool LookForUsualTradeClosure()

void CloseAllTrades(int type)
{

   ForceTradeClosure= false;
   int as = 0;//Array size
   
   if (OrdersTotal() == 0) return;
   
   bool result = false;
   for (int pass = 0; pass <= 1; pass++)
   {
      if (OrdersTotal() == 0 || OpenTrades == 0)
         break;
      for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
      {
         if (!BetterOrderSelect(FifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) ) continue;
         if (OrderMagicNumber() != MagicNumber) continue;
         if (OrderSymbol() != Symbol() ) continue;
         if (OrderType() != type) 
            if (type != AllTrades)
               continue;

            
            
         while(IsTradeContextBusy()) Sleep(100);
         if (pass == 0)
            if (OrderType() < 2)
            {
               result = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
               if (result) 
               {
                  //cc++;
                  OpenTrades--;
               }//(result) 
               
               if (!result) 
               {
                  ForceTradeClosure = true;
                  ArrayResize(ForceCloseTickets, as + 1);
                  ForceCloseTickets[as] = OrderTicket();
                  as++;
               }//if (!result)                      
            }//if (OrderType() < 2)
            
         if (pass == 1)
            if (OrderType() > 1) 
            {
               result = OrderDelete(OrderTicket(), clrNONE);
               if (result) 
               {
                  //cc++;
                  OpenTrades--;
               }//(result) 
               
               if (!result) 
               {
                  ForceTradeClosure = true;
                  ArrayResize(ForceCloseTickets, as + 1);
                  ForceCloseTickets[as] = OrderTicket();
                  as++;
               }//if (!result)  
            }//if (OrderType() > 1) 
            
      }//for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   }//for (int pass = 0; pass <= 1; pass++)
   
   //In case any trade closures failed
   if (ArraySize(ForceCloseTickets) > 0)
   {
      while (ArraySize(ForceCloseTickets) > 0)
      {
         MopUpTradeClosureFailures();
         CheckThatForceCloseArrayStillValid();
      }//while (ArraySize(ForceCloseTickets) > 0)      
   }//if (ArraySize(ForceCloseTickets) > 0)      
   
   CountOpenTrades();
   
}//End void CloseAllTradesFifo()


bool CheckTradingTimes()
  {

   //Friday-Monday trading first
   int sday=TimeDayOfWeek(TimeCurrent());
   int stime=TimeHour(TimeCurrent())*60+TimeMinute(TimeCurrent());

   double ttime;
   int thours,tminutes,sunstart,monstart,fristop,satstop;
   
   ttime=StrToDouble(FridayStopTradingTime);
   thours=(int)MathFloor(ttime);
   tminutes=(int)MathRound((ttime-thours)*100);
   fristop=60*thours+tminutes; 

   ttime=StrToDouble(SaturdayStopTradingTime);
   thours=(int)MathFloor(ttime);
   tminutes=(int)MathRound((ttime-thours)*100);
   satstop=60*thours+tminutes; 

   ttime=StrToDouble(SundayStartTradingTime);
   thours=(int)MathFloor(ttime);
   tminutes=(int)MathRound((ttime-thours)*100);
   sunstart=60*thours+tminutes;
      
   ttime=StrToDouble(MondayStartTradingTime);
   thours=(int)MathFloor(ttime);
   tminutes=(int)MathRound((ttime-thours)*100);
   monstart=60*thours+tminutes;
      
   //Friday
   if(sday==5)
      if(stime>=fristop)
         return(false);

   //Saturday
   if(sday==6)
      if(stime>=satstop)
         return(false);

   //Sunday
   if(sday==0)
      if(stime<sunstart)
         return(false);

   //Monday
   if(sday==1)
      if(stime<monstart)
         return(false);

   // Trade 24 hours if no input is given
   if( ArraySize( tradeHours ) == 0 ) return ( true );

   // Get local time in minutes from midnight
   int time=TimeHour(TimeLocal())*60+TimeMinute(TimeLocal());

   // Don't you love this?
   int i=0;
   while(time>=tradeHours[i])
     {
      if(i==ArraySize(tradeHours)) break;
      i++;
     }
   if( i % 2 == 1 ) return ( true );
   return ( false );
  }//End bool CheckTradingTimes2() 

//+------------------------------------------------------------------+
//| Initialize Trading Hours Array                                   |
//+------------------------------------------------------------------+
bool initTradingHours() 
{
   // Called from init()
   
	// Assume 24 trading if no input found
	if ( tradingHours == "" )	
	{
		ArrayResize( tradeHours, 0 );
		return ( true );
	}

	int i;

	// Add 00:00 start time if first element is stop time
	if ( StringSubstrOld( tradingHours, 0, 1 ) == "-" ) 
	{
		tradingHours = StringConcatenate( "+0,", tradingHours );   
	}
	
	// Add delimiter
	if ( StringSubstrOld( tradingHours, StringLen( tradingHours ) - 1) != "," ) 
	{
		tradingHours = StringConcatenate( tradingHours, "," );   
	}
	
	string lastPrefix = "-";
	i = StringFind( tradingHours, "," );
	
	while (i != -1) 
	{

		// Resize array
		int size = ArraySize( tradeHours );
		ArrayResize( tradeHours, size + 1 );

		// Get part to process
		string part = StringSubstrOld( tradingHours, 0, i );

		// Check start or stop prefix
		string prefix = StringSubstrOld ( part, 0, 1 );
		if ( prefix != "+" && prefix != "-" ) 
		{
			Print("ERROR IN TRADINGHOURS INPUT (NO START OR CLOSE FOUND), ASSUME 24HOUR TRADING.");
			ArrayResize ( tradeHours, 0 );
			return ( true );
		}

		if ( ( prefix == "+" && lastPrefix == "+" ) || ( prefix == "-" && lastPrefix == "-" ) )	
		{
			Print("ERROR IN TRADINGHOURS INPUT (START OR CLOSE IN WRONG ORDER), ASSUME 24HOUR TRADING.");
			ArrayResize ( tradeHours, 0 );
			return ( true );
		}
		
		lastPrefix = prefix;

		// Convert to time in minutes
		part = StringSubstrOld( part, 1 );
		double time = StrToDouble( part );
		int hour = (int)MathFloor( time );
		int minutes = (int)MathRound( ( time - hour ) * 100 );

		// Add to array
		tradeHours[size] = 60 * hour + minutes;

		// Trim input string
		tradingHours = StringSubstrOld( tradingHours, i + 1 );
		i = StringFind( tradingHours, "," );
	}//while (i != -1) 

	return ( true );
}//End bool initTradingHours() 

void CountOpenTrades()
{
   
   int cc = 0;
   bool TradeWasClosed = false;//See 'check for possible trade closure'

   
   //Not all these will be needed. Which ones are depends on the individual EA.
   //Market Buy trades
   BuyOpen=false;
   MarketBuysCount=0;
   LatestBuyPrice=0; EarliestBuyPrice=0; HighestBuyPrice=0; LowestBuyPrice=million;
   BuyTicketNo=-1; HighestBuyTicketNo=-1; LowestBuyTicketNo=-1; LatestBuyTicketNo=-1; EarliestBuyTicketNo=-1;
   BuyPipsUpl=0;
   BuyCashUpl=0;
   LatestBuyTradeTime=0;
   EarliestBuyTradeTime=TimeCurrent();
   BuyLotsTotal = 0;
   
   //Market Sell trades
   SellOpen=false;
   MarketSellsCount=0;
   LatestSellPrice=0; EarliestSellPrice=0; HighestSellPrice=0; LowestSellPrice=million;
   SellTicketNo=-1; HighestSellTicketNo=-1; LowestSellTicketNo=-1; LatestSellTicketNo=-1; EarliestSellTicketNo=-1;;
   SellPipsUpl=0;
   SellCashUpl=0;
   LatestSellTradeTime=0;
   EarliestSellTradeTime=TimeCurrent();
   TotalSellLots = 0;
   SellLotsTotal = 0;
   
   //BuyStop trades
   BuyStopOpen=false;
   BuyStopsCount=0;
   LatestBuyStopPrice=0; EarliestBuyStopPrice=0; HighestBuyStopPrice=0; LowestBuyStopPrice=million;
   BuyStopTicketNo=-1; HighestBuyStopTicketNo=-1; LowestBuyStopTicketNo=-1; LatestBuyStopTicketNo=-1; EarliestBuyStopTicketNo=-1;;
   LatestBuyStopTradeTime=0;
   EarliestBuyStopTradeTime=TimeCurrent();
   TotalBuyLots = 0;
   
   //BuyLimit trades
   BuyLimitOpen=false;
   BuyLimitsCount=0;
   LatestBuyLimitPrice=0; EarliestBuyLimitPrice=0; HighestBuyLimitPrice=0; LowestBuyLimitPrice=million;
   BuyLimitTicketNo=-1; HighestBuyLimitTicketNo=-1; LowestBuyLimitTicketNo=-1; LatestBuyLimitTicketNo=-1; EarliestBuyLimitTicketNo=-1;;
   LatestBuyLimitTradeTime=0;
   EarliestBuyLimitTradeTime=TimeCurrent();
   
   /////SellStop trades
   SellStopOpen=false;
   SellStopsCount=0;
   LatestSellStopPrice=0; EarliestSellStopPrice=0; HighestSellStopPrice=0; LowestSellStopPrice=million;
   SellStopTicketNo=-1; HighestSellStopTicketNo=-1; LowestSellStopTicketNo=-1; LatestSellStopTicketNo=-1; EarliestSellStopTicketNo=-1;;
   LatestSellStopTradeTime=0;
   EarliestSellStopTradeTime=TimeCurrent();
   
   //SellLimit trades
   SellLimitOpen=false;
   SellLimitsCount=0;
   LatestSellLimitPrice=0; EarliestSellLimitPrice=0; HighestSellLimitPrice=0; LowestSellLimitPrice=million;
   SellLimitTicketNo=-1; HighestSellLimitTicketNo=-1; LowestSellLimitTicketNo=-1; LatestSellLimitTicketNo=-1; EarliestSellLimitTicketNo=-1;;
   LatestSellLimitTradeTime=0;
   EarliestSellLimitTradeTime=TimeCurrent();
   
   //Not related to specific order types
   TicketNo=-1;OpenTrades=0;
   LatestTradeTime=0; EarliestTradeTime=TimeCurrent();//More specific times are in each individual section
   LatestTradeTicketNo=-1; EarliestTradeTicketNo=-1;
   PipsUpl=0;//For keeping track of the pips PipsUpl of multi-trade/hedged positions
   CashUpl=0;//For keeping track of the cash PipsUpl of multi-trade/hedged positions
   MarketTradesTotal = 0;
   FullyHedged = false;
   ReRunCOT = false;
   
   //FIFO ticket resize
   ArrayResize(FifoTicket, 0);
   
   //Fill the gap stuff. Not much used as my original concept was flawed.
   ArrayResize(BuyPrices, 0);
   ArrayResize(SellPrices, 0);
   int AnyKindOfBuy = 0, AnyKindOfSell = 0;
      
   //This is for complex single sided offsetting - not used but the code is in CanTradesBeOffset()
   //and for dydynamic's basket tp
   ArrayResize(GridOrderBuyTickets, 0);
   ArrayInitialize(GridOrderBuyTickets, 0);
   ArrayResize(GridOrderSellTickets, 0);
   ArrayInitialize(GridOrderSellTickets, 0);
   
   //Hedge closure
   ArrayResize(BuyCloseTicket, 0);
   ArrayResize(SellCloseTicket, 0);
   
   //The arrays that hold full hedge ticket numbers
   ArrayResize(BuyHedgeTickets, 0);
   ArrayResize(SellHedgeTickets, 0);
   int BuyHedgeArraySize = 0, SellHedgeArraySize = 0;//Array suze for multiple full hedge trades
   
   
   
   int type;//Saves the OrderType() for consulatation later in the function
   
   
   if(OrdersTotal() == 0)
     {
      Hedged=false;
      return;
     }
   
   //Iterating backwards through the orders list caters more easily for closed trades than iterating forwards
   for (cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      TradeWasClosed = false;//See 'check for possible trade closure'

      //Ensure the trade is still open
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      //Ensure the EA 'owns' this trade
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      
      //Fully hedged?
      if (OrderComment() == FullHedgeComment)
         FullyHedged = true;
      
      
      //Total of open lots
      if (OrderType() == OP_BUY)
         TotalBuyLots+= OrderLots();
      if (OrderType() == OP_SELL)
         TotalSellLots+= OrderLots();
         
      
      //The time of the most recent trade
      if (OrderOpenTime() > LatestTradeTime)
      {
         LatestTradeTime = OrderOpenTime();
         LatestTradeTicketNo = OrderTicket();
      }//if (OrderOpenTime() > LatestTradeTime)
        
      //The time of the earliest trade
      if (OrderOpenTime() < EarliestTradeTime)
      {
         EarliestTradeTime = OrderOpenTime();
         EarliestTradeTicketNo = OrderTicket();
      }//if (OrderOpenTime() < EarliestTradeTime)
      
      //All conditions passed, so carry on
      type = OrderType();//Store the order type
      
      if (!CloseEnough(OrderTakeProfit(), 0) )
         TpSet = true;
      if (!CloseEnough(OrderStopLoss(), 0) )
         SlSet = true;

      //Store the latest trade sent. Most of my EA's only need this final ticket number as either they are single trade
      //bots or the last trade in the sequence is the important one. Adapt this code for your own use.
      if (TicketNo  == -1) TicketNo = OrderTicket();
      
      //Store ticket numbers for FIFO      
      
      ArrayResize(FifoTicket, OpenTrades + 1); 
      FifoTicket[OpenTrades] = OrderTicket();
      OpenTrades++;
      
      //Fill in the gap stuff.
      //Store order open prices in an array for CanWeAddAnotherPendingTrade()
      //Buy abd buy stop trades
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP)
      {
         ArrayResize(BuyPrices, AnyKindOfBuy + 1);
         BuyPrices[AnyKindOfBuy] = OrderOpenPrice();
         AnyKindOfBuy++;      
      }//if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP)
      
      //Sell and sell stop trades
      if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP)
      {
         ArrayResize(SellPrices, AnyKindOfSell + 1);
         SellPrices[AnyKindOfSell] = OrderOpenPrice();
         AnyKindOfSell++;      
      }//if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP)
      
      
      //The time of the most recent pending order
      if (OrderType() > 1)
         if (OrderOpenTime() > LatestTradeTime)
            LatestTradeTime = OrderOpenTime();
      //Time of the furthest back in time trade
      if (OrderOpenTime() < EarliestTradeTime)
         EarliestTradeTime = OrderOpenTime();

     
      //The next line of code calculates the pips upl of an open trade. As yet, I have done nothing with it.
      //something = CalculateTradeProfitInPips()
      
      double pips = 0;
      
      //Buile up the position picture of market trades
      if (OrderType() < 2)
      {
         CashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
         MarketTradesTotal++;
         pips = CalculateTradeProfitInPips(OrderType());
         PipsUpl+= pips;
         
         //Buys
         if (OrderType() == OP_BUY)
         {
            ArrayResize(GridOrderBuyTickets, MarketBuysCount + 1);
            GridOrderBuyTickets[MarketBuysCount][TradeOpenPrice] = OrderOpenPrice();  //can be sorted by price
            GridOrderBuyTickets[MarketBuysCount][TradeTicket] = OrderTicket();
            ArrayResize(BuyCloseTicket, MarketBuysCount + 1);
            BuyCloseTicket[MarketBuysCount] = OrderTicket();
            if (OrderComment() == FullHedgeComment)
            {
               ArrayResize(BuyHedgeTickets, BuyHedgeArraySize + 1);
               BuyHedgeTickets[BuyHedgeArraySize] = OrderTicket();
               BuyHedgeArraySize+= 1;
            }//if (OrderComment() == FullHedgeComment)
            

            BuyOpen = true;
            BuyTicketNo = OrderTicket();
            MarketBuysCount++;
            BuyPipsUpl+= pips;
            BuyCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
            BuyLotsTotal+= OrderLots();
            
            //Latest trade
            if (OrderOpenTime() > LatestBuyTradeTime)
            {
               LatestBuyTradeTime = OrderOpenTime();
               LatestBuyPrice = OrderOpenPrice();
               LatestBuyTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestBuyTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestBuyTradeTime)
            {
               EarliestBuyTradeTime = OrderOpenTime();
               EarliestBuyPrice = OrderOpenPrice();
               EarliestBuyTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestBuyTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestBuyPrice)
            {
               HighestBuyPrice = OrderOpenPrice();
               HighestBuyTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestBuyPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestBuyPrice)
            {
               LowestBuyPrice = OrderOpenPrice();
               LowestBuyTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestBuyPrice)
              
         }//if (OrderType() == OP_BUY)
         
         //Sells
         if (OrderType() == OP_SELL)
         {
            ArrayResize(GridOrderSellTickets, MarketSellsCount + 1);
            GridOrderSellTickets[MarketSellsCount][TradeOpenPrice] = OrderOpenPrice();  //can be sorted by price
            GridOrderSellTickets[MarketSellsCount][TradeTicket] = OrderTicket();
            ArrayResize(SellCloseTicket, MarketSellsCount + 1);
            SellCloseTicket[MarketSellsCount] = OrderTicket();
            if (OrderComment() == FullHedgeComment)
            {
               ArrayResize(SellHedgeTickets, SellHedgeArraySize + 1);
               SellHedgeTickets[SellHedgeArraySize] = OrderTicket();
               SellHedgeArraySize+= 1;
            }//if (OrderComment() == FullHedgeComment)
            
            SellOpen = true;
            SellTicketNo = OrderTicket();
            MarketSellsCount++;
            SellPipsUpl+= pips;
            SellCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
            SellLotsTotal+= OrderLots();
            
            //Latest trade
            if (OrderOpenTime() > LatestSellTradeTime)
            {
               LatestSellTradeTime = OrderOpenTime();
               LatestSellPrice = OrderOpenPrice();
               LatestSellTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestSellTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestSellTradeTime)
            {
               EarliestSellTradeTime = OrderOpenTime();
               EarliestSellPrice = OrderOpenPrice();
               EarliestSellTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestSellTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestSellPrice)
            {
               HighestSellPrice = OrderOpenPrice();
               HighestSellTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestSellPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestSellPrice)
            {
               LowestSellPrice = OrderOpenPrice();
               LowestSellTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestSellPrice)
              
         }//if (OrderType() == OP_SELL)
         
         
      }//if (OrderType() < 2)
      
      
      //Build up the position details of stop/limit orders
      if (OrderType() > 1)
      {
         //Buystops
         if (OrderType() == OP_BUYSTOP)
         {
            BuyStopOpen = true;
            BuyStopTicketNo = OrderTicket();
            BuyStopsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestBuyStopTradeTime)
            {
               LatestBuyStopTradeTime = OrderOpenTime();
               LatestBuyStopPrice = OrderOpenPrice();
               LatestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestBuyStopTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestBuyStopTradeTime)
            {
               EarliestBuyStopTradeTime = OrderOpenTime();
               EarliestBuyStopPrice = OrderOpenPrice();
               EarliestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestBuyStopTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestBuyStopPrice)
            {
               HighestBuyStopPrice = OrderOpenPrice();
               HighestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestBuyStopPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestBuyStopPrice)
            {
               LowestBuyStopPrice = OrderOpenPrice();
               LowestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestBuyStopPrice)
              
         }//if (OrderType() == OP_BUYSTOP)
         
         //Sellstops
         if (OrderType() == OP_SELLSTOP)
         {
            SellStopOpen = true;
            SellStopTicketNo = OrderTicket();
            SellStopsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestSellStopTradeTime)
            {
               LatestSellStopTradeTime = OrderOpenTime();
               LatestSellStopPrice = OrderOpenPrice();
               LatestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestSellStopTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestSellStopTradeTime)
            {
               EarliestSellStopTradeTime = OrderOpenTime();
               EarliestSellStopPrice = OrderOpenPrice();
               EarliestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestSellStopTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestSellStopPrice)
            {
               HighestSellStopPrice = OrderOpenPrice();
               HighestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestSellStopPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestSellStopPrice)
            {
               LowestSellStopPrice = OrderOpenPrice();
               LowestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestSellStopPrice)
              
         }//if (OrderType() == OP_SELLSTOP)
         
         //Buy limits
         if (OrderType() == OP_BUYLIMIT)
         {
            BuyLimitOpen = true;
            BuyLimitTicketNo = OrderTicket();
            BuyLimitsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestBuyLimitTradeTime)
            {
               LatestBuyLimitTradeTime = OrderOpenTime();
               LatestBuyLimitPrice = OrderOpenPrice();
               LatestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestBuyLimitTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestBuyLimitTradeTime)
            {
               EarliestBuyLimitTradeTime = OrderOpenTime();
               EarliestBuyLimitPrice = OrderOpenPrice();
               EarliestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestBuyLimitTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestBuyLimitPrice)
            {
               HighestBuyLimitPrice = OrderOpenPrice();
               HighestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestBuyLimitPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestBuyLimitPrice)
            {
               LowestBuyLimitPrice = OrderOpenPrice();
               LowestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestBuyLimitPrice)
              
         }//if (OrderType() == OP_BUYLIMIT)
         
         //Sell limits
         if (OrderType() == OP_SELLLIMIT)
         {
            SellLimitOpen = true;
            SellLimitTicketNo = OrderTicket();
            SellLimitsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestSellLimitTradeTime)
            {
               LatestSellLimitTradeTime = OrderOpenTime();
               LatestSellLimitPrice = OrderOpenPrice();
               LatestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestSellLimitTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestSellLimitTradeTime)
            {
               EarliestSellLimitTradeTime = OrderOpenTime();
               EarliestSellLimitPrice = OrderOpenPrice();
               EarliestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestSellLimitTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestSellLimitPrice)
            {
               HighestSellLimitPrice = OrderOpenPrice();
               HighestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestSellLimitPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestSellLimitPrice)
            {
               LowestSellLimitPrice = OrderOpenPrice();
               LowestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestSellLimitPrice)
              
         }//if (OrderType() == OP_SELLLIMIT)
         
      
      }//if (OrderType() > 1)
      
      
         
      if (!Hedged && !UseHedgingWithGrid)
      {
         //Add missing tp/sl in case rapidly moving markets prevent their addition - ECN
         if (CloseEnough(OrderStopLoss(), 0) && !CloseEnough(StopLoss, 0)) InsertStopLoss(OrderTicket());
         if (CloseEnough(OrderTakeProfit(), 0) && !CloseEnough(TakeProfit, 0)) InsertTakeProfit(OrderTicket() );
         //Replace missing tp and sl lines
         if (HiddenPips > 0) ReplaceMissingSlTpLines();
         
         TradeWasClosed = LookForTradeClosure(OrderTicket() );
         if (TradeWasClosed) 
         {
            if (type == OP_BUY) BuyOpen = false;//Will be reset if subsequent trades are buys that are not closed
            if (type == OP_SELL) SellOpen = false;//Will be reset if subsequent trades are sells that are not closed
            cc++;
            continue;
         }//if (TradeWasClosed)

         //Profitable trade management
         if (OrderProfit() > 0) 
         {
            TradeManagementModule(OrderTicket() );
         }//if (OrderProfit() > 0) 
      }//if (!Hedged)
      
               
      
   }//for (int cc = OrdersTotal() - 1; cc <= 0; c`c--)
   
   //Sort ticket numbers for FIFO
   if (ArraySize(FifoTicket) > 0)
      ArraySort(FifoTicket, WHOLE_ARRAY, 0, MODE_DESCEND);
   
   //Sort the arrays for the fill the gap stuff
   if (ArraySize(BuyPrices) > 0 )
      ArraySort(BuyPrices, WHOLE_ARRAY, 0, MODE_ASCEND);//We need the lowest buy price at the start of the array
     
   if (ArraySize(SellPrices) > 0 )
      ArraySort(SellPrices, WHOLE_ARRAY, 0, MODE_ASCEND);//We need the lowest sell price at the start of the array

   //Sort arrays for dydynamic
   if (ArraySize(GridOrderBuyTickets) > 0)
      ArraySort(GridOrderBuyTickets, WHOLE_ARRAY, 0, MODE_DESCEND);
   
   if (ArraySize(GridOrderSellTickets) > 0)
      ArraySort(GridOrderSellTickets, WHOLE_ARRAY, 0, MODE_DESCEND);
     
   //Is the position hedged?
   Hedged = false;
   if (BuyOpen)
      if (SellOpen)
         Hedged=true;

   //Remove stop losses and take profits
   if (Hedged)
   {
      if (TpSet)
         RemoveTakeProfits();
      if (SlSet)
         RemoveStopLosses();
   }//if (Hegded)

   //Can we close a full hedge trade?
   if (FullyHedged)
   {
      //Buy hedges after a short trend is detected
      if (ArraySize(BuyHedgeTickets) > 0)
         if (HgiShortTrendDetected)
         {
            for (cc = ArraySize(BuyHedgeTickets) - 1; cc >=0; cc--)
            {
               if (BetterOrderSelect(BuyHedgeTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
               {
                  TradeWasClosed = LookForFullHedgeTradeClosure(OrderTicket());
                  if (TradeWasClosed)
                     BuyHedgeTickets[cc] = 0;
               }//if (BetterOrderSelect(BuyHedgeTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
            }//for (cc = ArraySize(BuyHedgeTickets) - 1; cc >=0; cc--)
            TrimIntArrays(BuyHedgeTickets);
         }//if (HgiShortTrendDetected)
         
      //Sell hedges after a long trend is detected
      if (ArraySize(SellHedgeTickets) > 0)
         if (HgiLongTrendDetected)
         {
            for (cc = ArraySize(SellHedgeTickets) - 1; cc >=0; cc--)
            {
               if (BetterOrderSelect(SellHedgeTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
               {
                  TradeWasClosed = LookForFullHedgeTradeClosure(OrderTicket());
                  if (TradeWasClosed)
                     SellHedgeTickets[cc] = 0;
               }//if (BetterOrderSelect(SellHedgeTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
            }//for (cc = ArraySize(SellHedgeTickets) - 1; cc >=0; cc--)
            TrimIntArrays(SellHedgeTickets);
         }//if (HgiLongTrendDetected)
         
   }//if (FullyHedged)
   
   
    
}//End void CountOpenTrades();

void RemoveTakeProfits()
{

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;

      if (!CloseEnough(OrderTakeProfit(), 0) )
         ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), 0, 
                     OrderExpiration(), clrNONE, __FUNCTION__, tpm);
      
      
  
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

}//void RemoveTakeProfits()

void RemoveStopLosses()
{

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;

      if (!CloseEnough(OrderStopLoss(), 0) )
         ModifyOrder(OrderTicket(), OrderOpenPrice(), 0, OrderTakeProfit(), 
                     OrderExpiration(), clrNONE, __FUNCTION__, tpm);
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

}//void RemoveStopLosses()



void InsertStopLoss(int ticket)
{
   //Inserts a stop loss if the ECN crim managed to swindle the original trade out of the modification at trade send time
   //Called from CountOpenTrades() if StopLoss > 0 && OrderStopLoss() == 0.
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (OrderStopLoss() > 0) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double stop=0;
   
   if (OrderType() == OP_BUY)
   {
      stop = CalculateStopLoss(OP_BUY, OrderOpenPrice());
   }//if (OrderType() == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      stop = CalculateStopLoss(OP_SELL, OrderOpenPrice());
   }//if (OrderType() == OP_SELL)
   
   if (CloseEnough(stop, 0) ) return;
   
   //In case some errant behaviour/code creates a sl the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && stop > OrderOpenPrice() ) 
   {
      stop = 0;
      ReportError(" InsertStopLoss()", " stop loss > market ");
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && stop < OrderOpenPrice() ) 
   {
      stop = 0;
      ReportError(" InsertStopLoss()", " stop loss > market ");
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 

   
   if (!CloseEnough(stop, OrderStopLoss())) 
   {
      bool result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (!CloseEnough(stop, OrderStopLoss())) 

}//End void InsertStopLoss(int ticket)

void InsertTakeProfit(int ticket)
{
   //Inserts a TP if the ECN crim managed to swindle the original trade out of the modification at trade send time
   //Called from CountOpenTrades() if TakeProfit > 0 && OrderTakeProfit() == 0.
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (!CloseEnough(OrderTakeProfit(), 0) ) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double take=0;
   
   if (OrderType() == OP_BUY)
   {
      take = CalculateTakeProfit(OP_BUY, OrderOpenPrice());
   }//if (OrderType() == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      take = CalculateTakeProfit(OP_SELL, OrderOpenPrice());
   }//if (OrderType() == OP_SELL)
   
   if (CloseEnough(take, 0) ) return;
   
   //In case some errant behaviour/code creates a tp the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && take < OrderOpenPrice()  && !CloseEnough(take, 0) ) 
   {
      take = 0;
      ReportError(" InsertTakeProfit()", " take profit < market ");
      return;
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   {
      take = 0;
      ReportError(" InsertTakeProfit()", " take profit < market ");
      return;
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   
   if (!CloseEnough(take, OrderTakeProfit()) ) 
   {
      bool result = ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (!CloseEnough(take, OrderTakeProfit()) ) 

}//End void InsertTakeProfit(int ticket)

////////////////////////////////////////////////////////////////////////////////////////
//Pending trade price lines module.
//Doubles up by providing missing lines for the stealth stuff
void DrawPendingPriceLines()
{
   //This function will work for a full pending-trade EA.
   //The pending tp/sl can be used for hiding the stops in a market-trading ea
   
   /*
   ObjectDelete(pendingpriceline);
   ObjectCreate(pendingpriceline, OBJ_HLINE, 0, TimeCurrent(), PendingPrice);
   if (PendingBuy) ObjectSet(pendingpriceline, OBJPROP_COLOR, Green);
   if (PendingSell) ObjectSet(pendingpriceline, OBJPROP_COLOR, Red);
   ObjectSet(pendingpriceline, OBJPROP_WIDTH, 1);
   ObjectSet(pendingpriceline, OBJPROP_STYLE, STYLE_DASH);
   */
   string LineName = TpPrefix + DoubleToStr(TicketNo, 0);//TicketNo is set by the calling function - either CountOpenTrades or DoesTradeExist
   HiddenTakeProfit = 0;
   if (TicketNo > -1 && OrderTakeProfit() > 0)
   {
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
      {
         HiddenTakeProfit = NormalizeDouble(OrderTakeProfit() - (HiddenPips / factor), Digits);
      }//if (OrderType() == OP_BUY)
      
      if (OrderType() == OP_SELL)
      {
         HiddenTakeProfit = NormalizeDouble(OrderTakeProfit() + (HiddenPips / factor), Digits);
      }//if (OrderType() == OP_BUY)      
   }//if (TicketNo > -1 && OrderTakeProfit() > 0)
   
   if (HiddenTakeProfit > 0 && ObjectFind(LineName) == -1)
   {
      ObjectDelete(LineName);
      ObjectCreate(LineName, OBJ_HLINE, 0, TimeCurrent(), HiddenTakeProfit);
      ObjectSet(LineName, OBJPROP_COLOR, Green);
      ObjectSet(LineName, OBJPROP_WIDTH, 1);
      ObjectSet(LineName, OBJPROP_STYLE, STYLE_DOT);
   }//if (HiddenTakeProfit > 0)
   
   
   LineName = SlPrefix + DoubleToStr(TicketNo, 0);//TicketNo is set by the calling function - either CountOpenTrades or DoesTradeExist
   HiddenStopLoss = 0;
   if (TicketNo > -1 && OrderStopLoss() > 0)
   {
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
      {
         HiddenStopLoss = NormalizeDouble(OrderStopLoss() + (HiddenPips / factor), Digits);
      }//if (OrderType() == OP_BUY)
      
      if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
      {
         HiddenStopLoss = NormalizeDouble(OrderStopLoss() - (HiddenPips / factor), Digits);
      }//if (OrderType() == OP_BUY)      
   }//if (TicketNo > -1 && OrderStopLoss() > 0)
   
   if (HiddenStopLoss > 0 && ObjectFind(LineName) == -1)
   {
      ObjectDelete(LineName);
      ObjectCreate(LineName, OBJ_HLINE, 0, TimeCurrent(), HiddenStopLoss);
      ObjectSet(LineName, OBJPROP_COLOR, Red);
      ObjectSet(LineName, OBJPROP_WIDTH, 1);
      ObjectSet(LineName, OBJPROP_STYLE, STYLE_DOT);
   }//if (HiddenStopLoss > 0)
   
   

}//End void DrawPendingPriceLines()


void DeletePendingPriceLines()
{

   
   //ObjectDelete(pendingpriceline);
   string LineName = TpPrefix + DoubleToStr(TicketNo, 0);
   ObjectDelete(LineName);
   LineName = SlPrefix + DoubleToStr(TicketNo, 0);
   ObjectDelete(LineName);
   
}//End void DeletePendingPriceLines()

void ReplaceMissingSlTpLines()
{

   if (OrderTakeProfit() > 0 || OrderStopLoss() > 0) DrawPendingPriceLines();

}//End void ReplaceMissingSlTpLines()

void DeleteOrphanTpSlLines()
{

   if (ObjectsTotal() == 0) return;
   
   for (int cc = ObjectsTotal() - 1; cc >= 0; cc--)
   {
      string name = ObjectName(cc);
      
      if ((StringSubstrOld(name, 0, 2) == TpPrefix || StringSubstrOld(name, 0, 2) == SlPrefix) && ObjectType(name) == OBJ_HLINE)
      {
         int tn = (int)StrToDouble(StringSubstrOld(name, 2));
         if (tn > 0) 
         {
            if (!BetterOrderSelect(tn, SELECT_BY_TICKET, MODE_TRADES) || OrderCloseTime() > 0)
            {
               ObjectDelete(name);
            }//if (!BetterOrderSelect(tn, SELECT_BY_TICKET, MODE_TRADES) || OrderCloseTime() > 0)
            
         }//if (tn > 0) 
         
         
      }//if (StringSubstrOld(name, 0, 1) == TpPrefix)
      
   }//for (int cc = ObjectsTotal() - 1; cc >= 0; cc--)
   
   
}//End void DeleteOrphanTpSlLines()


//END Pending trade price lines module
////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////
//TRADE MANAGEMENT MODULE

void ReportError(string function, string message)
{
   //All purpose sl mod error reporter. Called when a sl mod fails
   
   int err=GetLastError();
   if (err == 1) return;//That bloody 'error but no error' report is a nuisance
   
      
   Alert(WindowExpertName(), " ", OrderTicket(), function, message, err,": ",ErrorDescription(err));
   Print(WindowExpertName(), " ", OrderTicket(), function, message, err,": ",ErrorDescription(err));
   
}//void ReportError()

bool ModifyOrder(int ticket, double price, double stop, double take, datetime expiry, color col, string function, string reason)
{
   //Multi-purpose order modify function
   
   bool result = OrderModify(ticket, price ,stop , take, expiry, col);

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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BreakEvenStopLoss(int ticket) // Move stop loss to breakeven
{

   //Security check
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
      
   double NewStop=0;
   bool result;
   bool modify=false;
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   double target = OrderOpenPrice();
   
   if (OrderType()==OP_BUY)
   {
      if (HiddenPips > 0) target-= (HiddenPips / factor);
      if (OrderStopLoss() >= target) return;
      if (Bid >= OrderOpenPrice () + (BreakEvenPips / factor))          
      {
         //Calculate the new stop
         NewStop = NormalizeDouble(OrderOpenPrice()+(BreakEvenProfit / factor), Digits);
         if (HiddenPips > 0)
         {
            if (ObjectFind(LineName) == -1)
            {
               ObjectCreate(LineName, OBJ_HLINE, 0, TimeCurrent(), 0);
               ObjectSet(LineName, OBJPROP_COLOR, Red);
               ObjectSet(LineName, OBJPROP_WIDTH, 1);
               ObjectSet(LineName, OBJPROP_STYLE, STYLE_DOT);
            }//if (ObjectFind(LineName == -1) )
         
            ObjectMove(LineName, 0, TimeCurrent(), NewStop);         
         }//if (HiddenPips > 0)
         modify = true;   
      }//if (Bid >= OrderOpenPrice () + (Point*BreakEvenPips) && 
   }//if (OrderType()==OP_BUY)               			         
    
   if (OrderType()==OP_SELL)
   {
     if (HiddenPips > 0) target+= (HiddenPips / factor);
      if (OrderStopLoss() <= target && OrderStopLoss() > 0) return;
     if (Ask <= OrderOpenPrice() - (BreakEvenPips / factor)) 
     {
         //Calculate the new stop
         NewStop = NormalizeDouble(OrderOpenPrice()-(BreakEvenProfit / factor), Digits);
         if (HiddenPips > 0)
         {
            if (ObjectFind(LineName) == -1)
            {
               ObjectCreate(LineName, OBJ_HLINE, 0, TimeCurrent(), 0);
               ObjectSet(LineName, OBJPROP_COLOR, Red);
               ObjectSet(LineName, OBJPROP_WIDTH, 1);
               ObjectSet(LineName, OBJPROP_STYLE, STYLE_DOT);
            }//if (ObjectFind(LineName == -1) )
         
            ObjectMove(LineName, 0, Time[0], NewStop);
         }//if (HiddenPips > 0)         
         modify = true;   
     }//if (Ask <= OrderOpenPrice() - (Point*BreakEvenPips) && (OrderStopLoss()>OrderOpenPrice()|| OrderStopLoss()==0))     
   }//if (OrderType()==OP_SELL)

   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      if (NewStop == OrderStopLoss() ) return;
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
      
      while (IsTradeContextBusy() ) Sleep(100);
      if (PartCloseEnabled && OrderComment() == TradeComment) bool success = PartCloseOrder(OrderTicket() );
   }//if (modify)
   
} // End BreakevenStopLoss sub

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PartCloseOrder(int ticket)
{
   //Close PartClosePercent of the initial trade.
   //Return true if close succeeds, else false
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) return(true);//in case the trade closed
   
   bool Success = false;
   double CloseLots = NormalizeLots(OrderSymbol(),OrderLots() * (PartClosePercent / 100));
   
   Success = OrderClose(ticket, CloseLots, OrderClosePrice(), 1000, Blue); //fxdaytrader, NormalizeLots(...
   if (Success) TradeHasPartClosed = true;//Warns CountOpenTrades() that the OrderTicket() is incorrect.
   if (!Success) 
   {
       //mod. fxdaytrader, orderclose-retry if failed with ordercloseprice(). Maybe very seldom, but it can happen, so it does not hurt to implement this:
       while(IsTradeContextBusy()) Sleep(100);
       RefreshRates();
       if (OrderType()==OP_BUY) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_BID), 5000, Blue);
       if (OrderType()==OP_SELL) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_ASK), 5000, Blue);
       //end mod.  
       //original:
       if (Success) TradeHasPartClosed = true;//Warns CountOpenTrades() that the OrderTicket() is incorrect.
   
       if (!Success) 
       {
         ReportError(" PartCloseOrder()", pcm);
         return (false);
       } 
   }//if (!Success) 
      
   //Got this far, so closure succeeded
   return (true);   

}//bool PartCloseOrder(int ticket)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void JumpingStopLoss(int ticket) 
{
   // Jump sl by pips and at intervals chosen by user .

   //Security check
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;

   //if (OrderProfit() < 0) return;//Nothing to do
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(sl, 0) ) sl = OrderStopLoss();
   
   //if (CloseEnough(sl, 0) ) return;//No line, so nothing to do
   double NewStop=0;
   bool modify=false;
   bool result;
   
   
    if (OrderType()==OP_BUY)
    {
       if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
       // Increment sl by sl + JumpingStopPips.
       // This will happen when market price >= (sl + JumpingStopPips)
       //if (Bid>= sl + ((JumpingStopPips*2) / factor) )
       if (CloseEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
       if (Bid >=  sl + ((JumpingStopPips * 2) / factor) )//George{
       {
          NewStop = NormalizeDouble(sl + (JumpingStopPips / factor), Digits);
          if (AddBEP) NewStop = NormalizeDouble(NewStop + (BreakEvenProfit / factor), Digits);
          if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
          if (NewStop - OrderStopLoss() >= Point) modify = true;//George again. What a guy
       }// if (Bid>= sl + (JumpingStopPips / factor) && sl>= OrderOpenPrice())     
    }//if (OrderType()==OP_BUY)
       
       if (OrderType()==OP_SELL)
       {
          if (sl > OrderOpenPrice() ) return;//Not at breakeven yet
          // Decrement sl by sl - JumpingStopPips.
          // This will happen when market price <= (sl - JumpingStopPips)
          //if (Bid<= sl - ((JumpingStopPips*2) / factor)) Original code
          if (CloseEnough(sl, 0) ) sl = MathMin(OrderStopLoss(), OrderOpenPrice());
          if (CloseEnough(sl, 0) ) sl = OrderOpenPrice();
          if (Bid <= sl - ((JumpingStopPips * 2) / factor) )//George
          {
             NewStop = NormalizeDouble(sl - (JumpingStopPips / factor), Digits);
             if (AddBEP) NewStop = NormalizeDouble(NewStop - (BreakEvenProfit / factor), Digits);
             if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
             if (OrderStopLoss() - NewStop >= Point || OrderStopLoss() == 0) modify = true;//George again. What a guy   
          }// close if (Bid>= sl + (JumpingStopPips / factor) && sl>= OrderOpenPrice())         
       }//if (OrderType()==OP_SELL)



   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);      
   }//if (modify)

} //End of JumpingStopLoss sub

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStopLoss(int ticket)
{

   //Security check
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
   
   if (OrderProfit() < 0) return;//Nothing to do
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   //if (CloseEnough(sl, 0) ) return;//No line, so nothing to do
   if (CloseEnough(sl, 0) ) sl = OrderStopLoss();
   double NewStop=0;
   bool modify=false;
   bool result;
   
    if (OrderType()==OP_BUY)
       {
          if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
          // Increment sl by sl + TrailingStopPips.
          // This will happen when market price >= (sl + JumpingStopPips)
          //if (Bid>= sl + (TrailingStopPips / factor) ) Original code
          if (CloseEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
          if (Bid >= sl + (TrailingStopPips / factor) )//George
          {
             NewStop = NormalizeDouble(sl + (TrailingStopPips / factor), Digits);
             if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
             if (NewStop - OrderStopLoss() >= Point) modify = true;//George again. What a guy
          }//if (Bid >= MathMax(sl,OrderOpenPrice()) + (TrailingStopPips / factor) )//George
       }//if (OrderType()==OP_BUY)
       
       if (OrderType()==OP_SELL)
       {
          if (sl > OrderOpenPrice() ) return;//Not at breakeven yet
          // Decrement sl by sl - TrailingStopPips.
          // This will happen when market price <= (sl - JumpingStopPips)
          //if (Bid<= sl - (TrailingStopPips / factor) ) Original code
          if (CloseEnough(sl, 0) ) sl = MathMin(OrderStopLoss(), OrderOpenPrice());
          if (CloseEnough(sl, 0) ) sl = OrderOpenPrice();
          if (Bid <= sl  - (TrailingStopPips / factor))//George
          {
             NewStop = NormalizeDouble(sl - (TrailingStopPips / factor), Digits);
             if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
             if (OrderStopLoss() - NewStop >= Point || OrderStopLoss() == 0) modify = true;//George again. What a guy   
          }//if (Bid <= MathMin(sl, OrderOpenPrice() ) - (TrailingStopPips / factor) )//George
       }//if (OrderType()==OP_SELL)


   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
   }//if (modify)
      
} // End of TrailingStopLoss sub
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CandlestickTrailingStop(int ticket)
{

   //Security check
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
   
   //Trails the stop at the hi/lo of the previous candle shifted by the user choice.
   //Only tries to do this once per bar, so an invalid stop error will only be generated once. I could code for
   //a too-close sl, but cannot be arsed. Coders, sort this out for yourselves.
   
   if (OldCstBars == iBars(NULL, CstTimeFrame)) return;
   OldCstBars = iBars(NULL, CstTimeFrame);

   if (OrderProfit() < 0) return;//Nothing to do
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(sl, 0) ) sl = OrderStopLoss();
   double NewStop=0;
   bool modify=false;
   bool result;
   

   if (OrderType() == OP_BUY)
   {
      if (iLow(NULL, CstTimeFrame, CstTrailCandles) > sl)
      {
         NewStop = NormalizeDouble(iLow(NULL, CstTimeFrame, CstTrailCandles), Digits);
         //Check that the new stop is > the old. Exit the function if not.
         if (NewStop < OrderStopLoss() || CloseEnough(NewStop, OrderStopLoss()) ) return;
         //Check that the new stop locks in profit, if the user requires this.
         if (TrailMustLockInProfit && NewStop < OrderOpenPrice() ) return;
         
         if (HiddenPips > 0) 
         {
            ObjectMove(LineName, 0, Time[0], NewStop);
            NewStop = NormalizeDouble(NewStop - (HiddenPips / factor), Digits);
         }//if (HiddenPips > 0) 
         modify = true;   
      }//if (iLow(NULL, CstTimeFrame, CstTrailCandles) > sl)
   }//if (OrderType == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      if (iHigh(NULL, CstTimeFrame, CstTrailCandles) < sl)
      {
         NewStop = NormalizeDouble(iHigh(NULL, CstTimeFrame, CstTrailCandles), Digits);
         
         //Check that the new stop is < the old. Exit the function if not.
         if (NewStop > OrderStopLoss() || CloseEnough(NewStop, OrderStopLoss()) ) return;
         //Check that the new stop locks in profit, if the user requires this.
         if (TrailMustLockInProfit && NewStop > OrderOpenPrice() ) return;
         
         if (HiddenPips > 0) 
         {
            ObjectMove(LineName, 0, Time[0], NewStop);
            NewStop = NormalizeDouble(NewStop + (HiddenPips / factor), Digits);
         }//if (HiddenPips > 0) 
         modify = true;   
      }//if (iHigh(NULL, CstTimeFrame, CstTrailCandles) < sl)
   }//if (OrderType() == OP_SELL)
   
   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
      if (!result) 
      {
         OldCstBars = 0;
      }//if (!result) 
      
   }//if (modify)

}//End void CandlestickTrailingStop()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeManagementModule(int ticket)
{

   // Call the working subroutines one by one. 

   //Candlestick trailing stop
   if(UseCandlestickTrailingStop) CandlestickTrailingStop(ticket);

   // Breakeven
   if(BreakEven) BreakEvenStopLoss(ticket);

   // JumpingStop
   if(JumpingStop) JumpingStopLoss(ticket);

   //TrailingStop
   if(TrailingStop) TrailingStopLoss(ticket);


}//void TradeManagementModule()
//END TRADE MANAGEMENT MODULE
////////////////////////////////////////////////////////////////////////////////////////

double CalculateTradeProfitInPips(int type)
{
   //This code supplied by Lifesys. Many thanks Paul.
   
   //Returns the pips Upl of the currently selected trade. Called by CountOpenTrades()
   double profit=0;
   // double point = BrokerPoint(OrderSymbol() ); // no real use
   double ask = MarketInfo(OrderSymbol(), MODE_ASK);
   double bid = MarketInfo(OrderSymbol(), MODE_BID);

   if (type == OP_BUY)
   {
      profit = bid - OrderOpenPrice();
   }//if (OrderType() == OP_BUY)

   if (type == OP_SELL)
   {
      profit = OrderOpenPrice() - ask;
   }//if (OrderType() == OP_SELL)
   //profit *= PFactor(OrderSymbol()); // use PFactor instead of point. This line for multi-pair ea's
   profit *= factor; // use PFactor instead of point.

   return(profit); // in real pips
}//double CalculateTradeProfitInPips(int type)

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

/*double PFactor(string symbol)
{
   //This code supplied by Lifesys. Many thanks Paul - we all owe you. Gary was trying to make me see this, but I could not understand his explanation. Paul used Janet and John words
   
   for ( int i = ArraySize(pipFactor)-1; i >=0; i-- ) 
      if (StringFind(symbol,pipFactor[i],0) != -1) 
         return (pipFactors[i]);
   return(10000);

}//End double PFactor(string pair)
*/

void GetSwap(string symbol)
{
   LongSwap = MarketInfo(symbol, MODE_SWAPLONG);
   ShortSwap = MarketInfo(symbol, MODE_SWAPSHORT);

}//End void GetSwap()

bool TooClose()
{
   //Returns false if the previously closed trade and the proposed new trade are sufficiently far apart, else return true. Called from IsTradeAllowed().
   
   SafetyViolation = false;//For chart feedback
         
   if (OrdersHistoryTotal() == 0) return(false);
   
   for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderSymbol() != Symbol() ) continue;
      
      //Examine the OrderCloseTime to see if it closed far enought back in time.
      if (TimeCurrent() - OrderCloseTime() < (MinMinutesBetweenTrades * 60))
      {
         SafetyViolation = true;
         return(true);//Too close, so disallow the trade
      }//if (OrderCloseTime() - TimeCurrent() < (MinMinutesBetweenTrades * 60))
      break;      
   }//for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   
   //Got this far, so there is no disqualifying trade in the history
   return(false);
   
}//bool TooClose()

bool IsClosedTradeRogue()
{
   //~ Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Detect a closed trade and check that is was not a rogue. Examine trades closed within the last 5 minutes.
   
   //~ If it is a rogue:
   //~ * Show a warning alert.
   //~ * Send an email alert.
   //~ * Suspend the robot
   
   if (OrdersHistoryTotal() == 0) return(false);
   
   datetime latestTime = TimeCurrent() - ( 5 * 60 );
  
   datetime duration = -1; //impossible value
  
   //We cannot guarantee that the most recent trade shown in our History tab is actually the most recent on the crim's server - CraptT4 again. pah has supplied this code to ensure that we are examining the latest trade. Many thanks, Paul.
   
   // look for trades that closed within the last 5 minutes
   // otherwise we will always find the last rogue trade
   // even when that happened some time ago and can be ignored
   
   for ( int i = OrdersHistoryTotal()-1; i >= 0; i-- )
   {
      if ( ! BetterOrderSelect(i, SELECT_BY_POS, MODE_HISTORY) ) continue;
       
      if ( OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() ) continue;
        
      if ( OrderCloseTime() >= latestTime )
      {
         latestTime = OrderCloseTime();
         duration    = OrderCloseTime() - OrderOpenTime();
      }//if ( OrderCloseTime() >= latestTime )
       
   }//for ( int i = OrdersHistoryTotal()-1; i >= 0; i-- )
   
  
   bool rogue = ( duration >= 0 ) && ( duration < ( MinMinutesBetweenTradeOpenClose * 60) );
  
   if (rogue)
   {
      RobotSuspended = true;
      Alert(Symbol(), " ", WindowExpertName() , " possible rogue trade.");
      SendMail("Possible rogue trade warning ", Symbol() + " " + WindowExpertName() + " possible rogue trade.");
      Comment(NL, Gap, "****************** ROBOT SUSPENDED. POSSIBLE ROGUE TRADING ACTIVITY. REMOVE THIS EA IMMEDIATELY ****************** ");
      return(true);//Too close, so disallow the trade
   
   }//if (rogue)
   
   //Got this far, so there is no rogue trade
   return(false);
   


}//bool IsClosedTradeRogue()

void DrawTrendLine(string name, datetime time1, double val1, datetime time2, double val2, color col, int width, int style, bool ray)
{
   //Plots a trendline with the given parameters
//Alert(name);   
   ObjectDelete(name);
   
   if (!ObjectCreate(name, OBJ_TREND, 0, time1, val1, time2, val2) )
   {
      ReportError(__FUNCTION__, "Trend line ObjectCreate failure");
      return;
   }//if (!ObjectCreate(name, OBJ_TREND, 0, time1, val1, time2, val2) )
   ObjectSet(name, OBJPROP_COLOR, col);
   ObjectSet(name, OBJPROP_WIDTH, width);
   ObjectSet(name, OBJPROP_STYLE, style);
   ObjectSet(name, OBJPROP_RAY, ray);
   
}//End void DrawLine()

void DrawHorizontalLine(string name, double price, color col, int style, int width)
{
   
   ObjectDelete(name);
   
   ObjectCreate(name, OBJ_HLINE, 0, TimeCurrent(), price);
   ObjectSet(name, OBJPROP_COLOR, col);
   ObjectSet(name, OBJPROP_STYLE, style);
   ObjectSet(name, OBJPROP_WIDTH, width);
   

}//void DrawLine(string name, double price, color col)

void DrawVerticalLine(string name, datetime time, color col,int style,int width)
{
   //ObjectCreate(vline,OBJ_VLINE,0,iTime(NULL, TimeFrame, 0), 0);
   ObjectDelete(name);
   ObjectCreate(name,OBJ_VLINE,0,time,0);
   ObjectSet(name,OBJPROP_COLOR,col);
   ObjectSet(name,OBJPROP_STYLE,style);
   ObjectSet(name,OBJPROP_WIDTH,width);

}//void DrawVerticalLine()

bool MarginCheck()
{

   EnoughMargin = true;//For user display
   MarginMessage = "";
   if (UseScoobsMarginCheck && OpenTrades > 0)
   {
      if(AccountMargin() > (AccountFreeMargin()/100)) 
      {
         MarginMessage = "There is insufficient margin to allow trading. You might want to turn off the UseScoobsMarginCheck input.";
         return(false);
      }//if(AccountMargin() > (AccountFreeMargin()/100)) 
      
   }//if (UseScoobsMarginCheck)


   if (UseForexKiwi && AccountMargin() > 0)
   {
      
      double ml = NormalizeDouble(AccountEquity() / AccountMargin() * 100, 2);
      if (ml < FkMinimumMarginPercent)
      {
         MarginMessage = StringConcatenate("There is insufficient margin percent to allow trading. ", DoubleToStr(ml, 2), "%");
         return(false);
      }//if (ml < FkMinimumMarginPercent)
   }//if (UseForexKiwi && AccountMargin() > 0)
   
  
   //Got this far, so there is sufficient margin for trading
   return(true);
}//End bool MarginCheck()

string PeriodText(int period)
{

	switch (period)
	{
   	case PERIOD_M1:
   		return("M1");
   	case PERIOD_M5:
   		return("M5");
   	case PERIOD_M15:
   		return("M15");
   	case PERIOD_M30:
   		return("M30");
   	case PERIOD_H1:
   		return("H1");
   	case PERIOD_H4:
   		return("H4");
   	case PERIOD_D1:
   		return("D1");
   	case PERIOD_MN1:
   		return("MN1");
   	default:
   		return("");
	}

}//End string PeriodText(int period)


//+------------------------------------------------------------------+
//  Code to check that there are at least 100 bars of history in
//  the sym / per in the passed params
//+------------------------------------------------------------------+
bool HistoryOK(string sym,int period)
{

	double tempArray[][6];  //used for the call to ArrayCopyRates()

    //get the number of bars
	int bars = iBars(sym,period);
	//and report it in the log
	Print("Checking ",sym," for complete data.... number of ",PeriodText(period)," bars = ",bars);

	if (bars < 100)
	{   
	    //we didn't have enough, so set the comment and try to trigger the DL another way
		Comment("Symbol ",sym," -- Waiting for "+PeriodText(period)+" data.");
		ArrayCopyRates(tempArray,sym,period);
		int error=GetLastError();
		if (error != 0) Print(sym," - requesting data from the server...");

      //return false so the caller knows we don't have the data
		return(false);
	}//if (bars < 100)
	
	//if we got here, the data is fine, so clear the comment and return true
	Comment("");
	return(true);

}//End bool HistoryOK(string sym,int period)



void CheckTpSlAreCorrect(int type)
{
   //Looks at an open trade and checks to see that the exact tp/sl were sent with the trade.
   
   //Diad makes this function work incorrectly if >1 trades are open
   if (UseDiadStyleTrading)
      if (OpenTrades >= 1)
         return;
   
   double stop = 0, take = 0, diff = 0;
   bool ModifyStop = false, ModifyTake = false;
   bool result;
   
   //Is the stop at BE?
   if (type == OP_BUY && OrderStopLoss() >= OrderOpenPrice() ) return;
   if (type == OP_SELL && OrderStopLoss() <= OrderOpenPrice() ) return;
   
   if (type == OP_BUY)
   {
      if (!CloseEnough(OrderStopLoss(), 0) )
      {
         diff = (OrderOpenPrice() - OrderStopLoss()) * factor;
         if (!CloseEnough(diff, StopLoss + (HiddenPips / factor))) 
         {
            ModifyStop = true;
            stop = CalculateStopLoss(OP_BUY, OrderOpenPrice());
         }//if (!CloseEnough(diff, StopLoss) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      

      if (!CloseEnough(OrderTakeProfit(), 0) )
      {
         diff = (OrderTakeProfit() - OrderOpenPrice()) * factor;
         if (!CloseEnough(diff, TakeProfit -  (HiddenPips / factor))) 
         {
            ModifyTake = true;
            take = CalculateTakeProfit(OP_BUY, OrderOpenPrice());
         }//if (!CloseEnough(diff, TakeProfit) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      
   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(OrderStopLoss(), 0) )
      {
         diff = (OrderStopLoss() - OrderOpenPrice() ) * factor;
         if (!CloseEnough(diff, StopLoss -  (HiddenPips / factor))) 
         {
            ModifyStop = true;
            stop = CalculateStopLoss(OP_SELL, OrderOpenPrice());

         }//if (!CloseEnough(diff, StopLoss) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      

      if (!CloseEnough(OrderTakeProfit(), 0) )
      {
         diff = (OrderOpenPrice() - OrderTakeProfit() ) * factor;
         if (!CloseEnough(diff, TakeProfit +  (HiddenPips / factor))) 
         {
            ModifyTake = true;
            take = CalculateTakeProfit(OP_SELL, OrderOpenPrice());
         }//if (!CloseEnough(diff, TakeProfit) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      
   }//if (type == OP_SELL)
   
   if (ModifyStop)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (ModifyStop)
   
   if (ModifyTake)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, tpm);
   }//if (ModifyStop)
   

}//void CheckTpSlAreCorrect(int type)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//START OF PAUL'S (Baluda) Lib.CSS module
//Thank you, Paul, for providing the code and showing me how to use it. I am deeply grateful.
//Coders, go to http://www.stevehopwoodforex.com/phpBB3/viewtopic.php?f=45&t=2905 to read about implementing calls to the library. You might prefer the #include method, but you then have to atach the Lib.CSS to your post should you be coding an EA for wider release than just for your own use, and tell readers where it goes.

//+------------------------------------------------------------------+
//|                                                       LibCSS.mq4 |
//|                      Copyright 2013, Deltabron - Paul Geirnaerdt |
//|                                          http://www.deltabron.nl |
//+------------------------------------------------------------------+

#define libCSSversion            "v1.1.2"
#define libCSSEPSILON            0.00000001
#define libCSSCURRENCYCOUNT      8

//+------------------------------------------------------------------+
//| Release Notes                                                    |
//+------------------------------------------------------------------+
// v1.0.0, 5/7/13
// * Initial release
// * NanningBob's 10.5 rules apply
// v1.1.0, 8/2/13
// * Added getSlopeRSI
// * Changed to original NB rules
// v1.1.1, 8/5/13
// * Added getGlobalMarketTrend
// * Added parameters for caching mechanism
// v1.1.2, 9/6/13
// * Added flushCache parameter

bool    libCSSsundayCandlesDetected    = false;
bool    libCSSaddSundayToMonday        = false;
bool    libCSSuseOnlySymbolOnChart     = false;
string  libCSScacheSymbol              = "EURUSD";
int     libCSScacheTimeframe           = PERIOD_M1;
string  libCSSsymbolsToWeigh           = "GBPNZD,EURNZD,GBPAUD,GBPCAD,GBPJPY,GBPCHF,CADJPY,EURCAD,EURAUD,USDCHF,GBPUSD,EURJPY,NZDJPY,AUDCHF,AUDJPY,USDJPY,EURUSD,NZDCHF,CADCHF,AUDNZD,NZDUSD,CHFJPY,AUDCAD,USDCAD,NZDCAD,AUDUSD,EURCHF,EURGBP";
int     libCSSsymbolCount;
string  libCSSsymbolNames[];
string  libCSScurrencyNames[libCSSCURRENCYCOUNT]        = { "USD", "EUR", "GBP", "CHF", "JPY", "AUD", "CAD", "NZD" };
double  libCSScurrencyValues[libCSSCURRENCYCOUNT];      // Currency slope strength
double  libCSScurrencyOccurrences[libCSSCURRENCYCOUNT]; // Holds the number of occurrences of each currency in symbols

//+------------------------------------------------------------------+
//| libCSSinit()                                                    |
//+------------------------------------------------------------------+
void libCSSinit()
{
   libCSSinitSymbols();

   libCSSsundayCandlesDetected = false;
   for ( int i = 0; i < 8; i++ )
   {
      if ( TimeDayOfWeek( iTime( NULL, PERIOD_D1, i ) ) == 0 )
      {
         libCSSsundayCandlesDetected = true;
         break;
      }
   }
  
   return;
}
//+------------------------------------------------------------------+
//| Initialize Symbols Array                                         |
//+------------------------------------------------------------------+
int libCSSinitSymbols()
{
   int i = 0;
   int size = 0;
   
   // Get extra characters on this crimmal's symbol names
   string symbolExtraChars = StringSubstrOld(Symbol(), 6, 4);

   // Trim user input
   libCSSsymbolsToWeigh = StringTrimLeft(libCSSsymbolsToWeigh);
   libCSSsymbolsToWeigh = StringTrimRight(libCSSsymbolsToWeigh);

   // Add extra comma
   if (StringSubstrOld(libCSSsymbolsToWeigh, StringLen(libCSSsymbolsToWeigh) - 1) != ",")
   {
      libCSSsymbolsToWeigh = StringConcatenate(libCSSsymbolsToWeigh, ",");   
   }   

   // Split user input
   i = StringFind( libCSSsymbolsToWeigh, "," ); 
   while ( i != -1 )
   {
      size = ArraySize(libCSSsymbolNames);
      string newSymbol = StringConcatenate(StringSubstrOld(libCSSsymbolsToWeigh, 0, i), symbolExtraChars);
      if ( MarketInfo( newSymbol, MODE_TRADEALLOWED ) > libCSSEPSILON )
      {
         ArrayResize( libCSSsymbolNames, size + 1 );
         // Set array
         libCSSsymbolNames[size] = newSymbol;
      }
      // Trim symbols
      libCSSsymbolsToWeigh = StringSubstrOld(libCSSsymbolsToWeigh, i + 1);
      i = StringFind(libCSSsymbolsToWeigh, ","); 
   }
   
   // Kill unwanted symbols from array
   if ( libCSSuseOnlySymbolOnChart )
   {
      libCSSsymbolCount = ArraySize(libCSSsymbolNames);
      string tempNames[];
      for ( i = 0; i < libCSSsymbolCount; i++ )
      {
         for ( int j = 0; j < libCSSCURRENCYCOUNT; j++ )
         {
            if ( StringFind( Symbol(), libCSScurrencyNames[j] ) == -1 )
            {
               continue;
            }
            if ( StringFind( libCSSsymbolNames[i], libCSScurrencyNames[j] ) != -1 )
            {  
               size = ArraySize( tempNames );
               ArrayResize( tempNames, size + 1 );
               tempNames[size] = libCSSsymbolNames[i];
               break;
            }
         }
      }
      for ( i = 0; i < ArraySize( tempNames ); i++ )
      {
         ArrayResize( libCSSsymbolNames, i + 1 );
         libCSSsymbolNames[i] = tempNames[i];
      }
   }
   
   libCSSsymbolCount = ArraySize(libCSSsymbolNames);
   // Print("symbolCount: ", symbolCount);

   ArrayInitialize( libCSScurrencyOccurrences, 0.0 );
   for ( i = 0; i < libCSSsymbolCount; i++ )
   {
      // Increase currency occurrence
      int currencyIndex = libCSSgetCurrencyIndex(StringSubstrOld(libCSSsymbolNames[i], 0, 3));
      libCSScurrencyOccurrences[currencyIndex]++;
      currencyIndex = libCSSgetCurrencyIndex(StringSubstrOld(libCSSsymbolNames[i], 3, 3));
      libCSScurrencyOccurrences[currencyIndex]++;
   }  
   return(0); 
}

//+------------------------------------------------------------------+
//| getCurrencyIndex(string currency)                                |
//+------------------------------------------------------------------+
int libCSSgetCurrencyIndex(string currency)
{
   for (int i = 0; i < libCSSCURRENCYCOUNT; i++)
   {
      if (libCSScurrencyNames[i] == currency)
      {
         return(i);
      }   
   }   
   return (-1);
}

//+------------------------------------------------------------------+
//| getSlope()                                                       |
//+------------------------------------------------------------------+
double libCSSgetSlope( string symbol, int tf, int shift )
{
   double dblTma, dblPrev;
   int shiftWithoutSunday = shift;
   if ( libCSSaddSundayToMonday && libCSSsundayCandlesDetected && tf == PERIOD_D1 )
   {
      if ( TimeDayOfWeek( iTime( symbol, PERIOD_D1, shift ) ) == 0  ) shiftWithoutSunday++;
   }   
   double atr = iATR(symbol, tf, 100, shiftWithoutSunday + 10) / 10;
   double gadblSlope = 0.0;
   if ( atr != 0 )
   {
      dblTma = libCSScalcTmaTrue( symbol, tf, shiftWithoutSunday );
      dblPrev = libCSScalcPrevTrue( symbol, tf, shiftWithoutSunday );
      gadblSlope = ( dblTma - dblPrev ) / atr;
   }

   return ( gadblSlope );
}
//+------------------------------------------------------------------+
//| calcTmaTrue()                                                    |
//+------------------------------------------------------------------+
double libCSScalcTmaTrue( string symbol, int tf, int inx )
{
   return ( iMA( symbol, tf, 21, 0, MODE_LWMA, PRICE_CLOSE, inx ) );
}

//+------------------------------------------------------------------+
//| calcPrevTrue()                                                   |
//+------------------------------------------------------------------+
double libCSScalcPrevTrue( string symbol, int tf, int inx )
{
   double dblSum  = iClose( symbol, tf, inx + 1 ) * 21;
   double dblSumw = 21;
   int jnx, knx;
   
   dblSum  += iClose( symbol, tf, inx ) * 20;
   dblSumw += 20;
         
   for ( jnx = 1, knx = 20; jnx <= 20; jnx++, knx-- )
   {
      dblSum  += iClose( symbol, tf, inx + 1 + jnx ) * knx;
      dblSumw += knx;
   }
   
   return ( dblSum / dblSumw );
}
 
//+------------------------------------------------------------------+
//| getCSS( double& CSS[], int tf, int shift )                       |
//+------------------------------------------------------------------+
void libCSSgetCSS( double& css[], int tf, int shift, bool flushCache = true )
{
   static double volume;
   int i = 0;
      
   if ( flushCache || volume != iVolume(libCSScacheSymbol, libCSScacheTimeframe, 0) )
   {
      
      ArrayInitialize(libCSScurrencyValues, 0.0);

      // Get Slope for all symbols and totalize for all currencies   
      for ( i = 0; i < libCSSsymbolCount; i++ )
      {
         double slope = libCSSgetSlope(libCSSsymbolNames[i], tf, shift);
         libCSScurrencyValues[libCSSgetCurrencyIndex(StringSubstrOld(libCSSsymbolNames[i], 0, 3))] += slope;
         libCSScurrencyValues[libCSSgetCurrencyIndex(StringSubstrOld(libCSSsymbolNames[i], 3, 3))] -= slope;
      }
      ArrayResize( css, libCSSCURRENCYCOUNT );
      for ( i = 0; i < libCSSCURRENCYCOUNT; i++ )
      {
         // average
         if ( libCSScurrencyOccurrences[i] > 0 ) libCSScurrencyValues[i] /= libCSScurrencyOccurrences[i]; else libCSScurrencyValues[i] = 0;
      }
   }
   for ( i = 0; i < libCSSCURRENCYCOUNT; i++ )
   {
      css[i] = libCSScurrencyValues[i];
   }
   volume = (double)iVolume( libCSScacheSymbol, libCSScacheTimeframe, 0 );
}
//+------------------------------------------------------------------+
//| getCSSCurrency(string currency, int tf, int shift)               |
//+------------------------------------------------------------------+
double libCSSgetCSSCurrency( string currency, int tf, int shift )
{
   double css[];
   libCSSgetCSS( css, tf, shift, true );
   return ( css[libCSSgetCurrencyIndex(currency)] );
}

//+------------------------------------------------------------------+
//| getCSSdiff(int tf, int shift)                                    |
//+------------------------------------------------------------------+
double libCSSgetCSSDiff( string symbol, int tf, int shift )
{
   double css[];
   libCSSgetCSS( css, tf, shift, true );
   double diffLong = css[libCSSgetCurrencyIndex(StringSubstrOld(symbol, 0, 3))];
   double diffShort = css[libCSSgetCurrencyIndex(StringSubstrOld(symbol, 3, 3))];
   return ( diffLong - diffShort );
}

//+------------------------------------------------------------------+
//| getSlopeRSI( string symbol, int tf, int shift )                  |
//+------------------------------------------------------------------+
double libCSSgetSlopeRSI( string symbol, int tf, int shift )
{
   double slope[];
   int workPeriod = 17;                                         // RSI period Bob's default = 2, + overhead
   ArrayResize( slope, workPeriod );
   ArraySetAsSeries( slope, true );
   for ( int i = 0; i < workPeriod; i++ )
   {
      slope[i] = libCSSgetSlope( symbol, tf, shift + i );
   }
   return( iRSIOnArray( slope, workPeriod, 2, 0 ) );            // Again, 2 is Bob's default
}

//+------------------------------------------------------------------+
//| getBBonStoch( string symbol, int tf, int shift )                 |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| getGlobalMarketTrend( int tf, int shift )                        |
//+------------------------------------------------------------------+
double libCSSgetGlobalMarketTrend( int tf, int shift ) 
{
   double buffer[libCSSCURRENCYCOUNT];
   libCSSgetCSS( buffer, tf, shift, true );
      
   double gmt = 0;
   for ( int i = 0; i < libCSSCURRENCYCOUNT; i++ )
   {
      gmt += MathPow(buffer[i], 2);
   }
   
   return ( gmt );
}

//+------------------------------------------------------------------+
//| NormalizeLots(string symbol, double lots)                        |
//+------------------------------------------------------------------+
//function added by fxdaytrader
//Lot size must be adjusted to be a multiple of lotstep, which may not be a power of ten on some brokers
//see also the original function by WHRoeder, http://forum.mql4.com/45425#564188, fxdaytrader
double NormalizeLots(string symbol, double lots) 
{
  if (MathAbs(lots)==0.0) return(0.0); //just in case ... otherwise it may happen that after rounding 0.0 the result is >0 and we have got a problem, fxdaytrader
  double ls = MarketInfo(symbol,MODE_LOTSTEP);
  lots = MathMin(MarketInfo(symbol,MODE_MAXLOT),MathMax(MarketInfo(symbol,MODE_MINLOT),lots)); //check if lots >= min. lots && <= max. lots, fxdaytrader
return(MathRound(lots/ls)*ls);
}

// for 6xx build compatibilità added by milanese
string StringSubstrOld(string x,int a,int b=-1) 
{
   if (a < 0) a= 0; // Stop odd behaviour
   if (b<=0) b = -1; // new MQL4 EOL flag
   return StringSubstr(x,a,b);
}//End string StringSubstrOld(string x,int a,int b=-1) 

void TakeChartSnapshot(int ticket, string oc)
{

   //Takes a snapshot of the chart after a trade open or close. Files are stored in the MQL4/Files folder
   //of the platform.
   
   //--- Prepare a text to show on the chart and a file name.
   //oc is either " open" or " close"
   string name="ChartScreenShot " + string(ticket) + oc + ".gif";
   
   //--- Save the chart screenshot in a file in the terminal_directory\MQL4\Files\
   if(ChartScreenShot(0,name, PictureWidth, PictureHeight, ALIGN_RIGHT))
      Alert("Screen snapshot taken ",name);
   //---
   

}//void TakeChartSnapshot()

void ShouldTradesBeClosed()
{
   //Examine baskets of trades for possible closure
   
   if (OpenTrades == 0)
      return;//Nothing to do

        
   int tries = 0;
   bool ClosePosition = false;

   //Resize the ForceCloseTickets[] array so it can be populated
   //by the ticket numbers of failed trade closures in CloseAllTrades.
   ArrayResize(ForceCloseTickets, 0);
   
   
   //Has the basket tp been hit?
   if (!CloseEnough(BasketTakeProfit, 0))
   {
      if (PipsUpl >= BasketTakeProfit && CashUpl > 0) //Calculated in CountOpenTrades()
      {
         Alert(Symbol(), " TP hit. Closing all trades. BasketTakeProfit = ", DoubleToStr(BasketTakeProfit, 0), ": Pips upl = " + DoubleToStr(PipsUpl, 0));
         tries = 0;//In case of an accidental endless loop
         ForceTradeClosure = true;
         while (ForceTradeClosure)
         {
            CloseAllTrades(AllTrades);
            tries++;
            if (tries >= 20)
            {
               break;
            }//if (tries >= 20)
         }//while (ForceTradeClosure)
         
         //Restock the grid
         if (RestockGridAfterTP)
         {
            if (MarketBuys > 0)
            {
               SendBuyGrid(Symbol(), OP_BUYSTOP, NormalizeDouble(Ask + (DistanceBetweenTrades / factor), Digits), Lot);
               if (UseHedgingWithGrid)
                  SendSellGrid(Symbol(), OP_SELLSTOP, NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits), Lot);
            }//if (MarketBuys > 0)
            
            if (MarketSells > 0)
            {
               SendSellGrid(Symbol(), OP_SELLSTOP, NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits), Lot);    
               if (UseHedgingWithGrid)
                  SendBuyGrid(Symbol(), OP_BUYSTOP, NormalizeDouble(Ask + (DistanceBetweenTrades / factor), Digits), Lot);           
            }//if (MarketSells > 0)
            
         }//if (RestockGridAfterTP)
                  
      }//if (PipsUpl >= BasketTakeProfit)
   
   }//if (!CloseEnough(BasketTakeProfit, 0))
   
   
   
   //HGI yellow wave
   if (HgiCloseOnYellowRangeWave)
      if (HgiTrendTimeFrameStatus == Waverange)
         if (!HgiOnlyCloseProfitablePositions || CashUpl > 0)
            ClosePosition = true;
    
      
   //Hedged position. Has it hit tp?
   if (!ClosePosition)
      if (Hedged)
      {
         
         //Have we hit pips upl
         if (HedgeProfitPips > 0)
            if (PipsUpl >= HedgeProfitPips)
               if (CashUpl > 0)
                  ClosePosition = true;
               
         //Have we hit cash upl
         if (!ClosePosition)   
            if (HedgeProfitCash > 0)
               if (CashUpl >= HedgeProfitCash)
                  ClosePosition = true;
            
      }//if (Hedged)
         
   if (ClosePosition)
   {
      tries = 0;
      ForceTradeClosure = true;
      while(ForceTradeClosure)
      {
         ForceTradeClosure = false;
         //All of these can be replaced by CloseAllTrades(AllTrades)            
         if (BuyOpen)
         {
            CloseAllTrades(OP_BUY);
            if (!ForceTradeClosure)
               BuyOpen = false;
         }//if (BuyOpen)         
         
         if (SellOpen)
         {
            CloseAllTrades(OP_SELL);
            if (!ForceTradeClosure)
               SellOpen = false;
         }//if (SellOpen)
         
         if (SellStopOpen)
         {
            CloseAllTrades(OP_SELLSTOP);
            if (!ForceTradeClosure)
               SellStopOpen = false;
         }//if (SellStopOpen)
         
         if (SellLimitOpen)
         {
            CloseAllTrades(OP_SELLLIMIT);
            if (!ForceTradeClosure)
               SellLimitOpen = false;
         }//if (SellLimitOpen)
         
         if (BuyStopOpen)
         {
            CloseAllTrades(OP_BUYSTOP);
            if (!ForceTradeClosure)
               BuyStopOpen = false;
         }//if (BuyStopOpen)
         
         if (BuyLimitOpen)
         {
            CloseAllTrades(OP_BUYLIMIT);   
            if (!ForceTradeClosure)
               BuyLimitOpen = false;         
         }//if (BuyLimitOpen)
            
            tries++;
            if (tries >= 100)
            {
               break;
            }//if (tries >= 100)
      }//while(ForceTradeClosure)
      return;
   }//if (ClosePosition)

   //Can younger winners be offset against the oldest loser?
   if (!FullyHedged)
      if (!Hedged || AllowOffsettingWhenHedged)
         if (UseOffsetting)
         {
            if (CanTradesBeOffset())
            {
               CountOpenTrades();
               return;
            }//if (CanTradesBeOffset())
            //In case any trade closures failed
            if (ArraySize(ForceCloseTickets) > 0)
            {
               MopUpTradeClosureFailures();
               return;
            }//if (ArraySize(ForceCloseTickets) > 0)      
         }//if (UseOffsetting)


   //I am not sure if we should allow the next routine
   //if we are fully hedged. Allow it for now.
   //if (FullyHedged)
      //return;   

   //Opposite direction trade signal or change of trend
   if (HgiCloseOnOppositeSignalOrTrendChange)
   {
      //Close buys following a sell signal/trend change.
      
      if (BuyOpen && (SellSignal || NewShortTrendDetected))
      {
         DebugPrint((string)__LINE__+"  "+(string)__FUNCTION__+" called CloseAllPossibleBuys"); CloseAllPossibleBuys();
         NewShortTrendDetected=false;
      }//if (BuyOpen && (SellSignal || HgiShortTrendDetected)))
      
      
      //Close sells following a buy signal/trend change.
      
      if (SellOpen && (BuySignal || NewLongTrendDetected))
      {
         DebugPrint((string)__LINE__+"  "+(string)__FUNCTION__+" called CloseAllPossibleSells"); CloseAllPossibleSells();
         NewLongTrendDetected=false;
      }//if (SellOpen && (BuySignal || HgiLongTrendDetected))
   
   }//if (HgiCloseOnOppositeSignalOrTrendChange)
           
}//void ShouldTradesBeClosed()

void CloseAllPossibleSells()
{

   int tries = 0;
   int cc = 0;
   int as = 0;
   bool result = true;

   //The easy one. The buy position is in profit
   if (!HgiOnlyCloseProfitablePositions || SellCashUpl >= 0)
   {
      tries = 0;
      ForceTradeClosure = true;
      while (ForceTradeClosure)
      {
         CloseAllTrades(OP_SELL);
         if (ForceTradeClosure)
         {
            MopUpTradeClosureFailures();
            tries++;
            if (tries >= 100)
               ForceTradeClosure = false;
         }//if (ForceTradeClosure)
      }//while (ForceTradeClosure)
      
      if (!UseHedgingWithGrid)
      {
         tries = 0;
         ForceTradeClosure = true;
         while (ForceTradeClosure)
         {
            CloseAllTrades(OP_SELLSTOP);
            if (ForceTradeClosure)
            {
               MopUpTradeClosureFailures();
               tries++;
               if (tries >= 100)
                  ForceTradeClosure = false;
            }//if (ForceTradeClosure)
         }//while (ForceTradeClosure)
      }//if (!UseHedgingWithGrid)
         
      
      //Full close succeeded
      if (!ForceTradeClosure)
      {
         CountOpenTrades();
         return;
      }//if (!ForceTradeClosure)
      
   }//if (!HgiOnlyCloseProfitablePositions || SellCashUpl > 0)
   
   //We will have got here only if the cash upl is negative, so
   //close profitable trades only
   
   as = 0;
   ArrayResize(ForceCloseTickets, 0);
   for (cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(FifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderType() != OP_SELL && OrderType() != OP_SELLSTOP) continue; 
      if (OrderType() == OP_SELLSTOP && UseHedgingWithGrid) continue;//Only delete stop orders when not hedging
      if ((OrderProfit() + OrderSwap() + OrderCommission() ) < 0)
         if (OrderType() == OP_SELL)
            continue;//We want to delete stop orders   
      
      
      if (OrderType() == OP_SELL)
      {
         if (MarketSellsCount <= MarketBuysCount) continue;//All sells are needed for hedging
         //if (CalculateTradeProfitInPips(OP_SELL) < DistanceBetweenTrades) continue;//Minimum profit for closure is grid distance
         for (int i=0; i<MarketBuysCount; i++)
            if (GridOrderSellTickets[i][TradeTicket] == OrderTicket()) continue;//This sell is needed for hedging
      }

      result = CloseOrder(OrderTicket());
      //Save the ticket in case the trade closure failed
      if (!result)
      {
         ArrayResize(ForceCloseTickets, as + 1);
         ForceCloseTickets[as] = OrderTicket();
         as++;
      }//if (!result)
   }//for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   if (ArraySize(ForceCloseTickets) > 0)
   {
      MopUpTradeClosureFailures();
      return;//The code deals with further closure/deletion failures
   }//if (ArraySize(ForceCloseTickets) > 0)
   
   //Rebuild the position picture
   CountOpenTrades();
   return;


}//End void CloseAllPossibleSells()

void CloseAllPossibleBuys()
{

   int tries = 0;
   int cc = 0;
   int as = 0;
   bool result = true;
   
   //The easy one. The buy position is in profit
   if (!HgiOnlyCloseProfitablePositions || BuyCashUpl >= 0)
   {
      tries = 0;
      ForceTradeClosure = true;
      while (ForceTradeClosure)
      {
         CloseAllTrades(OP_BUY);
         if (ForceTradeClosure)
         {
            MopUpTradeClosureFailures();
            tries++;
            if (tries >= 100)
               ForceTradeClosure = false;
         }//if (ForceTradeClosure)
      }//while (ForceTradeClosure)
      
      if (!UseHedgingWithGrid)
      {
         tries = 0;
         ForceTradeClosure = true;
         while (ForceTradeClosure)
         {
            CloseAllTrades(OP_BUYSTOP);
            if (ForceTradeClosure)
            {
               MopUpTradeClosureFailures();
               tries++;
               if (tries >= 100)
                  ForceTradeClosure = false;
            }//if (ForceTradeClosure)
         }//while (ForceTradeClosure)
      }//if (!UseHedgingWithGrid)
      
      
      //Full close succeeded
      if (!ForceTradeClosure)
      {
         CountOpenTrades();
         return;
      }//if (!ForceTradeClosure)
      
   }//if (!HgiOnlyCloseProfitablePositions || BuyCashUpl > 0)
   
   //We will have got here only if the cash upl is negative, so
   //close profitable trades only
   
   as = 0;
   ArrayResize(ForceCloseTickets, 0);
   for (cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(FifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderType() != OP_BUY && OrderType() != OP_BUYSTOP) continue; 
      if (OrderType() == OP_BUYSTOP && UseHedgingWithGrid) continue;//Only delete stop orders when not hedging
      if ((OrderProfit() + OrderSwap() + OrderCommission() ) < 0)
         if (OrderType() == OP_BUY)
            continue;//We want to delete stop orders   
   
      
      if (OrderType() == OP_BUY)
      {
         if (MarketBuysCount <= MarketSellsCount) continue;//All buys are needed for hedging
         //if (CalculateTradeProfitInPips(OP_BUY) < DistanceBetweenTrades) continue;//Minimum profit for closure is grid distance
         for (int i=0; i<MarketSellsCount; i++)
            if (GridOrderBuyTickets[ArraySize(GridOrderBuyTickets)-i-1][TradeTicket] == OrderTicket()) continue;//This buy is needed for hedging
      }

      result = CloseOrder(OrderTicket());
      //Save the ticket in case the trade closure failed
      if (!result)
      {
         ArrayResize(ForceCloseTickets, as + 1);
         ForceCloseTickets[as] = OrderTicket();
         as++;
      }//if (!result)
   }//for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   if (ArraySize(ForceCloseTickets) > 0)
   {
      MopUpTradeClosureFailures();
      return;//The code deals with further closure/deletion failures
   }//if (ArraySize(ForceCloseTickets) > 0)
   
   //Rebuild the position picture
   CountOpenTrades();
   return;


}//void CloseAllPossibleBuys()

bool CanTradesBeOffset()
{

   bool CloseTrades = false;
   
   double pips = 0;//The pips upl of the highest buy or lowest sell
   double loss = 0;//Convers pips to a positive value for comparison with (DistanceBetweenTrades / factor)
   double profit = 0;//Cash upl of the side being calculated to see if they can combine to close a loser on the other side
   int TradesToClose = 0;
   bool result = false;
   int cc = 0;
   double HighestTradeCash = 0;
   double LowestTradeCash = 0;
   int tries = 0;
   int cas = 0;//ForceCloseTickets array size
   
   double CashLoss = 0;
   double CashProfit = 0;
   int NoOfTrades = 0;
   double ThisOrderProfit = 0;
   bool ClosePossible = false;
   int ClosureTickets[];
   ArrayInitialize(ClosureTickets, -1);
   double ThisTradeProfit = 0;
   tries = 0;
   int as = 0;//Array size
   
   //Store the order price for filling the gap
   double OrderPrice = 0;
                               
   ArrayResize(ForceCloseTickets, 0);
   
   //Look for a simple offset opportunity of a losing buy at the
   //top of the pile by the winner at the bottom.
  
   if (MarketBuysCount > MinOpenTradesToStartOffset)//Impossible with < 4
   {
      //Do we have a losing buy?
      if (BetterOrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      {
         //Calculate the pips upl of the highest, and so latest, buy
         pips = CalculateTradeProfitInPips(OP_BUY);
         if (pips < 0)//Only continue if it is losing
         {
            loss = (pips * -1);//Turn the loss into a positive number for the comparison
            if (loss >= DistanceBetweenTrades)//Only continue if losing by at least 1 grid level
            {
               HighestTradeCash = OrderSwap() + OrderCommission() + OrderProfit();
               if (BetterOrderSelect(LowestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  LowestTradeCash = OrderSwap() + OrderCommission() + OrderProfit();
               
               //Make sure we are closing at an overall cash profit
               if ((HighestTradeCash + LowestTradeCash) > 0)
               {
                  //The higest buy trade is losing by at least one grid level, so close it and the lowest buy
                  if (BetterOrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  {
                     if (FillInGaps)
                        OrderPrice = OrderOpenPrice();
                     result = CloseOrder(HighestBuyTicketNo);
                     if (!result)
                     {
                        return(false);
                     }//if (!result)
                     if (FillInGaps)
                        SendSingleTrade(Symbol(), OP_BUYSTOP, TradeComment, Lot, OrderPrice, 0,0);
                  }//if (BetterOrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     
                  if (BetterOrderSelect(LowestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  {
                     result = false;
                     while (!result)
                     {
                        result = CloseOrder(LowestBuyTicketNo);
                        if (!result)
                        {
                           tries++;
                           if (tries >= 20)
                           {
                              //The closure attempt has failed, but must be retried.
                              //Save the ticket number in the array
                              ArrayResize(ForceCloseTickets, 1);
                              ForceCloseTickets[0] = LowestBuyTicketNo;
                              return(false);
                           }//if (tries >= 20)  
                        }//if (!result)
                        
                     }//while (!result)
                     
                  }//if (BetterOrderSelect(LowestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     
                  return(true);//Routine succeeded
                  
               }//if ((HighestTradeCash + LowestTradeCash) > 0)                  
            }//if (loss >= DistanceBetweenTrades)
            
         }//if (pips < 0)
      }//if (BetterOrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      ArrayResize(ForceCloseTickets, 0);
   }//if (MarketBuysCount > 3)
     
   //Look for a simple offset opportunity of a losing sell at the
   //bottom of the pile by the winner at the top.
   if (MarketSellsCount > MinOpenTradesToStartOffset)//Impossible with < 3
   {

      //Do we have a losing sell?
      if (BetterOrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      {
         //Calculate the pips upl of the lowest, and so latest, sell
         pips = CalculateTradeProfitInPips(OP_SELL);

         if (pips < 0)//Only continue if it is losing
         {
            loss = (pips * -1);//Turn the loss into a positive number for the comparison

            if (loss >= DistanceBetweenTrades)//Only continue if losing by at least 1 grid level
            {
               LowestTradeCash = OrderSwap() + OrderCommission() + OrderProfit();
               if (BetterOrderSelect(HighestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  HighestTradeCash = OrderSwap() + OrderCommission() + OrderProfit();

               if ((HighestTradeCash + LowestTradeCash) > 0)
               {
                  if (BetterOrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  {
                     if (FillInGaps)
                        OrderPrice = OrderOpenPrice();
                     result = CloseOrder(LowestSellTicketNo);
                     if (!result)
                     {
                        return(false);
                     }//if (!result)
                     if (FillInGaps)
                        SendSingleTrade(Symbol(), OP_SELLSTOP, TradeComment, Lot, OrderPrice, 0,0);
                  }//if (BetterOrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  
                  if (BetterOrderSelect(HighestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  {   
                     result = false;
                     tries = 0;
                     while (!result)
                     {
                        result = CloseOrder(HighestSellTicketNo);               
                        if (!result)
                        {
                           tries++;
                           if (tries >= 20)
                           {
                              //The closure attempt has failed, but must be retried.
                              //Save the ticket number in the array
                              ArrayResize(ForceCloseTickets, 1);
                              ForceCloseTickets[0] = HighestSellTicketNo;
                              return(false);
                           }//if (tries >= 20)  
                        }//if (!result)      
                     }//while (!result)
                  }//if (BetterOrderSelect(HighestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     
                  return(true);//Routine succeeded
                  
               }//if ((HighestTradeCash + LowestTradeCash) > 0)               
            }//if (loss >= DistanceBetweenTrades)
            
         }//if (pips < 0)
      }//if (BetterOrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      ArrayResize(ForceCloseTickets, 0);
          
   }//if (MarketSellsCount  > 3)
       
    
   ////////////////////////////////////////////////////////////////////////
   //Got this far, so see if the combined winners on one side can combine
   //to close a loser on the other side.
   
   /*if (Hedged)
   {
      
      //Can we offset some buy trades against the lowest losing sell trade
      if (BuyCashUpl > 0)//The buy side of the hedge must be profitable overall
         if (MarketBuysCount >= MinOpenTradesToStartOffset)//Must be sufficient trades open to start offsetting
            if (BetterOrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the lowest sell
            {
            
                //Calculate the pips upl of the lowest, and so latest, sell
                if((CalculateTradeProfitInPips(OP_SELL)*-1)>=DistanceBetweenTrades) // Only continue if the trade is losing by more than DistanceBetweenTrades
                {
          
                     CashLoss = (OrderSwap() + OrderCommission() + OrderProfit());//Calculate its cash position
                     if (CashLoss < 0)//Is it losing?
                     {
                        CashLoss*= -1;//Convert to a positive for comparison with the profit on the other side
                        //Calculate the profit on the other side of the hedge
                        for (cc = MarketBuysCount; cc > 0; cc--)
                        {
                           if (BetterOrderSelect(GridOrderBuyTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                           {
                              ThisTradeProfit = (OrderSwap() + OrderCommission() + OrderProfit());
                              if (ThisTradeProfit > 0)
                                 if (!CloseEnough(ThisTradeProfit, 0) )
                                 {
                                    NoOfTrades++;
                                    ArrayResize(ClosureTickets, NoOfTrades);
                                    ClosureTickets[NoOfTrades - 1] = OrderTicket();
                                    CashProfit+= ThisTradeProfit;
                                 }//if (!CloseEnough(CashProfit, 0) )
                           }//if (BetterOrderSelect(FifoBuyTicket[cc - 1][ticket], SELECT_BY_TICKET, MODE_TRADES) )
                           
                           //Is the profit big enough to close the trade on the other side of the hedge?
                           if (CashProfit >= CashLoss)
                           {
                              //Yippee
                              ClosePossible = true;
                              break;
                           }//if (CashProfit >= CashLoss)
                        }//for (int cc = MarketBuysCount; cc >= 0; cc--)
                        
                        //Are there closures to make?
                        if (ClosePossible)
                        {
                           ForceTradeClosure = true;
                           while (ForceTradeClosure)
                           {
                              ForceTradeClosure = false;
                              as = ArraySize(ClosureTickets) - 1;
                              if (BetterOrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                              {
                                 if (FillInGaps)
                                    OrderPrice = OrderOpenPrice();
                                 result = OrderCloseBy(LowestSellTicketNo, ClosureTickets[as]);
                                 if (!result)
                                   return(false);
                                 if (FillInGaps)
                                    SendSingleTrade(Symbol(), OP_SELLSTOP, TradeComment, Lot, OrderPrice, 0,0);                                 
                              }//if (BetterOrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                              
                              for (cc = ArraySize(ClosureTickets) - 2; cc >= 0; cc--)
                              {
                                 if (BetterOrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))
                                 {
                                   result = CloseOrder(ClosureTickets[cc]);
                                   //  Print("Double Sided Complex buy closure"); // for debugging
                                    if (!result)
                                    {
                                       ForceTradeClosure = true;
                                       cc++;
                                       if (tries >= 20)//Something has gone wrong
                                       {   
                                          //The closure attempt has failed, but must be retried.
                                          //Save the ticket number in the array
                                          cas = ArraySize(ForceCloseTickets);
                                          ArrayResize(ForceCloseTickets, cas + 1);
                                          ForceCloseTickets[cas] = ClosureTickets[cc];
                                          cc--;//In case something has gone wrong and the trade no longer exists
                                       }//if (tries >= 20)                                       
                                    }//if (!result)
                                 }//if (BetterOrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))                          
                              }//for (cc = ArraySize(ClosureTickets); cc >= 0; cc--)
                           }//while (ForceTradeClosure)
                           
                           if (ArraySize(ForceCloseTickets) == 0)
                           {
                              CountOpenTrades();
                              return(true);
                           }//if (ArraySize(ForceCloseTickets) == 0)
                           else
                           {
                              return(false);
                           }//else                              
                        }//if (ClosePossible)
                     }//if (CashLoss < 0)
                  }// if((CalculateTradeProfitInPips(OP_SELL)*-1)>=DistanceBetweenTrades)
            }//if (BetterOrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))
            
      CashLoss = 0;
      CashProfit = 0;
      NoOfTrades = 0;
      ClosePossible = false;
      ArrayResize(ClosureTickets, 0);
      ArrayInitialize(ClosureTickets, -1);
      ArrayResize(ForceCloseTickets, 0);
      tries = 0;

      //Can we offset some sell trades against the highest losing buy trade
      if (SellCashUpl > 0)//The sell side of the hedge must be profitable overall
         if (MarketSellsCount >= MinOpenTradesToStartOffset)//Must be sufficient trades open to start offsetting
            if (BetterOrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the highest buy
            {
               
               //Calculate the pips upl of the lowest, and so latest, sell
               if((CalculateTradeProfitInPips(OP_BUY)*-1)>=DistanceBetweenTrades) // Only continue if the trade is losing by more than DistanceBetweenTrades
               {
               
                  CashLoss = (OrderSwap() + OrderCommission() + OrderProfit());//Calculate its cash position
                  if (CashLoss < 0)//Is it losing?
                  {
                     CashLoss*= -1;//Convert to a positive for comparison with the profit on the other side
                     //Calculate the profit on the other side of the hedge
                     for (cc = 0; cc < MarketSellsCount; cc++)
                     {
                        if (BetterOrderSelect(GridOrderSellTickets[cc][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                        {
                           ThisTradeProfit = (OrderSwap() + OrderCommission() + OrderProfit());
                           if (ThisTradeProfit > 0)
                              if (!CloseEnough(ThisTradeProfit, 0) )
                              {
                                 NoOfTrades++;
                                 ArrayResize(ClosureTickets, NoOfTrades);
                                 ClosureTickets[NoOfTrades - 1] = OrderTicket();
                                 CashProfit+= ThisTradeProfit;
                              }//if (!CloseEnough(CashProfit, 0) )
                        }//if (BetterOrderSelect(FifoSellTicket[cc1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                        
                        //Is the profit big enough to close the trade on the other side of the hedge?
                        if (CashProfit >= CashLoss)
                        {
                           //Yippee
                           ClosePossible = true;
                           break;
                        }//if (CashProfit >= CashLoss)
                     }//for (cc = 0; cc < MarketSellsCount - 1; cc++)
                     
                     //Are there closures to make?
                     if (ClosePossible)
                     {
                        ForceTradeClosure = true;
                        while (ForceTradeClosure)
                        {
                           ForceTradeClosure = false;
                           if (BetterOrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                           {
                              if (FillInGaps)
                                 OrderPrice = OrderOpenPrice();
                              as = ArraySize(ClosureTickets) - 1;
                              result = OrderCloseBy(HighestBuyTicketNo, ClosureTickets[as]);
                              if (!result)
                                return(false);
                             if (FillInGaps)
                                 SendSingleTrade(Symbol(), OP_BUYSTOP, TradeComment, Lot, OrderPrice, 0,0);                                 
                                
                           }//if (BetterOrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                           
                           for (cc = ArraySize(ClosureTickets) - 2; cc >= 0; cc--)
                           {
                              if (BetterOrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))
                              {
                                 result = CloseOrder(ClosureTickets[cc]);
                                 // Print("Double Sided Complex sell closure"); // for debugging
                                 if (!result)
                                 {
                                    ForceTradeClosure = true;
                                    cc++;
                                    tries++;
                                    if (tries >= 20)//Something has gone wrong
                                    {   
                                       //The closure attempt has failed, but must be retried.
                                       //Save the ticket number in the array
                                       cas = ArraySize(ForceCloseTickets);
                                       ArrayResize(ForceCloseTickets, cas + 1);
                                       ForceCloseTickets[cas] = ClosureTickets[cc];
                                       cc--;//In case something has gone wrong and the trade no longer exists
                                    }//if (tries >= 20)    
                                 }//if (!result)
                              }//if (BetterOrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))                          
                           }//for (cc = ArraySize(ClosureTickets); cc >= 0; cc--)
                        }//while (ForceTradeClosure)
                        if (ArraySize(ForceCloseTickets) == 0)
                        {
                           CountOpenTrades();
                           return(true);
                        }//if (ArraySize(ForceCloseTickets) == 0)
                        else
                        {
                           return(false);
                        }//else                              
                     }//if (ClosePossible)
                  }//if (CashLoss < 0)
               }//if((CalculateTradeProfitInPips(OP_SELL)*-1)>=DistanceBetweenTrades)
            }//if (BetterOrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))
   
   }//if (Hedged)*/

//////////////////////////////////////////////////////////////////////////////////////
// Added complex single side offset below:


   if(AllowComplexSingleSidedOffsets)//then allow buy side single offsets
   {
       CashLoss = 0;
       CashProfit = 0;
       NoOfTrades = 0;
       ArrayResize(ForceCloseTickets, 0);
      
 
      ////////////////////////////////////////////////////////////////
      ///As above but one sided; complex hedge closure - looking for a group of winning buys to close the worst losing buy:     
      //Can we offset some buy trades against the worst losing buy trade?
      //if (BuyCashUpl > 0)//The buy side of the hedge must be profitable overall // not true for single sided
      
      // buy side only variables
      bool ClosePossibleBuySide = false;
      int ClosureTicketsBuySide[];
      ArrayInitialize(ClosureTicketsBuySide, -1);
      
      
      if (MarketBuysCount >= MinOpenTradesToStartOffset)//Must be sufficient trades open to start offsetting
         if (BetterOrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the highest buy which will be the worst loser
         {
         
            //Calculate the pips upl of the lowest, and so latest, sell
            if((CalculateTradeProfitInPips(OP_BUY)*-1)>=DistanceBetweenTrades) // Only continue if the trade is losing by more than DistanceBetweenTrades
            {
            
            CashLoss = (OrderSwap() + OrderCommission() + OrderProfit());//Calculate its cash position
            CashLoss*= -1;//Convert to a positive for comparison with the profit on the other side
            //if (CashLoss < 0)//Is it losing?  // changed to check for DistanceBetweenTrades
            if (CashLoss>0)//Only continue if losing by at least 1 grid level
            {
               //Calculate the profit on the other side of the hedge
               for (cc = MarketBuysCount; cc > 0; cc--)
               {
                  if (BetterOrderSelect((int)GridOrderBuyTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                  {
                     ThisOrderProfit = (OrderSwap() + OrderCommission() + OrderProfit());
                     
                     if (ThisOrderProfit > 0) // only want to include the trade if it is in profit - this also sorts out the trade order issue
                     {
                        NoOfTrades++;
                        ArrayResize(ClosureTicketsBuySide, NoOfTrades);
                        ClosureTicketsBuySide[NoOfTrades - 1] = OrderTicket();
                        CashProfit+= ThisOrderProfit;  // now we can add this trade's profit to the basket of offset trades
                     }// if (ThisOrderProfit > 0)
                  }//if (BetterOrderSelect(FifoBuyTicket[cc - 1][ticket], SELECT_BY_TICKET, MODE_TRADES) )
                  
                  //Is the profit big enough to close the trade on the other side of the hedge?
                  if ((CashProfit) > CashLoss)
                  {
                     //Yippee
                     ClosePossibleBuySide = true;
                     break; // stop for loop here as don't need any more trades
                  }//if ((CashProfit) > CashLoss)
               }//for (int cc = MarketBuysCount; cc >= 0; cc--)
               
               //Are there closures to make?
               if (ClosePossibleBuySide)
               {
                  ForceTradeClosure = true;
                  while (ForceTradeClosure)
                  {
                     ForceTradeClosure = false;
                     if (BetterOrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     {
                        if (FillInGaps)
                           OrderPrice = OrderOpenPrice();
                        result = CloseOrder(HighestBuyTicketNo);
                        if (!result)
                           return(false);
                        if (FillInGaps)
                           SendSingleTrade(Symbol(), OP_BUYSTOP, TradeComment, Lot, OrderPrice, 0,0);    
                     }//if (BetterOrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     
                     for (cc = ArraySize(ClosureTicketsBuySide) - 1; cc >= 0; cc--)
                     {
                        tries = 0;
                        if (BetterOrderSelect(ClosureTicketsBuySide[cc], SELECT_BY_TICKET, MODE_TRADES))
                        {
                           result = CloseOrder(ClosureTicketsBuySide[cc]);
                           // Print("Single Sided Complex buy closure"); // for debugging
                           
                           if (!result)
                           {                               
                              //The closure attempt has failed, but must be retried.
                              //Save the ticket number in the array
                              cas = ArraySize(ForceCloseTickets);
                              ArrayResize(ForceCloseTickets, cas + 1);
                              ForceCloseTickets[cas] = ClosureTicketsBuySide[cc];
                           }//if (!result)
                        }//if (BetterOrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))                          
                     }//for (cc = ArraySize(ClosureTickets); cc >= 0; cc--)
                  }//while (ForceTradeClosure)
                  if (ArraySize(ForceCloseTickets) == 0)
                  {
                     CountOpenTrades();
                     return(true);
                  }//if (ArraySize(ForceCloseTickets) == 0)
                  else
                  {
                     return(false);
                  }//else                              
               }// if (ClosePossibleBuySide)
            }//if (CashLoss >= DistanceBetweenTrades)
         }//if((CalculateTradeProfitInPips(OP_BUY)*-1)>=DistanceBetweenTrades)
      }//if (BetterOrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))
         
      CashLoss = 0;
      CashProfit = 0;
      NoOfTrades = 0;
      ClosePossibleBuySide = false;
      ArrayResize(ClosureTicketsBuySide, 0);
      ArrayInitialize(ClosureTicketsBuySide, -1);
   
   
      //END - buy side only complex hedge
   
      ///////////////////////////////////////////
 
 
      ///One Sided complex hedge closure - looking for a group of winning sells to close the worst losing sell:
      // sell side only variables
      bool ClosePossibleSellSide = false;
      ArrayInitialize(ClosureTicketsSellSide, -1);
      
      //Can we offset some sell trades against the lowest losing sell trade
      
      if (MarketSellsCount >= MinOpenTradesToStartOffset)//Must be sufficient trades open to start offsetting
         if (BetterOrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the lowest sell which will be the worst loser
         {
            
            //Calculate the pips upl of the lowest, and so latest, sell
            if((CalculateTradeProfitInPips(OP_SELL)*-1)>=DistanceBetweenTrades) // Only continue if the trade is losing by more than DistanceBetweenTrades
            {
               CashLoss = (OrderSwap() + OrderCommission() + OrderProfit());//Calculate its cash position
               CashLoss*= -1;//Convert to a positive for comparison with the profit on the other side
               
               //if (CashLoss < 0)//Is it losing?  // changed to check for DistanceBetweenTrades.
               if (CashLoss>0)//Only continue if losing by at least 1 grid level
               {
                  //Calculate the profit on the other side of the hedge
                  for (cc = MarketSellsCount; cc > 0; cc--)
                  {
                                          
                     if (BetterOrderSelect((int)GridOrderSellTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                     {
                         ThisOrderProfit = (OrderSwap() + OrderCommission() + OrderProfit());
                        
                        if (ThisOrderProfit > 0) // only want to include the trade if it is in profit
                        {
                           NoOfTrades++;
                           ArrayResize(ClosureTicketsSellSide, NoOfTrades);
                           ClosureTicketsSellSide[NoOfTrades - 1] = OrderTicket();
                           CashProfit+= ThisOrderProfit;  // now we can add this trade's profit to the basket of offset trades
                        }//if (ThisOrderProfit > 0)
                     }//if (BetterOrderSelect(GridOrderSellTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                     
                     //Is the profit big enough to close the trade on the other side of the hedge?
                     if ((CashProfit) > CashLoss)
                     {
                        //Yippee
                        ClosePossibleSellSide = true;
                        break; // stop here as don't need any more trades
                     }//if ((CashProfit) > CashLoss)
                  }//for (int cc = MarketSellsCount; cc >= 0; cc--)
                  
                  //Are there closures to make?
                  if (ClosePossibleSellSide)
                  {
                     ForceTradeClosure = true;
                     while (ForceTradeClosure)
                     {
                        ForceTradeClosure = false;
                        if (BetterOrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                        {
                           if (FillInGaps)
                              OrderPrice = OrderOpenPrice();
                           result = CloseOrder(LowestSellTicketNo);
                           if (!result)
                              return(false);//First trade has not closed, so do not continue
                           if (FillInGaps)
                              SendSingleTrade(Symbol(), OP_SELLSTOP, TradeComment, Lot, OrderPrice, 0,0);    
                        }//if (BetterOrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                        
                        for (cc = ArraySize(ClosureTicketsSellSide) - 1; cc >= 0; cc--)
                        {
                           tries = 0;
                           if (BetterOrderSelect(ClosureTicketsSellSide[cc], SELECT_BY_TICKET, MODE_TRADES))
                           {
                              result = CloseOrder(ClosureTicketsSellSide[cc]);
                              
                             // Print("Single Sided Complex sell closure"); // for debugging
                              if (!result)
                              {
                                    
                                 //The closure attempt has failed, but must be retried.
                                 //Save the ticket number in the array
                                 cas = ArraySize(ForceCloseTickets);
                                 ArrayResize(ForceCloseTickets, cas + 1);
                                 ForceCloseTickets[cas] = ClosureTicketsSellSide[cc];
                              }//if (!result)
                           }// if (BetterOrderSelect(ClosureTicketsSellSide[cc], SELECT_BY_TICKET, MODE_TRADES))                        
                        }//for (cc = ArraySize(ClosureTicketsSellSide) - 1; cc >= 0; cc--)
                     }//while (ForceTradeClosure)
                     if (ArraySize(ForceCloseTickets) == 0)
                     {
                        CountOpenTrades();
                        return(true);
                     }//if (ArraySize(ForceCloseTickets) == 0)
                     else
                     {
                        return(false);
                     }//else                              

                  }//if (ClosePossibleSellSide)
               }//if (CashLoss >= DistanceBetweenTrades)
            }//if((CalculateTradeProfitInPips(OP_SELL)*-1)>=DistanceBetweenTrades) 
         }//if (BetterOrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))
         
      CashLoss = 0;
      CashProfit = 0;
      NoOfTrades = 0;
   
   //END - sell side only complex hedge
   ///////////////////////////////////////////////////////////////////////////// 
   
 }// if(AllowComplexSingleSidedOffsets)



   //////// End of added single side offset
 
   /*
   Next is dydynamic's partial basket closure.
   In 'normal' trading buys will be above sells but a mixture of market movement
   gap filling and offsetting can leave a bunch of buys below the lowest sell.
   
   Imagine the market has fallen for a substantial period with sufficient
   yoyo to allow a large number of losing buys to trigger, that are hedged by
   winning sells.
      
   The market rises substantially, closing a lot of sells through offsetting. The
   profit from the winning buy at the bottom is insufficient to close the
   loser at the top. Some of the market buy trades are now below the
   lowest sell trades.
   
   dydynamic's partial basket closure keeps a tally of the increasing
   profits of the profitable buys and closes them when the profit
   reaches BasketTakeProfit, so long as this results in cash profit.
   The remaining buys will become profitable if the market rise continues. 
   The profitable ones will not  become losers if the market reverses again and falls,
   because they have been closed.
      
   Vice-versa if the highest sell is above the highest buy.
   
   Comples single sided offsetting may deal with this situation. We
   shall see.
   
   Thanks dydynamic. This is a magnificent contribution.
   */
 
   if (UseDydynamicClosure)
   {
      double Points = 0, Range = 0;
         
      if (Hedged)
      {
         cas = 0;
         ArrayResize(ClosureTickets, 0);
         ArrayInitialize(ClosureTickets, -1);
         int ClosureTicketsCount = 0;
         ArrayResize(ForceCloseTickets, cas + 1);
         
         double PipsProfit = 0;
         double ThisPipsProfit = 0;
         bool ClosureHit = false;
         ////////////////////////////////////////////////////////////////////////////////////////////// 
    
         if (Digits == 4 || Digits == 2) 
         {
             
            Points = Point;
         }//if (Digits == 4 || Digits == 2) 
          
        
         if (Digits == 5 || Digits == 3) 
         {     
          
           Points = Point*10;
         }//if (Digits == 5 || Digits == 3) 
         
        
         if(ObjectFind("Dybuy")!=0)
         {
            ObjectCreate("Dybuy", OBJ_RECTANGLE, 0, Time[0], LowestBuyPrice,Time[100],LowestBuyPrice+(BasketTakeProfit*Points));
            ObjectSet("Dybuy", OBJPROP_COLOR, RectColor);
            ObjectSet("Dybuy", OBJPROP_BACK, True);
         }//if(ObjectFind("Dybuy")!=0)
   
       
         if(ObjectFind("Dybuy")==0)
         {
            ObjectSet("Dybuy", OBJPROP_COLOR, RectColor);
            ObjectSet("Dybuy", OBJPROP_TIME1, ObjectGet("Dybuy",OBJPROP_TIME1)); 
            ObjectSet("Dybuy", OBJPROP_TIME2, ObjectGet("Dybuy",OBJPROP_TIME2)); 
            ObjectSet("Dybuy", OBJPROP_PRICE1, ObjectGet("Dybuy",OBJPROP_PRICE1)); 
            ObjectSet("Dybuy", OBJPROP_PRICE2, ObjectGet("Dybuy",OBJPROP_PRICE2));
         }//if(ObjectFind("Dybuy")==0)
   
   
         ObjectSet("Dybuy", OBJPROP_COLOR, RectColor);
     /////////////////////////////////////////////////////////////////////////////////////////////// 
         //Examine buys first
         string TopBuy ="1", BottomBuy = "1", BoxRange = "1";
         BottomBuy =  DoubleToStr(ObjectGet("Dybuy",OBJPROP_PRICE1),Digits);
         Range = (ObjectGet("Dybuy",OBJPROP_PRICE2)-ObjectGet("Dybuy",OBJPROP_PRICE1))/Points;//difference between the lowest buy and highest buy
                                                                                              
         BoxRange = DoubleToStr(Range,0);
         //Is anything wrong
         if (CloseEnough((double)BottomBuy, 0))
            return(false);
            
         //Is the lowest buy  the top buy greater than BasketTakeprofit?
         if ((double)BoxRange >= BasketTakeProfit)
         {
            CashProfit = 0;
            NoOfTrades = 0;
            
            //The array is sorted with the lowest ticket number at the start of the array
            for (cc = 0; cc < ArraySize(GridOrderBuyTickets); cc++)
            {
               if (!BetterOrderSelect((int)GridOrderBuyTickets[cc][TicketNo], SELECT_BY_TICKET, MODE_TRADES))
                  continue;
               
               //Cash upl
               ThisOrderProfit = OrderSwap() + OrderCommission() + OrderProfit();
               if (ThisOrderProfit > 0)
               {
                  CashProfit+= ThisOrderProfit;
                  //Set up the closure ticket number in case closure is possible.
                  ArrayResize(ClosureTickets, ClosureTicketsCount + 1);
                  ClosureTickets[ClosureTicketsCount] = OrderTicket();
                  ClosureTicketsCount++;
               }//if (ThisOrderProfit > 0)
               
               ThisPipsProfit = CalculateTradeProfitInPips(OrderType());
               
               //Add the pips of a profitable trade to the accumulated pips
               if (ThisPipsProfit > 0)
               {
                  //NoOfTrades++;//The number of trades to close if the basket tp is hit
                  PipsProfit+= ThisPipsProfit;
                  //Can we close the trades?
                  if (!CloseEnough(BasketTakeProfit, 0) )
                     if (BasketTakeProfit > 0)
                        if (PipsProfit >= BasketTakeProfit)
                           if (CashProfit > 0)//No point in closing at a loss
                           {
                              ClosureHit = true;
                              break;
                           }//if (CashProfit > 0)
               }//if (ThisPipsProfit > 0)
            }//for (cc = 0; cc < ArraySize(GridOrderBuyTickets); cc++)
            
            //Are there closures to make?
            if (ClosureHit)
            {
               as = ArraySize(ClosureTickets) - 1;
               Alert(Symbol(), " DyDynamic closure attempt: ", TimeToStr(TimeCurrent(), TIME_DATE|TIME_SECONDS));

               for (cc = as; cc >= 0; cc--)
               {
                  ForceTradeClosure = false;
                  tries = 0;
                  if (BetterOrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))
                  {
                     result = CloseOrder(ClosureTickets[cc]);
                     
                     if (!result)
                     {
                        //The closure attempt has failed, but must be retried.
                        //Save the ticket number in the array
                        cas = ArraySize(ForceCloseTickets);
                        ArrayResize(ForceCloseTickets, cas + 1);
                        ForceCloseTickets[cas] = ClosureTicketsSellSide[cc];
                     }//if (!result)
                  }// if (GridOrderBuyTickets[cc][TicketNo], SELECT_BY_TICKET, MODE_TRADES))                        
               }//for (cc = as; cc >= 0; cc--)
               if (ArraySize(ForceCloseTickets) == 0)
               {
                  CountOpenTrades();
                  //RemoveExpert = true;
                  //ExpertRemove();
                  return(true);
               }//if (ArraySize(ForceCloseTickets) == 0)
               else
               {
                  return(false);
               }//else                              
            }//if (ClosureHit)
            
         }//if (BoxRange >= BasketTakeProfit)
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
         
         if(ObjectFind("Dysell")!=0)
         {
            ObjectCreate("Dysell", OBJ_RECTANGLE, 0, Time[0], HighestSellPrice,Time[100],HighestSellPrice-(BasketTakeProfit*Points));
            ObjectSet("Dysell", OBJPROP_COLOR, RectColor);
            ObjectSet("Dysell", OBJPROP_BACK, True);
        }//if(ObjectFind("Dysell")!=0)
         
         if(ObjectFind("Dysell")==0)
         {
            ObjectSet("Dysell", OBJPROP_COLOR, RectColor);
            ObjectSet("Dysell", OBJPROP_TIME1, ObjectGet("Dysell",OBJPROP_TIME1)); 
            ObjectSet("Dysell", OBJPROP_TIME2, ObjectGet("Dysell",OBJPROP_TIME2)); 
            ObjectSet("Dysell", OBJPROP_PRICE1, ObjectGet("Dysell",OBJPROP_PRICE1)); 
            ObjectSet("Dysell", OBJPROP_PRICE2, ObjectGet("Dysell",OBJPROP_PRICE2));
         }//if(ObjectFind("Dysell")==0)
         
       
         ObjectSet("Dysell", OBJPROP_COLOR, RectColor);
     /////////////////////////////////////////////////////////////////////////////////////////////// 
         ////////////////////////////////////////////////////////////////
         //Now examine the sells
         string TopSell ="1", BottomSell ="1";
   
         TopSell =  DoubleToStr(ObjectGet("Dysell",OBJPROP_PRICE1),Digits);
         Range = (ObjectGet("Dysell",OBJPROP_PRICE1)-ObjectGet("Dysell",OBJPROP_PRICE2))/Points;//diff btw highest sell price and lowest sell price
         BoxRange = DoubleToStr(Range,0);
         //Is anything wrong
         if (CloseEnough((double)TopSell, 0))
           return(false);
             
         ArrayResize(ClosureTickets, 0);
         ArrayInitialize(ClosureTickets, -1);
         ClosureTicketsCount = 0;
         ArrayResize(ForceCloseTickets, 0);
            
         //Is the lowest buy < the lowest sell
         if ((double)BoxRange>=BasketTakeProfit)
         {
            CashProfit = 0;
            NoOfTrades = ArraySize(GridOrderSellTickets) - 1;
   
            //The array is sorted with the lowest ticket number at the start of the array
            for (cc = ArraySize(GridOrderSellTickets) - 1; cc >= 0; cc--)
            {
               if (!BetterOrderSelect((int)GridOrderSellTickets[cc][TicketNo], SELECT_BY_TICKET, MODE_TRADES))
                  continue;
            
               //Cash upl
               ThisOrderProfit = OrderSwap() + OrderCommission() + OrderProfit();
               if (ThisOrderProfit > 0)
               {
                  CashProfit+= ThisOrderProfit;
                  //Set up the closure ticket number in case closure is possible.
                  ArrayResize(ClosureTickets, ClosureTicketsCount + 1);
                  ClosureTickets[ClosureTicketsCount] = OrderTicket();
                  ClosureTicketsCount++;
               }//if (ThisOrderProfit > 0)
               
               ThisPipsProfit = CalculateTradeProfitInPips(OrderType());
               
               //Add the pips of a profitable trade to the accumulated pips
               if (ThisPipsProfit > 0)
               {
                  //NoOfTrades--;//The number of trades to close if the basket tp is hit, before this reaches zero
                  PipsProfit+= ThisPipsProfit;
                  //Can we close the trades?
                  if (!CloseEnough(BasketTakeProfit, 0) )
                     if (BasketTakeProfit > 0)
                        if (PipsProfit >= BasketTakeProfit)
                           if (CashProfit > 0)//No point in closing at a loss
                           {
                              ClosureHit = true;
                              break;
                           }//if (CashProfit > 0)
               }//if (ThisPipsProfit > 0)
            }//for (cc = ArraySize(GridOrderSellTickets) - 1; cc >= 0; cc--)
               
            //Are there closures to make?
            if (ClosureHit)
            {
               as = ArraySize(ClosureTickets) - 1;
               Alert(Symbol(), " DyDynamic closure attempt: ", TimeToStr(TimeCurrent(), TIME_DATE|TIME_SECONDS));
               for (cc = as; cc >= 0; cc--)
               {
                  ForceTradeClosure = false;
                  tries = 0;
                  if (BetterOrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))
                  {
                     result = CloseOrder(ClosureTickets[cc]);
                     
                     if (!result)
                     {
                        //The closure attempt has failed, but must be retried.
                        //Save the ticket number in the array
                        cas = ArraySize(ForceCloseTickets);
                        ArrayResize(ForceCloseTickets, cas + 1);
                        ForceCloseTickets[cas] = ClosureTicketsSellSide[cc];
                     }//if (!result)
                  }// if (GridOrderBuyTickets[cc][TicketNo], SELECT_BY_TICKET, MODE_TRADES))                        
               }//for (cc = as; cc >= 0; cc--)
               if (ArraySize(ForceCloseTickets) == 0)
               {
                  CountOpenTrades();
                  //RemoveExpert = true;
                  //ExpertRemove();
                  return(true);
               }//if (ArraySize(ForceCloseTickets) == 0)
               else
               {
                  return(false);
               }//else                              
            
            }//if (ClosureHit)
   
         }//if (Highestsell > Highestbuy)
         
               
      }//if (Hedged)
      
   }//if (UseDydynamicClosure)
   
   
      CashLoss = 0;
      CashProfit = 0;
      NoOfTrades = 0;       
   ////////////////////////////////////////////////////////////////////////////
   //Got this far, so no trades closed
   return(false);

}//END bool CanTradesBeOffset()

bool MopUpTradeClosureFailures()
{
   
   CountOpenTrades();
   
   //Cycle through the ticket numbers in the ForceCloseTickets array, and attempt to close them
   
   bool Success = true;
   
   for (int cc = ArraySize(ForceCloseTickets) - 1; cc >= 0; cc--)
   {
      //Order might have closed during a previous attempt, so ensure it is still open.
      if (!BetterOrderSelect(ForceCloseTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
      {
         ForceCloseTickets[cc] = 0;
         continue;
      }//if (!BetterOrderSelect(ForceCloseTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
         
      if (ForceCloseTickets[cc] == 0)
         continue;   

      bool result = CloseOrder(OrderTicket() );
      
      //This next bit and void TrimIntArrays(int& Managed[])  were provided by
      //Radar. It inserts zero into the array element. void TrimIntArrays(int& Managed[]) 
      //removes the zero element from ForceCloseTickets[]. Lovely stuff Radar. Thanks.
      
      if (result)
      {
         ForceCloseTickets[cc] = 0;
      }//if (result)
      
      if (!result)
      {
         int err=GetLastError();
         if (err == 4108)
            ForceCloseTickets[cc] = 0;
      }//if (!result)
      
   }//for (int cc = ArraySize(ForceCloseTickets) - 1; cc >= 0; cc--)
   
   TrimIntArrays(ForceCloseTickets);
   
   if (ArrayRange(ForceCloseTickets, 0) == 0)
   {   
      return(Success);
   }
   else
   {
      return(false);
   }


}//END bool MopUpTradeClosureFailures()

void TrimIntArrays(int& Managed[]) 
{
   //This code removes zeroed elements.
   
   int index;
   int ElementsToGo=0;
   int EmptyElements = 0;
   int CurrentArrayRange = 0;
   int NewArrayRange = 0;

   if(ArrayRange(Managed,0)>=1)
   {
      for(index = (ArrayRange(Managed,0)-1); index >= 0; index--)
      {
         EmptyElements=Managed[index];
         if(EmptyElements == 0) ElementsToGo++;
      } // End for(index = (ArrayRange(Managed,0)-1); index >= 0; index--)

      ArraySort(Managed,WHOLE_ARRAY,0,MODE_DESCEND);
      CurrentArrayRange = ArrayRange(Managed,0);
      NewArrayRange = CurrentArrayRange-ElementsToGo;
      ArrayResize(Managed, NewArrayRange);

   } // End if(ArrayRange(Managed,0)>=1)

   if (NewArrayRange > 1) 
      ArraySort(Managed,WHOLE_ARRAY,0);
      
	return;
} // End TrimIntArrays(int& Managed[])


void SendBuyGrid(string symbol,int type,double price,double lot)
  {
   //Send a grid of stop orders using the passed parameters
   double stop = 0;
   double take = 0;
   bool result = false;

   //For minimum distance market to stop level
   //double spread = (Ask - Bid);
   //double StopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) + spread;

   int tries=0;//To break out of an infinite loop

   for(int cc=0; cc<GridSize; cc++)
     {
      tries++;
      if(tries>=100)
         break;

      //Check the trade has not already been sent
      
      if(DoesTradeExist(type,price,DistanceBetweenTrades*.5) || DoesTradeExist(OP_BUY,price,DistanceBetweenTrades*.5))
        {
         //Increment the price for the next pending
         if(type==OP_BUYSTOP)
            price=NormalizeDouble(price+(DistanceBetweenTrades/factor),Digits);
         else
            price=NormalizeDouble(price -(DistanceBetweenTrades/factor),Digits);

         cc--;
         continue;
        }//if (DoesTradeExist(OP_BUYSTOP, price))

      stop = CalculateStopLoss(OP_BUY, price);
      take = CalculateTakeProfit(OP_BUY, price);

      if(!IsExpertEnabled())
        {
         Comment("                          EXPERTS DISABLED");
         return;
        }//if (!IsExpertEnabled() )

      result = true;
      result=SendSingleTrade(Symbol(), type, TradeComment, lot, price, stop, take);

      //Each trade in the grid must be sent, so deal with failures
      if(!result)
        {
         Alert("Buy stop: Lots ",lot,": Price ",price,": Ask ",Ask);
         int err=GetLastError();
         if(err!=130)//If invalid stop, we go hunt the market. Else we wait 5 sec and try agin
           {
            Sleep(5000);
            cc--;
            continue;//Do not want price incrementing
           }//if err!=130
        }//if (!result)

      //Increment the price for the next pending
      if(type==OP_BUYSTOP)
         price=NormalizeDouble(price+(DistanceBetweenTrades/factor),Digits);
      else
         price=NormalizeDouble(price -(DistanceBetweenTrades/factor),Digits);
      Sleep(500);

     }//for (int cc = 0; cc < GridSize; cc++)

}//End void Print("___LINE___"); sendbuygrid(string symbol, double price, double lot)


void SendSellGrid(string symbol,int type,double price,double lot)
{
   //Send a grid of stop orders using the passed parameters
   double stop = 0;
   double take = 0;
   bool result = false;

   //For minimum distance market to stop level
   //double spread = (Ask - Bid);
   //double StopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) + spread;

   int tries=0;//To break out of an infinite loop

   for(int cc=0; cc<GridSize; cc++)
     {
      tries++;
      if(tries>=100)
         break;

      //Check the trade has not already been sent
      
      if(DoesTradeExist(type,price,DistanceBetweenTrades*.5) || DoesTradeExist(OP_SELL,price,DistanceBetweenTrades*.5))
        {
         //Increment the price for the next pending
         if(type==OP_SELLLIMIT)
            price=NormalizeDouble(price+(DistanceBetweenTrades/factor),Digits);
         else
            price=NormalizeDouble(price -(DistanceBetweenTrades/factor),Digits);

         cc--;
         continue;
        }//if (DoesTradeExist(OP_SELLSTOP, price))

      stop = CalculateStopLoss(OP_SELL, price);
      take = CalculateTakeProfit(OP_SELL, price);

      if(!IsExpertEnabled())
        {
         Comment("                          EXPERTS DISABLED");
         return;
        }//if (!IsExpertEnabled() )

      result = true;
      result=SendSingleTrade(Symbol(), type, TradeComment, lot, price, stop, take);

      //Each trade in the grid must be sent, so deal with failures
      if(!result)
        {
         Alert("Sell stop: Lots ",lot,": Price ",price,": Bid ",Bid);
         int err=GetLastError();
         if(err!=130)//If invalid stop, we go hunt the market. Else we wait 5 sec and try agin
           {
            Sleep(5000);
            cc--;
            continue;//Do not want price incrementing
           }//if err!=130
        }//if (!result)

      //Increment the price for the next pending
      if(type==OP_SELLLIMIT)
         price=NormalizeDouble(price+(DistanceBetweenTrades/factor),Digits);
      else
         price=NormalizeDouble(price -(DistanceBetweenTrades/factor),Digits);

      Sleep(500);

     }//for (int cc = 0; cc < GridSize; cc++)

}//End void SendSellGrid(string symbol, double price, double lot)


void CanWeAddAnotherPendingTrade()
{
   //Looks for gaps at the extremes of the gris and fills them. These gaps will be caused by offsetting.

   double price = 0;
   bool result = false;
   double stop = 0, take = 0;
   //double spread = NormalizeDouble(Ask - Bid, Digits);
   double target = 0;
   int as = 0;//Array size
   

   //Arrays are sorted into ascending order of prices.
   //Buy stop underneath the bottom of the buy grid.
   if (ArraySize(BuyPrices) > 0)
   {
      //We need to know if the market has fallen by DistanceBetweenTrades * 2 from the lowest buy price
      target = NormalizeDouble(BuyPrices[0] - ((DistanceBetweenTrades / factor)* 2), Digits);
      if (Bid <= target)
      {
         //Yes, it has so send a new stop order at lowest buy price - DistanceBetweenTrades
         price = NormalizeDouble(BuyPrices[0] - (DistanceBetweenTrades / factor), Digits);
         take = CalculateTakeProfit(OP_BUY, price);
         stop = CalculateStopLoss(OP_BUY, price);
         result = SendSingleTrade(Symbol(), OP_BUYSTOP, TradeComment, Lot, price, stop, take);
         CountOpenTrades();//It does no harm to restock the position picture
         return;//Nothing more to do
      }//if (Bid <= target)
      
            
   }//if (ArraySize(BuyPrices) > 0)
   
   if (ArraySize(SellPrices) > 0)
   {
      //We need to know if the market has risen by DistanceBetweenTrades * 2 from the highest sell price
      as = ArraySize(SellPrices) - 1;
      target = NormalizeDouble(SellPrices[as] + ((DistanceBetweenTrades / factor)* 2), Digits);
      if (Bid >= target)
      {
         price = NormalizeDouble(SellPrices[as] + (DistanceBetweenTrades / factor), Digits);
         take = CalculateTakeProfit(OP_SELL, price);
         stop = CalculateStopLoss(OP_SELL, price);
         result = SendSingleTrade(Symbol(), OP_SELLSTOP, TradeComment, Lot, price, stop, take);
         return;//Nothing more to do
      }//if (Bid >= target)

      
   }//if (ArraySize(SellPrices) > 0)
   
   

}//End void CanWeAddAnotherPendingTrade()

void TrimTheGrids()
{
   double price=0,stop=0,take=0,target=0;
   bool   changed=false;

   CountOpenTrades();//Lets see what is there
      
   if(UseGrid && OpenTrades>0)//We have trades open and need grids
   {
      if(BuyStopsCount>0 && BuyStopsCount<GridSize)//We need to add a buy stop
      {
         //We send a new stop order at highest buy (stop) price + DistanceBetweenTrades
         price=NormalizeDouble(MathMax(HighestBuyStopPrice,HighestBuyPrice)+(DistanceBetweenTrades/factor),Digits);
         take=CalculateTakeProfit(OP_BUY,price);
         stop=CalculateStopLoss(OP_BUY,price);
         if (SendSingleTrade(Symbol(),OP_BUYSTOP,TradeComment,Lot,price,stop,take))
            changed=true;
      }//if(BuyStopsCount>0 && BuyStopsCount<GridSize)
      
      if(SellStopsCount>0 && SellStopsCount<GridSize)//We need to add a sell stop
      {
         //We send a new stop order at lowest sell (stop) price - DistanceBetweenTrades
         price=NormalizeDouble(MathMin(LowestSellStopPrice,LowestSellPrice)-(DistanceBetweenTrades/factor),Digits);
         take=CalculateTakeProfit(OP_SELL,price);
         stop=CalculateStopLoss(OP_SELL,price);
         if (SendSingleTrade(Symbol(),OP_SELLSTOP,TradeComment,Lot,price,stop,take))
            changed=true;
      }//if(SellStopsCount>0 && SellStopsCount<GridSize)

      if(BuyStopsCount>GridSize && HighestBuyStopPrice>HighestBuyPrice)//We look to delete a buy stop without creating a gap
      {
         if(BetterOrderSelect(HighestBuyStopTicketNo,SELECT_BY_TICKET,MODE_TRADES))
            if (CloseOrder(HighestBuyStopTicketNo))
               changed=true;
      }//if(BuyStopsCount>GridSize && HighestBuyStopPrice>HighestBuyPrice)

      if(SellStopsCount>GridSize && LowestSellStopPrice<LowestSellPrice)//We look to delete a sell stop without creating a gap
      {
         if(BetterOrderSelect(LowestSellStopTicketNo,SELECT_BY_TICKET,MODE_TRADES))
            if (CloseOrder(LowestSellStopTicketNo))
               changed=true;
      }//if(SellStopsCount>GridSize && LowestSellStopPrice<LowestSellPrice)
      
      if (changed)
         CountOpenTrades();
      
   }//if(UseGrid && OpenTrades>0)
}//End void TrimTheGrids()

bool indiExists( string indiName ) 
{

   //Returns true if a custom indi exists in the user's indi folder, else false
   bool exists = false;
   
   ResetLastError();
   double value = iCustom( Symbol(), Period(), indiName, 0, 0 );
   if ( GetLastError() == 0 ) exists = true;
   
   return(exists);

}//End bool indiExists( string indiName ) 


bool DoesTradeExist(int type, double price, double pips)
{
   if (OrdersTotal() == 0 || OpenTrades == 0)
      return(false);
   
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderType() != type) continue;      
      
      //odrisb enhanced this function and added bool ExistingOrderCloseEnough(double neworderprice, double existingprice, double pips)
      //to try and stop trades being opened too close to one another.
      //Great contribution odrisb. Thanks.
      if (!ExistingOrderCloseEnough(OrderOpenPrice(), price, pips)) continue;
      return(true);
   }   
   return(false);   
}//End bool DoesTradeExist(int type, double price)

bool ExistingOrderCloseEnough(double neworderprice, double existingprice, double pips)
{
   double pipdigits = NormalizeDouble(pips / factor,Digits);   
   double neworderpricehigh = NormalizeDouble(neworderprice + pipdigits, Digits);
   double neworderpricelow = NormalizeDouble(neworderprice - pipdigits, Digits);   

   if (NormalizeDouble(existingprice,Digits) <= neworderpricehigh && NormalizeDouble(existingprice,Digits) >= neworderpricelow) return(true);
   return(false);

}//End bool ExistingOrderCloseEnough(double neworderprice, double existingprice, double pips)


void CheckThatForceCloseArrayStillValid()
{

   //Iterate through the ForceTradeClosure array to see which trades are still open
   
   //Declare a temporary array to hold the ticket nos of trades still open. These
   //will be failed closure attempts.
   int TempTickets[];
   
   int cc = 0;
   int as = 0;//TempTickets array size
   
   //Loop through the ForceCloseTickets array to see which trades
   //are still open.
   for (cc = ArraySize(ForceCloseTickets) - 1; cc >= 0; cc--)
   {
      if (BetterOrderSelect(ForceCloseTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
      {
         ArrayResize(TempTickets, as + 1);
         TempTickets[as] = OrderTicket();
         as++;
      }//if (BetterOrderSelect(ForceCloseTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
      
   }//for (int cc = ArraySize(ForceCloseTickets) - 1; cc >= 0; cc--)
   
   //Were any trades left open? If so, copy them into ForceCloseTickets[]]
   if (as > 0)
   {
      ArrayResize(ForceCloseTickets, as);
      ArrayCopy(ForceCloseTickets, TempTickets,0,0,WHOLE_ARRAY);
      return;
   }//if (as > 0)
   
   //No trades left open, so resize the array.
   ArrayResize(ForceCloseTickets, 0);

}//End void CheckThatForceCloseArrayStillValid()

//This code by tomele. Thank you Thomas. Wonderful stuff.
bool AreWeAtRollover()
  {

   double time;
   int hours,minutes,rstart,rend,ltime;
   
   time=StrToDouble(RollOverStarts);
   hours=(int)MathFloor(time);
   minutes=(int)MathRound((time-hours)*100);
   rstart=60*hours+minutes;
      
   time=StrToDouble(RollOverEnds);
   hours=(int)MathFloor(time);
   minutes=(int)MathRound((time-hours)*100);
   rend=60*hours+minutes;
   
   ltime=TimeHour(TimeCurrent())*60+TimeMinute(TimeCurrent());

   if (rend>rstart)
     if(ltime>rstart && ltime<rend)
       return(true);
   if (rend<rstart) //Over midnight
     if(ltime>rstart || ltime<rend)
       return(true);

   //Got here, so not at rollover
   return(false);

  }//End bool AreWeAtRollover()

bool ShouldWeFullyHedge()
{
   //Look for an imbalance between buys and sells.
   //If the imbalance is great enough and the trend time frame
   //is in the opposite direction to the unbalanced trades,
   //add a full hedge.
   
   //Is there an imbalance between the total lots of market trades?
   if (MathAbs(BuyLotsTotal - SellLotsTotal) < BuysAndSellsUnbalancedAtLots)
      return(false);

   
   //Got this far, so the position is unbalanced. Can we close some profitable trades?
   //Can we close some buys in a short trend?
   if (HgiShortTrendDetected)
   {
      CloseAllPossibleBuys();
   }//if (HgiShortTrendDetected)
   
   //Can we close some sells in a long trend?
   if (HgiLongTrendDetected)
   {
      CloseAllPossibleSells();
   }//if (HgiLongTrendDetected)
   
   //Retest for imbalance to see if the full hedge is still needed.
   //CloseAllPossibleBuys()/Sells() calls CountOpenTrades() to
   //rebuild the picture of the position.
   //Is there an imbalance between the number of market trades?
   if (MathAbs(BuyLotsTotal - SellLotsTotal) < BuysAndSellsUnbalancedAtLots)
      return(false);

   //Yes, so is there an imbalance between the open lots?
   if (CloseEnough(BuyLotsTotal, SellLotsTotal) )
      return(false);
   
   
   double LotsDifference = 0;
   bool result = false;
    
   //Yes, so rebalance the trades.
   //Buys in a sell trend
   if (HgiShortTrendDetected)
      if (BuyLotsTotal > SellLotsTotal)
      {
         LotsDifference = BuyLotsTotal - SellLotsTotal;//Not including error checks yet as I assume they are not needed. We shall see.
         result = SendSingleTrade(Symbol(), OP_SELL, FullHedgeComment, LotsDifference, Ask, 0, 0);
         if (result)
         {
            FullyHedged = true;
            return(true);
         }//if (result)
      }//if (BuyLotsTotal < SellLotsTotal)
      
   //Sells in a buy trend
   if (HgiLongTrendDetected)
      if (SellLotsTotal > BuyLotsTotal)
      {
         LotsDifference = SellLotsTotal - BuyLotsTotal;//Not including error checks yet as I assume they are not needed. We shall see.
         result = SendSingleTrade(Symbol(), OP_BUY, FullHedgeComment, LotsDifference, Bid, 0, 0);
         if (result)
         {
            FullyHedged = true;
            return(true);
         }//if (result)
      }//if (BuyLotsTotal < SellLotsTotal)
      

   //Got this far, so no.
   return(false);

}//End bool ShouldWeBeFullyHedged()

void DealWithBuySideGaps()
{
   //Offsetting can leave wide gaps between trades. This function
   //is an attempt to fill buy side gaps.
   
   //My original code did not work properly. oldbisb sorted this
   //out, so many thanks Brenden.


   double OrderPrice = 0;//OrderOpenPrice for the AnyBuyTicket[cc]
   double OrderPrice1 = 0;//OrderOpenPrice for the AnyBuyTicket[cc + 1]

   //Itterate through AnyBuyTicket array and look for fillable gaps in the grid
   for (int cc = 1; cc <= ArraySize(BuyPrices) - 1; cc++)
   {
      //Clever stuff provided by Phil. Thanks Phill.
      if (Ask < BuyPrices[cc] - (DistanceBetweenTrades / factor) - (SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL) / pow(10, Digits))) //Cannot place a stop order below market
      {  
         OrderPrice = BuyPrices[cc-1];
         OrderPrice1 = BuyPrices[cc];
 
         
         //I am making the assumption that neither of the trades were closed in between
         //being detected in COT and here.
         double distance = (OrderPrice1 - OrderPrice) * factor;//Distance between the trades
         //Is this a large gap?
         
         if(distance>=(DistanceBetweenTrades*1.5))
         {
            double price = NormalizeDouble(OrderPrice1 - (DistanceBetweenTrades / factor), Digits);
            bool result = SendSingleTrade(Symbol(), OP_BUYSTOP, TradeComment, Lot, price, 0, 0);
            //if (result)
              // Alert(Symbol(), ": New buy stop sent at ", DoubleToStr(price, Digits), ": Time ", TimeToStr(TimeCurrent(), TIME_DATE|TIME_SECONDS), 
                //     ": Ticket ", IntegerToString(TicketNo));
            return;
         }//if(distance>=(DistanceBetweenTrades*1.5))
         
      }//if (Bid < BuyPrices[cc] )
  
      
   }//for (int cc = 0; cc <= ArraySize(BuyPrices) - 2; cc++)
   
}//End void DealWithBuySideGaps()

void DealWithSellSideGaps()
{
   //Offsetting can leave wide gaps between trades. This function
   //is an attempt to fill buy side gaps.


   double OrderPrice = 0;//OrderOpenPrice for the AnyBuyTicket[cc]
   double OrderPrice1 = 0;//OrderOpenPrice for the AnyBuyTicket[cc + 1]

   //Itterate through AnyBuyTicket array and look for fillable gaps in the grid
   for (int cc = 1; cc <= ArraySize(SellPrices) - 1; cc++)
   {
      //Clever stuff provided by Phil. Thanks Phill.
      if (Bid > SellPrices[cc-1] + (DistanceBetweenTrades / factor) + (SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL) / pow(10, Digits))) //Cannot place a stop order above market      {  
      {
         OrderPrice = SellPrices[cc-1];
         OrderPrice1 = SellPrices[cc];
 

         
         //I am making the assumption that neither of the trades were closed in between
         //being detected in COT and here.
         double distance = (OrderPrice1 - OrderPrice) * factor;//Distance between the trades
         //Is this a large gap?
         
         if(distance>=(DistanceBetweenTrades*1.5))
         {
            double price = NormalizeDouble(OrderPrice + (DistanceBetweenTrades / factor), Digits);
            bool result = SendSingleTrade(Symbol(), OP_SELLSTOP, TradeComment, Lot, price, 0, 0);
            //if (result)
              // Alert(Symbol(), ": New sell stop sent at ", DoubleToStr(price, Digits), ": Time ", TimeToStr(TimeCurrent(), TIME_DATE|TIME_SECONDS), 
                //     ": Ticket ", IntegerToString(TicketNo));
            return;
         }//if(distance>=(DistanceBetweenTrades*1.5))
         
      }//if (Bid > SellPrices[cc + 1] )
      
   }//for (int cc = 0; cc <= ArraySize(SellPrices) - 2; cc++)
  
}//End void DealWithSellSideGaps()


void DebugPrint(string message,int level=1)
{
   if (level<=DebugLevel) Print(message);
}//End void DebugPrint(string message)


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

////////////////////////////////////////////////////////////////////////////////
//Start DIAD module
void DoDiadTrading()
{

   /////////////////////////////////////////////////////
   //TEMPORARY DURING DEVELOPMENT. REMOVE LATER.
   //OpenTrades = 0;
   //BuySignal = true;
   /////////////////////////////////////////////////////
   
   bool result = false;
   
   //Lot size based on account size
   if (!CloseEnough(LotsPerDollopOfCash, 0))
      CalculateLotAsAmountPerCashDollops();

   //Look for a new trade
   if (OpenTrades == 0)
   {
      
      //Buy trade
      if (BuySignal)
      {
         SendDiadBuy(OP_BUY);
         return;
      }//if (BuySignal)
      
      //Sell trade
      if (SellSignal)
      {
         SendDiadSell(OP_SELL);   
         return;
      }//if (SellSignal)
   
   }//if (OpenTrades == 0)
   
   //Refresh the prices in case the user is manually adjusting the lines
   RefreshDiadPrices();
   
   //Has a pending trade line been reached?
   //Trade 2
   result = false;
   if (ObjectFind(TradeLine2Name) > -1)
   {
      if (ObjectGet(TradeLine2Name, OBJPROP_STYLE) == Trade2BuyLineStyle)
         result = HasDiadBuyStopFilled(Trade2Price, TradeLine2Name);
      else
         result = HasDiadSellStopFilled(Trade2Price, TradeLine2Name);     
      if (result)
         return;       
   }//if (ObjectFind(TradeLine2Name) > -1)
   
   //Trade 3
   result = false;
   if (ObjectFind(TradeLine3Name) > -1)
   {
      if (ObjectGet(TradeLine3Name, OBJPROP_STYLE) == Trade3BuyLineStyle)
         result = HasDiadBuyStopFilled(Trade3Price, TradeLine3Name);
      else
         result = HasDiadSellStopFilled(Trade3Price, TradeLine3Name);     
      if (result)
         return;       
   }//if (ObjectFind(TradeLine3Name) > -1)
   
   
   //Adjust stop losses to breakeven
   if (OpenTrades == 2)
      AdjustStopLosses(Be1Price);
   
   if (OpenTrades == 3)
      AdjustStopLosses(Be2Price);
      
   //Adjust take profits
   if (OpenTrades > 0)
      AdjustTakeProfit(TpPrice);
   
   //Replace missing lines
   ReplaceMissingLines();
   
}//End void DoDiadTrading()

void SendDiadBuy(int type)
{
   double stop = 0, take = 0, price = 0;
   datetime tradeTime = iTime(Symbol(), TradingTimeFrame, 0);
   double SendLots = Lot;
   string comment = "";
   
   //User choice of trade direction
   if (!TradeLong) return;

   //Other filters
   //CSS.         
   if (UseCSS)
   {
      //We are buying the first in the pair ans selling the second, so ensure they are moving in the correct direction and on the right side of 0
      if (CurrDirection1 == downaccelerating || CurrDirection1 == downdecelerating) return;
      if (CurrDirection2 == upaccelerating || CurrDirection2 == updecelerating) return;
   }//if (UseCSS)
   
   //Other filters
    if (UseZeljko && !BalancedPair(OP_BUY) ) return;

   //Usual filters passed or not used, so we can continue
   RefreshRates();
   price = Ask;
   type = OP_BUY;
   
   stop = CalculateStopLoss(OP_BUY, price);
   
   
   take = CalculateTakeProfit(OP_BUY, price);
   
   
   //Lot size calculated by risk
   if (RiskPercent > 0) SendLots = CalculateLotSize(price, NormalizeDouble(stop + (HiddenPips / factor), Digits) );
   
   comment = Trade1TradeComment;
   
   bool result = SendSingleTrade(Symbol(), type, comment, SendLots, price, stop, take);
   
   //Draw the price lines
   if (result)
   {
      //Stop order lines
      //if (!BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )
         //return;//Order send failed, so no need to continue
      Trade1Price = OrderOpenPrice();   
      Trade2Price = Trade1Price + (Trade2At / factor);
      DrawHorizontalLine(TradeLine2Name, Trade2Price, Trade2LineColour, Trade2BuyLineStyle, 0);
      Be1Price = (Trade1Price + Trade2Price) / 2 + (DiadBreakevenProfit / factor);
      DrawHorizontalLine(BeLine1Name, Be1Price, BreakEven1LineColour, BeLineStyle, 0);
      Trade3Price = Trade1Price + (Trade3At / factor);
      DrawHorizontalLine(TradeLine3Name, Trade3Price, Trade3LineColour, Trade3BuyLineStyle, 0);
      Be2Price = (Trade2Price + Trade3Price) / 2 + (DiadBreakevenProfit / factor);
      DrawHorizontalLine(BeLine2Name, Be2Price, BreakEven2LineColour, BeLineStyle, 0);
      TpPrice = Trade1Price + (TakeProfit / factor);
      DrawHorizontalLine(TakeProfitLineName, TpPrice, TakeProfitLineColour, STYLE_SOLID, 0);
   }//if (result)


}//End void SendDiadBuy(int type)

void SendDiadSell(int type)
{

   double stop = 0, take = 0, price = 0;
   datetime tradeTime = iTime(Symbol(), TradingTimeFrame, 0);
   double SendLots = Lot;
   string comment = "";
   
   //User choice of trade direction
   if (!TradeShort) return;

   //Other filters
   
   
   //CSS.         
   if (UseCSS)
   {
      //We are selling the first in the pair ans buying the second, so ensure they are moving in the correct direction and on the right side of 0        
      if (CurrDirection1 == upaccelerating || CurrDirection1 == updecelerating) return;
      if (CurrDirection2 == downaccelerating || CurrDirection2 == downdecelerating) return;
   }//if (UseCSS)

   //Slope must be in the sell area
   if (UseZeljko && !BalancedPair(OP_SELL) ) return;

   //Usual filters passed or not used, so we can continue
   RefreshRates();
   price = Bid;
   type = OP_SELL;
   
   stop = CalculateStopLoss(OP_SELL, price);
   
   
   take = CalculateTakeProfit(OP_SELL, price);
   
   
   //Lot size calculated by risk
   if (RiskPercent > 0) SendLots = CalculateLotSize(price, NormalizeDouble(stop - (HiddenPips / factor), Digits) );
   
   comment = Trade1TradeComment;
   
   bool result = SendSingleTrade(Symbol(), type, comment, SendLots, price, stop, take);
   
   
   //Draw the price lines
   if (result)
   {
      //Stop order lines
      if (!BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )
         return;//Order send failed, so no need to continue
      Trade1Price = OrderOpenPrice();   
      Trade2Price = Trade1Price - (Trade2At / factor);
      DrawHorizontalLine(TradeLine2Name, Trade2Price, Trade2LineColour, Trade2SellLineStyle, 0);
      Be1Price = (Trade1Price + Trade2Price) / 2 - (DiadBreakevenProfit / factor);
      DrawHorizontalLine(BeLine1Name, Be1Price, BreakEven1LineColour, BeLineStyle, 0);
      Trade3Price = Trade1Price - (Trade3At / factor);
      DrawHorizontalLine(TradeLine3Name, Trade3Price, Trade3LineColour, Trade3SellLineStyle, 0);
      Be2Price = (Trade2Price + Trade3Price) / 2 - (DiadBreakevenProfit / factor);
      DrawHorizontalLine(BeLine2Name, Be2Price, BreakEven2LineColour, BeLineStyle, 0);
      TpPrice = Trade1Price - (TakeProfit / factor);
      DrawHorizontalLine(TakeProfitLineName, TpPrice, TakeProfitLineColour, STYLE_SOLID, 0);
   }//if (result)
}//End void SendDiadSell(int type)

void RefreshDiadPrices()
{
   
   int type = OP_BUY;
   int style = 0;
   
   //This allows the user to move the lines manually
   if (ObjectFind(TradeLine2Name) > -1)
   {
      Trade2Price = ObjectGet(TradeLine2Name, OBJPROP_PRICE1);
      style = ObjectGet(TradeLine2Name, OBJPROP_STYLE);
      if (style == Trade2SellLineStyle)
         type = OP_SELL;
   }//if (ObjectFind(TradeLine2Name) > -1)
   
   if (ObjectFind(TradeLine3Name) > -1)
   {
      Trade3Price = ObjectGet(TradeLine3Name, OBJPROP_PRICE1);
      style = ObjectGet(TradeLine3Name, OBJPROP_STYLE);
      if (style == Trade3SellLineStyle)
         type = OP_SELL;
   }//if (ObjectFind(TradeLine3Name) > -1)
   
   if (ObjectFind(TakeProfitLineName) > -1)
   {
      TpPrice = ObjectGet(TakeProfitLineName, OBJPROP_PRICE1);
   }//if (ObjectFind(TakeProfitLineName) > -1)
   
   if (ObjectFind(BeLine1Name) > -1)
      Be1Price = ObjectGet(BeLine1Name, OBJPROP_PRICE1);

   if (ObjectFind(BeLine2Name) > -1)
      Be2Price = ObjectGet(BeLine2Name, OBJPROP_PRICE1);

 }//End void RefreshDiadPrices()

bool HasDiadBuyStopFilled(double lineprice, string lineName)
{

   if (Ask < lineprice)
      return(false);//Not reached the line yet
   
   double SendLots = Lot;
   
   string comment = Trade2TradeComment;
   if (lineName == TradeLine3Name)
      comment = Trade3TradeComment;
      
   RefreshRates();
   
   double stop = CalculateStopLoss(OP_BUY, Ask);
   
   
   //Lot size calculated by risk
   if (RiskPercent > 0) SendLots = CalculateLotSize(Ask, NormalizeDouble(stop + (HiddenPips / factor), Digits) );
   
   
   bool result = SendSingleTrade(Symbol(), OP_BUY, comment, SendLots, Ask, stop, TpPrice);
   
   if (result)
   {
      //Trade succeeded so we do not need the line any more
      ObjectDelete(lineName);
      return(true);
   }//if (result)
   
   
   //Got this far, so no trade sent
   return(false);

}//End bool HasDiadBuyStopFilled(double price)

bool HasDiadSellStopFilled(double lineprice, string lineName)
{

   if (Bid > lineprice)
      return(false);//Not reached the line yet
   
   double SendLots = Lot;
   
    string comment = Trade2TradeComment;
   if (lineName == TradeLine3Name)
      comment = Trade3TradeComment;
      
   RefreshRates();
   
   double stop = CalculateStopLoss(OP_SELL, Bid);
   
   
   //Lot size calculated by risk
   if (RiskPercent > 0) SendLots = CalculateLotSize(Bid, NormalizeDouble(stop - (HiddenPips / factor), Digits) );
   
   
   bool result = SendSingleTrade(Symbol(), OP_SELL, comment, SendLots, Bid, stop, TpPrice);
   
   if (result)
   {
      //Trade succeeded so we do not need the line any more
      ObjectDelete(lineName);
      return(true);
   }//if (result)
   
   
   //Got this far, so no trade sent
   return(false);

}//End bool HasDiadSellStopFilled(double price, string lineName)

void AdjustStopLosses(double stop)
{
   
   //Move the stop losses if they are not the same as the passed parameter
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
         
      if (!CloseEnough(OrderStopLoss(), stop) )
         ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
   }//for (int cc = OpenTrades - 1; cc >= 0; cc--)
   

}//End void AdjustStopLosses(double stop)

void AdjustTakeProfit(double take)
{

   //Move the stop losses if they are not the same as the passed parameter
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
         
      if (!CloseEnough(OrderTakeProfit(), take) )
         ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, slm);
   }//for (int cc = OpenTrades - 1; cc >= 0; cc--)
   

}//End void AdjustTakeProfit(double take)

void ReplaceMissingLines()
{
//if (Symbol() == "USDCHF") Alert(EarliestTradeTicketNo);
   if (!BetterOrderSelect(EarliestTradeTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      return;//Trade was closed for some reason
//if (Symbol() == "USDCHF") Alert("Y");
    
   //Calculate the line prices
   Trade1Price = OrderOpenPrice();   
   if (OrderType() == OP_BUY)
   {
      Trade2Price = Trade1Price + (Trade2At / factor);
      Be1Price = (Trade1Price + Trade2Price) / 2 + (DiadBreakevenProfit / factor);
      Trade3Price = Trade1Price + (Trade3At / factor);
      Be2Price = (Trade2Price + Trade3Price) / 2 + (DiadBreakevenProfit / factor);
      TpPrice = Trade1Price + (TakeProfit / factor);   
   }//if (OrderType() == OP_BUY)
         
   if (OrderType() == OP_SELL)
   {
      Trade2Price = Trade1Price - (Trade2At / factor);
      Be1Price = (Trade1Price + Trade2Price) / 2 - (DiadBreakevenProfit / factor);
      Trade3Price = Trade1Price - (Trade3At / factor);
      Be2Price = (Trade2Price + Trade3Price) / 2 - (DiadBreakevenProfit / factor);
      TpPrice = Trade1Price - (TakeProfit / factor);      
   }//if (OrderType() == OP_SELL)

//if (Symbol() == "USDCHF") Alert(Trade1Price, "  ", TpPrice);
   //Replace any missing lines
   if (OpenTrades == 1)
   {
      if (ObjectFind(TradeLine2Name) == -1)
      {
         if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP)
            DrawHorizontalLine(TradeLine2Name, Trade2Price, Trade2LineColour, Trade2BuyLineStyle, 0);
         else
            DrawHorizontalLine(TradeLine2Name, Trade2Price, Trade2LineColour, Trade2SellLineStyle, 0);
      }//if (ObjectFind(TradeLine2Name) == -1)
      
      if (ObjectFind(BeLine1Name) == -1)
      {
         DrawHorizontalLine(BeLine1Name, Be1Price, BreakEven1LineColour, BeLineStyle, 0);
      }//if (ObjectFind(BeLine1Name) == -1)
         
      if (ObjectFind(TradeLine3Name) == -1)
      {
         if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP)
            DrawHorizontalLine(TradeLine3Name, Trade3Price, Trade3LineColour, Trade3BuyLineStyle, 0);
         else
            DrawHorizontalLine(TradeLine3Name, Trade3Price, Trade3LineColour, Trade3SellLineStyle, 0);
      }//if (ObjectFind(TradeLine3Name) == -1)
         
      if (ObjectFind(BeLine2Name) == -1)
      {
         DrawHorizontalLine(BeLine2Name, Be2Price, BreakEven2LineColour, BeLineStyle, 0);
      }//if (ObjectFind(BeLine2Name) == -1)
            
      if (ObjectFind(TakeProfitLineName) == -1)
      {
         DrawHorizontalLine(TakeProfitLineName, TpPrice, TakeProfitLineColour, STYLE_SOLID, 0);
      }//if (ObjectFind(TakeProfitLineName) == -1)
            
   }//if (OpenTrades == 1)
   


}//End void ReplaceMissingLines()


//End DIAD module
////////////////////////////////////////////////////////////////////////////////

bool UsualOnTick()
{
   
   if (!IsTradeAllowed() )
   {
      Comment("                          THIS EXPERT HAS LIVE TRADING DISABLED");
      return(false);
   }//if (!IsTradeAllowed() )

   //Rollover
   if (DisableDottyDuringRollover)
   {
      RolloverInProgress = false;
      if (AreWeAtRollover())
      {
         RolloverInProgress = true;
         DisplayUserFeedback();
         return(false);
      }//if (AreWeAtRollover)
   }//if (DisableDottyDuringRollover)
   
   //Check for a massive spread widening event and pause the ea whilst it is happening
   if (!IsTesting())
      CheckForSpreadWidening();

   //mptm sets a Global Variable when it is closing the trades.
   //This tells this ea not to send any fresh trades.
   if (GlobalVariableCheck(GvName))
      return(false);
   //'Close all trades this pair only script' sets a GV to tell EA's not to attempt a trade during closure
   if (GlobalVariableCheck(LocalGvName))
      return(false);
   //'Nuclear option script' sets a GV to tell EA's not to attempt a trade during closure
   if (GlobalVariableCheck(NuclearGvName))
      return(false);
   //Code provided by Radar. Many thanks Radar.
   // If the HGBnD - MultiSymbol - Controller has disabled trading for this symbol ==> return
   if (GlobalVariableCheck(GvEnableTrading) && GlobalVariableGet(GvEnableTrading) < 0.0)
      return(false);
   
   //Those stupid sods at MetaCrapper have ensured that stopping an ea by diabling AutoTrading no longer works. Ye Gods alone know why.
   //This routine provided by FxCoder. Thanks Bob.
   if ( !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) )
   {
      Comment("                          TERMINAL AUTOTRADING IS DISABLED");
      return(false);
      
   }//if ( !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) )

   //In case any trade closures failed
   if (ArraySize(ForceCloseTickets) > 0)
   {
      CheckThatForceCloseArrayStillValid();
      if (ArraySize(ForceCloseTickets) == 0)
         return(false);
      MopUpTradeClosureFailures();
      return(false);
   }//if (ArraySize(ForceCloseTickets) > 0)      
      
   //Code to check that there are sufficient bars in the chart's history. Gaheitman provided this. Many thanks George.
   static bool NeedToCheckHistory=false;
   if (NeedToCheckHistory)
   {
        //Customize these for the EA.  You can use externs for the periods 
        //if the user can change the timeframes used.
        //In a multi-currency bot, you'd put the calls in a loop across
        //all pairs
        
        //Customise these to suit what you are doing
        bool WeHaveHistory = true;
        if (!HistoryOK(Symbol(),TradingTimeFrame)) WeHaveHistory = false;
        if (!WeHaveHistory)
        {
            Alert("There are <100 bars on this chart so the EA cannot work. It has removed itself. Please refresh your chart.");
            ExpertRemove();
        }//if (!WeHaveHistory)
        
        //if we get here, history is OK, so stop checking
        NeedToCheckHistory=false;
   }//if (NeedToCheckHistory)

   //Spread calculation
   
   if(!IsTesting())
     {
      if(CloseEnough(AverageSpread,0))
        {
         GetAverageSpread();
         ShortAverageSpread=AverageSpread;
         ScreenMessage="";
         int left=TicksToCount-CountedTicks;
         SM("Calculating the average spread. "+DoubleToStr(left,0)+" left to count.");
         Comment(ScreenMessage);
         return(false);
        }//if (CloseEnough(AverageSpread, 0) || RunInSpreadDetectionMode) 

      //Keep the average spread updated
      RefreshRates();
      double spread=(Ask-Bid)*factor;
      if(spread>BiggestSpread) BiggestSpread=spread;//Widest spread since the EA was loaded

      static double SpreadTotal=0;
      static int Counter=0;
      
      static double ShortSpreadTotal=0;
      static int ShortCounter=0;
      
      if (NormalizeDouble(spread,1)>0)
        {
         SpreadTotal+=spread;
         Counter++;
         ShortSpreadTotal+=spread;
         ShortCounter++;
        }
        
      if(Counter>=500)
        {
         AverageSpread=NormalizeDouble(SpreadTotal/Counter,1);
         //Save the average for restarts.
         GlobalVariableSet(SpreadGvName,AverageSpread);
         SpreadTotal=0;
         Counter=0;
        }//if(Counter>=500)
        
      if(ShortCounter>=TicksToCount)
        {
         ShortAverageSpread=NormalizeDouble(ShortSpreadTotal/ShortCounter,1);
         ShortSpreadTotal=0;
         ShortCounter=0;
        }//if(ShortCounter>=TicksToCount)
        
     }//if (!IsTesting() )

   //Create a flashing comment if there has been a rogue trade
   if (RobotSuspended) 
   {
      while (RobotSuspended)
      {
         Comment(NL, Gap, "****************** ROBOT SUSPENDED. POSSIBLE ROGUE TRADING ACTIVITY. REMOVE THIE EA IMMEDIATELY ****************** ");
         Sleep(2000);
         Comment("");
         Sleep(1000);
         if ( !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) )
            return(false);
       }//while (RobotSuspended)           
      return(false);
   }//if (RobotSuspended) 

   
    //If HG is sleeping after a trade closure, is it time to awake?
   if (SafetyViolation) TooClose();
   if (SafetyViolation)//TooClose() sets SafetyViolation
   {
      DisplayUserFeedback();
      return(false);
   }//if (SafetyViolation) 
  
      if (OrdersTotal() == 0)
   {
      TicketNo = -1;
      ForceTradeClosure = false;
   }//if (OrdersTotal() == 0)


   GetSwap(Symbol() );//For the swap filters, and in case crim has changed swap rates
   
   //New candle. Cancel an existing alert sent. By default, all the email stuff is turned off, so this is probably redundant.
   static datetime OldAlertBarsTime;
   if (OldAlertBarsTime != iTime(NULL, 0, 0) )
   {
      AlertSent = false;
      OldAlertBarsTime = iTime(NULL, 0, 0);
   }//if (OldAlertBarsTimeBarsTime != iTime(NULL, 0, 0) )
   
      //Daily results so far - they work on what in in the history tab, so users need warning that
   //what they see displayed on screen depends on that.   
   //Code courtesy of TIG yet again. Thanks, George.
   static int OldHistoryTotal;
   if (OrdersHistoryTotal() != OldHistoryTotal)
   {
      CalculateDailyResult();//Does no harm to have a recalc from time to time
      OldHistoryTotal = OrdersHistoryTotal();
   }//if (OrdersHistoryTotal() != OldHistoryTotal)
   
   
   ReadIndicatorValues();//This might want moving to the trading section at the end of this function if EveryTickMode = false
   if (CloseEnough(DistanceBetweenTrades, 0))
      DistanceBetweenTrades = MinimumDistanceBetweenTradesPips;

   //Sixths
   if (UseSixths)
   {
      SixthsStatus = untradable;
      if (Bid > phTradeLine)
         SixthsStatus = tradableshort;
      if (Bid < plTradeLine)
         SixthsStatus = tradablelong;
      if (SixthsStatus == untradable)
         if (AllowTradingInTheMiddle)
            SixthsStatus = tradableboth;            
   }//if (UseSixths)
      
   //Delete orphaned tp/sl lines
   static int M15Bars;
   if (M15Bars != iBars(NULL, PERIOD_M15) )
   {
      M15Bars = iBars(NULL, PERIOD_M15);
      DeleteOrphanTpSlLines();
   }//if (M15Bars != iBars(NULL, PERIOD_M15)
   
      ///////////////////////////////////////////////////////////////////////////////////
   //Find open trades.
   CountOpenTrades();
   //In case a full hedge closed and there were offsetting failures.
   if (ArraySize(ForceCloseTickets) > 0)
   {
      MopUpTradeClosureFailures();
      return(false);
   }//if (ArraySize(ForceCloseTickets) > 0)
   
   if (ReRunCOT)
      CountOpenTrades();
      
   //Should an open position be fully hedged?
   if (MarketTradesTotal > 0)
      //if (!FullyHedged)
      if (UseFullHedging)
         if (ShouldWeFullyHedge())
         {
            FullyHedged = true;
            CountOpenTrades();
            DisplayUserFeedback();
            return(false);
         }//if (ShouldWeFullyHedge)
         
   //Can any of the trades be closed to bank profits?
   ShouldTradesBeClosed();
   //In case any trade closures failed
   if (ArraySize(ForceCloseTickets) > 0)
   {
      while (ArraySize(ForceCloseTickets) > 0)
      {
         MopUpTradeClosureFailures();
         CheckThatForceCloseArrayStillValid();
         if (ArraySize(ForceCloseTickets) == 0)
            return(false);
      }//while (ArraySize(ForceCloseTickets) > 0)      
   }//if (ArraySize(ForceCloseTickets) > 0)      

   //Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Detect a closed trade and check that is was not a rogue.
   if (OldOpenTrades != OpenTrades)
   {
      //Delete orphan diad lines
      if (OpenTrades == 0)   
         if (ObjectFind(TakeProfitLineName) )
            removeDaidLines();
      
      if (IsClosedTradeRogue() )
      {
         RobotSuspended = true;
         return(false);
      }//if (IsClosedTradeRogue() )      
   }//if (OldOpenTrades != OpenTrades)
   
   OldOpenTrades = OpenTrades;

   //Reset various variables
   if (OpenTrades == 0)
   {

   }//if (OpenTrades > 0)
   
   //Just in case we are hedging and part of the grid is entirely missing
   if (UseGrid)
      if (UseHedgingWithGrid)
      {
         //No buy stops
         if (SellOpen || SellStopOpen)
            if (Ask >= HighestBuyPrice)
               if (!BuyStopOpen)
               {
                  SendBuyGrid(Symbol(), OP_BUYSTOP, NormalizeDouble(Ask + (DistanceBetweenTrades / factor), Digits), Lot);
                  CountOpenTrades();
               }//if (!BuyStopOpen)
               
         //No sell stops
         if (BuyOpen || BuyStopOpen)
            if (Bid <= LowestSellPrice)
               if (!SellStopOpen)
               {
                  SendSellGrid(Symbol(), OP_SELLSTOP, NormalizeDouble(Bid - (DistanceBetweenTrades / factor), Digits), Lot);
                  CountOpenTrades();
               }//if (!BuyStopOpen)
              
      }//if (UseHedgingWithGrid)
      
   //Try to fill in gaps left by offsetting
   static datetime OldGapTime = 0;
   //OldGapTime = 0;//Just for now
   if (OldGapTime != iTime(Symbol(), PERIOD_M1, 0))
   {

      OldGapTime = iTime(Symbol(), PERIOD_M1, 0);
      if (UseOffsetting)
      {
         if (ArraySize(BuyPrices) >= 2)
            DealWithBuySideGaps();
      
         if (ArraySize(SellPrices) >= 2)
            DealWithSellSideGaps();
               
      }//if (UseOffsetting)
   }//if (OldGapTime != iTime(Symbol(), PERIOD_M1, 0))

   //Has the market moved far enough away from the grid to demand another trade be sent?
   if (OpenTrades > 0)
      if (UseOffsetting)
         if (FillInGaps)
            CanWeAddAnotherPendingTrade();
      
   //Make sure that the grids on every side have GridSize
   if (UseGrid)
      TrimTheGrids();
   
   ///////////////////////////////////////////////////////////////////////////////////

   //Lot size based on account size
   if (!CloseEnough(LotsPerDollopOfCash, 0))
      CalculateLotAsAmountPerCashDollops();
 
   //Trading times
   TradeTimeOk = CheckTradingTimes();
   if (!TradeTimeOk)
   {
      DisplayUserFeedback();
      return(false);
   }//if (!TradeTimeOk)
   
   ///////////////////////////////////////////////////////////////////////////////////
  
   //Check that there is sufficient margin for trading
   if (!MarginCheck() )
   {
      DisplayUserFeedback();
      Sleep(1000);
      return(false);
   }//if (!MarginCheck() )
   
   //Call the diad function to take over this style of trading
   if (UseDiadStyleTrading)
   {
      DoDiadTrading();
      DisplayUserFeedback();
      return(false);//We do not want OnTick doing anything else
   }//if (UseDiadStyleTrading)
   
   
   //Got this far, so ok to look for trades
   return(true);

}//End bool UsualOnTick()

/*
Places where where you are most likely to need to make changes, and 
a search string for you to find them.

void DisplayUserFeedback(): this is the start of void DisplayUserFeedback(), so add any additional chart information you want to display.
[*]   //Adapt this to suit the indi you are using: add a check for the presence of the indi you are adding.
[*]   if (!EveryTickMode) OldBarsTime = iTime(Symbol(), TradingTimeFrame, 0);: decide whether to make the bot wait for the open 
        of a new candle before attempting to trade.
[*]   //Add a Getxxxxxx function here: add a function to read the indi you are adding.
[*]   if (OldCcaReadTime != iTime(Symbol(), TradingTimeFrame, 0) ): this opens the code block that calls the function/s you have added 
         to read the indi. OldCcaReadTime is set to 0 early in ReadIndicatorValues() if EveryTickMode is 'true'.
[*]   if (!BuySignal): add your indi to the list of conditionals leading to setting BuySignal to 'true' at 3033.
[*]   if (!SellSignal): add your indi to the list of conditionals leading to setting SellSignal to 'true' at 3041.
[*]   bool LookForFullHedgeTradeClosure(int ticket): is the start of bool LookForFullHedgeTradeClosure(int ticket). You may need 
        to add to/amend this function.
[*]   //Add consideration of your CCA here: add code that tells the bot to close/delete the buy trade being examined if the 
          indi you are adding has changed signal. bool LookForTradeClosure(int ticket) is called from within CountOpenTrades, at line 4359.
[*]   //Add consideration of your CCA here: ditto the previous but for sell trades.
[*]   CountOpenTrades(): the start of void CountOpenTrades(). This function builds a picture of the trading position that the EA 'owns'. Make necessary 
        additions to this function. You probably will not need to if all you are doing is adding your own favourite indi, but bear in mind the possible need.
[*]   //ReadUsualIndicatorValues(); You are unlikely to need to make changes here.

*/

/*
  

Matt Kennel has provided the code for bool O_R_CheckForHistory(int ticket). Cheers Matt, You are a star.

Code for adding debugging Sleep
Alert("G");
int x = 0;
while (x == 0) Sleep(100);

Standard order loop code
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;

   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

Code from George, to detect the shift of an order open time
int shift = iBarShift(NULL,Period(),OrderOpenTime(), false);

To calculate what percentage a small number is of a larger one:
(Given amount Divided by Total amount) x100 = %
as in UpperWickPercentage = (UpperWick / CandleSize) * 100; where CandleSize is the size of the the candle and UpperWick the size of the top of the body to the High.

Example of iHighest and iLowest
double lastHigh = iHigh( symbolNames[i], PERIOD_H1, iHighest( symbolNames[i], PERIOD_H1, MODE_HIGH, 24, 1 ) );
double lastLow = iLow( symbolNames[i], PERIOD_H1, iLowest( symbolNames[i], PERIOD_H1, MODE_LOW, 24, 1 ) );

   Full snippet to force closure of all open trades. Use whichever part is most appropriate.
   if (ForceTradeClosure)
   {
      CloseAllTrades();
      if (ForceTradeClosure)
      {
         CloseAllTrades();
         if (ForceTradeClosure)
         {
            return;
         }//if (ForceTradeClosure)                     
      }//if (ForceTradeClosure)         
   }//if (ForceTradeClosure)      

*/
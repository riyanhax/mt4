//+-------------------------------------------------------------------+
//|                               Holy Graily Bob's Candle Power.mq4  |
//|                                    Copyright 2012, Steve Hopwood  |
//|                              http://www.hopwood3.freeserve.co.uk  |
//+-------------------------------------------------------------------+

#define  version "Version 1a"

#property copyright "Copyright 2012, Steve Hopwood"
#property link      "http://www.hopwood3.freeserve.co.uk"
#include <WinUser32.mqh>
#include <stdlib.mqh>
#define  NL    "\n"
#define  up "Up"
#define  down "Down"
#define  ranging "Ranging"
#define  none "None"
#define  both "Both"
#define  buy "Buy"
#define  sell "Sell"

//Peaky status
#define  longdirection ": Long"
#define  shortdirection ": Short"

//SuperSlope colours
#define  red ": Red"
#define  blue ": Blue"
//Changed by tomele
#define white ": White"


//Using hgi_lib
//The HGI library functionality was added by tomele. Many thanks Thomas.
#import "hgi_lib.ex4"
   enum SIGNAL {NONE=0,TRENDUP=1,TRENDDN=2,RANGEUP=3,RANGEDN=4,RADUP=5,RADDN=6};
   enum SLOPE {UNDEFINED=0,RANGEABOVE=1,RANGEBELOW=2,TRENDABOVE=3,TRENDBELOW=4};
   SIGNAL getHGISignal(string symbol,int timeframe,int shift);
   SLOPE getHGISlope (string symbol,int timeframe,int shift);
#import

//HGI constants
#define  hginoarrow " No relevant signal"
#define  hgiuparrowtradable " Tradable up arrow"
#define  hgidownarrowtradable " Tradable down arrow"
#define  hgiuparrowuntradable " Untradable up arrow"
#define  hgidownarrowuntradable " Untradable down arrow"
#define  hgiupradarrowtradable " Tradable Rad up arrow"
#define  hgidownradarrowtradable " Tradable Rad down arrow"
#define  hgiupradarrowuntradable " Untradable Rad up arrow"
#define  hgidownradarrowuntradable " Untradable Rad down arrow"
#define  hgibluewavylong " Blue wavy long"
#define  hgibluewavyshort " Blue wavy short"
#define  hgiyellowrangewavey " Yellow range wavey"
//Chaos
#define  chaosnoarrow "No signal"
#define  chaosuparrow "Up arrow"
#define  chaosdownarrow "Dn arrow"

#define  chaosd1up "Up arrow"
#define  chaosd1dn "Dn arrow"
#define  chaosd1no "No signal"
#define  chaosd2up "Up arrow"
#define  chaosd2dn "Dn arrow"
#define  chaosd2no "No signal"
#define  chaosd3up "Up arrow"
#define  chaosd3dn "Dn arrow"
#define  chaosd3no "No signal"
#define  chaosd4up "Up arrow"
#define  chaosd4dn "Dn arrow"
#define  chaosd4no "No signal"
#define  chaosd5up "Up arrow"
#define  chaosd5dn "Dn arrow"
#define  chaosd5no "No signal"



#define  AllTrades 10 //Tells CloseAllTrades() to close/delete everything
#define  million 1000000;

//Define the FifoBuy/SellTicket fields for offsetting
#define  TradeTicket 1




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

/*

 
Matt Kennel has provided the code for bool O_R_CheckForHistory(int ticket). Cheers Matt, You are a star.

Code for adding debugging Sleep
Alert("G");
int x = 0;
while (x == 0) Sleep(100);
      or
Alert("Y");
RemoveExpert = true;
ExpertRemove();
return;

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
double high = iHigh( Symbol(), TradingTimeFrame, iHighest( Symbol(), TradingTimeFrame, MODE_HIGH, 24, 1 ) );
double low = iLow( Symbol(), TradingTimeFrame, iLowest( Symbol(), TradingTimeFrame, MODE_LOW, 24, 1 ) );

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


extern string  gen="----General inputs----";
/*
Note to coders about TradingTimeFrame. Be consistent in your calls to indicators etc and always use TradingTimeFrame i.e.
double v = iClose(Symbol(), TradingTimeFrame, shift) instead of Close[shift].
This allows the user to change time frames without disturbing the ea. There is a line of code in OnInit(), just above the call
to DisplayUserFeedback() that forces the EA to wait until the open of a new TradingTimeFrame candle; you might want to comment
this out during your EA development.
*/
extern ENUM_TIMEFRAMES TradingTimeFrame=PERIOD_M5;
 bool    EveryTickMode=false;
extern double  Lot=0.01;
extern double  RiskPercent=0;//Set to zero to disable and use Lot
extern double  LotsPerDollopOfCash=0;//Over rides Lot. Zero input to cancel.
extern double  SizeOfDollop=1000;
extern bool    UseBalance=false;
extern bool    UseEquity=true;
//extern int     MaxTradesAllowed=1;//For multi-trade EA's
extern bool    StopTrading=false;
extern bool    TradeLong=true;
extern bool    TradeShort=true;
extern int     TakeProfitPips=0;
extern int     StopLossPips=200;
extern int     MagicNumber=0;
extern string  TradeComment="Chaos Power";
extern bool    IsGlobalPrimeOrECNCriminal=false;
extern double  MaxSlippagePips=5;
//We need more safety to combat the cretins at Crapperquotes managing to break Matt's OR code occasionally.
//EA will make no further attempt to trade for PostTradeAttemptWaitMinutes minutes, whether OR detects a receipt return or not.
extern int     PostTradeAttemptWaitSeconds=10;//Defaults to 10 minutes
////////////////////////////////////////////////////////////////////////////////////////
datetime       TimeToStartTrading=0;//Re-start calling LookForTradingOpportunities() at this time.
double         TakeProfit, StopLoss;
datetime       OldBarsTime;
double         dPriceFloor = 0, dPriceCeiling = 0;//Next x0 numbers
double         PriceCeiling100 = 0, PriceFloor100 = 0;// Next 'big' numbers

string         GvName="Under management flag";//The name of the GV that tells the EA not to send trades whilst the manager is closing them.
//'Close all trades this pair only script' sets a GV to tell EA's not to attempt a trade during closure
string         LocalGvName = "Local closure in operation " + Symbol();
//'Nuclear option script' sets a GV to tell EA's not to attempt a trade during closure
string         NuclearGvName = "Nuclear option closure in operation " + Symbol();

string         TradingTimeFrameDisplay="";
//For FIFO
int            FifoTicket[];//Array to store trade ticket numbers in FIFO mode, to cater for
                            //US citizens and to make iterating through the trade closure loop 
                            //quicker.
//An array to store ticket numbers of trades that need closing, should an offsetting OrderClose fail
double         ForceCloseTickets[];
bool           RemoveExpert=false;
double         MinDistanceBetweenTrades=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep2c="================================================================";
extern string  mpp="---- Minimum pips in between same-pair trades ----";
extern int     MinDistanceBetweenTradesPips=20;


//Hgi is used to close profitable trades
extern string  sep1="================================================================";
extern string  hgic="======== HGI choices ========";
extern string  hgi="-- HGI Inputs --"; 
extern ENUM_TIMEFRAMES HgiTimeFrame=PERIOD_M5;
extern bool    CloseOnLargeArrows=false;
extern bool    CloseOnBlueWavy=false;
extern bool    OnlyCloseWinningTrades=true;
////////////////////////////////////////////////////////////////////////////////////////
string         HgiStatus;//Constants defined at top of file//Amended HGI code
string         HgiTimeFrameDisplay="";
////////////////////////////////////////////////////////////////////////////////////////


extern string  sep2="================================================================";
extern string  btp="---- Hedged Basket take profit inputs ----";
extern int     HedgedBasketCashTakeProfit=20;
////////////////////////////////////////////////////////////////////////////////////////
bool           Hedged=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sepb="================================================================";
extern string  off="---- Offsetting ----";
extern bool    UseOffsetting=false;//Simple offset and double-sided complex offset
extern bool    AllowComplexSingleSidedOffsets=true;//Allow complex single-sided offset. Not allowed if UseOffsetting = false
extern int     MinOpenTradesToStartOffset=4;//Only use offsetting if there are at least this number of trades in the group

extern string  sep2a="================================================================";
extern string  ubp="---- Unbalanced positions inputs ----";
extern int     PositionIsUnbalancedAt=5;//The difference between open buys and sells to constitute an unbalanced position.
                                        //Set this to a high value to disable the feature.
extern string  rec="-- Offsetting for unbalanced positions --";
extern bool    UseOffsettingForBalanceRecovery=false;
extern bool    AllowComplexSingleSidedOffsetsRecovery=true;//Allow complex single-sided offset. Not allowed if UseOffsetting = false
extern int     MinTradesToStartUnbalancedOffset=6;
extern string  nco="-- Nuclear option closure --";
extern bool    UseInstantClosure=false;//Close the position the moment it becomes unbalanced.
extern bool    UseMarginLevelClosure=false;//Only close when the margin level drops
extern int     ClosureMarginLevel=500;     //to this point.
////////////////////////////////////////////////////////////////////////////////////////
//Some variables to turn off the management features to allow for a form of
//recovery basket trading in an unbalanced position.
bool           AllowTradeManagement=true, Unbalanced=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  ads1="================================================================";
//Additional strategies. These can be used in conjunction with all the original Candle Power
//features. 
extern string  DirectionalTrading="---- Directional trade filters ----";
extern string  thgi="-- HGI --";
extern bool    UseHgiTrendFilter=true;
extern ENUM_TIMEFRAMES HgiTradeFilterTimeFrame=PERIOD_H4;
extern bool    TradeTrendArrows=true;
extern bool    TradeBlueWavyLines=true;
extern bool    HgiCloseOnOppositeSignal=true;
extern bool    HgiCloseOnYellowWavy=false;
////////////////////////////////////////////////////////////////////////////////////////
string         TradeHgiStatus;//Constants defined at top of file//Amended HGI code
string         TradeHgiTimeFrameDisplay="";
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
extern bool    SsCloseTradesOnColourChange=true;
////////////////////////////////////////////////////////////////////////////////////////
string         SsColour="";//For shifts 0 to 2. Colours defined at top of file
string         SsTimeFrameDisplay="";
////////////////////////////////////////////////////////////////////////////////////////
sinput string  sepx1="================================================================";
sinput string  chi="---- Chaos inputs ----";
bool    UseChaosOnTradingTimeFrame=true;
extern ENUM_TIMEFRAMES ChaosTimeFrame=PERIOD_M5;

datetime time_cur_up, time_cur_dw;
  double fractal_l;
  double fractal_h;
  double upfractal;
  double dwfractal;

extern int       JawPeriod = 13;
extern int       JawShift = 8;
extern int       TeethPeriod = 8;
extern int       TeethShift = 5;
extern int       LipsPeriod = 5;
extern int       LipsShift = 3;
extern int       AlligatorMethod = 2;
extern int       AlligatorPrice = 4;

string ChaosStatus;
string ChaosD1;
string ChaosD2;
string ChaosD3;
string ChaosD4;
string ChaosD5;





double ZigzagBuffer[];
double HighMapBuffer[];
double LowMapBuffer[];
int level=3; // recounting's depth 
bool downloadhistory=false;
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
extern bool    MaCloseTradesOnTrendChange=true;
////////////////////////////////////////////////////////////////////////////////////////
double         MaVal;
string         MaTrend;//up, down or none constants
string         MaTimeFrameDisplay="";
////////////////////////////////////////////////////////////////////////////////////////

extern string  asep3="----";
extern string  pea="-- Peaky --";
extern bool    UsePeaky = true;
extern ENUM_TIMEFRAMES PeakyTimeFrame=PERIOD_M5;
extern int     NoOfBarsOnChart=1682;
extern bool    PeakyCloseTradesOnDirectionChange=true;
////////////////////////////////////////////////////////////////////////////////////////
string         PeakyStatus="";// One of the longdirection/shortdirection constants
string         PeakyTimeFrameDisplay="";
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1a="================================================================";
extern string  sfs="----SafetyFeature----";
//Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Use the next input 
//in combination with TooClose() to abort the trade if the previous one closed within the time limit.
extern int     MinMinutesBetweenTradeOpenClose=0;//For spotting possible rogue trades
extern int     MinMinutesBetweenTrades=0;//Minimum time to pass after a trade closes, until the ea can open another.
////////////////////////////////////////////////////////////////////////////////////////
bool           SafetyViolation;//For chart display
bool           RobotSuspended=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep3="================================================================";
//Hidden tp/sl inputs.
extern string  hts="----Stealth stop loss and take profit inputs----";
extern int     PipsHiddenFromCriminal=0;//Added to the 'hard' sl and tp and used for closure calculations
                                         ////////////////////////////////////////////////////////////////////////////////////////
double         HiddenStopLoss,HiddenTakeProfit;
double         HiddenPips=0;//Added to the 'hard' sl and tp and used for closure calculations
                             ////////////////////////////////////////////////////////////////////////////////////////

extern string  sep7="================================================================";
//CheckTradingTimes. Baluda has provided all the code for this. Mny thanks Paul; you are a star.
extern string  trh            = "----Trading hours----";
extern string  tr1            = "tradingHours is a comma delimited list";
extern string  tr1a="of start and stop times.";
extern string  tr2="Prefix start with '+', stop with '-'";
extern string  tr2a="Use 24H format, local time.";
extern string  tr3="Example: '+07.00,-10.30,+14.15,-16.00'";
extern string  tr3a="Do not leave spaces";
extern string  tr4="Blank input means 24 hour trading.";
extern string  tradingHours="";
////////////////////////////////////////////////////////////////////////////////////////
double         TradeTimeOn[];
double         TradeTimeOff[];
// trading hours variables
int            tradeHours[];
string         tradingHoursDisplay;//tradingHours is reduced to "" on initTradingHours, so this variable saves it for screen display.
bool           TradeTimeOk;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1de="================================================================";
extern string  fssmt="---- Inputs applied to individual days ----";
extern int     FridayStopTradingHour=14;//Ignore signals at and after this time on Friday.
                                        //Local time input. >23 to disable.
extern int     FridayCloseAllHour=20;//Friday time to close all open trades/delete stop orders for the weekend.
                                     //Local time input. >23 to disable.
extern int     SaturdayStopTradingHour=24;//For those in Upside Down Land.  
extern int     SaturdayCloseAllHour=24;//For those in Upside Down Land.  
                                       //Local time input. >23 to disable.
extern int     MaxAllowableCashLoss=-20;//Only close all trades when the negative cash upl is less than this.
                                       //Converted into a negative value in OnInit()   
extern bool    TradeSundayCandle=false;
extern int     MondayStartHour=8;//24h local time     
 bool    TradeThursdayCandle=true;//Thursday tends to be a reversal day, so avoid it.                               

//This code by tomele. Thank you Thomas. Wonderful stuff.
extern string  sep7b="================================================================";
extern string  roll="---- Rollover time ----";
extern bool    DisableEaDuringRollover=true;
extern string  ro1 = "Use 24H format, SERVER time.";
extern string  ro2 = "Example: '23.55'";
extern string  RollOverStarts="23.55";
extern string  RollOverEnds="00.15";
////////////////////////////////////////////////////////////////////////////////////////
bool           RolloverInProgress=false;//Tells DisplayUserFeedback() to display the rollover message
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
bool    RunInSpreadDetectionMode=false;
extern int     TicksToCount=5;//The ticks to count whilst canculating the av spread
extern double  MultiplierToDetectStopHunt=10;
////////////////////////////////////////////////////////////////////////////////////////
double         AverageSpread=0;
string         SpreadGvName;//A GV will hold the calculated average spread
int            CountedTicks=0;//For status display whilst calculating the spread
double         BiggestSpread=0;//Holds a record of the widest spread since the EA was loaded
////////////////////////////////////////////////////////////////////////////////////////


extern string  sep13="================================================================";
extern string  tmm="----Trade management module----";
//Breakeven has to be enabled for JS and TS to work.
extern string  BE="Break even settings";
extern bool    BreakEven=true;
extern int     BreakEvenTargetPips=20;
extern int     BreakEvenTargetProfit=2;
extern bool    PartCloseEnabled=false;
extern double  PartClosePercent=50;//Percentage of the trade lots to close
////////////////////////////////////////////////////////////////////////////////////////
double         BreakEvenPips,BreakEvenProfit;
bool           TradeHasPartClosed=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep14="================================================================";
extern string  JSL="Jumping stop loss settings";
extern bool    JumpingStop=true;
extern int     JumpingStopTargetPips=2;
////////////////////////////////////////////////////////////////////////////////////////
double         JumpingStopPips;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep15="================================================================";
extern string  cts="----Candlestick jumping stop----";
extern bool    UseCandlestickTrailingStop=false;
extern int     CstTimeFrame=0;//Defaults to current chart
extern int     CstTrailCandles=1;//Defaults to previous candle
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
extern int     DisplayGapSize    = 30; // if using Comments
// ****************************** added to make screen Text more readable
extern bool    DisplayAsText     = true;  // replaces Comment() with OBJ_LABEL text
extern bool    KeepTextOnTop     = true;//Disable the chart in foreground CrapTx setting so the candles do not obscure the text
extern int     DisplayX          = 100;
extern int     DisplayY          = 0;
extern int     fontSise          = 8;
extern string  fontName          = "Arial";
extern color   colour            = Yellow;
////////////////////////////////////////////////////////////////////////////////////////
int            DisplayCount;
string         Gap,ScreenMessage;
////////////////////////////////////////////////////////////////////////////////////////
//  *****************************

//Calculating the factor needed to turn pip values into their correct points value to accommodate different Digit size.
//Thanks to Lifesys for providing this code. Coders, you need to briefly turn of Wrap and turn on a mono-spaced font to view this properly and see how easy it is to make changes.
//string         pipFactor[]  = {"JPY","XAG","SILVER","BRENT","WTI","XAU","GOLD","SP500","S&P","UK100","WS30","DAX30","DJ30","NAS100","CAC400"};
//double         pipFactors[] = { 100,  100,  100,     100,    100,  10,   10,    10,     10,   1,      1,     1,      1,     1,       1};
//And by Steve. I have pinched Tomasso's APTM function for returning the value of factor. Thanks Tommaso
double         factor;//For pips/points stuff. Set up in int init()
////////////////////////////////////////////////////////////////////////////////////////

//Matt's O-R stuff
int            O_R_Setting_max_retries=10;
double         O_R_Setting_sleep_time=4.0; /* seconds */
double         O_R_Setting_sleep_max=15.0; /* seconds */
int            RetryCount=10;//Will make this number of attempts to get around the trade context busy error.


//Running total of trades
int            LossTrades,WinTrades;
double         OverallProfit;

//Misc
int            OldBars;
string         PipDescription=" pips";
bool           ForceTradeClosure;
int            TurnOff=0;//For turning off functions without removing their code

//Variables for building a picture of the open position
int            MarketTradesTotal=0;//Total of open market trades
//Market Buy trades
bool           BuyOpen=false;
int            MarketBuysCount=0;
double         LatestBuyPrice=0, EarliestBuyPrice=0, HighestBuyPrice=0, LowestBuyPrice=0;
int            BuyTicketNo=-1, HighestBuyTicketNo=-1, LowestBuyTicketNo=-1, LatestBuyTicketNo=-1, EarliestBuyTicketNo=-1;
double         BuyPipsUpl=0;
double         BuyCashUpl=0;
datetime       LatestBuyTradeTime=0;
datetime       EarliestBuyTradeTime=0;

//Market Sell trades
bool           SellOpen=false;
int            MarketSellsCount=0;
double         LatestSellPrice=0, EarliestSellPrice=0, HighestSellPrice=0, LowestSellPrice=0;
int            SellTicketNo=-1, HighestSellTicketNo=-1, LowestSellTicketNo=-1, LatestSellTicketNo=-1, EarliestSellTicketNo=-1;;
double         SellPipsUpl=0;
double         SellCashUpl=0;
datetime       LatestSellTradeTime=0;
datetime       EarliestSellTradeTime=0;

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
//Variable for the hedging/recovery code to tell if there are tp's and sl's set
bool           TpSet=false, SlSet=false;
//Offsetting arrays
double         GridOrderBuyTickets[][2]; // number of lines will be equal to MarketBuysOpen - 1
double         GridOrderSellTickets[][2];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplayUserFeedback()
{
   if(IsTesting() && !IsVisualMode()) return;

   string text = "";

   //cpu saving
   static datetime CurrentTime = 0;
   static datetime DisplayNow = 0;
   if (TimeCurrent() < DisplayNow )
      return;
   CurrentTime = TimeCurrent();
   DisplayNow = CurrentTime + ChartRefreshDelaySeconds;

 
 
//   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   removeAllObjects();
//   *************************

   ScreenMessage="";
   //ScreenMessage = StringConcatenate(ScreenMessage,Gap + NL);
   SM(NL);
   if(SafetyViolation) SM("*************** CANNOT TRADE YET. TOO SOON AFTER CLOSE OF PREVIOUS TRADE***************"+NL);

   SM("Updates for this EA are to be found at http://www.stevehopwoodforex.com"+NL);
   SM("Feeling generous? Help keep the coder going with a small Paypal donation to pianodoodler@hotmail.com"+NL);
   SM("Broker time = "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS)+": Local time = "+TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS)+NL);
   SM(version+NL);
/*
   //Code for time to bar-end display donated by Baluda. Cheers Paul.
   SM( TimeToString( iTime(Symbol(), TradingTimeFrame, 0) + TradingTimeFrame * 60 - CurTime(), TIME_MINUTES|TIME_SECONDS ) 
   + " left to bar end" + NL );
   */
   if(!TradeTimeOk)
   {
      SM(NL);
      SM("---------- OUTSIDE TRADING HOURS. Will continue to monitor opent trades. ----------"+NL+NL);
   }//if (!TradeTimeOk)

   if(RolloverInProgress)
   {
      SM(NL);
      SM("---------- ROLLOVER IN PROGRESS. I am taking no action until "+RollOverEnds+" ----------"+NL+NL);
      return;
   }//if (RolloverInProgress)
 
   SM(NL);

   SM(NL);
   //Hidden HGI code
   
   if (CloseOnLargeArrows || CloseOnBlueWavy)
   {
      SM("HGI trade closure time frame: " + HgiTimeFrameDisplay + " Signal status is " + HgiStatus + NL);
   }//if (CloseOnLargeArrows || CloseOnBlueWavy)
   
   if (UseHgiTrendFilter)
      SM("Trade filter HGI time frame is " + TradeHgiTimeFrameDisplay + ": Signal status is " + TradeHgiStatus + NL);

   if (UseSuperSlope)
      SM("SuperSlope time frame is " + SsTimeFrameDisplay + ": colour is" + SsColour + NL); 
   
   if (UseBobMovingAverage) 
      SM("Moving average time frame is " + MaTimeFrameDisplay + ": Value = " + DoubleToStr(MaVal, Digits) + ": Trend is " + MaTrend + NL);
   
   if (UsePeaky) 
      SM("Peak time frame is " + PeakyTimeFrameDisplay + ": Trading direction is" + PeakyStatus + NL);

   if (UseChaosOnTradingTimeFrame) 
      SM("Chaos: Trading direction is: " + ChaosStatus + NL);
      SM("Chaos: dimension 1 is: " + ChaosD1 + NL);
      SM("Chaos: dimension 2 is: " + ChaosD2 + NL);
      SM("Chaos: dimension 3 is: " + ChaosD3 + NL);
      SM("Chaos: dimension 4 is: " + ChaosD4 + NL);
      SM("Chaos: dimension 5 is: " + ChaosD5 + NL);
   
   if (BuySignal)
      SM("I am taking long trades" + NL);
   if (SellSignal)
      SM("I am taking short trades" + NL);
   if (!BuySignal)
      if (!SellSignal)
         SM("The dimension signals are mixed, so I cannot trade" + NL);
               
   SM(NL);     
   text = "Market trades open = ";
   SM(text + IntegerToString(MarketTradesTotal) + ": Pips UPL = " + DoubleToStr(PipsUpl, 0)
   +  ": Cash UPL = " + DoubleToStr(CashUpl, 2) + NL);
   if (BuyOpen)
      SM("Buy trades = " + IntegerToString(MarketBuysCount)
         + ": Pips upl = " + IntegerToString(BuyPipsUpl)
         + ": Cash upl = " + DoubleToStr(BuyCashUpl, 2)
         + NL);
   if (SellOpen)
      SM("Sell trades = " + IntegerToString(MarketSellsCount)
         + ": Pips upl = " + IntegerToString(SellPipsUpl)
         + ": Cash upl = " + DoubleToStr(SellCashUpl,2)
         + NL);
   if (Hedged || Unbalanced)
      SM("I am looking for an opportunity to close the position at a profit." + NL);

   
   SM(NL);
   SM("Trading time frame: " + TradingTimeFrameDisplay + NL);
   if (TradeLong) SM("Taking long trades" + NL);
   if (TradeShort) SM("Taking short trades" + NL);
   if (!TradeLong && !TradeShort) SM("Both TradeLong and TradeShort are set to false" + NL);
   SM("Lot size: "+DoubleToStr(Lot,2)+" (Criminal's minimum lot size: "+DoubleToStr(MarketInfo(Symbol(),MODE_MINLOT),2)+")"+NL);
   if(!CloseEnough(TakeProfit,0)) SM("Take profit: "+DoubleToStr(TakeProfit,0)+PipDescription+NL);
   if(!CloseEnough(StopLoss,0)) SM("Stop loss: "+DoubleToStr(StopLoss,0)+PipDescription+NL);
   SM("Magic number: "+MagicNumber+NL);
   SM("Trade comment: "+TradeComment+NL);
   if(IsGlobalPrimeOrECNCriminal) SM("IsGlobalPrimeOrECNCriminal = true"+NL);
   else SM("IsGlobalPrimeOrECNCriminal = false"+NL);
   double spread=(Ask-Bid)*factor;
   SM("Average Spread = "+DoubleToStr(AverageSpread,1)+": Spread = "+DoubleToStr(spread,1)+": Widest since loading = "+DoubleToStr(BiggestSpread,1)+NL);
   SM(NL);

   //Trading hours
   if(tradingHoursDisplay!="") SM("Trading hours: "+tradingHoursDisplay+NL);
   else SM("24 hour trading: "+NL);

   if(MarginMessage!="") SM(MarginMessage+NL);

   //Running total of trades
   SM(Gap+NL);
   SM("Results today. Wins: "+WinTrades+": Losses "+LossTrades+": P/L "+DoubleToStr(OverallProfit,2)+NL);

   SM(NL);

   if(BreakEven)
   {
      SM("Breakeven is set to "+DoubleToStr(BreakEvenPips,0)+PipDescription+": BreakEvenProfit = "+DoubleToStr(BreakEvenProfit,0)+PipDescription);
      SM(NL);
      if(PartCloseEnabled)
      {
         double CloseLots=NormalizeLots(Symbol(),Lot *(PartClosePercent/100));
         SM("Part-close is enabled at "+DoubleToStr(PartClosePercent,2)+"% ("+DoubleToStr(CloseLots,2)+" lots to close)"+NL);
      }//if (PartCloseEnabled)      
   }//if (BreakEven)

   if(UseCandlestickTrailingStop)
   {
      SM("Using candlestick trailing stop"+NL);
   }//if (UseCandlestickTrailingStop)

   if(JumpingStop)
   {
      SM("Jumping stop is set to "+DoubleToStr(JumpingStopPips,0)+PipDescription);
      SM(NL);
   }//if (JumpingStop)

   if(TrailingStop)
   {
      SM("Trailing stop is set to "+DoubleToStr(TrailingStopPips,0)+PipDescription);
      SM(NL);
   }//if (TrailingStop)


   Comment(ScreenMessage);

}//void DisplayUserFeedback()
  
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
     ObjectSet(lab_str, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(fontSise+4));
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
        ofset+=(int)(w-fontSise*0.25);
     else
        ofset+=(int)(w-fontSise*0.65);
     /////////////////////////////////////////////////
        
  }//for (int cc = 0; cc < 5; cc++)
}
         

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

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//----


   //Missing indi check
   /*
   if (!indiExists( "IndiName" ))
   {
      Alert("");
      Alert("Download the indi from the thread or from http://www.stevehopwoodforex.com/phpBB3/viewtopic.php?f=15&t=79&p=803#p803");
      Alert("The required indicator " + "IndiName" + " does not exist on your platform. I am removing myself from your chart.");
      RemoveExpert = true;
      ExpertRemove();
      return(0);
   }//if (! indiExists( "IndiName" ))
   */
  
   

//~ Set up the pips factor. tp and sl etc.
//~ The EA uses doubles and assume the value of the integer user inputs. This: 
//~    1) minimises the danger of the inputs becoming corrupted by restarts; 
//~    2) the integer inputs cannot be divided by factor - doing so results in zero.

   factor=GetPipFactor(Symbol());
   StopLoss=StopLossPips;
   TakeProfit=TakeProfitPips;
   BreakEvenPips=BreakEvenTargetPips;
   BreakEvenProfit = BreakEvenTargetProfit;
   JumpingStopPips = JumpingStopTargetPips;
   TrailingStopPips= TrailingStopTargetPips;
   HiddenPips=PipsHiddenFromCriminal;
   MinDistanceBetweenTrades = MinDistanceBetweenTradesPips;

   while(IsConnected()==false)
   {
      Comment("Waiting for MT4 connection...");
      Comment("");

      Sleep(1000);
   }//while (IsConnected()==false)


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

   //Turn MaxAllowableCashLoss begative if the user has forgotten.
   if (MaxAllowableCashLoss > 0)
      MaxAllowableCashLoss*= -1;
   
   
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
   string name= TerminalCompany();
   int ispart = StringFind(name,"IBFX",0);
   if(ispart<0) ispart=StringFind(name,"Interbank FX",0);
   if(ispart>-1) IsGlobalPrimeOrECNCriminal=true;
   ispart=StringFind(name,"Global Prime",0);
   if(ispart>-1) IsGlobalPrimeOrECNCriminal=true;

   //Set up the trading hours
   tradingHoursDisplay=tradingHours;//For display
   initTradingHours();//Sets up the trading hours array

   
   if(TradeComment=="") TradeComment=" ";
   OldBars=Bars;
   TicketNo=-1;
   ReadIndicatorValues();//For initial display in case user has turned of constant re-display
   TooClose();
   CountOpenTrades();
   OldOpenTrades=OpenTrades;
   TradeTimeOk=CheckTradingTimes();
   
   //The apread global variable
   if (!IsTesting() )
   {
      SpreadGvName=Symbol()+" average spread";
      AverageSpread=GlobalVariableGet(SpreadGvName);//If no gv, then the value will be left at zero.
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
   //Hidden HGI code
   HgiTimeFrameDisplay = GetTimeFrameDisplay(HgiTimeFrame);
   TradeHgiTimeFrameDisplay = GetTimeFrameDisplay(HgiTradeFilterTimeFrame);
   SsTimeFrameDisplay = GetTimeFrameDisplay(SsTimeFrame);
   MaTimeFrameDisplay = GetTimeFrameDisplay(MaTimeFrame);
   PeakyTimeFrameDisplay = GetTimeFrameDisplay(PeakyTimeFrame);
   
   
   DisplayUserFeedback();


//Call sq's show trades indi
//iCustom(NULL, 0, "SQ_showTrades",Magic, 0,0);


//----
   return(0);
}//End OnInit
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//----
   Comment("");
   removeAllObjects();

//----
   return;
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SendSingleTrade(string symbol,int type,string comment,double lotsize,double price,double stop,double take)
{

   double slippage=MaxSlippagePips*MathPow(10,Digits)/factor;
   int ticket = -1;


   color col=Red;
   if(type==OP_BUY || type==OP_BUYSTOP || type == OP_BUYLIMIT) col=Green;

   datetime expiry=0;
   //if (SendPendingTrades) expiry = TimeCurrent() + (PendingExpiryMinutes * 60);

   //RetryCount is declared as 10 in the Trading variables section at the top of this file
   for(int cc=0; cc<RetryCount; cc++)
     {
      //for (int d = 0; (d < RetryCount) && IsTradeContextBusy(); d++) Sleep(100);

      while(IsTradeContextBusy()) Sleep(100);//Put here so that excess slippage will cancel the trade if the ea has to wait for some time.
      
      RefreshRates();
      if(type == OP_BUY) price = MarketInfo(symbol, MODE_ASK);
      if(type == OP_SELL) price = MarketInfo(symbol, MODE_BID);

      
      if(!IsGlobalPrimeOrECNCriminal)
         ticket=OrderSend(symbol,type,lotsize,price,slippage,stop,take,comment,MagicNumber,expiry,col);

      //Is a 2 stage criminal
      if(IsGlobalPrimeOrECNCriminal)
      {
         ticket=OrderSend(symbol,type,lotsize,price,slippage,0,0,comment,MagicNumber,expiry,col);
         if(ticket>-1)
         {
            ModifyOrderTpSl(ticket,stop,take);
         }//if (ticket > 0)}
      }//if (IsGlobalPrimeOrECNCriminal)

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
         if (type < 2)
            Alert(symbol," ",WindowExpertName()," ",stype," order send failed with error(",err,"): ",ErrorDescription(err));
         Print(symbol," ",WindowExpertName()," ",stype," order send failed with error(",err,"): ",ErrorDescription(err));
         return(false);
        }//if (ticket < 0)  
     }//for (int cc = 0; cc < RetryCount; cc++);

   TicketNo=ticket;
   //Make sure the trade has appeared in the platform's history to avoid duplicate trades.
   //My mod of Matt's code attempts to overcome the bastard crim's attempts to overcome Matt's code.
   bool TradeReturnedFromCriminal=false;
   while(!TradeReturnedFromCriminal)
     {
      TradeReturnedFromCriminal=O_R_CheckForHistory(ticket);
      if(!TradeReturnedFromCriminal)
        {
         Alert(Symbol()," sent trade not in your trade history yet. Turn of this ea NOW.");
        }//if (!TradeReturnedFromCriminal)
     }//while (!TradeReturnedFromCriminal)

   //Got this far, so trade send succeeded
   return(true);

}//End bool SendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
         Print("Did not find #"+ticket+" in history, sleeping, then doing retry #"+cnt);
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
      Print("Never found #"+ticket+" in history! crap!");
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
   int ms = t*1000;
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
   
    
   
   
   return(true);


}//End bool IsTradingAllowed()

double CalculateLotSize(double price1,double price2)
{
   //Calculate the lot size by risk. Code kindly supplied by jmw1970. Nice one jmw.

   if(price1==0 || price2==0) return(Lot);//Just in case

   double FreeMargin= AccountFreeMargin();
   double TickValue = MarketInfo(Symbol(),MODE_TICKVALUE);
   double LotStep=MarketInfo(Symbol(),MODE_LOTSTEP);

   double SLPts=MathAbs(price1-price2);
   //SLPts/=Point;//No idea why *= factor does not work here, but it doesn't
   SLPts = int(SLPts * factor * 10);//Code from Radar. Thanks Radar; much appreciated

   double Exposure=SLPts*TickValue; // Exposure based on 1 full lot

   double AllowedExposure=(FreeMargin*RiskPercent)/100;

   int TotalSteps = ((AllowedExposure / Exposure) / LotStep);
   double LotSize = TotalSteps * LotStep;

   double MinLots = MarketInfo(Symbol(), MODE_MINLOT);
   double MaxLots = MarketInfo(Symbol(), MODE_MAXLOT);

   if(LotSize < MinLots) LotSize = MinLots;
   if(LotSize > MaxLots) LotSize = MaxLots;
   return(LotSize);

}//double CalculateLotSize(double price1, double price1)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateStopLoss(int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double stop;

   RefreshRates();
   

   
   if (type == OP_BUY)
   {
      if (!CloseEnough(StopLoss, 0) ) 
      {
         stop = price - (StopLoss / factor);
         HiddenStopLoss = stop;
      }//if (!CloseEnough(StopLoss, 0) ) 

      if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop - (HiddenPips / factor), Digits);
   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(StopLoss, 0) ) 
      {
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
   double take;

   RefreshRates();
   
   double StopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD);
   double spread = (Ask - Bid) * factor;

   
   if (type == OP_BUY)
   {
      if (!CloseEnough(TakeProfit, 0) )
      {
         if (TakeProfit < StopLevel) 
            if (TakeProfitPips > 0)   
               TakeProfit = StopLevel;
         take = price + (TakeProfit / factor);
         HiddenTakeProfit = take;
      }//if (!CloseEnough(TakeProfit, 0) )

               
      if (HiddenPips > 0 && take > 0) take = NormalizeDouble(take + (HiddenPips / factor), Digits);

   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(TakeProfit, 0) )
      {
         if (TakeProfit < StopLevel) 
            if (TakeProfitPips > 0)   
               TakeProfit = StopLevel;
         take = price - (TakeProfit / factor);
         HiddenTakeProfit = take;         
      }//if (!CloseEnough(TakeProfit, 0) )
      
      
      if (HiddenPips > 0 && take > 0) take = NormalizeDouble(take - (HiddenPips / factor), Digits);

   }//if (type == OP_SELL)
   
   return(take);
   
}//End double CalculateTakeProfit(int type)

bool EnoughDistance(int type, double price)
{
   //Returns false if the is < MinDistanceBetweenTradesPips
   //between the price and the nearest order open prices.
   
   double pips = 0;
   
   //No market order yet
   if (type == OP_BUY)
      if (!BuyOpen)
         return(true);
      
   if (type == OP_SELL)
      if (!SellOpen)
         return(true);
      
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderType() != type) continue;

      pips = MathAbs(price - OrderOpenPrice() ) * factor;
      if (pips < MinDistanceBetweenTrades)
         return(false);
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

 
   //Got here, so OK to trade
   return(true);

   

}//End bool EnoughDistance(int type, double price)


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LookForTradingOpportunities()
{


   RefreshRates();
   double take, stop, price;
   int type;
   bool result = false;

   double SendLots = Lot;
   //Check filters
   if (!IsTradingAllowed() ) return;
   
   bool SendTrade = false;
   double targetHigh = 0, targetLow = 0;//For the hilo of market trades open
   int err = 0;
   
   
   /////////////////////////////////////////////////////////////////////////////////////
   
   
    

////////////////////////////////////////////////////////////////////////////////////////
   
   
   //Long 
   if (!BuyStopOpen && TradeLong && BuySignal)
   {
       
      //The idea is to place a stop order at the top of the previous candle,
      //so send an immediate market order it the price already exceeds this.
      if (Ask >= iHigh(Symbol(), TradingTimeFrame, 1) )
      {
         type=OP_BUY;
         price = Ask;//Change this to whatever the price needs to be
      }//if (Ask >= iHigh(Symbol(), TradingTimeFrame, 1) )
      else
      {
         type = OP_BUYSTOP;
         price = iHigh(Symbol(), TradingTimeFrame, 1);      
      }//else
        
      //The market must be MinDistanceBetweenTradesPips away from the existing market trades
      //to avoid bunching.
      SendTrade = true;
      if (BuyOpen)
         if (MinDistanceBetweenTradesPips > 0)
         {
            if (!EnoughDistance(OP_BUY, price) )
               SendTrade = false;                  
         }//if (MinDistanceBetweenTradesPips > 0)
         
    
      
      if (SendTrade)
      {
         stop = CalculateStopLoss(OP_BUY, price);
         
         
         take = CalculateTakeProfit(OP_BUY, price);
         
         
         //Lot size calculated by risk
         if (!CloseEnough(RiskPercent, 0)) SendLots = CalculateLotSize(price, NormalizeDouble(stop + (HiddenPips / factor), Digits) );
   
            
         result = SendSingleTrade(Symbol(), type, TradeComment, SendLots, price, stop, take);
         
   
         if (result) 
         {
            if (type == OP_BUYSTOP)
               BuyStopOpen = true;
            if (type == OP_BUY)
               BuyOpen = true;
               
            //The latest garbage from the morons at Crapperquotes appears to occasionally break Matt's OR code, so tell the
            //ea not to trade for a while, to give time for the trade receipt to return from the server.
            TimeToStartTrading = TimeCurrent() + PostTradeAttemptWaitSeconds;         
            if (BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )
            {         
               CheckTpSlAreCorrect(type);
            }//if (BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )   
         }//if (result)          
               
         //If a stop level error prevented the stop order being sent, then send a market order instead
         if (!result)
         {
            err = GetLastError();
            if (err == 130)
            {
               result = SendSingleTrade(Symbol(), OP_BUY, TradeComment, SendLots, price, stop, take);
               TimeToStartTrading = TimeCurrent() + PostTradeAttemptWaitSeconds;         
               if (BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  CheckTpSlAreCorrect(OrderType() );
            }//if (err == 130)
         }//if (!result)
         
         if (!result)
         {
            TimeToStartTrading = 0;
            OldBarsTime = 0;
         }//if (!result)
      
      }//if (SendTrade)
      
   
   }//if (!BuyStopOpen)
   
   //Short
   if (!SellStopOpen && TradeShort && SellSignal)
   {
      
      //The idea is to place a stop order at the bottom of the previous candle,
      //so send an immediate market order it the price already exceeds this.
      if (Bid <= iLow(Symbol(), TradingTimeFrame, 1) )
      {
         type=OP_SELL;
         price = Bid;//Change this to whatever the price needs to be
      }//if (Bid <= iLow(Symbol(), TradingTimeFrame, 1) )
      else
      {
         type = OP_SELLSTOP;
         price = iLow(Symbol(), TradingTimeFrame, 1);      
      }//else
        
      
      //The market must be MinDistanceBetweenTradesPips away from the existing market trades
      //to avoid bunching.
      SendTrade = true;
      if (SellOpen)
         if (MinDistanceBetweenTradesPips > 0)
         {
            if (!EnoughDistance(OP_SELL, price) )
               SendTrade = false;                  
         }//if (MinDistanceBetweenTradesPips > 0)
        
      if (SendTrade)
      {
         stop = CalculateStopLoss(OP_SELL, price);
      
      
         take = CalculateTakeProfit(OP_SELL, price);
         
         
         //Lot size calculated by risk
         if (!CloseEnough(RiskPercent, 0)) SendLots = CalculateLotSize(price, NormalizeDouble(stop - (HiddenPips / factor), Digits) );
   
            
         result = SendSingleTrade(Symbol(), type, TradeComment, SendLots, price, stop, take);
         
   
         if (result) 
         {
            if (type == OP_SELLSTOP)
               SellStopOpen = true;
            if (type == OP_SELL)
               SellOpen = true;
            
            //The latest garbage from the morons at Crapperquotes appears to occasionally break Matt's OR code, so tell the
            //ea not to trade for a while, to give time for the trade receipt to return from the server.
            TimeToStartTrading = TimeCurrent() + PostTradeAttemptWaitSeconds;         
            if (BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )
            {         
               CheckTpSlAreCorrect(type);
            }//if (BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )   
         }//if (result)          

         //If a stop level error prevented the stop order being sent, then send a market order instead
         if (!result)
         {
            err = GetLastError();
            if (err == 130)
            {
               result = SendSingleTrade(Symbol(), OP_SELL, TradeComment, SendLots, price, stop, take);
               TimeToStartTrading = TimeCurrent() + PostTradeAttemptWaitSeconds;         
               if (BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  CheckTpSlAreCorrect(OrderType() );
            }//if (err == 130)
         }//if (!result)
               
         if (!result)
         {
            TimeToStartTrading = 0;
            OldBarsTime = 0;
         }//if (!result)
         
      }//if (SendTrade)
      
         
   }// if (!SellStopOpen)
   

   
   

}//void LookForTradingOpportunities()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CloseOrder(int ticket)
{   
   while(IsTradeContextBusy()) Sleep(100);
   bool orderselect=BetterOrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if (!orderselect) return(false);

   bool result = OrderClose(ticket, OrderLots(), OrderClosePrice(), 1000, clrBlue);

   //Actions when trade send succeeds
   if (result)
   {
      return(true);
   }//if (result)
   
   //Actions when trade send fails
   if (!result)
   {
      ReportError(" CloseOrder()", ocm);
      return(false);
   }//if (!result)
   
   return(0);
}//End bool CloseOrder(ticket)

////////////////////////////////////////////////////////////////////////////////////////
//Indicator module

void CheckForSpreadWidening()
{
   if (CloseEnough(AverageSpread, 0)) return;
   //Detect a dramatic widening of the spread and pause the ea until this passes
   double TargetSpread = AverageSpread * MultiplierToDetectStopHunt;
   double spread = (Ask - Bid) * factor;
   
   if (spread >= TargetSpread)
   {
      if (OpenTrades == 0) Comment(Gap + "PAUSED DURING A MASSIVE SPREAD EVENT");
      if (OpenTrades > 0) Comment(Gap + "PAUSED DURING A MASSIVE SPREAD EVENT. STILL MONITORING TRADES.");
      while (spread >= TargetSpread)
      {
         RefreshRates();
         spread = (Ask - Bid) * factor;
         
         CountOpenTrades();
         //Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Detect a closed trade and check that is was not a rogue.
         if (OldOpenTrades != OpenTrades)
         {
            if (IsClosedTradeRogue() )
            {
               RobotSuspended = true;
               return;
            }//if (IsClosedTradeRogue() )      
         }//if (OldOpenTrades != OpenTrades)
         if (ForceTradeClosure) return;//Emergency measure to force a retry at the next tick
         
         OldOpenTrades = OpenTrades;
         
         Sleep(1000);

      }//while (spread >= TargetSpread)      
   }//if (spread >= TargetSpread)
}//End void CheckForSpreadWidening()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
      if (OrderCloseTime() < iTime(Symbol(), PERIOD_D1, 0) ) continue;
      
      OverallProfit+= (OrderProfit() + OrderSwap() + OrderCommission() );
      if (OrderProfit() > 0) WinTrades++;
      if (OrderProfit() < 0) LossTrades++;
   }//for (int cc = 0; cc <= tot -1; cc++)
   
   

}//End void CalculateDailyResult()

//+------------------------------------------------------------------+
//| GetSlope()                                                       |
//+------------------------------------------------------------------+
void GetAverageSpread()
{

//   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   removeAllObjects();
//   *************************

   static double SpreadTotal=0;
   AverageSpread=0;

   //Add spread to total and keep track of the ticks
   double Spread=(Ask-Bid)*factor;
   SpreadTotal+=Spread;
   CountedTicks++;

   //All ticks counted?
   if(CountedTicks>=TicksToCount)
   {
      AverageSpread=NormalizeDouble(SpreadTotal/TicksToCount,1);
      //Save the average for restarts.
      GlobalVariableSet(SpreadGvName,AverageSpread);
      RunInSpreadDetectionMode=false;
   }//if (CountedTicks >= TicksToCount)


}//void GetAverageSpread()

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

double GetMa(string symbol, int tf, int period, int mashift, int method, int ap, int shift)
{
   return(iMA(symbol, tf, period, mashift, method, ap, shift) );
}//End double GetMa(int tf, int period, int mashift, int method, int ap, int shift)

void GetPeakyTradeDirection(string symbol, int tf, int bars)
{
   //Set PeakyStatus to the direction implied by the chart peak hilo
   
   int Highest = iHighest(symbol, tf, MODE_CLOSE, bars);
   int Lowest = iLowest(symbol, tf, MODE_CLOSE, bars);
   //int Highest = iHighest(symbol, tf, MODE_HIGH, bars);
   //int Lowest = iLowest(symbol, tf, MODE_LOW, bars);
   
   PeakyStatus = longdirection;//Default
   if (Highest < Lowest)
      PeakyStatus = shortdirection;



}//End void GetPeakyTradeDirection(string symbol, int tf, int bars)


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ReadIndicatorValues()
{

   int cc = 0;
   
   //Declare a shift for use with indicators.
   int shift = 0;
   if (!EveryTickMode)
   {
      shift = 1;
   }//if (!EveryTickMode)

   
   //Declare a datetime variable to force cca reading only at the open of a new candle.
   static datetime OldCcaReadTime = 0;
   //Accommodate every tick mode
   if (EveryTickMode)
      OldCcaReadTime = 0;
   
   double val = 0;
   
   //Allow easy experimentation.
   //shift = 2;
   
   /////////////////////////////////////////////////////////////////////////////////////
   //Read indicators for the system being coded and put them together into a trade signal
   if (OldCcaReadTime != iTime(Symbol(), TradingTimeFrame, 0) )
   {
      OldCcaReadTime = iTime(Symbol(), TradingTimeFrame, 0);
    
      ///////////////////////////////////////
      //Indi reading code goes here
               
   
      //Using hgi_lib
      //The HGI library functionality was added by tomele. Many thanks Thomas.
      SIGNAL signal = 0;
      SLOPE  slope  = 0;

      if (CloseOnLargeArrows || CloseOnBlueWavy)
      {
         //Read HGI at the open of each new HgiTimeFrame candle
         static datetime OldHgiReadTime = 0;
         if (OldHgiReadTime != iTime(Symbol(), HgiTimeFrame, 0))
         {
            
            signal = getHGISignal(Symbol(), HgiTimeFrame, 1);//This library function looks for arrows.
            slope  = getHGISlope (Symbol(), HgiTimeFrame, 1);//This library function looks for wavy lines.
   
            HgiStatus = hginoarrow;
            
            if (signal==TRENDUP)
            {
               if (CloseOnLargeArrows)
               HgiStatus = hgiuparrowtradable;
            }
            else 
            if (signal==TRENDDN)
            {
               if (CloseOnLargeArrows)
                  HgiStatus = hgidownarrowtradable;
            }
            else 
            if (slope==TRENDBELOW)
            {
               if (CloseOnBlueWavy)
                  HgiStatus = hgibluewavylong;
            }
            else 
            if (slope==TRENDABOVE)
            {
               if (CloseOnBlueWavy)
                  HgiStatus = hgibluewavyshort;
            }
            /*else
            if (signal==RADUP)
            {
               if (RadTradingAllowed)
               HgiStatus = hgiuparrowtradable;
            }
            else 
            if (signal==RADDN)
            {
               if (RadTradingAllowed)
                  HgiStatus = hgiuparrowtradable;
            */
         
         }//if (OldHgiReadTime != iTime(Symbol(), HgiTimeFrame, 0))
         
      }//if (CloseOnLargeArrows || CloseOnBlueWavy)
      
      ///////////////////////////////////////
      //Anything else?
      
      //Outstanding stop orders from the previous candle need deleting.
      bool result;
      if(BuyStopOpen)
      {
         if (BetterOrderSelect(BuyStopTicketNo, SELECT_BY_TICKET, MODE_TRADES) && OrderType() > 1)
         {
            result = OrderDelete(OrderTicket());
            if (result)
            {
               OpenTrades--;
               BuyStopOpen = 0;
            }//if (result)
            
            if (!result)
            {
               OldCcaReadTime = 0;//Force a retry at the next tick.
               ForceTradeClosure = true;//Used to stop the ea sending fresh pending trades
               return;//Await the next tick.
            }//if (!result)            
         }//if (BetterOrderSelect(BuyStopTicketNo, SELECT_BY_TICKET, MODE_TRADES))         
      }//if(BuyStopOpen)
      
      if(SellStopOpen)
      {
         if (BetterOrderSelect(SellStopTicketNo, SELECT_BY_TICKET, MODE_TRADES) && OrderType() > 1)
         {
            result = OrderDelete(OrderTicket());
            if (result)
            {
               OpenTrades--;
               SellStopOpen = 0;
            }//if (result)

            if (!result)
            {
               OldCcaReadTime = 0;//Force a retry at the next tick.
               ForceTradeClosure = true;//Used to stop the ea sending fresh pending trades
               return;//Await the next tick.
            }//if (!result)            
         }//if (BetterOrderSelect(SellStopTicketNo, SELECT_BY_TICKET, MODE_TRADES))         
      }//if(SellStopOpen)

      
      ///////////////////////////////////////
      
//////////////////////////////////////////////////////////////////////////////////      
      
      /*The rest of this function is concerned with the optional filters added for those
      who prefer to trade in the direction of one or more, of the well established indi's
      available at SHF. Those that I offer here are:
         * HGI
         * SuperSlope
         * Bob's H4 Moving Average trend filter
         *Peaky*/
         
      //Set BuySignal and SellSignal to true if none of the filters are selected so that
      //LookForTradingOpportunities() can still trade, then exit the function.
      if (!UseHgiTrendFilter)
         if (!UseSuperSlope)
            if (!UseBobMovingAverage)
               if (!UsePeaky)
                  if (!UseChaosOnTradingTimeFrame)
               {
                  BuySignal = true;
                  SellSignal = true;
                  BuyCloseSignal = false;
                  SellCloseSignal = false;
                  return;
               }//if (!UsePeaky)
               
                   
      //Interrogate the filters chosen by the user.
      
      ///////////////////
      //HGI
      
      if (UseHgiTrendFilter)
      {
         //Using hgi_lib
         //The HGI library functionality was added by tomele. Many thanks Thomas.
         signal = 0;
         slope  = 0;
         

         //Read HGI at the open of each new HgiTimeFrame candle, iterating back in time to
         //find the most recent signal.
         static datetime OldTradeHgiReadTime = 0;
         if (OldTradeHgiReadTime != iTime(Symbol(), HgiTradeFilterTimeFrame, 0) )
         {
            OldTradeHgiReadTime = iTime(Symbol(), HgiTradeFilterTimeFrame, 0);
      
            TradeHgiStatus = hginoarrow;
            
            cc = 1;   
            while(TradeHgiStatus == hginoarrow)
            {
               signal = getHGISignal(Symbol(), HgiTradeFilterTimeFrame, cc);//This library function looks for arrows.
               slope  = getHGISlope (Symbol(), HgiTradeFilterTimeFrame, cc);//This library function looks for wavy lines.
            
               if (signal==TRENDUP)
               {
                  if (TradeTrendArrows)
                  TradeHgiStatus = hgiuparrowtradable;
               }
               else 
               if (signal==TRENDDN)
               {
                  if (TradeTrendArrows)
                     TradeHgiStatus = hgidownarrowtradable;
               }
               else 
               if (slope==TRENDBELOW)
               {
                  if (TradeBlueWavyLines)
                     TradeHgiStatus = hgibluewavylong;
               }
               else 
               if (slope==TRENDABOVE)
               {
                  if (TradeBlueWavyLines)
                     TradeHgiStatus = hgibluewavyshort;
               }
               else
               if (HgiCloseOnYellowWavy)
               {
                  if (slope==RANGEABOVE || slope == RANGEBELOW)
                  {
                     //No need to discriminate between the market and the yellow lines - a range
                     //is a range and we are closing all trades on a range.
                     TradeHgiStatus = hgiyellowrangewavey;
                  }//if (slope==RANGEABOVE || slope == RANGEBELOW)
                  
               }//if (HgiCloseOnYellowWavy)
               
               /*else
               if (signal==RADUP)
               {
                  if (RadTradingAllowed)
                  TradeHgiStatus = hgiuparrowtradable;
               }
               else 
               if (signal==RADDN)
               {
                  if (RadTradingAllowed)
                     TradeHgiStatus = hgiuparrowtradable;
               */
               
               cc++;
            }//while(TradeHgiStatus == hginoarrow)
            
         }//if (OldTradeHgiReadTime != iTime(Symbol(), HgiTimeFrame, 0))
              
      }//if (UseHgiTrendFilter)
      
      
      ///////////////////

            if (UseChaosOnTradingTimeFrame)
            {
               ChaosStatus = chaosnoarrow;
//               int signal_period=GetPeriod(s_signal_period);
               int signal_period=ChaosTimeFrame;
//               upfractal=iFractals(Symbol(),signal_period, MODE_UPPER, 2);
//               dwfractal=iFractals(Symbol(),signal_period, MODE_LOWER, 2);
               upfractal=iCustom(Symbol(),signal_period,"FractalsMod",0,0);
               dwfractal=iCustom(Symbol(),signal_period,"FractalsMod",1,0);


               double Teeth = iAlligator(Symbol(), signal_period, JawPeriod, JawShift, TeethPeriod, TeethShift, 
                           LipsPeriod, LipsShift, AlligatorMethod, AlligatorPrice, 
                           MODE_GATORTEETH, 1);

               double AO1 =  iAO(Symbol(), signal_period, 1);
               double AO2 =  iAO(Symbol(), signal_period, 2);
               double AO3 =  iAO(Symbol(), signal_period, 3);

               double AC1 =  iAC(Symbol(), signal_period, 1);
               double AC2 =  iAC(Symbol(), signal_period, 2);
               double AC3 =  iAC(Symbol(), signal_period, 3);
               double AC4 =  iAC(Symbol(), signal_period, 4);
               double AC5 =  iAC(Symbol(), signal_period, 5);

               double CL1 =  iClose(Symbol(), signal_period, 1);
               double CL2 =  iClose(Symbol(), signal_period, 2);
           
					ChaosD1 = chaosd1no;
					ChaosD2 = chaosd2no;
					ChaosD3 = chaosd3no;
					ChaosD4 = chaosd4no;
					ChaosD5 = chaosd5no;
           //UP
					//1
					if (dwfractal!=0 && dwfractal<upfractal && dwfractal<Teeth)// down fractal under the teeth
						ChaosD1 = chaosd1up;
					//2
					if((AO1>0 && AO2<0) || // upward crossover of zero line
						(AO1>AO2 && AO2>0 && AO3>AO2)) // saucer above the zero line
						ChaosD2 = chaosd2up;
					//3
					if((AC1>AC2 && AC1>0 && AC2>AC3) || //(buy) ÀÑ 2 bars up
						(AC1>AC2 && AC3<0 && AC2>AC3 && AC3>AC4)) //(buy) ÀÑ 3 bars up (3rd below the zero line)
						ChaosD3 = chaosd3up;
					//4
					if(AO1>AO2 && AO2>AO3 && AC1>AC2 && AC2>AC3 && CL1>CL2)
						ChaosD4 = chaosd4up;
					//5
					if(CL1>Teeth) // last close above the Teeth
						ChaosD5 = chaosd5up;
          //DOWN
					//1
					if (upfractal!=0 && upfractal>dwfractal && upfractal>Teeth)// up fractal above the teeth
						ChaosD1 = chaosd1dn;
					//2
   				if((AO1<0 && AO2>0) || // downward crossover of zero line
						(AO1<AO2 && AO2<0 && AO3<AO2)) // saucer below the zero line
						ChaosD2 = chaosd2dn;
					//3
					if((AC1<AC2 && AC1<0 && AC2<AC3) || //(sell) ÀÑ 2 bars down
						(AC1<AC2 && AC3>0 && AC2<AC3 && AC3>AC4)) //(sell) ÀÑ 3 bars down (3rd above the zero line)
						ChaosD3 = chaosd3dn;
					//4
					if(AO1<AO2 && AO2<AO3 && AC1<AC2 && AC2<AC3 && CL1<CL2)
						ChaosD4 = chaosd4dn;
					//5
					if(CL1<Teeth) // last close under the Teeth
						ChaosD5 = chaosd5dn;
           //UP
               if(
                  (dwfractal!=0 && dwfractal<upfractal && dwfractal<Teeth) // down fractal under the teeth
                  &&
                  ((AO1>0 && AO2<0) || // upward crossover of zero line
						(AO1>AO2 && AO2>0 && AO3>AO2)) // saucer above the zero line &&
						&&
                  ((AC1>AC2 && AC1>0 && AC2>AC3) || //(buy) ÀÑ 2 bars up
						(AC1>AC2 && AC3<0 && AC2>AC3 && AC3>AC4)) //(buy) ÀÑ 3 bars up (3rd below the zero line)
                  &&
                  (AO1>AO2 && AO2>AO3 && AC1>AC2 && AC2>AC3 && CL1>CL2)
                  &&
                  (CL1>Teeth) // last close above the Teeth
                 )
               ChaosStatus = chaosuparrow;
          //DOWN
               if (
                  (upfractal!=0 && upfractal>dwfractal && upfractal>Teeth)// up fractal above the teeth
                  &&
                  ((AO1<0 && AO2>0) || // downward crossover of zero line
						(AO1<AO2 && AO2<0 && AO3<AO2)) // saucer below the zero line
                  &&
                  ((AC1<AC2 && AC1<0 && AC2<AC3) || //(sell) ÀÑ 2 bars down
						(AC1<AC2 && AC3>0 && AC2<AC3 && AC3>AC4)) //(sell) ÀÑ 3 bars down (3rd above the zero line)
                  &&
                  (AO1<AO2 && AO2<AO3 && AC1<AC2 && AC2<AC3 && CL1<CL2)
                  &&
                  (CL1<Teeth)
                  )
               ChaosStatus = chaosdownarrow;


            }//if (UseChaosOnTradingTimeFrame)



      
      //Read SuperSlope at the open of each new trading time frame candle
      if (UseSuperSlope)
      {   
         static datetime OldSsBarTime = 0;
         if (OldSsBarTime != iTime(Symbol(), TradingTimeFrame, 0) )
         {  
            OldSsBarTime = iTime(Symbol(), TradingTimeFrame, 0);
            
            val = GetSuperSlope(Symbol(), SsTimeFrame,SsTradingSlopeMAPeriod,SsTradingSlopeATRPeriod,0);
               
            //Changed by tomele. Many thanks Thomas.
            //Set the colours
            SsColour = white;
            
            if (val > 0)  //buy
               if (val - SsTradingDifferenceThreshold/2 > 0) //blue
                  SsColour = blue;
   
            if (val < 0)  //sell
               if (val + SsTradingDifferenceThreshold/2 < 0) //red
                  SsColour = red;
                                                     
         }//if (OldSsBarTime != iTime(Symbol(), TradingTimeFrame, 0) )
         
      }//if (UseSuperSlope)

      //Bob's moving average
      if (UseBobMovingAverage)
      {
         static datetime OldM1BarTime;
         if (OldM1BarTime != iTime(NULL, PERIOD_M1, 0) && MaPeriod > 0)
         {
            OldM1BarTime = iTime(NULL, PERIOD_M1, 0);
            //~ TradeLong = false;
            //~ TradeShort = false;
            MaVal = GetMa(Symbol(), MaTimeFrame, MaPeriod, MaShift, MaMethod, MaAppliedPrice, 0);
            if (Bid > MaVal) 
            {
               MaTrend = up;
            }//if (Bid > MaVal) 
            
            if (Bid < MaVal) 
            {
               MaTrend = down;
            }//if (Bid < MaVal) 
   
         }//if (OldM1BarTime != iTime(NULL, PERIOD_M1, 0))
      }//if (MaPeriod > 0)

      //Peaky
      GetPeakyTradeDirection(Symbol(), PeakyTimeFrame, NoOfBarsOnChart);
      
      //Do we have a trade signal
      BuySignal = false;
      SellSignal = false;
      
      //Code to compare all the indi values and generate a signal if they all pass
      if (!UseBobMovingAverage || MaTrend == up)
         if (!UseSuperSlope || SsColour == blue)
            if (!UseHgiTrendFilter || (TradeHgiStatus == hgiuparrowtradable || TradeHgiStatus == hgibluewavylong) )
               if (!UsePeaky || PeakyStatus == longdirection)
                  if (!UseChaosOnTradingTimeFrame || ChaosStatus == chaosuparrow)
                   BuySignal = true;

      
      if (!UseBobMovingAverage || MaTrend == down)
         if (!UseSuperSlope || SsColour == red)
            if (!UseHgiTrendFilter || (TradeHgiStatus == hgidownarrowtradable || TradeHgiStatus == hgibluewavyshort) )
               if (!UsePeaky || PeakyStatus == shortdirection)
                  if (!UseChaosOnTradingTimeFrame || ChaosStatus == chaosdownarrow)
                  SellSignal = true;
     
      //Close trades on an opposite direction signal
      BuyCloseSignal = false;
      SellCloseSignal = false;
      
      /*if (BuySignal)
         SellCloseSignal = true;
      
      if (SellSignal)
         BuyCloseSignal = true;*/
   
   }//if (OldCcaReadTime != iTime(Symbol(), TradingTimeFrame, 0) )   
         
   

}//void ReadIndicatorValues()
//End Indicator module
////////////////////////////////////////////////////////////////////////////////////////


int GetPeriod(int period)
{int periodres;
 switch(period)
  {
   case 1: periodres=1;break;
   case 2: periodres=5;break;
   case 3: periodres=15;break;
   case 4: periodres=30;break;
   case 5: periodres=60;break;
   case 6: periodres=240;break;
   case 7: periodres=1440;break;
   case 8: periodres=10080;break;
   default: periodres=1;break;
  }
return(periodres);
} 

bool LookForTradeClosure(int ticket)
{
   //Close the trade if the close conditions are met.
   //Called from within CountOpenTrades(). Returns true if a close is needed and succeeds, so that COT can increment cc,
   //else returns false
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET) ) return(true);
   if (BetterOrderSelect(ticket, SELECT_BY_TICKET) && OrderCloseTime() > 0) return(true);
   
   bool CloseThisTrade = false;
   
   string LineName = TpPrefix + DoubleToStr(ticket, 0);
   //Work with the lines on the chart that represent the hidden tp/sl
   double take = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(take, 0) ) take = OrderTakeProfit();
   LineName = SlPrefix + DoubleToStr(ticket, 0);
   double stop = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(stop, 0) ) stop = OrderStopLoss();
   
   //Direction hgi yellow range wave   
   if (HgiCloseOnYellowWavy)
      if (TradeHgiStatus == hgiyellowrangewavey)
         CloseThisTrade = true;
        
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (!CloseThisTrade)
   {
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
      {
         //TP
         if (Bid >= take && !CloseEnough(take, 0) && !CloseEnough(take, OrderTakeProfit()) ) CloseThisTrade = true;
         //SL
         if (Bid <= stop && !CloseEnough(stop, 0)  && !CloseEnough(stop, OrderStopLoss())) CloseThisTrade = true;
   
         
         
      //Hidden HGI code
      
         //Original Hgi closure
         if (!CloseThisTrade)
            if (CloseOnLargeArrows)
               if (HgiStatus == hgidownarrowtradable)
                  if (!OnlyCloseWinningTrades || (OrderProfit() + OrderCommission() + OrderSwap()) > 0)
                     if (OrderOpenTime() < iTime(Symbol(), HgiTimeFrame, 0) )//Don't close trades opened during the current HGI candle
                        CloseThisTrade = true;
            
         if (!CloseThisTrade)
            if (CloseOnBlueWavy)
               if (HgiStatus == hgibluewavyshort)
                  if (!OnlyCloseWinningTrades || (OrderProfit() + OrderCommission() + OrderSwap()) > 0)
                     if (OrderOpenTime() < iTime(Symbol(), HgiTimeFrame, 0) )//Don't close trades opened during the current HGI candle
                        CloseThisTrade = true;
      
         
         //Opposite direction directional hgi
         if (!CloseThisTrade)
            if (UseHgiTrendFilter)
               if (HgiCloseOnOppositeSignal)
                  if (TradeHgiStatus == hgidownarrowtradable || TradeHgiStatus == hgibluewavyshort)
                     CloseThisTrade = true;
                  
             
         //Change of SS colour
         if (!CloseThisTrade)
            if (UseSuperSlope)
               if (SsCloseTradesOnColourChange)
                  if (SsColour == red)
                     CloseThisTrade = true; 

         //Change of moving average trend
         if (!CloseThisTrade)
            if (UseBobMovingAverage)
               if (MaCloseTradesOnTrendChange)
                  if (MaTrend == down)
                     CloseThisTrade = true;

         //Change of peaky direction
         if (!CloseThisTrade)
            if (UsePeaky)
               if (PeakyCloseTradesOnDirectionChange)
                  if (PeakyStatus == shortdirection)
                     CloseThisTrade = true;

            
      }//if (OrderType() == OP_BUY)
      
      
      ///////////////////////////////////////////////////////////////////////////////////////////////////////////
      if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
      {
         //TP
         if (Bid <= take && !CloseEnough(take, 0) && !CloseEnough(take, OrderTakeProfit()) ) CloseThisTrade = true;
         //SL
         if (Bid >= stop && !CloseEnough(stop, 0)  && !CloseEnough(stop, OrderStopLoss())) CloseThisTrade = true;
   
   
         
         //Original Hgi closure
         if (CloseOnLargeArrows)
            if (HgiStatus == hgiuparrowtradable)
               if (!OnlyCloseWinningTrades || (OrderProfit() + OrderCommission() + OrderSwap()) > 0)
                  if (OrderOpenTime() < iTime(Symbol(), HgiTimeFrame, 0) )//Don't close trades opened during the current HGI candle
                     CloseThisTrade = true;
         
         if (!CloseThisTrade)
            if (CloseOnBlueWavy)
               if (HgiStatus == hgibluewavylong)
                  if (!OnlyCloseWinningTrades || (OrderProfit() + OrderCommission() + OrderSwap()) > 0)
                     if (OrderOpenTime() < iTime(Symbol(), HgiTimeFrame, 0) )//Don't close trades opened during the current HGI candle
                        CloseThisTrade = true;
      
         //Opposite direction directional hgi
         if (!CloseThisTrade)
            if (UseHgiTrendFilter)
               if (HgiCloseOnOppositeSignal)
                  if (TradeHgiStatus == hgiuparrowtradable || TradeHgiStatus == hgibluewavylong)
                     CloseThisTrade = true;

         //Change of SS colour
         if (!CloseThisTrade)
            if (UseSuperSlope)
               if (SsCloseTradesOnColourChange)
                  if (SsColour == blue)
                     CloseThisTrade = true; 

         //Change of moving average trend
         if (!CloseThisTrade)
            if (UseBobMovingAverage)
               if (MaCloseTradesOnTrendChange)
                  if (MaTrend == up)
                     CloseThisTrade = true;

         //Change of peaky direction
         if (!CloseThisTrade)
            if (UsePeaky)
               if (PeakyCloseTradesOnDirectionChange)
                  if (PeakyStatus == longdirection)
                     CloseThisTrade = true;

            
      }//if (OrderType() == OP_SELL)
   }//if (!CloseThisTrade)
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (CloseThisTrade)
   {
      bool result = false;
      
      if (OrderType() < 2)//Market orders
         result = CloseOrder(ticket);
      else
         result = OrderDelete(ticket, clrNONE);
            
      //Actions when trade close succeeds
      if (result)
      {
         DeletePendingPriceLines();
         TicketNo = -1;//TicketNo is the most recently trade opened, so this might need editing in a multi-trade EA
         OpenTrades--;//Rather than OpenTrades = 0 to cater for multi-trade EA's
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
   
}//End bool LookForTradeClosure()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllTrades(int type)
{

   ForceTradeClosure= false;
   
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
         if (OrderType() < 2)
         {
            result = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
            if (result) 
            {
               cc++;
               OpenTrades--;
            }//(result) 
            
            if (!result) ForceTradeClosure= true;
         }//if (OrderType() < 2)
         
         if (pass == 1)
            if (OrderType() > 1) 
            {
               result = OrderDelete(OrderTicket(), clrNONE);
               if (result) 
               {
                  cc++;
                  OpenTrades--;
               }//(result) 
               if (!result) ForceTradeClosure= true;
            }//if (OrderType() > 1) 
            
      }//for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   }//for (int pass = 0; pass <= 1; pass++)
   
   //If full closure succeeded, then allow new trading
   if (!ForceTradeClosure) 
   {
      OpenTrades = 0;
      BuyOpen = false;
      SellOpen = false;
   }//if (!ForceTradeClosure) 


}//End void CloseAllTradesFifo()


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckTradingTimes() 
{

	// Trade 24 hours if no input is given
	if ( ArraySize( tradeHours ) == 0 ) return ( true );

	// Get local time in minutes from midnight
    int time = TimeHour( TimeLocal() ) * 60 + TimeMinute( TimeLocal() );
   
	// Don't you love this?
	int i = 0;
	while ( time >= tradeHours[i] ) 
	{	
		i++;		
		if ( i == ArraySize( tradeHours ) ) break;
	}
	if ( i % 2 == 1 ) return ( true );
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
		int hour = MathFloor( time );
		int minutes = MathRound( ( time - hour ) * 100 );

		// Add to array
		tradeHours[size] = 60 * hour + minutes;

		// Trim input string
		tradingHours = StringSubstrOld( tradingHours, i + 1 );
		i = StringFind( tradingHours, "," );
	}//while (i != -1) 

	return ( true );
}//End bool initTradingHours() 

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CountOpenTrades()
{
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
   
   //Market Sell trades
   SellOpen=false;
   MarketSellsCount=0;
   LatestSellPrice=0; EarliestSellPrice=0; HighestSellPrice=0; LowestSellPrice=million;
   SellTicketNo=-1; HighestSellTicketNo=-1; LowestSellTicketNo=-1; LatestSellTicketNo=-1; EarliestSellTicketNo=-1;;
   SellPipsUpl=0;
   SellCashUpl=0;
   LatestSellTradeTime=0;
   EarliestSellTradeTime=TimeCurrent();
   
   //BuyStop trades
   BuyStopOpen=false;
   BuyStopsCount=0;
   LatestBuyStopPrice=0; EarliestBuyStopPrice=0; HighestBuyStopPrice=0; LowestBuyStopPrice=million;
   BuyStopTicketNo=-1; HighestBuyStopTicketNo=-1; LowestBuyStopTicketNo=-1; LatestBuyStopTicketNo=-1; EarliestBuyStopTicketNo=-1;;
   LatestBuyStopTradeTime=0;
   EarliestBuyStopTradeTime=TimeCurrent();
   
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
   MarketTradesTotal = 0;
   TicketNo=-1;OpenTrades=0;
   LatestTradeTime=0; EarliestTradeTime=TimeCurrent();//More specific times are in each individual section
   LatestTradeTicketNo=-1; EarliestTradeTicketNo=-1;
   PipsUpl=0;//For keeping track of the pips PipsUpl of multi-trade/hedged positions
   CashUpl=0;//For keeping track of the cash PipsUpl of multi-trade/hedged positions
   //Recover
   TpSet = false; SlSet = false;

   
   //FIFO ticket resize
   ArrayResize(FifoTicket, 0);
   
   //For opposite side offsetting
   ArrayResize(GridOrderBuyTickets, 0);
   ArrayInitialize(GridOrderBuyTickets, -1);
   ArrayResize(GridOrderSellTickets, 0);
   ArrayInitialize(GridOrderSellTickets, -1);
    
   
   int type;//Saves the OrderType() for consulatation later in the function
   
   
   if (OrdersTotal() == 0) return;
   
   //Iterating backwards through the orders list caters more easily for closed trades than iterating forwards
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      bool TradeWasClosed = false;//See 'check for possible trade closure'

      //Ensure the trade is still open
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      //Ensure the EA 'owns' this trade
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      
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

      OpenTrades++;
      //Store the latest trade sent. Most of my EA's only need this final ticket number as either they are single trade
      //bots or the last trade in the sequence is the important one. Adapt this code for your own use.
      if (TicketNo  == -1) TicketNo = OrderTicket();
      
      //Store ticket numbers for FIFO
      ArrayResize(FifoTicket, OpenTrades + 1);
      FifoTicket[OpenTrades] = OrderTicket();
      
      
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
            BuyOpen = true;
            BuyTicketNo = OrderTicket();
            MarketBuysCount++;
            BuyPipsUpl+= pips;
            BuyCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 

            ArrayResize(GridOrderBuyTickets, MarketBuysCount + 1);
            GridOrderBuyTickets[MarketBuysCount][TradeTicket] = OrderTicket();
             
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
            SellOpen = true;
            SellTicketNo = OrderTicket();
            MarketSellsCount++;
            SellPipsUpl+= pips;
            SellCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
 
            ArrayResize(GridOrderSellTickets, MarketSellsCount + 1);
            GridOrderSellTickets[MarketSellsCount][TradeTicket] = OrderTicket();
            
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
      
      
      
      
      if (!Unbalanced && !Hedged)
      {
         if (CloseEnough(OrderStopLoss(), 0) && !CloseEnough(StopLoss, 0)) InsertStopLoss(OrderTicket());
         if (CloseEnough(OrderTakeProfit(), 0) && !CloseEnough(TakeProfit, 0)) InsertTakeProfit(OrderTicket() );
      }//if (!Unbalanced)
      
      //Replace missing tp and sl lines
      if (HiddenPips > 0) ReplaceMissingSlTpLines();
      
      TradeWasClosed = false;
      if (OrderType() < 2)
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
      
               
      
   }//for (int cc = OrdersTotal() - 1; cc <= 0; c`c--)
   
   //Sort ticket numbers for FIFO
   if (ArraySize(FifoTicket) > 0)
      ArraySort(FifoTicket, WHOLE_ARRAY, 0, MODE_DESCEND);

   
   //Hedging
   Hedged = false;
   if (BuyOpen)
      if (SellOpen)
         Hedged = true;
   
   //Balance
   Unbalanced = false;
   if (MathAbs(MarketBuysCount - MarketSellsCount) >= PositionIsUnbalancedAt)
   {
      Unbalanced = true;
      AllowTradeManagement = false;

      if (TpSet)
         RemoveTakeProfits();

      if (SlSet)
         RemoveStopLosses();

   }//if (MathAbs(MarketBuysCount - MarketSellsCount) >= PositionIsUnbalancedAt)
   
   //Resume individual trade management if we are not in recovery.
   if (!Unbalanced)
      AllowTradeManagement = true;

   if (ArraySize(GridOrderBuyTickets) > 0)
      ArraySort(GridOrderBuyTickets, WHOLE_ARRAY, 0, MODE_DESCEND);
   
   if (ArraySize(GridOrderSellTickets) > 0)
      ArraySort(GridOrderSellTickets, WHOLE_ARRAY, 0, MODE_DESCEND);
    
}//End void CountOpenTrades();
//+------------------------------------------------------------------+

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
   
   double stop;
   
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InsertTakeProfit(int ticket)
{
   //Inserts a TP if the ECN crim managed to swindle the original trade out of the modification at trade send time
   //Called from CountOpenTrades() if TakeProfit > 0 && OrderTakeProfit() == 0.
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (!CloseEnough(OrderTakeProfit(), 0) ) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double take;
   
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeletePendingPriceLines()
{

   //ObjectDelete(pendingpriceline);
   string LineName=TpPrefix+DoubleToStr(TicketNo,0);
   ObjectDelete(LineName);
   LineName=SlPrefix+DoubleToStr(TicketNo,0);
   ObjectDelete(LineName);

}//End void DeletePendingPriceLines()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ReplaceMissingSlTpLines()
{

   if(OrderTakeProfit()>0 || OrderStopLoss()>0) DrawPendingPriceLines();

}//End void ReplaceMissingSlTpLines()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteOrphanTpSlLines()
{

   if (ObjectsTotal() == 0) return;
   
   for (int cc = ObjectsTotal() - 1; cc >= 0; cc--)
   {
      string name = ObjectName(cc);
      
      if ((StringSubstrOld(name, 0, 2) == TpPrefix || StringSubstrOld(name, 0, 2) == SlPrefix) && ObjectType(name) == OBJ_HLINE)
      {
         int tn = StrToDouble(StringSubstrOld(name, 2));
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
   
      
   Alert(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   Print(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   
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
      
   double NewStop;
   bool result;
   bool modify=false;
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   double target = OrderOpenPrice();
   
   
   if (OrderType()==OP_BUY)
   {
      if (HiddenPips > 0) target-= (HiddenPips / factor);
      if (OrderStopLoss() >= target) return;
      if (Bid >= OrderOpenPrice () + (BreakEvenPips / factor) )          
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
     if (Ask <= OrderOpenPrice() - (BreakEvenPips / factor) ) 
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
      if (!result)
         Sleep(10000);//10 seconds before trying again
         
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

   //Thomas substantially rewrote this function. Many thanks, Thomas.
   
  //Security check
  if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
     return;

  //if (OrderProfit() < 0) return;//Nothing to do
  string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
  double sl = ObjectGet(LineName, OBJPROP_PRICE1);
  if (CloseEnough(sl, 0) ) sl = OrderStopLoss();
  
  //if (CloseEnough(sl, 0) ) return;//No line, so nothing to do
  double NewStop;
  bool modify=false;
  bool result;
  
  double JSWidth=JumpingStopPips/factor;//Thomas
  int JSMultiple;//Thomas
  
   if (OrderType()==OP_BUY)
   {
      if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
      // Increment sl by sl + JumpingStopPips.
      // This will happen when market price >= (sl + JumpingStopPips)
      //if (Bid>= sl + ((JumpingStopPips*2) / factor) )
      if (CloseEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
      if (Bid >= sl + (JSWidth * 2))//Thomas
      {
         JSMultiple = floor((Bid-sl)/(JSWidth))-1;//Thomas
         NewStop = NormalizeDouble(sl + (JSMultiple*JSWidth), Digits);//Thomas
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
         if (Bid <= sl - (JSWidth * 2))//Thomas
         {
            JSMultiple = floor((sl-Bid)/(JSWidth))-1;//Thomas
            NewStop = NormalizeDouble(sl - (JSMultiple*JSWidth), Digits);//Thomas
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

} //End of JumpingStopLoss
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
   double NewStop;
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
   double NewStop;
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

   //Is individual trade management allowed?
   if (!AllowTradeManagement)
      return;
      
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
   double profit;
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CloseEnough(double num1,double num2)
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

   if(num1==0 && num2==0) return(true); //0==0
   if(MathAbs(num1 - num2) / (MathAbs(num1) + MathAbs(num2)) < 0.00000001) return(true);

//Doubles are unequal
   return(false);

}//End bool CloseEnough(double num1, double num2)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetPipFactor(string Xsymbol)
{
   //Code from Tommaso's APTM. Thanks Tommaso.
   
   //static const string factor1000[]={"SEK","TRY","ZAR","MXN"};
   static const string factor1000[]        = {"TRY","ZAR","MXN"};
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
      if (OrderType() > 1) continue;
      
      
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
      if ( !BetterOrderSelect(i, SELECT_BY_POS, MODE_HISTORY) ) continue;
       
      if ( OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() ) continue;
      if (OrderType() > 1) continue;
        
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawTrendLine(string name,datetime time1,double val1,datetime time2,double val2,color col,int width,int style,bool ray)
{
//Plots a trendline with the given parameters

   ObjectDelete(name);

   ObjectCreate(name,OBJ_TREND,0,time1,val1,time2,val2);
   ObjectSet(name,OBJPROP_COLOR,col);
   ObjectSet(name,OBJPROP_WIDTH,width);
   ObjectSet(name,OBJPROP_STYLE,style);
   ObjectSet(name,OBJPROP_RAY,ray);

}//End void DrawLine()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawHorizontalLine(string name,double price,color col,int style,int width)
{

   ObjectDelete(name);

   ObjectCreate(name,OBJ_HLINE,0,TimeCurrent(),price);
   ObjectSet(name,OBJPROP_COLOR,col);
   ObjectSet(name,OBJPROP_STYLE,style);
   ObjectSet(name,OBJPROP_WIDTH,width);

}//void DrawLine(string name, double price, color col)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawVerticalLine(string name,color col,int style,int width)
{
//ObjectCreate(vline,OBJ_VLINE,0,iTime(NULL, TimeFrame, 0), 0);
   ObjectDelete(name);
   ObjectCreate(name,OBJ_VLINE,0,iTime(NULL,0,0),0);
   ObjectSet(name,OBJPROP_COLOR,col);
   ObjectSet(name,OBJPROP_STYLE,style);
   ObjectSet(name,OBJPROP_WIDTH,width);

}//void DrawVerticalLine()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string PeriodText(int per)
{

	switch (per)
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

}//End string PeriodText(int per)

//+------------------------------------------------------------------+
//  Code to check that there are at least 100 bars of history in
//  the sym / per in the passed params
//+------------------------------------------------------------------+
bool HistoryOK(string sym,int per)
  {

   double tempArray[][6];  //used for the call to ArrayCopyRates()

                           //get the number of bars
   int bars=iBars(sym,per);
//and report it in the log
   Print("Checking ",sym," for complete data.... number of ",PeriodText(per)," bars = ",bars);

   if(bars<100)
     {
      //we didn't have enough, so set the comment and try to trigger the DL another way
      Comment("Symbol ",sym," -- Waiting for "+PeriodText(per)+" data.");
      ArrayCopyRates(tempArray,sym,per);
      int error=GetLastError();
      if(error!=0) Print(sym," - requesting data from the server...");

      //return false so the caller knows we don't have the data
      return(false);
     }//if (bars < 100)

//if we got here, the data is fine, so clear the comment and return true
   Comment("");
   return(true);

  }//End bool HistoryOK(string sym,int per)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTpSlAreCorrect(int type)
{
   //Looks at an open trade and checks to see that the exact tp/sl were sent with the trade.
   
   
   double stop = 0, take = 0, diff = 0;
   bool ModifyStop = false, ModifyTake = false;
   bool result;
   
   //Is the stop at BE?
   if (type == OP_BUY && OrderStopLoss() >= OrderOpenPrice() ) return;
   if (type == OP_SELL && OrderStopLoss() <= OrderOpenPrice() ) return;
   
   if (type == OP_BUY || type == OP_BUYSTOP || type == OP_BUYLIMIT)
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
   
   if (type == OP_SELL || type == OP_SELLSTOP || type == OP_SELLLIMIT)
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

//+------------------------------------------------------------------+
//| NormalizeLots(string symbol, double lots)                        |
//+------------------------------------------------------------------+
//function added by fxdaytrader
//Lot size must be adjusted to be a multiple of lotstep, which may not be a power of ten on some brokers
//see also the original function by WHRoeder, http://forum.mql4.com/45425#564188, fxdaytrader
double NormalizeLots(string symbol,double lots)
{
   if(MathAbs(lots)==0.0) return(0.0); //just in case ... otherwise it may happen that after rounding 0.0 the result is >0 and we have got a problem, fxdaytrader
   double ls=MarketInfo(symbol,MODE_LOTSTEP);
   lots=MathMin(MarketInfo(symbol,MODE_MAXLOT),MathMax(MarketInfo(symbol,MODE_MINLOT),lots)); //check if lots >= min. lots && <= max. lots, fxdaytrader
   return(MathRound(lots/ls)*ls);
}
////////////////////////////////////////////////////////////////////////////////////////

// for 6xx build compatibilità added by milanese

string StringSubstrOld(string x,int a,int b=-1) 
{
   if(a<0) a=0; // Stop odd behaviour
   if(b<=0) b=-1; // new MQL4 EOL flag
   return StringSubstr(x,a,b);
}


bool MopUpTradeClosureFailures()
{
   //Cycle through the ticket numbers in the ForceCloseTickets array, and attempt to close them
   
   bool Success = true;
   
   for (int cc = ArraySize(ForceCloseTickets) - 1; cc >= 0; cc--)
   {
      //Order might have closed during a previous attempt, so ensure it is still open.
      if (!BetterOrderSelect(ForceCloseTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
         continue;
   
      bool result = CloseOrder(OrderTicket() );
      if (!result)
         Success = false;
   }//for (int cc = ArraySize(ForceCloseTickets) - 1; cc >= 0; cc--)
   
   if (Success)
      ArrayResize(ForceCloseTickets, 0);
   
   return(Success);


}//END bool MopUpTradeClosureFailures()



bool DoesTradeExist(int type, double price)
{

   if (OrdersTotal() == 0)
      return(false);
   if (OpenTrades == 0)
      return(false);
   
   
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderType() != type) continue;
      if (!CloseEnough(OrderOpenPrice(), price) ) continue;
      
      //Got to here, so we have found a trade
      return(true);

   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
   
   //Got this far, so no trade found
   return(false);   

}//End bool DoesTradeExist(int type, double price)

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
   Lot = NormalizeDouble((DoshDollop / SizeOfDollop) * LotsPerDollopOfCash, decimal);
     
   //Min/max size check
   if (Lot > maxlot)
      Lot = maxlot;
      
   if (Lot < minlot)
      Lot = minlot;      


}//void CalculateLotAsAmountPerCashDollops()

bool SundayMondayFridayStuff()
{

   //Friday/Saturday stop trading hour
   int d = TimeDayOfWeek(TimeLocal());
   int h = TimeHour(TimeLocal());
   if (d == 5)
      if (h >= FridayStopTradingHour)
         if (OpenTrades == 0)
            return(false);
         
   if (d == 4)
      if (!TradeThursdayCandle)
         return(false);
        
   
   if (d == 6)
      if (h >= SaturdayStopTradingHour)
         return(false);
  
   //Sunday candle
   if (d == 0)
      if (!TradeSundayCandle)
         return(false);
         
   //Monday start hour
   if (d == 1)
      if (h < MondayStartHour)      
         return(false);
         
   //Got this far, so we are in a trading period
   return(true);      
   
}//End bool  SundayMondayFridayStuff()

bool indiExists( string indiName ) 
{

   //Returns true if a custom indi exists in the user's indi folder, else false
   bool exists = false;
   
   ResetLastError();
   double value = iCustom( Symbol(), Period(), indiName, 0, 0 );
   if ( GetLastError() == 0 ) exists = true;
   
   return(exists);

}//End bool indiExists( string indiName ) 

//For OrderSelect() Craptrader documentation states:
//   The pool parameter is ignored if the order is selected by the ticket number. The ticket number is a unique order identifier. 
//   To find out from what list the order has been selected, its close time must be analyzed. If the order close time equals to 0, 
//   the order is open or pending and taken from the terminal open orders list.
//This function heals this and allows use of pool parameter when selecting orders by ticket number.
//Tomele provided this code. Thanks Thomas.
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

void LookForBasketClosure()
{
  bool ClosePosition = false;
   
   //Cash upl
   if (CashUpl >= HedgedBasketCashTakeProfit)
   {
      ClosePosition = true;
   }//if (CashUpl >= BasketCashTakeProfit)


   if (ClosePosition)   
   {
      Alert(Symbol(), " Candle Power has hit its hedged basket take profit. All trades should have closed.");
      CloseAllTrades(AllTrades);
      if (ForceTradeClosure)
      {
         CloseAllTrades(AllTrades);
         if (ForceTradeClosure)
         {
            CloseAllTrades(AllTrades);
         }//if (ForceTradeClosure)                     
         if (ForceTradeClosure)
         {
            return;
         }//if (ForceTradeClosure)                     
      }//if (ForceTradeClosure)  

   }//if (ClosePosition)   
   
   //Got this far, so all the trades have been closed/deleted. Clear all the variables.
   CountOpenTrades();

}//End void LookForBasketClosure()

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

void ShutDownForTheWeekend()
{

   //Close/delete all trades to be flat for the weekend.
   
   int day = TimeDayOfWeek(TimeLocal() );
   int hour = TimeHour(TimeLocal() );
   bool CloseDelete = false;
   
   //Friday
   if (day == 5)
   {
      if (hour >= FridayCloseAllHour)
         if (CashUpl > MaxAllowableCashLoss)//MaxAllowableCashLoss is a negative number
            CloseDelete = true;
   }//if (day == 5)
 
   //Saturday
   if (day == 6)
   {
      if (hour >= SaturdayCloseAllHour)
         if (CashUpl > MaxAllowableCashLoss)//MaxAllowableCashLoss is a negative number
            CloseDelete = true;
   }//if (day == 6)
   
   if (CloseDelete)
   {
      CloseAllTrades(AllTrades);
      if (ForceTradeClosure)
         CloseAllTrades(AllTrades);
      if (ForceTradeClosure)
         CloseAllTrades(AllTrades);
   }//if (CloseDelete)
      

}//End void ShutDownForTheWeekend()

void ShouldTradesBeClosed(int NoOfTradesMustBeOpen)
{
   //Examine baskets of trades for possible closure
   
   if (OpenTrades == 0)
      return;//Nothing to do

   //Can younger winners be offset against the oldest loser?
   if (UseOffsetting)
   {
      if (CanTradesBeOffset(NoOfTradesMustBeOpen))
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
        
}//void ShouldTradesBeClosed()

bool CanTradesBeOffset(int NoOfTradesMustBeOpen)
{

   double pips = 0;//The pips upl of the highest buy or lowest sell
   double loss = 0;//Convers pips to a positive value for comparison with (MinDistanceBetweenTradesPips / factor)
   double profit = 0;//Cash upl of the side being calculated to see if they can combine to close a loser on the other side
   int TradesToClose = 0;
   bool result = false;
   int cc = 0;
   double HighestTradeCash = 0;
   double LowestTradeCash = 0;
   int tries = 0;
   int cas = 0;//ForceCloseTickets array size
                                             
   ArrayResize(ForceCloseTickets, 0);
   
   //Look for a simple offset opportunity of a losing buy at the
   //top of the pile by the winner at the bottom.
   if (MarketBuysCount > NoOfTradesMustBeOpen)//Impossible with < 4
   {
      //Do we have a losing buy?
      if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      {
         //Calculate the pips upl of the highest, and so latest, buy
         pips = CalculateTradeProfitInPips(OP_BUY);
         if (pips < 0)//Only continue if it is losing
         {
            loss = (pips * -1);//Turn the loss into a positive number for the comparison
            if (loss >= MinDistanceBetweenTradesPips)//Only continue if losing by at least 1 grid level
            {
              HighestTradeCash = OrderSwap() + OrderCommission() + OrderProfit();
               if (OrderSelect(LowestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  LowestTradeCash = OrderSwap() + OrderCommission() + OrderProfit();
               
               //Make sure we are closing at an overall cash profit
               if ((HighestTradeCash + LowestTradeCash) > 0)
               {
                  //The higest buy trade is losing by at least one grid level, so close it and the lowest buy
                  if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  {
                     result = CloseOrder(HighestBuyTicketNo);
                     if (!result)
                     {
                        return(false);
                     }//if (!result)
                  }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     
                  if (OrderSelect(LowestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
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
                  }//if (OrderSelect(LowestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     
                  return(true);//Routine succeeded
                  
               }//if ((HighestTradeCash + LowestTradeCash) > 0)                  
            }//if (loss >= MinDistanceBetweenTradesPips)
            
         }//if (pips < 0)
      }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      ArrayResize(ForceCloseTickets, 0);
   }//if (MarketBuysCount > 3)
     
   //Look for a simple offset opportunity of a losing sell at the
   //top of the pile by the winner at the bottom.
   if (MarketSellsCount > NoOfTradesMustBeOpen)//Impossible with < 3
   {

      //Do we have a losing buy?
      if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      {
         //Calculate the pips upl of the lowest, and so latest, sell
         pips = CalculateTradeProfitInPips(OP_SELL);

         if (pips < 0)//Only continue if it is losing
         {
            loss = (pips * -1);//Turn the loss into a positive number for the comparison

            if (loss >= MinDistanceBetweenTradesPips)//Only continue if losing by at least 1 grid level
            {
               LowestTradeCash = OrderSwap() + OrderCommission() + OrderProfit();
               if (OrderSelect(HighestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  HighestTradeCash = OrderSwap() + OrderCommission() + OrderProfit();

               if ((HighestTradeCash + LowestTradeCash) > 0)
               {
                  if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  {
                     result = CloseOrder(LowestSellTicketNo);
                     if (!result)
                     {
                        return(false);
                     }//if (!result)
                  }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  
                  if (OrderSelect(HighestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
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
                  }//if (OrderSelect(HighestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     
                  return(true);//Routine succeeded
                  
               }//if ((HighestTradeCash + LowestTradeCash) > 0)               
            }//if (loss >= MinDistanceBetweenTradesPips)
            
         }//if (pips < 0)
      }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
      ArrayResize(ForceCloseTickets, 0);
          
   }//if (MarketSellsCount  > 3)
       
    
   ////////////////////////////////////////////////////////////////////////
   //Got this far, so see if the combined winners on one side can combine
   //to close a loser on the other side.
   
   if (Hedged)
   {
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

      //Can we offset some buy trades against the lowest losing sell trade
      if (BuyCashUpl > 0)//The buy side of the hedge must be profitable overall
         if (MarketBuysCount >= NoOfTradesMustBeOpen)//Must be sufficient trades open to start offsetting
            if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the lowest sell
            {
            
                //Calculate the pips upl of the lowest, and so latest, sell
                if((CalculateTradeProfitInPips(OP_SELL)*-1)>=MinDistanceBetweenTradesPips) // Only continue if the trade is losing by more than MinDistanceBetweenTradesPips
                {
          
                     CashLoss = (OrderSwap() + OrderCommission() + OrderProfit());//Calculate its cash position
                     if (CashLoss < 0)//Is it losing?
                     {
                        CashLoss*= -1;//Convert to a positive for comparison with the profit on the other side
                        //Calculate the profit on the other side of the hedge
                        for (cc = MarketBuysCount; cc > 0; cc--)
                        {
                           if (OrderSelect(GridOrderBuyTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
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
                           }//if (OrderSelect(FifoBuyTicket[cc - 1][ticket], SELECT_BY_TICKET, MODE_TRADES) )
                           
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
                              if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                              {
                                 result = OrderCloseBy(LowestSellTicketNo, ClosureTickets[as]);
                                 if (!result)
                                   return(false);
                              }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                              
                              for (cc = ArraySize(ClosureTickets) - 2; cc >= 0; cc--)
                              {
                                 if (OrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))
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
                                 }//if (OrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))                          
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
                  }// if((CalculateTradeProfitInPips(OP_SELL)*-1)>=MinDistanceBetweenTradesPips)
            }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))
            
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
         if (MarketSellsCount >= NoOfTradesMustBeOpen)//Must be sufficient trades open to start offsetting
            if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the highest buy
            {
               
               //Calculate the pips upl of the lowest, and so latest, sell
               if((CalculateTradeProfitInPips(OP_BUY)*-1)>=MinDistanceBetweenTradesPips) // Only continue if the trade is losing by more than MinDistanceBetweenTradesPips
               {
               
                  CashLoss = (OrderSwap() + OrderCommission() + OrderProfit());//Calculate its cash position
                  if (CashLoss < 0)//Is it losing?
                  {
                     CashLoss*= -1;//Convert to a positive for comparison with the profit on the other side
                     //Calculate the profit on the other side of the hedge
                     for (cc = 0; cc < MarketSellsCount; cc++)
                     {
                        if (OrderSelect(GridOrderSellTickets[cc][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
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
                        }//if (OrderSelect(FifoSellTicket[cc1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                        
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
                           if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                           {
                              as = ArraySize(ClosureTickets) - 1;
                              result = OrderCloseBy(HighestBuyTicketNo, ClosureTickets[as]);
                              if (!result)
                                 return(false);
                           }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                           
                           for (cc = ArraySize(ClosureTickets) - 2; cc >= 0; cc--)
                           {
                              if (OrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))
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
                              }//if (OrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))                          
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
               }//if((CalculateTradeProfitInPips(OP_SELL)*-1)>=MinDistanceBetweenTradesPips)
            }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))
   
   }//if (Hedged)

//////////////////////////////////////////////////////////////////////////////////////
// Added single side offset below:


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
      
      
      if (MarketBuysCount >= NoOfTradesMustBeOpen)//Must be sufficient trades open to start offsetting
         if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the highest buy which will be the worst loser
         {
         
            //Calculate the pips upl of the lowest, and so latest, sell
            if((CalculateTradeProfitInPips(OP_BUY)*-1)>=MinDistanceBetweenTradesPips) // Only continue if the trade is losing by more than MinDistanceBetweenTradesPips
            {
            
            CashLoss = (OrderSwap() + OrderCommission() + OrderProfit());//Calculate its cash position
            CashLoss*= -1;//Convert to a positive for comparison with the profit on the other side
            //if (CashLoss < 0)//Is it losing?  // changed to check for MinDistanceBetweenTradesPips
            if (CashLoss>0)//Only continue if losing by at least 1 grid level
            {
               //Calculate the profit on the other side of the hedge
               for (cc = MarketBuysCount; cc > 0; cc--)
               {
                  if (OrderSelect(GridOrderBuyTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                  {
                     ThisOrderProfit = (OrderSwap() + OrderCommission() + OrderProfit());
                     
                     if (ThisOrderProfit > 0) // only want to include the trade if it is in profit - this also sorts out the trade order issue
                     {
                        NoOfTrades++;
                        ArrayResize(ClosureTicketsBuySide, NoOfTrades);
                        ClosureTicketsBuySide[NoOfTrades - 1] = OrderTicket();
                        CashProfit+= ThisOrderProfit;  // now we can add this trade's profit to the basket of offset trades
                     }// if (ThisOrderProfit > 0)
                  }//if (OrderSelect(FifoBuyTicket[cc - 1][ticket], SELECT_BY_TICKET, MODE_TRADES) )
                  
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
                     if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     {
                        result = CloseOrder(HighestBuyTicketNo);
                        if (!result)
                           return(false);
                     }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                     
                     for (cc = ArraySize(ClosureTicketsBuySide) - 1; cc >= 0; cc--)
                     {
                        tries = 0;
                        if (OrderSelect(ClosureTicketsBuySide[cc], SELECT_BY_TICKET, MODE_TRADES))
                        {
                           result = CloseOrder(ClosureTicketsBuySide[cc]);
                          // Print("Single Sided Complex buy closure"); // for debugging
                           
                           if (!result)
                           {
                              ForceTradeClosure = true;
                              cc++;
                              //We need to avoid an endless loop when something goes wrong
                              tries++;
                              if (tries >= 20)//Something has gone wrong
                              {   
                                 //The closure attempt has failed, but must be retried.
                                 //Save the ticket number in the array
                                 cas = ArraySize(ForceCloseTickets);
                                 ArrayResize(ForceCloseTickets, cas + 1);
                                 ForceCloseTickets[cas] = ClosureTicketsBuySide[cc];
                                 cc--;//In case something has gone wrong and the trade no longer exists
                              }//if (tries >= 20)                                      
                           }//if (!result)
                        }//if (OrderSelect(ClosureTickets[cc], SELECT_BY_TICKET, MODE_TRADES))                          
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
            }//if (CashLoss >= MinDistanceBetweenTradesPips)
         }//if((CalculateTradeProfitInPips(OP_BUY)*-1)>=MinDistanceBetweenTradesPips)
      }//if (OrderSelect(HighestBuyTicketNo, SELECT_BY_TICKET, MODE_TRADES))
         
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
      int ClosureTicketsSellSide[];
      ArrayInitialize(ClosureTicketsSellSide, -1);
      
      //Can we offset some sell trades against the lowest losing sell trade
      
      if (MarketSellsCount >= NoOfTradesMustBeOpen)//Must be sufficient trades open to start offsetting
         if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))//Select the lowest sell which will be the worst loser
         {
            
            //Calculate the pips upl of the lowest, and so latest, sell
            if((CalculateTradeProfitInPips(OP_SELL)*-1)>=MinDistanceBetweenTradesPips) // Only continue if the trade is losing by more than MinDistanceBetweenTradesPips
            {
               CashLoss = (OrderSwap() + OrderCommission() + OrderProfit());//Calculate its cash position
               CashLoss*= -1;//Convert to a positive for comparison with the profit on the other side
               
               //if (CashLoss < 0)//Is it losing?  // changed to check for MinDistanceBetweenTradesPips.
               if (CashLoss>0)//Only continue if losing by at least 1 grid level
               {
                  //Calculate the profit on the other side of the hedge
                  for (cc = MarketSellsCount; cc > 0; cc--)
                  {
                                          
                     if (OrderSelect(GridOrderSellTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                     {
                         ThisOrderProfit = (OrderSwap() + OrderCommission() + OrderProfit());
                        
                        if (ThisOrderProfit > 0) // only want to include the trade if it is in profit
                        {
                           NoOfTrades++;
                           ArrayResize(ClosureTicketsSellSide, NoOfTrades);
                           ClosureTicketsSellSide[NoOfTrades - 1] = OrderTicket();
                           CashProfit+= ThisOrderProfit;  // now we can add this trade's profit to the basket of offset trades
                        }//if (ThisOrderProfit > 0)
                     }//if (OrderSelect(GridOrderSellTickets[cc - 1][TradeTicket], SELECT_BY_TICKET, MODE_TRADES) )
                     
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
                        if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                        {
                           result = CloseOrder(LowestSellTicketNo);
                           if (!result)
                              return(false);//First trade has not closed, so do not continue
                        }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES) )
                        
                        for (cc = ArraySize(ClosureTicketsSellSide) - 1; cc >= 0; cc--)
                        {
                           tries = 0;
                           if (OrderSelect(ClosureTicketsSellSide[cc], SELECT_BY_TICKET, MODE_TRADES))
                           {
                              result = CloseOrder(ClosureTicketsSellSide[cc]);
                              
                             // Print("Single Sided Complex sell closure"); // for debugging
                              if (!result)
                              {
                                 ForceTradeClosure = true;
                                 cc++;
                                 //We need to avoid an endless loop when something goes wrong
                                 tries++;
                                 if (tries >= 20)//Something has gone wrong
                                 {   
                                    //The closure attempt has failed, but must be retried.
                                    //Save the ticket number in the array
                                    cas = ArraySize(ForceCloseTickets);
                                    ArrayResize(ForceCloseTickets, cas + 1);
                                    ForceCloseTickets[cas] = ClosureTicketsSellSide[cc];
                                    cc--;//In case something has gone wrong and the trade no longer exists
                                 }//if (tries >= 20)  
                              }//if (!result)
                           }// if (OrderSelect(ClosureTicketsSellSide[cc], SELECT_BY_TICKET, MODE_TRADES))                        
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
               }//if (CashLoss >= MinDistanceBetweenTradesPips)
            }//if((CalculateTradeProfitInPips(OP_SELL)*-1)>=MinDistanceBetweenTradesPips) 
         }//if (OrderSelect(LowestSellTicketNo, SELECT_BY_TICKET, MODE_TRADES))
         
      CashLoss = 0;
      CashProfit = 0;
      NoOfTrades = 0;
   
   //END - sell side only complex hedge
   ///////////////////////////////////////////////////////////////////////////// 
   
 }// if(AllowComplexSingleSidedOffsets)



   // End of added single side offset

   ////////////////////////////////////////////////////////////////////////////
   //Got this far, so no trades closed
   return(false);

}//END bool CanTradesBeOffset()

void NuclearOptions()
{
   //Respond to the user's choice of options when a position becomes unbalanced.
   
   //Instant closure of the position.
   if (UseInstantClosure)
   {
      CloseAllTrades(AllTrades);
      if(ForceTradeClosure)
      {
         CloseAllTrades(AllTrades);
         if (ForceTradeClosure)
            return;
      }//if (ForceTradeClosure) 
      
      //Closure succeeded, so rebuild a picture of the position.
      CountOpenTrades();
   }//if (UseInstantClosure)
   
   //Margin level
   if (UseMarginLevelClosure)
   {
      //Use the existing MarginCheck function
      //Store the user' choices
      bool OldFk = UseForexKiwi;
      double OldFkMin = FkMinimumMarginPercent;
      UseForexKiwi = true;
      FkMinimumMarginPercent = ClosureMarginLevel;
      
      bool MarginOk = MarginCheck();
      
      //Restore the user's choices
      UseForexKiwi = OldFk;
      FkMinimumMarginPercent = OldFkMin;
      
      if (!MarginOk)
      {
         CloseAllTrades(AllTrades);
         if(ForceTradeClosure)
         {
            CloseAllTrades(AllTrades);
            if (ForceTradeClosure)
               return;
         }//if (ForceTradeClosure) 
      
         //Closure succeeded, so rebuild a picture of the position.
         CountOpenTrades();
      }//if (!MarginOk() )
      
      
   }//if (UseMarginLevelClosure)
   
   
   
}//End void NuclearOptions()


//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
//----
   //int cc;

   //mptm sets a Global Variable when it is closing the trades.
   //This tells this ea not to send any fresh trades.
   if (GlobalVariableCheck(GvName))
      return;
   //'Close all trades this pair only script' sets a GV to tell EA's not to attempt a trade during closure
   if (GlobalVariableCheck(LocalGvName))
      return;
   //'Nuclear option script' sets a GV to tell EA's not to attempt a trade during closure
   if (GlobalVariableCheck(NuclearGvName))
      return;

   if (RemoveExpert)
   {
      ExpertRemove();
      return;
   }//if (RemoveExpert)

   //Those stupid sods at MetaCrapper have ensured that stopping an ea by diabling AutoTrading no longer works. Ye Gods alone know why.
   //This routine provided by FxCoder. Thanks Bob.
   if ( !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) )
   {
      Comment("                          TERMINAL AUTOTRADING IS DISABLED");
      return;
      
   }//if ( !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) )
   if (!IsTradeAllowed() )
   {
      Comment("                          THIS EXPERT HAS LIVE TRADING DISABLED");
      return;
   }//if (!IsTradeAllowed() )
      
   //In case any trade closures failed
   if (ArraySize(ForceCloseTickets) > 0)
   {
      MopUpTradeClosureFailures();
      return;
   }//if (ArraySize(ForceCloseTickets) > 0)      
      
   //Rollover
   if (DisableEaDuringRollover)
   {
      RolloverInProgress = false;
      if (AreWeAtRollover())
      {
         RolloverInProgress = true;
         DisplayUserFeedback();
         return;
      }//if (AreWeAtRollover)
   }//if (DisableEaDuringRollover)
         
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
        if (!HistoryOK(Symbol(),Period())) WeHaveHistory = false;
        if (!WeHaveHistory)
        {
            Alert("There are <100 bars on this chart so the EA cannot work. It has removed itself. Please refresh your chart.");
            ExpertRemove();
        }//if (!WeHaveHistory)
        
        //if we get here, history is OK, so stop checking
        NeedToCheckHistory=false;
   }//if (NeedToCheckHistory)

   //Spread calculation
   if (!IsTesting() )
   {   
      if(CloseEnough(AverageSpread,0) || RunInSpreadDetectionMode)
      {
         GetAverageSpread();
         ScreenMessage="";
         int left=TicksToCount-CountedTicks;
         //   ************************* added for OBJ_LABEL
         DisplayCount = 1;
         removeAllObjects();
         //   *************************
         SM("Calculating the average spread. "+DoubleToStr(left,0)+" left to count.");
         Comment(ScreenMessage);
         return;
      }//if (CloseEnough(AverageSpread, 0) || RunInSpreadDetectionMode) 
      //Keep the average spread updated
      double spread=(Ask-Bid)*factor;
      if(spread>BiggestSpread) BiggestSpread=spread;//Widest spread since the EA was loaded
      static double SpreadTotal=0;
      static int counter=0;
      SpreadTotal+=spread;
      counter++;
      if(counter>=500)
      {
         AverageSpread=NormalizeDouble(SpreadTotal/counter,1);
         //Save the average for restarts.
         GlobalVariableSet(SpreadGvName,AverageSpread);
         SpreadTotal=0;
         counter=0;
      }//if (counter >= 500)
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
            return;
      }//while (RobotSuspended)           
      return;
   }//if (RobotSuspended) 

   //If HG is sleeping after a trade closure, is it time to awake?
   TooClose();
   if(SafetyViolation)//TooClose() sets SafetyViolation
   {
      DisplayUserFeedback();
      return;
   }//if (SafetyViolation) 


   
   if(OrdersTotal()==0)
   {
      TicketNo=-1;
      ForceTradeClosure=false;
   }//if (OrdersTotal() == 0)

   if(ForceTradeClosure)
   {
      CloseAllTrades(AllTrades);
      if (ForceTradeClosure)
         return;
   }//if (ForceTradeClosure) 


   //Check for a massive spread widening event and pause the ea whilst it is happening
   if (!IsTesting() )
      CheckForSpreadWidening();

   
   
   //Daily results so far - they work on what in in the history tab, so users need warning that
   //what they see displayed on screen depends on that.   
   //Code courtesy of TIG yet again. Thanks, George.
   static int OldHistoryTotal;
   if(OrdersHistoryTotal()!=OldHistoryTotal)
   {
      CalculateDailyResult();//Does no harm to have a recalc from time to time
      OldHistoryTotal=OrdersHistoryTotal();
   }//if (OrdersHistoryTotal() != OldHistoryTotal)

   ForceTradeClosure = false;
   ReadIndicatorValues();//This might want moving to the trading section at the end of this function if EveryTickMode = false
   if (ForceTradeClosure)//In case a stop order deletion failed
   {
      ForceTradeClosure = false;
      ReadIndicatorValues();//Try again
      if (ForceTradeClosure)
      {
         DisplayUserFeedback();
         return;//Make sure the bot does not send pending orders that will be deleted at the next tick
      }//if (ForceTradeClosure)      
   }//if (ForceTradeClosure)
   

   //Delete orphaned tp/sl lines
   static int M15Bars;
   if(M15Bars!=iBars(NULL,PERIOD_M15))
   {
      M15Bars=iBars(NULL,PERIOD_M15);
      DeleteOrphanTpSlLines();
   }//if (M15Bars != iBars(NULL, PERIOD_M15)

///////////////////////////////////////////////////////////////////////////////////
   //Find open trades.
   CountOpenTrades();
   //Possible shut down for the weekend
   if (OpenTrades > 0)
   {
      ShutDownForTheWeekend();
      if (ForceTradeClosure)
      {
         CloseAllTrades(AllTrades);
         return;
      }//if (ForceTradeClosure)

      //Offsetting in a balanced position
      if (!Unbalanced)
         if (UseOffsetting)
         {
            ShouldTradesBeClosed(MinOpenTradesToStartOffset);
            //In case any trade closures failed
            if (ArraySize(ForceCloseTickets) > 0)
            {
               MopUpTradeClosureFailures();
               return;
            }//if (ArraySize(ForceCloseTickets) > 0)        
         }//if (UseOffsetting)
      
      
      //Unbalanced positions
      if (Unbalanced)
      {
         //Offsetting in Recovery
         if (UseOffsettingForBalanceRecovery)
         {
            //Save the user inputs
            bool OldAllowComplex = AllowComplexSingleSidedOffsets;//Save the user input
            AllowComplexSingleSidedOffsets = AllowComplexSingleSidedOffsetsRecovery;
            int OldMinTrades = MinOpenTradesToStartOffset;
            MinOpenTradesToStartOffset = MinTradesToStartUnbalancedOffset;
            CanTradesBeOffset(0);
            //Restore the user's inputs
            AllowComplexSingleSidedOffsets = OldAllowComplex;
            MinTradesToStartUnbalancedOffset = OldMinTrades;
            //In case any trade closures failed
            if (ArraySize(ForceCloseTickets) > 0)
            {
               MopUpTradeClosureFailures();
               return;
            }//if (ArraySize(ForceCloseTickets) > 0)        
         }//if (UseOffsettingForBalanceRecovery)
      
         //User's choice of 'nuclear options' when a position becomes unbalanced.
         NuclearOptions();
         if(ForceTradeClosure)
         {
            CloseAllTrades(AllTrades);
            if (ForceTradeClosure)
               return;
         }//if (ForceTradeClosure) 
      }//if (Unbalanced)
         
   }//if (OpenTrades > 0)
   
//Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Detect a closed trade and check that is was not a rogue.
   if(OldOpenTrades!=OpenTrades)
   {
      if(IsClosedTradeRogue())
      {
         RobotSuspended=true;
         return;
      }//if (IsClosedTradeRogue() )      
   }//if (OldOpenTrades != OpenTrades)

   OldOpenTrades=OpenTrades;

   if (Hedged || Unbalanced)
      LookForBasketClosure();
      
   if (ForceTradeClosure)
   {
      CloseAllTrades(AllTrades);
      if (ForceTradeClosure)
      {
         CloseAllTrades(AllTrades);
         if (ForceTradeClosure)
         {
            return;
         }//if (ForceTradeClosure)                     
      }//if (ForceTradeClosure)         
   }//if (ForceTradeClosure)      
 
   //Lot size based on account size
   if (!CloseEnough(LotsPerDollopOfCash, 0))
      CalculateLotAsAmountPerCashDollops();

///////////////////////////////////////////////////////////////////////////////////

   //Trading times
   TradeTimeOk=CheckTradingTimes();
   if(!TradeTimeOk)
   {
      DisplayUserFeedback();
      Sleep(1000);
      return;
   }//if (!TradeTimeOk)

   //Sunday trading, Monday start time, Friday stop time, Thursday trading
   TradeTimeOk = SundayMondayFridayStuff();
   if (!TradeTimeOk)
   {
      DisplayUserFeedback();
      return;
   }//if (!TradeTimeOk)

///////////////////////////////////////////////////////////////////////////////////

   //Check that there is sufficient margin for trading
   if(!MarginCheck())
   {
      DisplayUserFeedback();
      return;
   }//if (!MarginCheck() )

   
   //Trading
   if(EveryTickMode) OldBarsTime=0;
   if(OldBarsTime!=iTime(NULL,TradingTimeFrame,0))
   {
      OldBarsTime = iTime(NULL, TradingTimeFrame, 0);
      if (TimeCurrent() >= TimeToStartTrading)
         if (!StopTrading)              
            {
               TimeToStartTrading = 0;//Set to TimeCurrent() + (PostTradeAttemptWaitMinutes * 60) when there is an OrderSend() attempt)
               LookForTradingOpportunities();
            }//if (!StopTrading)
   }//if(OldBarsTime!=iTime(NULL,TradingTimeFrame,0))


///////////////////////////////////////////////////////////////////////////////////

   DisplayUserFeedback();

//----
   return;
}
//+------------------------------------------------------------------+

//+-------------------------------------------------------------------+
//|      Holy Graily Bob 'n Dotty 'n Super Slope 'n Flying Buddha.mq4 |
//|                         Copyright 2012, tomele and Steve Hopwood  |
//|                              http://www.hopwood3.freeserve.co.uk  |
//+-------------------------------------------------------------------+


/*
All our thanks go to tomele for the major contribution he has made
to the development of this EA. It would not be the trading force
it is without him. Many thanks Thomas. You are one of SHF's stars.
*/

#define  version "Version 1e"

#property copyright "Copyright 2012, Steve Hopwood"
#property link      "http://www.hopwood3.freeserve.co.uk"
#property strict

//Flying Buddha
#define  fbnoarrow ": No arrow"
#define  fbuparrowtradable ": Tradable up arrow"
#define  fbdownarrowtradable ": Tradable down arrow"
#define  fbuparrowuntradable ": Untradable up arrow"
#define  fbdownarrowuntradable ": Untradable down arrow"



//SuperSlope colours
#define  red ": Red"
#define  blue ": Blue"
//Changed by tomele
#define white ": White"



extern string  gen="----General inputs----";
/*
Note to coders about TradingTimeFrame. Be consistent in your calls to indicators etc and always use TradingTimeFrame i.e.
double v = iCustom(Symbol(), TradingTimeFrame, ....................)
This allows the user to change time frames without disturbing the ea. There is a line of code in OnInit(), just above the call
to DisplayUserFeedback() that forces the EA to wait until the open of a new TradingTimeFrame candle; you might want to comment
this out during your EA development.
*/
extern ENUM_TIMEFRAMES TradingTimeFrame=PERIOD_D1;
extern bool    EveryTickMode=false;
int            DebugLevel=0;
extern
 double  Lot=0.11;
//Set to zero to disable and use Lot
extern double  RiskPercent = 0;
//Over rides Lot. Zero input to cancel.
extern double  LotsPerDollopOfCash=0;
extern double  SizeOfDollop=1000;
extern bool    UseBalance=false;
extern bool    UseEquity=true;
extern bool    StopTrading=false;
extern bool    TradeLong=true;
extern bool    TradeShort=true;
extern int     TakeProfitPips=0;
extern int     StopLossPips=0;
extern int     MagicNumber=0;
extern string  TradeComment="HGInDB";
extern bool    IsGlobalPrimeOrECNCriminal=false;
extern double  MaxSlippagePips=5;
//We need more safety to combat the cretins at Crapperquotes managing to break Matt's OR code occasionally.
//EA will make no further attempt to trade for PostTradeAttemptWaitMinutes minutes, whether OR detects a receipt return or not.
extern int     PostTradeAttemptWaitSeconds=600;//Defaults to 10 minutes
////////////////////////////////////////////////////////////////////////////////////////
bool           RemoveExpert=false;
datetime       TimeToStartTrading=0;//Re-start calling LookForTradingOpportunities() at this time.
double         TakeProfit, StopLoss;
datetime       OldBarsTime;
double         dPriceFloor = 0, dPriceCeiling = 0;//Next x0 numbers
double         PriceCeiling100 = 0, PriceFloor100 = 0;// Next 'big' numbers

string         GvName="Under management flag";//The name of the GV that tells the EA not to send trades whilst the manager is closing them.
//'Close all trades this pair only script' sets a GV to tell EA's not to attempt a trade during closure
string         LocalGvName = "Local closure in operation " + Symbol();
//'Nuclear option script' sets a GV to tell EA's not to attempt a trade during closure
string         NuclearGvName = "Nuclear option closure in operation ";

string         TradingTimeFrameDisplay="", TrendTimeFrameDisplay="";
//For FIFO
int            FifoTicket[];//Array to store trade ticket numbers in FIFO mode, to cater for
                            //US citizens and to make iterating through the trade closure loop 
                            //quicker.
double         GridOrderBuyTickets[][2]; // number of lines will be equal to MarketBuysOpen - 1
double         GridOrderSellTickets[][2];
//An array to store ticket numbers of trades that need closing, should an offsetting OrderClose fail
int            ForceCloseTickets[];//Keep track of the position variables
//I have not been able to make the existing arrays work for closing opposite losers after
//closing a full hedge trade, so I am adding these.
int            BuyCloseTicket[], SellCloseTicket[];

//Arrays for holding trade prices for the fill the gap stuff
double         BuyPrices[], SellPrices[];

//Arrays for holding the ticket numbers of full hedge trades
int            BuyHedgeTickets[], SellHedgeTickets[];

double         upl;//For keeping track of the upl of multi-trade positions
//double         MostRecentBuyPrice, MostRecentSellPrice;//Hold the prices of the latest trades

//Variables for storing market trade ticket numbers
int            MarketBuys=0, MarketSells=0;
int            PendingBuyStops=0, PendingSellStops=0;
int            PendingBuyLimits=0, PendingSellLimits=0;

bool           ReRunCOT=false;

////////////////////////////////////////////////////////////////////////////////////////

sinput string  sep30="================================================================";
sinput string  ssi="---- SuperSlope inputs ----";
sinput string  hstf="-- Highest time frame ";
sinput bool    UseSsHigherTimeFrameControl=true;
//Only take the trade if it is in line with this i.e. only buy when SS bar is green and sell when red.
sinput ENUM_TIMEFRAMES SsHigherTimeFrame=PERIOD_MN1;
//SsHtfMaxBars>0 turns off WindowFirstVisibleBar()
sinput int     SsHtfMaxBars              = 0; 
sinput bool    SsHtfAutoTimeFrame        = true;
sinput double  SsHtfDifferenceThreshold  = 0;
sinput double  SsHtfLevelCrossValue      = 0;
sinput int     SsHtfSlopeMAPeriod        = 5; 
sinput int     SsHtfSlopeATRPeriod       = 50; 
sinput bool    SsCloseTradesOnHtfColourChange=false;
sinput string  mstf="-- Medium time frame ";
sinput bool    UseSsMediumTimeFrameControl=false;
sinput ENUM_TIMEFRAMES SsMediumTimeFrame=PERIOD_W1;
sinput int     SsMtfMaxBars              = 0;
sinput bool    SsMtfAutoTimeFrame        = true;
sinput double  SsMtfDifferenceThreshold  = 0.0;
sinput double  SsMtfLevelCrossValue      = 2.0;
sinput int     SsMtfSlopeMAPeriod        = 7; 
sinput int     SsMtfSlopeATRPeriod       = 50; 
sinput bool    SsCloseTradesOnMtfColourChange=false;
sinput string  ttf="-- Trading time frame --";
sinput bool    UseSsTradingTimeFrameControl=false;
sinput int     SsTradingMaxBars              = 0;
sinput bool    SsTradingAutoTimeFrame        = true;
sinput double  SsTradingDifferenceThreshold  = 0.0;
sinput double  SsTradingLevelCrossValue      = 2.0;
sinput int     SsTradingSlopeMAPeriod        = 5; 
sinput int     SsTradingSlopeATRPeriod       = 50; 
sinput bool    SsCloseTradesOnColourChange=false;
////////////////////////////////////////////////////////////////////////////////////////
//I added HTF as an afterthought, so these variables are for TradingTimeFrame
double         SsTtfCurr1Val=0, SsTtfCurr2Val=0;
string         SsColour;//For shifts 0 to 2. Colours defined at top of file
//Variables for SsHigherTimeFrame
double         SsHtfCurr1Val, SsHtfCurr2Val;
string         SsHtfColour="";
//Variables for SsMediumTimeFrame
double         SsMtfCurr1Val, SsMtfCurr2Val;
string         SsMtfColour="";
bool           BrokerHasSundayCandles;
bool           LongTradeTrigger=false, ShortTradeTrigger=false;//Set to true when there is a signal on the TradingTimeFrame
////////////////////////////////////////////////////////////////////////////////////////

sinput string  sep100="================================================================";
sinput string  fbi="---- Flying Buddha inputs ----";
sinput string  ini="-- Indi inputs --";
sinput int     FbFastPeriod=5;
sinput int     FbFastAvgMode=1;
sinput int     FbFastPrice=0;
sinput int     FbSlowPeriod=5;
sinput int     FbSlowAvgMode=1;
sinput int     FbSlowPrice=0;
sinput int     FbMaxBars=2000;
sinput double  FbFactorWindow=0.03;
//Take every trade signal
sinput string  tri="-- Trading inputs --";
sinput bool    TradeEverySignal=true;
//Up to this maximum
sinput int     MaxSignalsToFollow=10;
//With this distance between signals.
sinput int     MinimumDistanceBetweenSignalsPips=10;
//Use atr to calculate the minimum distance
sinput bool    UsePercentageOfAtrForDistance=true;
//over this period
sinput int     FbAtrPeriod=24;                     
//at this percentage.
sinput int     FbPercentageOfAtrToUse=100;         
sinput string  trcl="-- Trade closure inputs --";
//Close buys following a down arrow and sells at an up arrow
sinput bool    CloseOnOppositeFB=true;            
//but only when SS is the same direction as the arrow.
sinput bool    OnlyCloseWhenSuperSlopeAgrees=true; 
////////////////////////////////////////////////////////////////////////////////////////
string         FbStatus="";//Constants defined at top of file
double         MinimumDistanceBetweenSignals=0;
double         fbAtrVal=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1="================================================================";
extern string  hgic="======== HGI choices ========";
extern string  hgi="-- HGI Inputs --"; 
extern bool    UseTrendHGI=false;
//The overriding signal
extern ENUM_TIMEFRAMES HgiTrendTimeFrame=PERIOD_H4;
//Furthest back in time to look for an arrow. 0 means the current candle.
extern int     HgiTrendTimeFrameCandlesLookBack=20;
//Uses the TradingTimeFrame value at the top of the inputs
extern bool    UseTradingTimeFrameHGI=false;
extern bool    HgiTrendTradingAllowed=true;
extern bool    HgiRadTradingAllowed=false;
extern bool    HgiWaveTradingAllowed=true;
//Close market trades and delete pendings. Works in conjunction
//with HgiOnlyCloseProfitablePositions
extern bool    HgiCloseOnYellowRangeWave=false;
//Close buys on a sell signal/trend etc                                               
extern bool    HgiCloseOnOppositeSignalOrTrendChange=true;
//but only if in profit. If whole position is not profitable, 
//then close the individual profitable trades.
extern bool    HgiOnlyCloseProfitablePositions=true;      
extern string  fhi="-- Full hedge Inputs --"; 
extern bool    UseFullHedging=true;
//The difference between open buy and sell lots to fully hedge on an opposite direction signal.   
extern double  BuysAndSellsUnbalancedAtLots=0.1;                               
extern bool    OnlyCloseFullHedgeWhenInProfit=true;
//Uses ClosedHedgeProfit to close an equal cash value of opposite trades.
extern bool    OffsetOppositeLosersAgainstProfit=true;
extern string  FullHedgeComment="Full hedge";
extern bool    CloseProfitableFullHedgeOnYellowWave=true;
////////////////////////////////////////////////////////////////////////////////////////
//Trading variables
int            HgiTrendTimeFrameCandlesBack;//For displaying how far back the arrow was found.
double         TotalBuyLots=0, TotalSellLots=0;
string         HgiTrendTimeFrameStatus="", HgiTradingTimeFrameStatus="";//One of the arrow status constants at the top of this file
bool           HgiLongTrendDetected=false, HgiShortTrendDetected=false;
bool           HgiLongTradeTrigger=false, HgiShortTradeTrigger=false;//Set to true when there is a signal on the TradingTimeFrame
double         ClosedHedgeProfit=0;//The profit taken by to successful full hedge trade.


bool           NewLongTrendDetected=false, NewShortTrendDetected=false;//For detecting trend changes
bool           OldLongTrendDetected=false, OldShortTrendDetected=false;//For remembering the last trend detected
string         TrendGvName="";//For saving the last trend detected. Set up and read in OnInit
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1a="================================================================";
extern string  tts="---- Trading style. ----";
extern bool    ImmediateMarketOrders=true;
extern string  ad="-- Associated details --";
//Stack when there is a reversal candle instead of using the grid
extern bool    StackByCandleDirection=false;
//For multi-trade EA's
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1i="================================================================";
extern string  sxs="---- Sixths ----";
extern bool    UseSixths=true;
//Divides the space between PH and PL to create the sixths
extern int     ChartDivisor=4;
//Trade both ways if the market is in the middleof the chart
extern bool    AllowTradingInTheMiddle=true;
//cozybooks wants to experiment with only trading in the middle
extern bool    OnlyTradeTheMiddle=false;
//The next four inputs are telling the bot to follow a market that has filled a stop or limit order before continuing 
//in the wrong direction for the trade. Peaky will leave stop orders at (MarketDistancePips / 2) pips behind the market price.
//The purpose is to cash in on the inevitable reversal.
extern bool    FollowAdverseMarketWithStopOrders=true;
extern int     MarketDistancePips=100;
extern int     MaxTradesAllowed=6;//For multi-trade EA's
extern int     TradesToConstituteBasket=3;
extern double  BasketCashProfitTarget=100;
////////////////////////////////////////////////////////////////////////////////////////
int            per=0;//Chart period passed as a parameter
string         SixthsStatus="";
double         MarketDistance=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1j="================================================================";
extern string  ict="---- Inputs common to Sixths and BLSH ----";
//Allow the user to specify the number of bars on the chart
extern int     NoOfBarsOnChart=1682;
extern color   CurrentPeakHighColour=Yellow;
extern color   CurrentPeakLowColour=Yellow;
extern bool    ShowTradingArea=true;
//Thans to Radar for this
extern string  ztxt1             =  "Set Zoom Level...";
extern string  ztxt2             =  "0 = Sky-High...";
extern string  ztxt3             =  "5 = Ground-Level";
extern int     Zoom_Level        =  0;


extern string  sep1k="================================================================";
extern string  bls="---- Buy Low Sell High ----";
extern bool    UseBuyLowSellHigh=false;
extern string  hitf="-- Highest time frame --";
extern bool    UseBlshHighestTimeFrame=false;
extern ENUM_TIMEFRAMES BlshHighestTimeFrame=PERIOD_W1;
extern color   BlshHighestTimeFrameLineColour=Magenta;
extern int     BlshHighestTimeFrameLineSize=3;
//////////////////////////////////////////////////////////
double         blshHighestPeakHigh=0, blshHighestPeakLow=0;
//How far back the hilo were found
int            blshHighestPeakHighBar=0, blshHighestPeakLowBar=0;
//Names for the lines
string         blshHighestPeakHighLineName="phl_Highest time frame peak high";
string         blshHighestPeakLowLineName="phl_Highest time frame peak low";
string         highestBlshStatus="";
//////////////////////////////////////////////////////////

extern string  htf="-- High time frame --";
extern bool    UseBlshHighTimeFrame=false;
extern ENUM_TIMEFRAMES BlshHighTimeFrame=PERIOD_D1;
extern color   BlshHighTimeFrameLineColour=Blue;
extern int     BlshHighTimeFrameLineSize=2;
//////////////////////////////////////////////////////////
double         blshHighPeakHigh=0, blshHighPeakLow=0;
//How far back the hilo were found
int            blshHighPeakHighBar=0, blshHighPeakLowBar=0;
//Name for the line
string         blshHighPeakHighLineName="phl_High time frame peak high";
string         blshHighPeakLowLineName="phl_High time frame peak low";
string         highBlshStatus="";
//////////////////////////////////////////////////////////

extern string  mtf="-- Medium time frame --";
extern bool    UseBlshMediumTimeFrame=false;
extern ENUM_TIMEFRAMES BlshMediumTimeFrame=PERIOD_H4;
extern color   BlshMediumTimeFrameLineColour=Turquoise;
extern int     BlshMediumTimeFrameLineSize=1;
//////////////////////////////////////////////////////////
double         blshMediumPeakHigh=0, blshMediumPeakLow=0;
int            blshMediumPeakHighBar=0, blshMediumPeakLowBar=0;
string         blshMediumPeakHighLineName="phl_Medium time frame peak high";
string         blshMediumPeakLowLineName="phl_Medium time frame peak low";
string         mediumBlshStatus="";
//////////////////////////////////////////////////////////

extern string  bttf="-- Trading time frame --";
extern color   BlshTradingTimeFrameLineColour=Yellow;
extern int     BlshTradingTimeFrameLineSize=0;
//////////////////////////////////////////////////////////
//PH and PL
double         blshTradingPeakHigh=0, blshTradingPeakLow=0;
//How far back the hilo were found
int            blshTradingPeakHighBar=0, blshTradingPeakLowBar=0;
string         blshTradingPeakHighLineName="phl_Trading time frame peak high";
string         blshTradingPeakLowLineName="phl_Trading time frame peak low";
string         tradingBlshStatus="";
string         combinedBlshStatus="";
//These inputs are for displaying the top trading area
double         phTradeLine=0, plTradeLine=0;
string         phTradeLineName="phl_Peak high trading line", plTradeLineName="phl_Peak Low Trading LIne";
//////////////////////////////////////////////////////////

//Code provided by lifesys. Thanks again Paul.
extern string  lab="-- Labels --";
extern int     BlshDisplayX          = 1600;
extern int     BlshDisplayY          = 100;
extern int     BlshfontSise          = 14;
extern string  BlshfontName          = "Arial";
extern color   BuyColour=Green;
extern color   SellColour=Red; 
// adjustment to reform lines for different font size
//////////////////////////////////////////////////////////
string         highestTimeFrameLabelName="phl_Highest time frame label", highTimeFrameLabelName="phl_High time frame label";
string         mediumTimeFrameLabelName="phl_Medium time frame label", tradingTimeFrameLabelName="phl_Trading time frame label";
string         highestTimeFrameLabelDirection="phl_Highest time frame label direction", highTimeFrameLabelDirection="phl_High time frame label direction";
string         mediumTimeFrameLabelDirection="phl_Medium time frame label direction", tradingTimeFrameLabelDirection="phl_Trading time frame label direction";
//////////////////////////////////////////////////////////

//More externs and variables can be found in the library
#include <HGBnD core library.mqh>


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//----

   UsualOnInit();
   
   MarketDistance = MarketDistancePips;
   
   
   
//----
   return(0);
}//End int OnInit()

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//----
   UsualOnDeinit();

/*
   if (UseSixths)
   {
      ObjectDelete(blshHighestPeakHighLineName);
      ObjectDelete(blshHighestPeakLowLineName);
      ObjectDelete(phTradeLineName);
      ObjectDelete(plTradeLineName);      
   }//if (UseSixths)

   if (UseBuyLowSellHigh)
   {
      if (!UseSixths)
      {
         ObjectDelete(blshHighestPeakHighLineName);
         ObjectDelete(blshHighestPeakLowLineName);
         ObjectDelete(phTradeLineName);
         ObjectDelete(plTradeLineName);      
      }//if (!UseSixths)
      ObjectDelete(blshHighPeakHighLineName);
      ObjectDelete(blshHighPeakLowLineName);
      ObjectDelete(blshMediumPeakHighLineName);
      ObjectDelete(blshMediumPeakLowLineName);
      ObjectDelete(blshTradingPeakHighLineName);
      ObjectDelete(blshTradingPeakLowLineName);
   }//if (UseBuyLowSellHigh)
*/   
   
//----
   return;
}//End void OnDeinit(const int reason)

void DisplayUserFeedback()
{

   if (IsTesting() && !IsVisualMode()) return;

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

 
   ScreenMessage = "";
   //ScreenMessage = StringConcatenate(ScreenMessage,Gap + NL);
   SM(NL);
   if (SafetyViolation) SM("*************** CANNOT TRADE YET. TOO SOON AFTER CLOSE OF PREVIOUS TRADE***************" + NL);
   
   SM("Updates for this EA are to be found at http://www.stevehopwoodforex.com"+NL);
   SM("Feeling generous? Help keep the coder going with a small Paypal donation to pianodoodler@hotmail.com"+NL);
   SM("Broker time = " + TimeToStr(TimeCurrent(), TIME_DATE|TIME_SECONDS) + ": Local time = " + TimeToStr(TimeLocal(), TIME_DATE|TIME_SECONDS) + NL );
   SM(version + NL);
   /*
   //Code for time to bar-end display donated by Baluda. Cheers Paul.
   SM( TimeToString( iTime(Symbol(), TradingTimeFrame, 0) + TradingTimeFrame * 60 - CurTime(), TIME_MINUTES|TIME_SECONDS ) 
   + " left to bar end" + NL );
   */
   
   if (!TradeTimeOk)
   {
      SM(NL);
      SM("---------- OUTSIDE TRADING HOURS. Will continue to monitor open trades ----------" + NL + NL);
   }//if (!TradeTimeOk)

   
   if(RolloverInProgress)
     {
      SM(NL);
      SM("---------- ROLLOVER IN PROGRESS. I am taking no action until "+RollOverEnds+" ----------"+NL+NL);
      return;
     }//if (RolloverInProgress)
   
   SM("Flying Buddha arros status" + FbStatus + NL);
   if (UsePercentageOfAtrForDistance)
      text = "ATR value = " + DoubleToStr(fbAtrVal, 4) + ":  ";
   text = text + "Minimum distance between trades = " + DoubleToStr(MinimumDistanceBetweenSignals, 2) + " pips";   
   SM(text + NL);
   
   if (UseSsHigherTimeFrameControl)
   SM("Higher time frame SuperSlope colour is" + SsHtfColour + NL); 

   if (UseSsMediumTimeFrameControl)
      SM("Medium time frame SuperSlope colour is" + SsMtfColour + NL); 
   
   if (UseSsTradingTimeFrameControl)
      SM("Trading time frame SuperSlope colour is" + SsColour + NL); 
    
   
   
   if (UseTrendHGI)
   {
      //SM("HGI_Name = " + HGI_Name + NL);
      text = "HGI Trend time frame status: " + HgiTrendTimeFrameStatus;
      if (HgiTrendTimeFrameStatus != hginotrend)
         text = text + " " + (string)HgiTrendTimeFrameCandlesBack + " candles ago.";
         if (HgiLongTrendDetected)
            text = text + " We are in a long trend.";
         if (HgiShortTrendDetected)
            text = text + " We are in a short trend.";
         text = text + NL;
      SM(text);     
   }//if (UseTrendHGI)
   
   if (UseTradingTimeFrameHGI)
   {      
      SM("HGI Trading time frame status: " + HgiTradingTimeFrameStatus + NL);
   }//if (UseTradingTimeFrameHGI)
      
      
   text = "No trade signal on the trading time frame";
   if (BuySignal)
      text = "We have a buy signal on the trading time frame";
   if (SellSignal)
      text = "We have a sell signal on the trading time frame";
   SM(text + NL);
   
   if (UseSixths)
      SM("Sixths trading status" + SixthsStatus + NL);
   
   
   //Display the indi values and status here
   
   SM(NL);
   if (UseChandelierExit)
      SM("Chandelier colour:" + ChanColour + NL);
   
   if (UseCSS)
   {
      SM(Curr1 + " = " + DoubleToStr(CurrVal1[2], 2) + "  "  + DoubleToStr(CurrVal1[1], 2) + ": Direction is " + CurrDirection1 + NL);
      SM(Curr2 + " = " + DoubleToStr(CurrVal2[2], 2) + "  "  + DoubleToStr(CurrVal2[1], 2) + ": Direction is " + CurrDirection2 + NL);
   }//if (UseCSS)
   
   
   if (UseGrid)
   {
      if (!UseAtrForGrid)
         SM("Distance between grid trades = " + DoubleToStr(DistanceBetweenTrades, 0) + " pips" + NL);

      if (UseAtrForGrid)
      {
         SM("ATR for the grid size = " + DoubleToString(GridAtrVal, 0) + " pips" + NL);
         SM("Distance between trades = " + DoubleToStr(DistanceBetweenTrades, 0) + " pips" + NL);
      }//if (UseAtrForGrid)
   }//if (UseGrid)
   
   
   SM(NL);     
   text = "Market trades open = ";
   if (Hedged)
   {
      text = "Hedged position. Market trades open = ";
   }
   SM(text + IntegerToString(MarketTradesTotal) + ": Pips UPL = " + DoubleToStr(PipsUpl, 0)
   +  ": Cash UPL = " + DoubleToStr(CashUpl, 2) + NL);
   if (BuyOpen)
      SM("Buy trades = " + IntegerToString(MarketBuysCount)
         + ": Pips upl = " + DoubleToString(BuyPipsUpl, 0)
         + ": Cash upl = " + DoubleToStr(BuyCashUpl, 2)
         + NL);
   if (SellOpen)
      SM("Sell trades = " + IntegerToString(MarketSellsCount)
         + ": Pips upl = " + DoubleToString(SellPipsUpl, 0)
         + ": Cash upl = " + DoubleToStr(SellCashUpl,2)
         + NL);
   if (BuyStopOpen)
      SM("Buy stops = " + IntegerToString(BuyStopsCount) + NL);
   if (SellStopOpen)
      SM("Sell stops = " + IntegerToString(SellStopsCount) + NL);
      
   if (FullyHedged)
   {
      SM("The position is fully hedged" + NL); 
   }//if (FullyHedged)
   SM("Total buy lots = " + DoubleToStr(TotalBuyLots, 2) + ": Total sell lots = " + DoubleToStr(TotalSellLots, 2) + NL);

   SM(NL);     
   SM("Trend time frame: " + TrendTimeFrameDisplay + NL);
   SM("Trading time frame: " + TradingTimeFrameDisplay + NL);

   if (TradeLong) SM("Taking long trades" + NL);
   if (TradeShort) SM("Taking short trades" + NL);
   if (!TradeLong && !TradeShort) SM("Both TradeLong and TradeShort are set to false" + NL);
   SM("Lot size: " + DoubleToStr(Lot, 2) + " (Criminal's minimum lot size: " + DoubleToStr(MarketInfo(Symbol(), MODE_MINLOT) , 2)+ ")" + NL);
   if (!CloseEnough(TakeProfit, 0)) SM("Take profit: " + DoubleToStr(TakeProfit, 0) + PipDescription +  NL);
   if (!CloseEnough(BasketTakeProfit, 0)) SM("Basket take profit: " + DoubleToStr(BasketTakeProfit, 0) + PipDescription +  NL);
   if (!CloseEnough(StopLoss, 0)) SM("Stop loss: " + DoubleToStr(StopLoss, 0) + PipDescription +  NL);
   SM("Magic number: " + (string)MagicNumber + NL);
   SM("Trade comment: " + TradeComment + NL);
   if (IsGlobalPrimeOrECNCriminal) SM("IsGlobalPrimeOrECNCriminal = true" + NL);
   else SM("IsGlobalPrimeOrECNCriminal = false" + NL);
   double spread = (Ask - Bid) * factor;   
   SM("Average Spread = " + DoubleToStr(AverageSpread, 1) + ": Spread = " + DoubleToStr(spread, 1) + ": Widest since loading = " + DoubleToStr(BiggestSpread, 1) + NL);
   SM("Long swap " + DoubleToStr(LongSwap, 2) + ": ShortSwap " + DoubleToStr(ShortSwap, 2) + NL);
   SM(NL);
   
   //Trading hours
   
   SM("Rollover starts at "+RollOverStarts+" and ends at "+RollOverEnds+NL);
   SM("Trading starts on Sunday at "+SundayStartTradingTime+" and on Monday at "+MondayStartTradingTime+NL);
   SM("Trading stops on Friday at "+FridayStopTradingTime+" and on Saturday at "+SaturdayStopTradingTime+NL);
   
   if (tradingHoursDisplay != "") SM("Trading hours: " + tradingHoursDisplay + NL);
   else SM("24 hour trading: " + NL);
   
   if (MarginMessage != "") SM(MarginMessage + NL);


   //Running total of trades
   SM(Gap + NL);
   SM("Results today. Wins: " + (string)WinTrades + ": Losses " + (string)LossTrades + ": P/L " + DoubleToStr(OverallProfit, 2) + NL);
   
      
   SM(NL); 
   
   if (BreakEven)
   {
      SM("Breakeven is set to " + DoubleToStr(BreakEvenPips, 0) + PipDescription + ": BreakEvenProfit = " + DoubleToStr(BreakEvenProfit, 0) + PipDescription);
      SM(NL);
      if (PartCloseEnabled)
      {
         double CloseLots = NormalizeLots(Symbol(),Lot * (PartClosePercent / 100));
         SM("Part-close is enabled at " + DoubleToStr(PartClosePercent, 2) + "% (" + DoubleToStr(CloseLots, 2) + " lots to close)" + NL);
      }//if (PartCloseEnabled)      
   }//if (BreakEven)

   if (UseCandlestickTrailingStop)
   {
      SM("Using candlestick trailing stop" + NL);      
   }//if (UseCandlestickTrailingStop)
   
   if (JumpingStop)
   {
      SM("Jumping stop is set to " + DoubleToStr(JumpingStopPips, 0) + PipDescription);
      SM(NL);  
   }//if (JumpingStop)
   

   if (TrailingStop)
   {
      SM("Trailing stop is set to " + DoubleToStr(TrailingStopPips, 0) + PipDescription);
      SM(NL);  
   }//if (TrailingStop)
   
   
   
   Comment(ScreenMessage);


}//void DisplayUserFeedback()

double GetSuperSlope( int tf, int maperiod, int atrperiod, int pShift )
{
   double dblTma, dblPrev;
   int shiftWithoutSunday = pShift;
   if ( BrokerHasSundayCandles && PERIOD_CURRENT == PERIOD_D1 )
   {
      if ( TimeDayOfWeek( iTime( NULL, PERIOD_D1, pShift ) ) == 0  ) shiftWithoutSunday++;
   }   

   double atr = iATR( NULL, tf, atrperiod, shiftWithoutSunday + 10 ) / 10;
   double result = 0.0;
   if ( atr != 0 )
   {
      dblTma = iMA( NULL, tf, maperiod, 0, MODE_LWMA, PRICE_CLOSE, shiftWithoutSunday );
      dblPrev = ( iMA( NULL, tf, maperiod, 0, MODE_LWMA, PRICE_CLOSE, shiftWithoutSunday + 1 ) * 231 + iClose( NULL, tf, shiftWithoutSunday ) * 20 ) / 251;

      result = ( dblTma - dblPrev ) / atr;
   }
   
   return ( result );
   
}//GetSuperSlope(}

double GetFlyingBuddha(string symbol, int tf, int ffp, int ffam, int ffpr, int fsp, int fsam, int fspr, int fbmb, double ffw, int buffer, int shift)
{

   //return(iCustom(symbol, tf, "smFlyingBuddha Signals_v2", false, false, false, false, " ", ffp, ffam, ffpr, fsp, fsam, fspr, fbmb, ffw, buffer, shift));
   return(iCustom(symbol, tf, "smFlyingBuddha Signals_v2", true, true, false, false, " ", ffp, ffam, ffpr, fsp, fsam, fspr, fbmb, ffw, buffer, shift));
   

}//End double GetFlyingBuddha()


void ReadIndicatorValues()
{

   //ReadUsualIndicatorValues() is in HGBnD core library.mqh
   ReadUsualIndicatorValues();
   
   //Declare a shift for use with indicators.
   int shift = 0;
   if (!EveryTickMode)
   {
      shift = 1;
   }//if (!EveryTickMode)
   
  
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
   
   
   
         
   
   if (OldCcaReadTime != iTime(Symbol(), TradingTimeFrame, 0) )
   {
      OldCcaReadTime = iTime(Symbol(), TradingTimeFrame, 0);
    
      ///////////////////////////////////////
      //Indi reading code goes here.

      //Super Slope
      //HTF SS
      //Read at the open of each new TradingTimeFrame in case it has changed colour
      if (UseSsHigherTimeFrameControl)
      {
            
            //Buffer 0 holds first currency in the pair
            SsHtfCurr1Val = GetSuperSlope(SsHigherTimeFrame,SsHtfSlopeMAPeriod,SsHtfSlopeATRPeriod,0);
            
            //What colour is the histo:
            SsHtfColour = red;
            if (SsHtfCurr1Val > 0)
               SsHtfColour = blue;
                              
      }//if (UseSsHigherTimeFrameControl)
      
      //MTF SS
      //Read at the open of each new TradingTimeFrame in case it has changed colour
      if (UseSsMediumTimeFrameControl)
      {
            
            //Buffer 0 holds first currency in the pair
            SsMtfCurr1Val = GetSuperSlope(SsMediumTimeFrame,SsMtfSlopeMAPeriod,SsMtfSlopeATRPeriod,0);
            
            //What colour is the histo:
            SsMtfColour = red;
            if (SsMtfCurr1Val > 0)
               SsMtfColour = blue;
                                            
      }//if (UseSsMediumTimeFrameControl)

      LongTradeTrigger = false;
      ShortTradeTrigger = false;
      
      //Read SuperSlope
      if (UseSsTradingTimeFrameControl)
      {   
        //Buffer 0 holds first currency in the pair
         SsTtfCurr1Val = GetSuperSlope(TradingTimeFrame,SsTradingSlopeMAPeriod,SsTradingSlopeATRPeriod,shift);
            
         //Changed by tomele
         //Set the colours
         SsColour = white;
         if (SsTtfCurr1Val > 0)  //buy
            if (SsTtfCurr1Val - SsTradingDifferenceThreshold/2 > 0) //blue
               SsColour = blue;

         if (SsTtfCurr1Val < 0)  //sell
            if (SsTtfCurr1Val + SsTradingDifferenceThreshold/2 < 0) //red
               SsColour = red;
                                                  
         
         
      }//if (UseSsTradingTimeFrameControl)

      //FB
      FbStatus = fbnoarrow;
      //Buffer 2 holds blue up arrow
      double val = GetFlyingBuddha(Symbol(), TradingTimeFrame, FbFastPeriod, FbFastAvgMode, FbFastPrice, 
                                   FbSlowPeriod, FbSlowAvgMode, FbSlowPrice, FbMaxBars, FbFactorWindow, 2, shift);
      if (!CloseEnough(val, EMPTY_VALUE) )
         FbStatus = fbuparrowtradable;
      
      //Buffer 2 holds blue up arrow
      if (FbStatus == fbnoarrow)
      {
         val = GetFlyingBuddha(Symbol(), TradingTimeFrame, FbFastPeriod, FbFastAvgMode, FbFastPrice, 
                               FbSlowPeriod, FbSlowAvgMode, FbSlowPrice, FbMaxBars, FbFactorWindow, 3, shift);
         if (!CloseEnough(val, EMPTY_VALUE) )
            FbStatus = fbdownarrowtradable;
      }//if (FbStatus == fbnoarrow)
      
      //Calculate MinimumDistanceBetweenSignals if using atr
      if (UsePercentageOfAtrForDistance)
      {
         fbAtrVal = GetAtr(Symbol(), TradingTimeFrame, FbAtrPeriod, shift);
         fbAtrVal= NormalizeDouble(fbAtrVal * factor, 0);
         MinimumDistanceBetweenSignals = fbAtrVal * (FbPercentageOfAtrToUse / 100);
      }//if (UsePercentageOfAtrForDistance)
      
      
      //We need to check that the market is sufficient distance from the highest/lowest open trade
      if (OpenTrades > 0)
      {
         //Buy signal. Market must be above the highest open buy price or below the lowest.
         if (FbStatus == fbuparrowtradable)
            if (Bid <= HighestBuyPrice + (MinimumDistanceBetweenSignals / factor) || 
                Bid >= LowestBuyPrice - (MinimumDistanceBetweenSignals / factor) )
                  FbStatus = fbuparrowuntradable;
         
         //Sell signal. Market must be above the lowest open sell price or above the highest.
         if (FbStatus == fbdownarrowtradable)
            if (Bid >= LowestSellPrice - (MinimumDistanceBetweenSignals / factor) || 
                Bid <= HighestSellPrice + (MinimumDistanceBetweenSignals / factor) )
                  FbStatus = fbdownarrowuntradable;
                  
      }//if (OpenTrades > 0)
      
    
         
      ///////////////////////////////////////
      //Anything else?
      
      
      ///////////////////////////////////////
      
      //Do we have a trade signal
      BuySignal = false;
      SellSignal = false;
      string CandleDirection = "";
      
      //Code to compare all the indi values and generate a signal if they all pass
      
      //Non-offsetting/hedging trade stacking.
      if (!Hedged)
         if (StackByCandleDirection)
         {
            if (MarketBuysCount > 0)
            {
               CandleDirection = GetPreviousCandleDirection();
               if (CandleDirection == down)
                  BuySignal = true;
            }//if (MarketBuysCount > 0)
            
         
            if (MarketSellsCount > 0)
            {
               CandleDirection = GetPreviousCandleDirection();
               if (CandleDirection == up)
                  SellSignal = true;
            }//if (MarketSellsCount > 0)
         
         }//if (StackByCandleDirection)
         
      if (!BuySignal)
         if (!SellSignal)
            if (!UseTrendHGI || HgiLongTrendDetected)
               if (!UseTradingTimeFrameHGI || HgiLongTradeTrigger)
                  if (!UseSixths || (SixthsStatus == tradablelong || SixthsStatus == tradableboth))
                     if (!UseBuyLowSellHigh || combinedBlshStatus == tradablelong)
                        if (!UseSsHigherTimeFrameControl || SsHtfColour == blue)
                              if (!UseSsMediumTimeFrameControl || SsMtfColour == blue)
                                 if (!UseSsTradingTimeFrameControl || SsColour == blue)
                                    if (FbStatus == fbuparrowtradable)
                                       BuySignal = true; 
         
      if (!SellSignal)
         if (!BuySignal)
            if (!UseTrendHGI || HgiShortTrendDetected)
               if (!UseTradingTimeFrameHGI || HgiShortTradeTrigger)
                  if (!UseSixths || (SixthsStatus == tradableshort || SixthsStatus == tradableboth))
                     if (!UseBuyLowSellHigh || combinedBlshStatus == tradableshort)
                        if (!UseSsHigherTimeFrameControl || SsHtfColour == red)
                              if (!UseSsMediumTimeFrameControl || SsMtfColour == red)
                                 if (!UseSsTradingTimeFrameControl || SsColour == red)
                                    if (FbStatus == fbdownarrowtradable)
                                       SellSignal = true; 
         
      if (BuySignal)
         SellCloseSignal = true;
      
      if (SellSignal)
         BuyCloseSignal = true;

           
      
       
   }//if (OldCcaReadTime != iTime(Symbol(), TradingTimeFrame, 0) )
   
   /////////////////////////////////////////////////////////////////////////////////////
      
 
      
}//End void ReadIndicatorValues()

//End Indicator module
////////////////////////////////////////////////////////////////////////////////////////


bool LookForTradeClosure(int ticket)
{
   //Close the trade if the close conditions are met.
   //Called from within CountOpenTrades(). Returns true if a close is needed and succeeds, so that COT can increment cc,
   //else returns false
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET) ) return(true);
   if (BetterOrderSelect(ticket, SELECT_BY_TICKET) && OrderCloseTime() > 0) return(true);
   
   bool CloseThisTrade = LookForUsualTradeClosure(ticket);
   
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (!CloseThisTrade)
   {
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
      {
         
         //Delete pendings on a new signal.
         //You may need to make changes here.
         if (!CloseThisTrade)
           if (SellSignal)
               if (DeletePendingsOnNewSignal)
                  if (MarketTradesTotal == 0)
                     CloseThisTrade = true;


        //Change of SS colour and/or opposite direction FB
        //Higher time frame
        if (!CloseThisTrade)
           if (UseSsHigherTimeFrameControl)
           {
               if (SsCloseTradesOnHtfColourChange)
                  if(SsHtfColour != blue)
                     CloseThisTrade = true;              
           
               //Opposite FB signal
               if (!CloseThisTrade)
                  if (SsCloseTradesOnHtfColourChange)
                     if (!OnlyCloseWhenSuperSlopeAgrees || SsHtfColour == red)
                        if (FbStatus == fbdownarrowtradable || FbStatus == fbdownarrowuntradable)
                           CloseThisTrade = true;
           }//if (UseSsHigherTimeFrameControl)
          
        //Medium time frame
        if (!CloseThisTrade)
           if (UseSsMediumTimeFrameControl)
           {
               if (SsCloseTradesOnMtfColourChange)
                  if(SsMtfColour != blue)
                     CloseThisTrade = true;              
           
               //Opposite FB signal
               if (!CloseThisTrade)
                  if (SsCloseTradesOnMtfColourChange)
                     if (!OnlyCloseWhenSuperSlopeAgrees || SsMtfColour == red)
                        if (FbStatus == fbdownarrowtradable || FbStatus == fbdownarrowuntradable)
                           CloseThisTrade = true;
           }//if (UseSsMediumTimeFrameControl)
          
        //Trading time frame
        if (!CloseThisTrade)
           if (UseSsTradingTimeFrameControl)
           {
               if (SsCloseTradesOnColourChange)
                  if(SsColour != blue)
                     CloseThisTrade = true;              
           
               //Opposite FB signal
               if (!CloseThisTrade)
                  if (SsCloseTradesOnColourChange)
                     if (!OnlyCloseWhenSuperSlopeAgrees || SsColour == red)
                        if (FbStatus == fbdownarrowtradable || FbStatus == fbdownarrowuntradable)
                           CloseThisTrade = true;
           }//if (UseSsTradingTimeFrameControl)
          
                
       //Opposite FB with no slope
       if (!CloseThisTrade)
         if (CloseOnOppositeFB)
         {
            if (!UseSsHigherTimeFrameControl || !SsCloseTradesOnHtfColourChange)
               if (!UseSsMediumTimeFrameControl || !SsCloseTradesOnMtfColourChange)
                  if (!UseSsTradingTimeFrameControl || !SsCloseTradesOnColourChange)
                     if(!OnlyCloseWhenSuperSlopeAgrees)
                        if (FbStatus == fbdownarrowtradable || FbStatus == fbdownarrowuntradable)
                           CloseThisTrade = true;
         }//if (CloseOnOppositeFB)
                                 
       
      }//if (OrderType() == OP_BUY)
      
      
      ///////////////////////////////////////////////////////////////////////////////////////////////////////////
      if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
      {
            
         //Delete pendings on a new signal.
         //You may need to make changes here.
         if (!CloseThisTrade)
           if (BuySignal)
               if (DeletePendingsOnNewSignal)
                  if (MarketTradesTotal == 0)
                     CloseThisTrade = true;
         

         //Close trade on opposite direction signal
         if (SellCloseSignal)
            CloseThisTrade = true;
   
        //Change of SS colour and/or opposite direction FB
        //Higher time frame
        if (!CloseThisTrade)
           if (UseSsHigherTimeFrameControl)
           {
               if (SsCloseTradesOnHtfColourChange)
                  if(SsHtfColour != blue)
                     CloseThisTrade = true;              
           
               //Opposite FB signal
               if (!CloseThisTrade)
                  if (SsCloseTradesOnHtfColourChange)
                     if (!OnlyCloseWhenSuperSlopeAgrees || SsHtfColour == blue)
                        if (FbStatus == fbuparrowtradable || FbStatus == fbuparrowuntradable)
                           CloseThisTrade = true;
           }//if (UseSsHigherTimeFrameControl)
          
        //Medium time frame
        if (!CloseThisTrade)
           if (UseSsMediumTimeFrameControl)
           {
               if (SsCloseTradesOnMtfColourChange)
                  if(SsMtfColour != blue)
                     CloseThisTrade = true;              
           
               //Opposite FB signal
               if (!CloseThisTrade)
                  if (SsCloseTradesOnMtfColourChange)
                     if (!OnlyCloseWhenSuperSlopeAgrees || SsMtfColour == blue)
                        if (FbStatus == fbuparrowtradable || FbStatus == fbuparrowuntradable)
                           CloseThisTrade = true;
           }//if (UseSsMediumTimeFrameControl)
          
        //Trading time frame
        if (!CloseThisTrade)
           if (UseSsTradingTimeFrameControl)
           {
               if (SsCloseTradesOnColourChange)
                  if(SsColour != blue)
                     CloseThisTrade = true;              
           
               //Opposite FB signal
               if (!CloseThisTrade)
                  if (SsCloseTradesOnColourChange)
                     if (!OnlyCloseWhenSuperSlopeAgrees || SsColour == blue)
                        if (FbStatus == fbuparrowtradable || FbStatus == fbuparrowuntradable)
                           CloseThisTrade = true;
           }//if (UseSsTradingTimeFrameControl)
   
   
      //Opposite FB with no slope
      if (!CloseThisTrade)
         if (CloseOnOppositeFB)
         {
            if (!UseSsHigherTimeFrameControl || !SsCloseTradesOnHtfColourChange)
               if (!UseSsMediumTimeFrameControl || !SsCloseTradesOnMtfColourChange)
                  if (!UseSsTradingTimeFrameControl || !SsCloseTradesOnColourChange)
                     if(!OnlyCloseWhenSuperSlopeAgrees)
                        if (FbStatus == fbuparrowtradable || FbStatus == fbuparrowuntradable)
                           CloseThisTrade = true;
         }//if (CloseOnOppositeFB)
                      
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


void FillGapsWithStopOrders()
{

   //Fill in the gaps between the market price and the most recent trade
   //when the market is above the PH or below the PL.
   
   bool result = true;
   double price = 0;
   double SendLots = Lot;
   double stop = 0, take = 0;
   
   //Sell stops
   if (LatestTradeTicketNo > -1)   
      if (BetterOrderSelect(LatestTradeTicketNo, SELECT_BY_TICKET, MODE_TRADES))
         if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP)
            if (Bid - OrderOpenPrice() >= (MarketDistance / factor) )
            {
               price = NormalizeDouble(OrderOpenPrice() + (MarketDistance / factor) / 2, Digits);
               if (!DoesStopOrderExist(OP_SELLSTOP, price))
               {
                  stop = CalculateStopLoss(OP_SELL, price);
                  take = OrderTakeProfit();
                  //Lot size calculated by risk
                  if (!CloseEnough(RiskPercent, 0)) SendLots = CalculateLotSize(price, NormalizeDouble(stop + (HiddenPips / factor), Digits) );
   
                  result = SendSingleTrade(Symbol(), OP_SELLSTOP, TradeComment, SendLots, price, stop, take);
               }//if (!DoesTradeExist(OP_SELLSTOP, price))
               
            }//if (Bid - OrderOpenPrice() >= (MarketDistance / factor) )

   //Buy stops
   if (LatestTradeTicketNo > -1)   
      if (BetterOrderSelect(LatestTradeTicketNo, SELECT_BY_TICKET, MODE_TRADES))
         if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP)
            if (OrderOpenPrice() - Bid >= (MarketDistance / factor) )
            {
               price = NormalizeDouble(OrderOpenPrice() - (MarketDistance / factor) / 2, Digits);
               if (!DoesStopOrderExist(OP_BUYSTOP, price))
               {
                  stop = CalculateStopLoss(OP_BUY, price);
                  take = OrderTakeProfit();
                  //Lot size calculated by risk
                  if (!CloseEnough(RiskPercent, 0)) SendLots = CalculateLotSize(price, NormalizeDouble(stop + (HiddenPips / factor), Digits) );
   
                  result = SendSingleTrade(Symbol(), OP_BUYSTOP, TradeComment, SendLots, price, stop, take);
               }//if (!DoesTradeExist(OP_BUYSTOP, price))
               
            }//if (Bid - OrderOpenPrice() >= (MarketDistance / factor) )
      

}//End void FillGapWithStopOrders()

bool DoesStopOrderExist(int type, double price)
{

   if (OrdersTotal() == 0)
      return(false);
   if (OpenTrades == 0)
      return(false);
   
   
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!OrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderType() != type) continue;
      if (!CloseEnough(OrderOpenPrice(), price) ) continue;
      
      //Got to here, so we have found a trade
      return(true);

   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
   
   //Got this far, so no trade found
   return(false);   

}//End bool DoesStopOrderExist(int type, double price)

////////////////////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
//----
   //int cc;

   if (!UsualOnTick() )
   {
      if (RemoveExpert)
      {
         ExpertRemove();
         return;
      }//if (RemoveExpert)
      
      return;
   }//if (!UsualOnTick())
   
   //Sixths
   if (UseSixths)
   {
      //Allow trading both ways if required
      if (SixthsStatus == untradable)
         if (AllowTradingInTheMiddle)
            SixthsStatus = tradableboth;   
            
      //Disable trading from the outer sixths
      if (OnlyTradeTheMiddle)
         if (SixthsStatus == tradablelong || SixthsStatus == tradableshort)
            SixthsStatus = untradable;
            
   }//if (UseSixths)
     
   if (FollowAdverseMarketWithStopOrders)
      if (OpenTrades < MaxTradesAllowed)
         FillGapsWithStopOrders();  

   
   //Trading
   if(EveryTickMode) OldBarsTime=0;
   if(OldBarsTime!=iTime(NULL,TradingTimeFrame,0))
   {
      OldBarsTime = iTime(NULL, TradingTimeFrame, 0);
      //ReadIndicatorValues();//Remember to delete the call higher up in this function if EveryTickMode = false
      if (TimeCurrent() >= TimeToStartTrading)
         if (!StopTrading)
            if (OpenTrades < MaxTradesAllowed)//Un-comment this line for multi traders. Leave commented 
                                              //for single traders
            //if (TicketNo == -1)//Comment out this line for multi-traders. Leave uncomment 
                               //for single traders  
            {
               TimeToStartTrading = 0;//Set to TimeCurrent() + (PostTradeAttemptWaitMinutes * 60) when there is an OrderSend() attempt)
               LookForTradingOpportunities();
            }//if (TicketNo == -1 or if (OpenTrades < MaxTradesAllowed))
   }//if(OldBarsTime!=iTime(NULL,TradingTimeFrame,0))

   
   ///////////////////////////////////////////////////////////////////////////////////
  
   DisplayUserFeedback();


//----
   return;
}

/*
Places where where you are most likely to need to make changes, and 
a search string for you to find them.

[*]   //Add your own constants here: any constants you will be creating. 
[*]   //Add your extern's here: add the extern inputs and variables you will be using with whatever you are adding.
[*]   extern bool    UseTrendHGI=true;: disable any of the panoply of features that you know you do not want by setting 
        the relevant Usexxxx booleans to 'false'. Also:
         [*]hide external variables you do not need but do not want to delete 'just in case', by removing the 'extern'.
         [*]deleting any inputs and variables then recompiling will take you to all the code blocks that need deleting.
[*]   //ReadIndicatorValues();//Remember to delete the call higher up in this function if EveryTickMode = false
[*]   if (OpenTrades < MaxTradesAllowed)//Un-comment this line: decide which of the conditionals you want to use:
         [*]leave 8276 uncommented if you are coding a multi-trader.
         [*]comment 8276 for a single trading EA, and un-comment 8278.

*/
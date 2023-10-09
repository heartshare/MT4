// ------------------------------------------------------------------------------------------------
// HIGH RISK GRID TRADING EA, USE IT ON DEMO ONLY UNTIL YOU KNOW HOW TO HANDLE AND ARE WILLING TO ACCEPT THE INVOLED RISKS!!!
// ------------------------------------------------------------------------------------------------
//
// To change global vars (F3):
//    - Switch Auto Trading OFF
//    - Change vars by hit F3-key
//    - Restart Ikarus
//    - Switch Auto Trading ON
//    - Restart Ikarus again
//
//#define DEMO 1                 // to make it a Demo Version (work on demo account only), this line MUST NOT be comment
//#define DEBUG 1                // to switch off debug info of, make this line as comment

#define max_open_positions 100   // maximum number of open positions, was constant = 50 before

#include <stdlib.mqh>
#include <stderror.mqh>

#define versionNo "2.0"
#define versionBMI "BlackMamba Ikarus " + versionNo
#define versionOld "based on Super Money Grid v1.41"
string key="BlackMamba Ikarus 2.0";

// ------------------------------------------------------------------------------------------------
// EXTERN VARS
// ------------------------------------------------------------------------------------------------
extern int magic=11235;
// ------------------------------------------------------------------------------------------------
int user_slippage=2;
extern int grid_size=20;            // grid distance from one position to the next one; is neither a Pip nor a money dimension
extern int gs_progression=3;        // use progression as well for grid distance: 0=none | 1:d'alembert | 2:martingale | 3:fibonacci
extern int take_profit=20;          // distance for the profit rate; will rise by number of open Lot size; is neither a Pip nor a money dimension
extern double profit_lock=0.3;      // percentage of profit that will be protected by trailing stop
extern double min_lots=0.01;        // volume, to start a new cycle
extern double equity_warning=0.20;  // change account state to red, if equity is warning percent less than max equtiy ever reached
extern double account_risk=1.00;    // percentage, for stop and close all open positions; trading will also be stopped
extern int progression=3;           // oder volume progression: 0=none | 1:d'alembert | 2:martingale | 3:fibonacci
extern int max_positions=6;         // for each direction maximum open postitions of buys and sells
extern int unbalance_control=0;     // hedge option, if more than 4 open trades; new starting volume = volume of 3rd last active volume
extern int max_spread=100;          // do not trade, if spread is higher than this value
extern int show_forecast=1;         // extern option to hide forecast lines
                                    //
// ------------------------------------------------------------------------------------------------
// GLOBAL VARS
// ------------------------------------------------------------------------------------------------
// Ticket
// #007: be able to deal with variable number of open positions
int buy_tickets[max_open_positions];
int sell_tickets[max_open_positions];
// Lots
double buy_lots[max_open_positions];
double sell_lots[max_open_positions];
// Current Profit
double buy_profit[max_open_positions];
double sell_profit[max_open_positions];
// Open Price
double buy_price[max_open_positions];
double sell_price[max_open_positions];
// Number of orders
int buys=0;
int sells=0;

// #020: show line, where the next line_buy /line_sell would be, if it would be opened
// value of lines:
double line_buy=0,line_sell=0,line_buy_tmp=0,line_sell_tmp=0,line_buy_next=0,line_sell_next=0,line_buy_ts=0,line_sell_ts=0,line_margincall=0;
// profits:
double total_buy_profit=0,total_sell_profit=0,total_buy_swap=0,total_sell_swap=0;
double buy_max_profit=0,buy_close_profit=0;
double sell_max_profit=0,sell_close_profit=0;
double total_buy_lots=0,total_sell_lots=0;
double relativeVolume=0;

// Colors:
// #001: eliminate all warnings:
//color c=Black;
int colInPlus=clrGreen;
int colInMinus=clrRed;
int colNeutral=clrGray;

int colFontLight=clrWhite;
int colFontDark=clrGray;

int colCodeGreen=clrGreen;
int colCodeYellow=clrGold;
int colCodeRed=clrRed;

int colPauseButtonPassive=clrBlue;

int panelCol=colNeutral;         // fore color of neutral panel text
int instrumentCol=colNeutral;    // panel color that changes depending on its value
                                 //
// OrderReliable:
int slippage=0;               // is fix; depending on chart: 2 or 20
int retry_attempts= 10;
double sleep_time = 4.0;      // in seconds
double sleep_maximum=25.0;    // in seconds
string OrderReliable_Fname="OrderReliable fname unset";
static int _OR_err=0;
string OrderReliableVersion="V1_1_1";

// #023: implement account state by 3 colored button
enum ACCOUNT_STATE{as_green,as_yellow,as_red};
int accountState=as_green;
// #025: use equity percentage instead of unpayable position
double max_equity=0;          // maximum of equity ever reached, saved in global vars
                              //
// global flags:
// #019: new button: Stop Next Cyle, which trades normally, until cycle is closed
int stopNextCycle=0;          // flag, if trading will be terminated after next successful cycle, trades normally until cyle is closed
int restAndRealize=0;         // flag, if trading will be terminated after next successful cycle, does not open new positions
int stopAll=0;                // flag, if stopAll must close all and stop trading or continue with trading
                              //
// #044: Add button to hide comment
int showComment=1;            // flag for comment at left side
bool isFirstStartLoop=true;   // flag, to do some things only one time after program start
                              //
// screen coordinates:
// #054: make size of buttons flexible
int btnWidth = 70;            // width of smallest buttons
int btnHeight = 30;           // height of all buttons
int btnGap= 10;               // gap, between buttons
int btnLeftAxis = 200;        // distance of button from left screen border
int btnTopAxis = 17;          // distance of button from top screen border
int btnNextLeft=btnWidth+btnGap;        // distance to next button
int btnNextTop=btnHeight+btnGap;          // distance to next button
                                          //
// debugging:
string debugCommentDyn="\n";        // will be added to regular Comment txt and updated each program loop
string debugCommentStat="";       // will be added only - no updates
string debugCommentCloseBuys="";    // show condition, when cycle will be closed
string debugCommentCloseSells="";
string codeRedMsg="";               // tell user, why account state is yellow or red
string codeYellowMsg="";
double ter_IkarusChannel=0;         // line_buy - line_sell
string globalVarsID=Symbol()+"_"+magic+"_";   //ID to specify the global vars from other charts
                                              //
// values read from terminal:
double ter_priceBuy=0;
double ter_priceSell=0;
double ter_point=0;
int ter_digits=0;
double ter_tick_value=0;
double ter_tick_size =0;
double ter_spread=0;
datetime ter_timeNow=0;             // date and time while actual loop
                                    //
// calculate by values from terminal:
double ter_ticksPerGrid=0;          // ticks of 1 min_lot per 1 grid size
double ter_chartMultiplier=1;       // if digits = 3 or 5: chart multiplier = 10
string ter_currencySymbol="$";      // € if account is in Euro, $ for all other

double ter_MODE_MARGINHEDGED=MarketInfo(Symbol(),MODE_MARGINHEDGED);
double ter_MODE_MARGININIT=MarketInfo(Symbol(),MODE_MARGININIT);
double ter_MODE_MARGINMAINTENANCE=MarketInfo(Symbol(),MODE_MARGINMAINTENANCE);
double ter_MODE_MARGINREQUIRED=MarketInfo(Symbol(),MODE_MARGINREQUIRED);
// ------------------------------------------------------------------------------------------------
// START
// ------------------------------------------------------------------------------------------------
int start()
  {
#ifdef DEMO
// #049: add option to work with demo account only
   if(!IsDemo())
     {
      stopAll=0;           // force a dived by zero error, to stop this EA
      MessageBox("Only on  D E M O  account please!","C A U T I O N  !",MB_OK);
      stopAll=1/stopAll;   // divide by zero stops it all
      return(0);           //just in case ;o)
     }
#endif

// do this only one time after starting the program
   if(isFirstStartLoop)
     {
      if(AccountCurrency()=="EUR")
         ter_currencySymbol="€";
      if(MarketInfo(Symbol(),MODE_DIGITS)==4 || MarketInfo(Symbol(),MODE_DIGITS)==2)
        {
         slippage=user_slippage;
         ter_chartMultiplier=1;
        }
      else if(MarketInfo(Symbol(),MODE_DIGITS)==5 || MarketInfo(Symbol(),MODE_DIGITS)==3)
        {
         ter_chartMultiplier=10;
         slippage=ter_chartMultiplier*user_slippage;
        }
      // do we have any data from previous session?
      ReadIniData();

      debugCommentStat+="\nNew program start at "+TimeToStr(TimeCurrent());

      isFirstStartLoop=false;
     }

   if(IsTradeAllowed()==false)
     {
      Comment(versionBMI+"\n\nTrade not allowed.");
      // #001: eliminate all warnings:
      return 0;
     }

   ter_priceBuy=MarketInfo(Symbol(),MODE_ASK);
   ter_priceSell=MarketInfo(Symbol(),MODE_BID);
   ter_tick_value=MarketInfo(Symbol(),MODE_TICKVALUE);
   ter_spread=MarketInfo(Symbol(),MODE_SPREAD);
   ter_digits=MarketInfo(Symbol(),MODE_DIGITS);
   ter_tick_size=MarketInfo(Symbol(),MODE_TICKSIZE);
   ter_point=MarketInfo(Symbol(),MODE_POINT);
   if(slippage>user_slippage)ter_point=ter_point*10;
   ter_timeNow=TimeCurrent();
   ter_ticksPerGrid=-CalculateTicksByPrice(min_lots,CalculateSL(min_lots,1))-ter_spread*ter_tick_size;
// #025: use equity percentage instead of unpayable position
   if(AccountEquity()>max_equity)
      max_equity=AccountEquity();

// Updating current status:
   InitVars();
   UpdateVars();
   SortByLots();
   ShowData();

// #014: start new dynamic debug output here; will be shown at the end of comment string; will be updated each program loop
   debugCommentDyn="\n";

   ShowLines();

// #023: implement account state by 3 colored button
   CheckAccountState();
// #010: implement button: Stop & Close
   if(stopAll)
     {
      // Closing all open orders
      SetButtonText("btnStopAll","Continue");
      SetButtonColor("btnStopAll",colCodeRed,colFontLight);
      CloseAllBuys();
      CloseAllSells();
     }
   else
     {
      Robot();
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| WrtieIniData()                                                                 |
// #017: deal with global vars to save and restore data, while chart is closed or must be restarted by other reason
//+------------------------------------------------------------------+
void WriteIniData()
  {
// #016: Save status of buttons in global vars
   if(!IsTesting())
     {
      // #010: implement button: Stop & Close
      // #011 #018 #019: implement button: Stop On Next Cycle
      GlobalVariableSet(globalVarsID+"stopNextCycle",stopNextCycle);
      GlobalVariableSet(globalVarsID+"restAndRealize",restAndRealize);
      GlobalVariableSet(globalVarsID+"stopAll",stopAll);
      GlobalVariableSet(globalVarsID+"showComment",showComment);            // #044: Add button to show or hide comment
      GlobalVariableSet(globalVarsID+"max_equity",DoubleToString(max_equity,2));   // #037: save max equity at global vars 
                                                                                   //
      //GlobalVariableSet(globalVarsID + "",DoubleToStr());
      //GlobalVariableSet(globalVarsID + "",);

     }
  }
//+------------------------------------------------------------------+
//| ReadIniData()                                                                 |
// #017: deal with global vars to save and restore data, while chart is closed or must be restarted by other reason
//+------------------------------------------------------------------+
void ReadIniData()
  {
// #016: read status of buttons from global vars
   if(!IsTesting())
     {
      int count=GlobalVariablesTotal();
      if(count>0)
        {
         // #011 #018 #019: implement button: Stop On Next Cycle
         if(GlobalVariableCheck(globalVarsID+"stopNextCycle"))
            stopNextCycle=DoubleToString(GlobalVariableGet(globalVarsID+"stopNextCycle"),0);

         if(GlobalVariableCheck(globalVarsID+"restAndRealize"))
            restAndRealize=DoubleToString(GlobalVariableGet(globalVarsID+"restAndRealize"),0);

         // #010: implement button: Stop & Close
         if(GlobalVariableCheck(globalVarsID+"stopAll"))
            stopAll=DoubleToString(GlobalVariableGet(globalVarsID+"stopAll"),0);

         // #044: Add button to show or hide comment
         if(GlobalVariableCheck(globalVarsID+"showComment"))
            showComment=DoubleToString(GlobalVariableGet(globalVarsID+"showComment"),0);

         if(GlobalVariableCheck(globalVarsID+"max_equity")) // #037: save max equity at global vars 
            max_equity=DoubleToString(GlobalVariableGet(globalVarsID+"max_equity"),2);

         //if(GlobalVariableCheck(globalVarsID + ""))
         //   =DoubleToString(GlobalVariableGet(globalVarsID + ""),0);
        }
     }
  }
// ------------------------------------------------------------------------------------------------
// INIT VARS
// ------------------------------------------------------------------------------------------------
void InitVars()
  {
// Reset number of buy/sell orders
   buys=0;
   sells=0;
// Reset arrays
   for(int i=0; i<max_open_positions; i++)
     {
      buy_tickets[i]=0;
      buy_lots[i]=0;
      buy_profit[i]= 0;
      buy_price[i] = 0;
      sell_tickets[i]=0;
      sell_lots[i]=0;
      sell_profit[i]= 0;
      sell_price[i] = 0;
     }
// #021: new setting: max_open_positions
   if(max_positions==0) // if not used, set it to maximum => no restriction
      max_positions=max_open_positions;
// #030: disable equity and account risk by setting them to 0
// #025: use equity percentage instead of unpayable position
   if(equity_warning==0)
      equity_warning=1.0;
   if(account_risk==0)
      account_risk=1.0;
  }
// ------------------------------------------------------------------------------------------------
// UPDATE VARS
// ------------------------------------------------------------------------------------------------
void UpdateVars()
  {
   int aux_buys=0,aux_sells=0;
   double aux_total_buy_profit=0,aux_total_sell_profit=0;
   double aux_total_buy_swap=0,aux_total_sell_swap=0;
   double aux_total_buy_lots=0,aux_total_sell_lots=0;

// We are going to introduce data from opened orders in arrays  
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic && OrderType()==OP_BUY)
           {
            buy_tickets[aux_buys]=OrderTicket();
            buy_lots[aux_buys]=OrderLots();
            buy_profit[aux_buys]= OrderProfit()+OrderCommission()+OrderSwap();
            buy_price[aux_buys] = OrderOpenPrice();
            aux_total_buy_profit= aux_total_buy_profit+buy_profit[aux_buys];
            aux_total_buy_lots=aux_total_buy_lots+buy_lots[aux_buys];
            aux_total_buy_swap+=OrderSwap();
            aux_buys++;
           }
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic && OrderType()==OP_SELL)
           {
            sell_tickets[aux_sells]=OrderTicket();
            sell_lots[aux_sells]=OrderLots();
            sell_profit[aux_sells]= OrderProfit()+OrderCommission()+OrderSwap();
            sell_price[aux_sells] = OrderOpenPrice();
            aux_total_sell_profit = aux_total_sell_profit + sell_profit[aux_sells];
            aux_total_sell_lots=aux_total_sell_lots+sell_lots[aux_sells];
            aux_total_sell_swap+=OrderSwap();
            aux_sells++;
           }
        }
     }

// Update global vars
   buys=aux_buys;
   sells=aux_sells;
   total_buy_profit=aux_total_buy_profit;
   total_sell_profit=aux_total_sell_profit;
   total_buy_lots=aux_total_buy_lots;
   total_sell_lots=aux_total_sell_lots;
   total_buy_swap=aux_total_buy_swap;
   total_sell_swap=aux_total_sell_swap;

   relativeVolume=MathAbs(total_buy_lots-total_sell_lots);
  }
// ------------------------------------------------------------------------------------------------
// SORT BY LOTS
// ------------------------------------------------------------------------------------------------
void SortByLots()
  {
   int aux_tickets;
   double aux_lots,aux_profit,aux_price;

// We are going to sort orders by volume
// m[0] smallest volume m[size-1] largest volume

// BUY ORDERS
   for(int i=0; i<buys-1; i++)
     {
      for(int j=i+1; j<buys; j++)
        {
         if(buy_lots[i]>0 && buy_lots[j]>0)
           {
            // at least 2 orders
            if(buy_lots[j]<buy_lots[i])
              {
               // sorting
               // ...lots...
               aux_lots=buy_lots[i];
               buy_lots[i]=buy_lots[j];
               buy_lots[j]=aux_lots;
               // ...tickets...
               aux_tickets=buy_tickets[i];
               buy_tickets[i]=buy_tickets[j];
               buy_tickets[j]=aux_tickets;
               // ...profits...
               aux_profit=buy_profit[i];
               buy_profit[i]=buy_profit[j];
               buy_profit[j]=aux_profit;
               // ...and open price
               aux_price=buy_price[i];
               buy_price[i]=buy_price[j];
               buy_price[j]=aux_price;
              }
           }
        }
     }

// SELL ORDERS
   for(i=0; i<sells-1; i++)
     {
      for(j=i+1; j<sells; j++)
        {
         if(sell_lots[i]>0 && sell_lots[j]>0)
           {
            // at least 2 orders
            if(sell_lots[j]<sell_lots[i])
              {
               // sorting...
               // ...lots...
               aux_lots=sell_lots[i];
               sell_lots[i]=sell_lots[j];
               sell_lots[j]=aux_lots;
               // ...tickets...
               aux_tickets=sell_tickets[i];
               sell_tickets[i]=sell_tickets[j];
               sell_tickets[j]=aux_tickets;
               // ...profits...
               aux_profit=sell_profit[i];
               sell_profit[i]=sell_profit[j];
               sell_profit[j]=aux_profit;
               // ...and open price
               aux_price=sell_price[i];
               sell_price[i]=sell_price[j];
               sell_price[j]=aux_price;
              }
           }
        }
     }
  }
// ------------------------------------------------------------------------------------------------
// SHOW LINES
// ------------------------------------------------------------------------------------------------
void ShowLines()
  {
   double aux_tp_buy=0,aux_tp_sell=0;  // CalculateTP(next positions) = take_profit * pipvalue
   double buy_tar=0,sell_tar=0,        // local results
   diff_tar=0;
   double buy_a=0, sell_a=0;           // sum: # of total opened min_lots
   double buy_b=0, sell_b=0;           // sum: price payed for all positions
   double buy_pip=0,sell_pip=0;        // terminal value: tick_value / min_lots
   double buy_v[max_open_positions],   // array: # of min_lots of this index; if progression = 0, it is always 1; if prog. = 2 then: 1, 2, 4, 8, ... 
   sell_v[max_open_positions];
   double swapDiff=0;                  // swap accumulated until actual date

   int i;
   double myVal=1,offset=0,spreadPart=0,gridSizePart=0;

// init all lines to 0 to make sure they will be removed, if not more active

   line_buy=0;line_buy_tmp=0;line_buy_next=0;line_buy_ts=0;
   line_sell=0;line_sell_tmp=0;line_sell_next=0;line_sell_ts=0;line_margincall=0;

   if(buys<=1) aux_tp_buy=CalculateTP(buy_lots[buys-1]);
   else if(progression==0) aux_tp_buy = CalculateTP(buy_lots[0]);
   else if(progression==1) aux_tp_buy = buys*CalculateTP(buy_lots[0]);
   else if(progression==2) aux_tp_buy = CalculateTP(buy_lots[buys-1]);
   else if(progression==3) aux_tp_buy = CalculateTP(buy_lots[buys-1]);

   if(sells<=1) aux_tp_sell=CalculateTP(sell_lots[sells-1]);
   else if(progression==0) aux_tp_sell = CalculateTP(sell_lots[0]);
   else if(progression==1) aux_tp_sell = sells*CalculateTP(sell_lots[0]);
   else if(progression==2) aux_tp_sell = CalculateTP(sell_lots[sells-1]);
   else if(progression==3) aux_tp_sell = CalculateTP(sell_lots[sells-1]);

   double tp_buy=aux_tp_buy;
   double tp_sell=aux_tp_sell;

//Print("progression = "+progression);
//Print(StringConcatenate("aux_tp_buy = ",aux_tp_buy));
   if(buys>=1)
     {
      buy_pip=CalculatePipValue(buy_lots[0]);
      for(i=0;i<max_open_positions;i++) buy_v[i]=0;

      for(i=0;i<buys;i++)
        {
         buy_v[i]=MathRound(buy_lots[i]/buy_lots[0]);
         //Print(StringConcatenate("buy_v[",i,"] = ",buy_v[i]));
        }

      for(i=0;i<buys;i++)
        {
         buy_a = buy_a + buy_v[i];
         buy_b = buy_b + buy_price[i]*buy_v[i];

        }
      //Print(StringConcatenate("pip = ",buy_pip));
      //Print(StringConcatenate("buy_a = ",buy_a));
      //Print(StringConcatenate("buy_b = ",buy_b));

      buy_tar=aux_tp_buy/(buy_pip/ter_point);
      //Print(StringConcatenate("buy_tar 1: ",buy_tar));
      buy_tar=buy_tar+buy_b;
      //Print(StringConcatenate("buy_tar 2: ",buy_tar));
      buy_tar=buy_tar/buy_a;
      //Print(StringConcatenate("RESULT BUY: ",buy_tar));
      swapDiff=MathAbs(CalculateTicksByPrice(total_buy_lots,total_buy_swap));
      line_buy=buy_tar+swapDiff;
      HorizontalLine(line_buy,"TakeProfit_buy",DodgerBlue,STYLE_SOLID,2);
      //debugCommentDyn+="\nline_buy: "+DoubleToString(line_buy,3);

      ter_IkarusChannel=buy_tar/ter_tick_size;    // ter_IkarusChannel=line_buy - line_sell
                                                  //
      // calculate trailing stop line
      if(buy_close_profit>0)
        {
         buy_tar = buy_close_profit/(buy_pip/ter_point);
         buy_tar = buy_tar + buy_b;
         line_buy_ts=buy_tar/buy_a;
         HorizontalLine(line_buy_ts,"ProfitLock_buy",DodgerBlue,STYLE_DASH,1);
        }

      // #027: extern option to hide forecast lines
      // #029: hide forecast lines, if trailing stop is active
      if(show_forecast && line_buy_ts==0)
        {
         // #022: show next line_buy/line_sell
         // #045: Fine tuning lines buy/sell next based on profit instead of grid_size
         if(gs_progression==0) line_buy_next=buy_price[buys-1]-ter_ticksPerGrid;
         else if(gs_progression==1) line_buy_next=buy_price[buys-1]-buys*ter_ticksPerGrid;
         else if(gs_progression==2) line_buy_next=buy_price[buys-1]+CalculateTicksByPrice(buy_lots[buys-1],CalculateSL(buy_lots[buys-1],buys));
         else if(gs_progression==3) line_buy_next=buy_price[buys-1]+CalculateTicksByPrice(buy_lots[buys-1],CalculateSL(buy_lots[buys-1],buys));

         HorizontalLine(line_buy_next,"Next_buy",DodgerBlue,STYLE_DASHDOT,1);

         // #020: show line, where the next line_buy /line_sell would be, if it would be opened right now
         if(accountState!=as_green && total_buy_profit<0)
           {
            myVal=MathRound(buy_lots[buys-1]/buy_lots[0]);
            buy_a+=myVal;
            buy_b=(buy_b+ter_priceSell*myVal);
            buy_tar=aux_tp_buy/(buy_pip/ter_point);
            line_buy_tmp=(buy_tar+buy_b)/buy_a+swapDiff;
            if(line_buy_tmp>0)
               HorizontalLine(line_buy_tmp,"NewTakeProfit_buy",clrDarkViolet,STYLE_DASHDOTDOT,1);
           }
        }
     }

   if(sells>=1)
     {
      sell_pip=CalculatePipValue(sell_lots[0]);
      for(i=0;i<max_open_positions;i++) sell_v[i]=0;

      for(i=0;i<sells;i++)
        {
         sell_v[i]=MathRound(sell_lots[i]/sell_lots[0]);
        }

      for(i=0;i<sells;i++)
        {
         sell_a = sell_a + sell_v[i];
         sell_b = sell_b + sell_price[i]*sell_v[i];

        }

      sell_tar = -1*(aux_tp_sell/(sell_pip/ter_point));
      sell_tar = sell_tar + sell_b;
      sell_tar = sell_tar/sell_a;

      swapDiff = MathAbs(CalculateTicksByPrice(total_sell_lots,total_sell_swap));
      line_sell=sell_tar-swapDiff;
      HorizontalLine(line_sell,"TakeProfit_sell",Tomato,STYLE_SOLID,2);

      ter_IkarusChannel-=sell_tar/ter_tick_size;         // ter_IkarusChannel=line_buy - line_sell
      if(buys>0 && sells>0)                              // only valid, if both direction have positions
         ter_IkarusChannel=MathAbs(ter_IkarusChannel);
      else
         ter_IkarusChannel=0;

      // calculate trailing stop line
      if(sell_close_profit>0)
        {
         sell_tar = -1*(sell_close_profit/(sell_pip/ter_point));
         sell_tar = sell_tar + sell_b;
         line_sell_ts=sell_tar/sell_a;
         HorizontalLine(line_sell_ts,"ProfitLock_sell",Tomato,STYLE_DASH,1);
        }

      // #027: extern option to hide forecast lines
      // #029: hide forecast lines, if trailing stop is active
      if(show_forecast && line_sell_ts==0)
        {
         // #022: show next line_buy/line_sell
         // line_sell_next=sell_price[sells-1]+CalculateVolume(sells)/min_lots*ter_ticksPerGrid;
         // #045: Fine tuning lines buy/sell next based on profit instead of grid_size
         if(gs_progression==0) line_sell_next=sell_price[sells-1]+ter_ticksPerGrid;
         else if(gs_progression==1) line_sell_next=sell_price[sells-1]+sells*ter_ticksPerGrid;
         else if(gs_progression==2) line_sell_next=sell_price[sells-1]-CalculateTicksByPrice(sell_lots[sells-1],CalculateSL(sell_lots[sells-1],sells));
         else if(gs_progression==3) line_sell_next=sell_price[sells-1]-CalculateTicksByPrice(sell_lots[sells-1],CalculateSL(sell_lots[sells-1],sells));
         HorizontalLine(line_sell_next,"Next_sell",Tomato,STYLE_DASHDOT,1);

         // #020: show line, where the next line_buy /line_sell would be, if it would be opened at the actual price
         if(accountState!=as_green && total_sell_profit<0)
           {
            myVal=MathRound(sell_lots[sells-1]/sell_lots[0]);
            sell_a+=myVal;
            sell_b=(sell_b+ter_priceBuy*myVal);
            sell_tar=-1*(aux_tp_sell/(sell_pip/ter_point));
            line_sell_tmp=(sell_b-(aux_tp_sell/(sell_pip/ter_point)))/sell_a-swapDiff;

            if(line_sell_tmp>0)
               HorizontalLine(line_sell_tmp,"NewTakeProfit_sell",clrDarkViolet,STYLE_DASHDOTDOT,1);
           }
        }
     }

// #036: new line: margin call (free margin = 0)
// #039: fixing bug that Stop&Close buttons works only once: divide by zero, if total_buy/sell_lots = 0
   line_margincall=0;
   if(show_forecast && (accountState==as_yellow || accountState==as_red))
     {
      double freeMargin=AccountFreeMargin();
      double maxLoss=freeMargin/ter_tick_value*ter_tick_size;
      //debugCommentDyn+="\nmaxLoss: "+DoubleToString(maxLoss,3);
      if(total_buy_profit<total_sell_profit) // calculate line_margincall for worse profit
        {
         // formular to transfer an account price to chart diff:
         // profit (€) = tick_value * lot_size * chart diff (in ticks)
         // 30€ = 0,76 * 0.08 Lot * 500 (0,500) for USDJPY
         if(total_buy_lots>0)
            line_margincall=ter_priceBuy-maxLoss/total_buy_lots;
         //debugCommentDyn+="\nline_margincall buys: "+DoubleToString(line_margincall,3);
         if(line_margincall>0)
            HorizontalLine(line_margincall,"MarginCall",clrSilver,STYLE_SOLID,5);
        }
      else
        {
         if(total_sell_lots>0)
            line_margincall=ter_priceSell+maxLoss/total_sell_lots;
         //debugCommentDyn+="\nline_margincall sells: "+DoubleToString(line_margincall,3);
         if(maxLoss<ter_priceSell)
            HorizontalLine(line_margincall,"MarginCall",clrSilver,STYLE_SOLID,5);
        }
     }

// #028: make sure, all unused lines (value=0) will be hidden

   if(line_buy==0)
      ObjectDelete("TakeProfit_buy");
   if(line_buy_next==0)
      ObjectDelete("Next_buy");
   if(line_buy_tmp==0)
      ObjectDelete("NewTakeProfit_buy");
   if(line_buy_ts==0)
      ObjectDelete("ProfitLock_buy");

   if(line_sell==0)
      ObjectDelete("TakeProfit_sell");
   if(line_sell_next==0)
      ObjectDelete("Next_sell");
   if(line_sell_tmp==0)
      ObjectDelete("NewTakeProfit_sell");
   if(line_sell_ts==0)
      ObjectDelete("ProfitLock_sell");

   if(line_margincall==0)
      ObjectDelete("MarginCall");
  }
// ------------------------------------------------------------------------------------------------
// SHOW DATA
// ------------------------------------------------------------------------------------------------
void ShowData()
  {
   string txt;
   double aux_tp_buy=0,aux_tp_sell=0;
// #002: correct message of fibo progression
   string info_money_management[4];
   string info_activation[2];

   info_money_management[0]="min_lots";
   info_money_management[1]="D´Alembert";
   info_money_management[2]="Martingale";
   info_money_management[3]="Fibonacci";
   info_activation[0]="Disabled";
   info_activation[1]="Enabled";

   if(buys<=1) aux_tp_buy=CalculateTP(buy_lots[buys-1]);
   else if(progression==0) aux_tp_buy = CalculateTP(buy_lots[0]);
   else if(progression==1) aux_tp_buy = buys*CalculateTP(buy_lots[0]);
   else if(progression==2) aux_tp_buy = CalculateTP(buy_lots[buys-1]);
   else if(progression==3) aux_tp_buy = CalculateTP(buy_lots[buys-1]);

   if(sells<=1) aux_tp_sell=CalculateTP(sell_lots[sells-1]);
   else if(progression==0) aux_tp_sell = CalculateTP(sell_lots[0]);
   else if(progression==1) aux_tp_sell = sells*CalculateTP(sell_lots[0]);
   else if(progression==2) aux_tp_sell = CalculateTP(sell_lots[sells-1]);
   else if(progression==3) aux_tp_sell = CalculateTP(sell_lots[sells-1]);

// #008: use progression for grid size as well as volume
   string info_gs_progression;
   if(gs_progression==0)
      info_gs_progression="\nGS progression: Disabled";
   else
      info_gs_progression="\nGS progression: "+info_money_management[gs_progression];

// #051: change info of panel and comment
   txt="\n"+versionBMI+
       "\n"+versionOld+
       "\nServer Time: "+TimeToStr(ter_timeNow,TIME_DATE|TIME_SECONDS)+
       "\n"+
       "\nBUY ORDERS"+
       "\nNumber of orders: "+buys+
       "\nTotal lots: "+DoubleToStr(total_buy_lots,2)+
       "\nCurrent profit: "+DoubleToStr(total_buy_profit,2)+
       "\nProfit goal: "+ter_currencySymbol+DoubleToStr(aux_tp_buy,2)+
       "\nMaximum profit reached: "+ter_currencySymbol+DoubleToStr(buy_max_profit,2)+
       "\nProfit locked: "+ter_currencySymbol+DoubleToStr(buy_close_profit,2)+

       "\n"+
       "\nSELL ORDERS"+
       "\nNumber of orders: "+sells+
       "\nTotal lots: "+DoubleToStr(total_sell_lots,2)+
       "\nCurrent profit: "+DoubleToStr(total_sell_profit,2)+
       "\nProfit goal: "+ter_currencySymbol+DoubleToStr(aux_tp_sell,2)+
       "\nMaximum profit reached: "+ter_currencySymbol+DoubleToStr(sell_max_profit,2)+
       "\nProfit locked: "+ter_currencySymbol+DoubleToStr(sell_close_profit,2)+"\n";

   if(line_margincall>0)
      txt+="\nLine: \"margin call\": "+DoubleToString(line_margincall,3);
// #038: give user info, why account state is yellow or red
   if(codeYellowMsg!="")
      txt+="\n"+codeYellowMsg;
   if(codeRedMsg!="")
      txt+="\n"+codeRedMsg;

   txt+=
        "\n\nMax. Equity: "+DoubleToString(max_equity,2)+" "+ter_currencySymbol+
        "\nCurren drawdown: "+DoubleToString((max_equity-AccountEquity()),2)+" "+ter_currencySymbol+" ("+DoubleToString((max_equity-AccountEquity())/max_equity*100,2)+" %)"+
        "\n\nSETTINGS: "+
        "\nGrid size: "+grid_size+
        info_gs_progression+
        "\nTake profit: "+take_profit+
        "\nProfit locked: "+DoubleToStr(100*profit_lock,2)+"%"+
        "\nMinimum lots: "+DoubleToStr(min_lots,2)+
        "\nEquity warning: "+DoubleToStr(100*equity_warning,2)+"%"+
        "\nAccount risk: "+DoubleToStr(100*account_risk,2)+"%"+
        "\nProgression: "+info_money_management[progression]+
        "\nMax Positions: "+max_positions+
        "\nUnbalance control: "+info_activation[unbalance_control]+

        // #004 new setting: max_spread; trades only, if spread <= max spread:
        "\nMax Spread: "+max_spread+" pts; actual spread: "+MarketInfo(Symbol(),MODE_SPREAD)+" pts"+
        // #027: extern option to hide forecast lines
        "\nShow Forecast: "+info_activation[show_forecast]+
        "\nID for GlobalVariables: "+globalVarsID+"\n";

   ObjectSetInteger(0,"btnShowComment",OBJPROP_STATE,0);      // switch color back to not selected
   if(showComment)
     {
      // #050: show/hide buttons together with comment
      if(ObjectFind(0,"btnManualBuy")==-1)
        {
         DrawButton("btnManualBuy","Buy",btnLeftAxis,btnTopAxis,btnWidth,btnHeight,false,colNeutral,clrBlack);
         DrawButton("btnManualSell","Sell",btnLeftAxis+btnNextLeft,btnTopAxis,btnWidth,btnHeight,false,colNeutral,clrBlack);
         DrawButton("btnCloseLastBuy","Cl. Last B",btnLeftAxis,btnTopAxis+btnNextTop,btnWidth,btnHeight,false,colNeutral,clrBlack);
         DrawButton("btnCloseLastSell","Cl. Last S",btnLeftAxis+btnNextLeft,btnTopAxis+btnNextTop,btnWidth,btnHeight,false,colNeutral,clrBlack);
         DrawButton("btnCloseAllBuys","Cl. All Bs",btnLeftAxis,btnTopAxis+2*btnNextTop,btnWidth,btnHeight,false,colNeutral,clrBlack);
         DrawButton("btnCloseAllSells","Cl. All Ss",btnLeftAxis+btnNextLeft,btnTopAxis+2*btnNextTop,btnWidth,btnHeight,false,colNeutral,clrBlack);
         DrawButton("btnShowComment","Show/Hide Comment",5,btnTopAxis,btnWidth*2,btnHeight,false,colNeutral,colCodeYellow);

         DrawButton("btnstopNextCycle","Stop Next Cycle",btnLeftAxis+2*btnNextLeft,btnTopAxis,MathRound(btnWidth*1.5),btnHeight,false,colNeutral,clrBlack);
         DrawButton("btnrestAndRealize","Rest & Realize",btnLeftAxis+2*btnNextLeft,btnTopAxis+btnNextTop,btnWidth*1.5,btnHeight,false,colNeutral,clrBlack);
         DrawButton("btnStopAll","Stop & Close",btnLeftAxis+2*btnNextLeft,btnTopAxis+2*btnNextTop,btnWidth*1.5,btnHeight,false,colNeutral,clrBlack);
        }
      // set state off all buttons to: Not Selected
      ObjectSetInteger(0,"btnManualBuy",OBJPROP_STATE,0);      // switch color back to not selected
      ObjectSetInteger(0,"btnManualSell",OBJPROP_STATE,0);      // switch color back to not selected
      ObjectSetInteger(0,"btnCloseLastBuy",OBJPROP_STATE,0);      // switch color back to not selected
      ObjectSetInteger(0,"btnCloseLastSell",OBJPROP_STATE,0);      // switch color back to not selected
      ObjectSetInteger(0,"btnCloseAllBuys",OBJPROP_STATE,0);      // switch color back to not selected
      ObjectSetInteger(0,"btnCloseAllSells",OBJPROP_STATE,0);      // switch color back to not selected

      ObjectSetInteger(0,"btnstopNextCycle",OBJPROP_STATE,0);      // switch color back to not selected
      ObjectSetInteger(0,"btnrestAndRealize",OBJPROP_STATE,0);      // switch color back to not selected
      ObjectSetInteger(0,"btnStopAll",OBJPROP_STATE,0);      // switch color back to not selected
                                                             //
      // #019: implement button: Stop On Next Cycle
      if(stopNextCycle)
        {
         SetButtonText("btnstopNextCycle","Continue");
         // set color to red, if everything is closed
         if(sells+buys==0)
            SetButtonColor("btnstopNextCycle",colCodeRed,colFontLight);
         else
            SetButtonColor("btnstopNextCycle",colCodeYellow,colFontDark);
        }
      else
        {
         SetButtonText("btnstopNextCycle","Stop Next Cycle");
         SetButtonColor("btnstopNextCycle",colPauseButtonPassive,colFontLight);
        }

      // #011 #018: implement button: Stop On Next Cycle
      if(restAndRealize)
        {
         SetButtonText("btnrestAndRealize","Continue");
         if(sells+buys==0)
            SetButtonColor("btnrestAndRealize",colCodeRed,colFontLight);
         else
            SetButtonColor("btnrestAndRealize",colCodeYellow,colFontDark);
        }
      else
        {
         SetButtonText("btnrestAndRealize","Rest & Realize");
         SetButtonColor("btnrestAndRealize",colPauseButtonPassive,colFontLight);
        }

      // #010: implement button: Stop & Close
      if(stopAll)
        {
         SetButtonText("btnStopAll","Continue");
         SetButtonColor("btnStopAll",colCodeRed,colFontLight);
        }
      else
        {
         SetButtonText("btnStopAll","Stop & Close");
         SetButtonColor("btnStopAll",colPauseButtonPassive,colFontLight);
        }

     }
   else
     {
      DeleteButton("btnStopAll");
      DeleteButton("btnrestAndRealize");
      DeleteButton("btnstopNextCycle");

      DeleteButton("btnManualBuy");
      DeleteButton("btnManualSell");
      DeleteButton("btnCloseLastBuy");
      DeleteButton("btnCloseLastSell");
      DeleteButton("btnCloseAllBuys");
      DeleteButton("btnCloseAllSells");
     }

#ifdef DEBUG
// #014: debug out at the end of comment string; will be updated each program loop
   debugCommentDyn+=
                    "Ikarus Channel: "+DoubleToStr(ter_IkarusChannel,0)+
                    "\n"+
                    //"\nPrice Buy: "+DoubleToStr(ter_priceBuy,ter_digits)+
                    //"\nPrice Sell: "+DoubleToStr(ter_priceSell,ter_digits)+
                    "\nTick Value: "+DoubleToStr(ter_tick_value,ter_digits)+
                    "\nTick Size: "+DoubleToStr(ter_tick_size,ter_digits)+
                    "\nPoint: "+DoubleToStr(ter_point,ter_digits)+
                    "\nDigits: "+ter_digits+
                    "\n"+
                    "\nTicks/Grid Size: "+DoubleToStr(ter_ticksPerGrid,ter_digits)+
                    "\nRelative Volume: "+DoubleToString(relativeVolume,2)+" Lot"+
                    "\nAct. Price/Tick: "+DoubleToString(CalculatePriceByTickDiff(relativeVolume,ter_tick_size),ter_digits)+ter_currencySymbol+
                    "\nAct. Ticks/1,- "+ter_currencySymbol+": "+DoubleToString(CalculateTicksByPrice(relativeVolume,1),ter_digits)+
                    "\n"+
                    debugCommentCloseBuys+
                    debugCommentCloseSells+
                    //"\n"+
                    //"\n\nMargins for 1 Lot:"
                    //"\nMODE_MARGINHEDGED: "+DoubleToString(MarketInfo(Symbol(),MODE_MARGINHEDGED)/AccountLeverage(),2)+
                    //"\nMODE_MARGININIT: "+DoubleToString(MarketInfo(Symbol(),MODE_MARGININIT)/AccountLeverage(),2)+
                    //"\nMODE_MARGINMAINTENANCE: "+DoubleToString(MarketInfo(Symbol(),MODE_MARGINMAINTENANCE)/AccountLeverage(),2)+
                    //"\nMODE_MARGINREQUIRED: "+DoubleToString(MarketInfo(Symbol(),MODE_MARGINREQUIRED),2)+
                    //"\nAccountLeverage: "+DoubleToString(AccountLeverage(),2)+
                    //"\nBalance: "+DoubleToString(AccountBalance(),2)+
                    //"\nEquity: "+DoubleToString(AccountEquity(),2)+
                    //"\nMargin: "+DoubleToString(AccountMargin(),5)+
                    //"\nFree Margin: "+DoubleToString(AccountFreeMargin(),2)+
                    //"\nNext Margin: "+DoubleToString(CalculateNextMargin(),2)+
                    //"\n"+
                    //"\nLineBuyTmp: "+DoubleToString(line_buy_tmp,ter_digits)+
                    //"\nLineSellTmp: "+DoubleToString(line_sell_tmp,ter_digits)+
                    //"\nLineBuyNext: "+DoubleToString(line_buy_next,ter_digits)+
                    //"\nLineSellNext: "+DoubleToString(line_sell_next,ter_digits)+
                    //"\nLineBuyTS: "+DoubleToString(line_buy_ts,ter_digits)+
                    //"\nLineSellTS: "+DoubleToString(line_sell_ts,ter_digits)+
                    "";
//"\n: "++
//"\n: "+DoubleToString(,2)+

   if(showComment)
      Comment("\n\n"+txt+"\n\nDebug info (switch of in code):"+debugCommentStat+debugCommentDyn);
   else
      Comment("");
#else
   if(showComment)
      Comment("\n\n"+txt);
   else
      Comment("");
#endif

// #047: add panel right upper corner
   if(show_forecast)
     {
      if(total_buy_profit+total_sell_profit>0)
         instrumentCol=colInPlus;
      else
         instrumentCol=colInMinus;

      Write("panel_1_01",ChartSymbol(0),5,22,"Arial",14,instrumentCol);
      if(ter_spread>max_spread)
         Write("panel_1_02","Spread: "+DoubleToString(ter_spread/10,1),5,42,"Arial",10,colCodeRed);
      else
         Write("panel_1_02","Spread: "+DoubleToString(ter_spread/10,1),5,42,"Arial",10,panelCol);

      Write("panel_1_03",DoubleToString(CalculatePriceByTickDiff(relativeVolume,ter_tick_size*10),2)+" "+ter_currencySymbol+" / Pip",5,58,"Arial",10,panelCol);
      Write("panel_1_04","Balance: "+DoubleToString(AccountBalance(),2)+" "+ter_currencySymbol,5,74,"Arial",10,panelCol);
      Write("panel_1_05","Equity: "+DoubleToString(AccountEquity(),2)+" "+ter_currencySymbol,5,90,"Arial",10,panelCol);
      Write("panel_1_06","Free Margin: "+DoubleToString(AccountFreeMargin(),2)+" "+ter_currencySymbol,5,106,"Arial",10,panelCol);
      Write("panel_1_07","P/L Sym. "+DoubleToString(total_buy_profit+total_sell_profit,2)+" "+ter_currencySymbol,5,122,"Arial",14,instrumentCol);
      if(total_buy_profit<0)
         Write("panel_1_08","P/L Buy: "+DoubleToStr(total_buy_profit,2)+" "+ter_currencySymbol,5,144,"Arial",10,colInMinus);
      else
         Write("panel_1_08","P/L Buy: "+DoubleToStr(total_buy_profit,2)+" "+ter_currencySymbol,5,144,"Arial",10,colInPlus);
      if(total_sell_profit<0)
         Write("panel_1_09","P/L sell: "+DoubleToStr(total_sell_profit,2)+" "+ter_currencySymbol,5,160,"Arial",10,colInMinus);
      else
         Write("panel_1_09","P/L sell: "+DoubleToStr(total_sell_profit,2)+" "+ter_currencySymbol,5,160,"Arial",10,colInPlus);

      double accountPL=AccountProfit();
      if(accountPL<0)
         Write("panel_1_10","P/L Acc. "+DoubleToString(accountPL,2)+" "+ter_currencySymbol,5,176,"Arial",10,colInMinus);
      else
         Write("panel_1_10","P/L Acc. "+DoubleToString(accountPL,2)+" "+ter_currencySymbol,5,176,"Arial",10,colInPlus);
      //double pips2go_Buys = (line_buy-ter_priceSell)*ter_tick_size;
      double pips2go_Buys = MathAbs(line_buy/ter_tick_size-ter_priceSell/ter_tick_size)/10;
      double pips2go_Sells = MathAbs(line_sell/ter_tick_size-ter_priceBuy/ter_tick_size)/10;
      Write("panel_1_11","Pips2Go B "+DoubleToString(pips2go_Buys,0)+" S "+DoubleToStr(pips2go_Sells,0),5,192,"Arial",10,panelCol);
     }
  }
//+------------------------------------------------------------------+
//| CheckAccountState
//+------------------------------------------------------------------+
void CheckAccountState()
  {
   accountState=as_green;     // init state
   codeYellowMsg="";          // #038: give user info, why account state is yellow or red
   codeRedMsg="";
   double myPercentage=0;

// check if max_positions is reached:
   if(buys>=max_positions)
      accountState=as_yellow;
   if(sells>=max_positions)
      accountState=as_yellow;
   if(accountState==as_yellow)
      codeYellowMsg="Code YELLOW: Max positions reached";

// #024: calculate, if margin of next Ikarus position can be paid
   if(CalculateNextMargin()>AccountFreeMargin())
     {
      accountState=as_red;
      codeRedMsg="Code RED: Next M. "+DoubleToString(CalculateNextMargin(),2)+" > Free M. "+DoubleToString(AccountFreeMargin(),2);
     }

// #025: use equity percentage instead of unpayable position
   if((100-(100*equity_warning))/100*max_equity>AccountEquity())
     {
      accountState=as_red;
      if(codeRedMsg=="")
         codeRedMsg="Code RED: Equ. "+NormalizeDouble(AccountEquity(),2)+" < "+NormalizeDouble((100*equity_warning),0)+"% of max. equ. "+NormalizeDouble(max_equity,2);
      else
         codeRedMsg+="\nand\nEqu. "+NormalizeDouble(AccountEquity(),2)+" < "+NormalizeDouble((100*equity_warning),0)+"% of max. equ. "+NormalizeDouble(max_equity,2);
     }

// #026: implement manual trades, if account state is not green
// #053: paint comment button in status color
   switch(accountState)
     {
      case as_yellow:
         SetButtonColor("btnManualBuy",colCodeYellow,colFontDark);
         SetButtonColor("btnManualSell",colCodeYellow,colFontDark);
         SetButtonColor("btnCloseLastBuy",colCodeYellow,colFontDark);
         SetButtonColor("btnCloseLastSell",colCodeYellow,colFontDark);
         SetButtonColor("btnCloseAllBuys",colCodeYellow,colFontDark);
         SetButtonColor("btnCloseAllSells",colCodeYellow,colFontDark);
         SetButtonColor("btnShowComment",colCodeYellow,colFontDark);
         break;
      case as_red:
         SetButtonColor("btnManualBuy",colCodeRed,colFontLight);
         SetButtonColor("btnManualSell",colCodeRed,colFontLight);
         SetButtonColor("btnCloseLastBuy",colCodeRed,colFontLight);
         SetButtonColor("btnCloseLastSell",colCodeRed,colFontLight);
         SetButtonColor("btnCloseAllBuys",colCodeRed,colFontLight);
         SetButtonColor("btnCloseAllSells",colCodeRed,colFontLight);
         SetButtonColor("btnShowComment",colCodeRed,colFontLight);
         break;
      default:
         SetButtonColor("btnManualBuy",colCodeGreen,colCodeGreen);
         SetButtonColor("btnManualSell",colCodeGreen,colCodeGreen);
         SetButtonColor("btnCloseLastBuy",colCodeGreen,colCodeGreen);
         SetButtonColor("btnCloseLastSell",colCodeGreen,colCodeGreen);
         SetButtonColor("btnCloseAllBuys",colCodeGreen,colCodeGreen);
         SetButtonColor("btnCloseAllSells",colCodeGreen,colCodeGreen);
         SetButtonColor("btnShowComment",colCodeGreen,colFontLight);
         break;
     }
   return;
  }
//+------------------------------------------------------------------+
//| CalculateVolume                                                                 |
//+------------------------------------------------------------------+
double CalculateVolume(int positions)
  {
   int factor=0;
   int i=0;

   if(positions==0)
      return(min_lots);

   switch(gs_progression)
     {
      case 0:
         factor=1;
         break;
      case 1:
         factor=positions;
         break;
      case 2:
         for(i=1,factor=1;i<positions;i++)
         factor=factor*2;
         break;
      case 3:
         factor=CalculateFibonacci(positions);
         break;
     }
//debugCommentDyn+="\nCalculate Volume of "+positions+" positions = "+DoubleToString(factor*min_lots,2);
   return(factor*min_lots);
  }
//+------------------------------------------------------------------+
//| CalculateNextVolume                                                                 |
//+------------------------------------------------------------------+
double CalculateNextVolume(int orderType)
  {
   if(orderType==OP_BUY && buys==0)
      return(min_lots);
   if(orderType==OP_SELL && sells==0)
      return(min_lots);

// next volume must be calulated by actual positions + 1
   switch(progression)
     {
      case 0:
         return(min_lots);
         break;

      case 1:
         if(orderType==OP_BUY)
         return(buy_lots[buys-1]+buy_lots[0]);
         else
            return(sell_lots[sells-1]+sell_lots[0]);
         break;

      case 2:
         if(orderType==OP_BUY)
         return(2*buy_lots[buys-1]);
         else
            return(2*sell_lots[sells-1]);
         break;

      case 3:
         if(orderType==OP_BUY)
         return(CalculateFibonacci(buys+1)*buy_lots[0]);
         else
            return(CalculateFibonacci(sells+1)*sell_lots[0]);
         break;
     }
   return(min_lots);
  }
//+------------------------------------------------------------------+
//| CalculateMargin                                                                 |
//+------------------------------------------------------------------+
double CalculateNextMargin()
  {
   double leverage=100/AccountLeverage();

   if(buys+sells==0)
      return(min_lots*leverage*ter_MODE_MARGINREQUIRED);
   if(buys>sells)
      return(CalculateNextVolume(OP_BUY)*leverage*ter_MODE_MARGINREQUIRED);
   else
      return(CalculateNextVolume(OP_SELL)*leverage*ter_MODE_MARGINREQUIRED);
  }
//+------------------------------------------------------------------+
// WRITE
//+------------------------------------------------------------------+
void Write(string name,string s,int x,int y,string font,int size,color c)
  {
   if(ObjectFind(name)==-1)
     {
      ObjectCreate(name,OBJ_LABEL,0,0,0);
      ObjectSet(name,OBJPROP_CORNER,1);
     }
   ObjectSetText(name,s,size,font,c);
   ObjectSet(name,OBJPROP_XDISTANCE,x);
   ObjectSet(name,OBJPROP_YDISTANCE,y);
  }
//+------------------------------------------------------------------+
// HORIZONTAL LINE
//+------------------------------------------------------------------+
void HorizontalLine(double value,string name,color c,int style,int thickness)
  {
   if(ObjectFind(name)==-1)
     {
      ObjectCreate(name,OBJ_HLINE,0,Time[0],value);
     }
   ObjectSet(name,OBJPROP_PRICE1,value);
   ObjectSet(name,OBJPROP_STYLE,style);
   ObjectSet(name,OBJPROP_COLOR,c);
   ObjectSet(name,OBJPROP_WIDTH,thickness);
  }
// ------------------------------------------------------------------------------------------------
// CALCULATE STARTING VOLUME
// ------------------------------------------------------------------------------------------------
double CalculateStartingVolume()
  {
   double aux;
// #001: eliminate all warnings

   aux=min_lots;

   if(aux>MarketInfo(Symbol(),MODE_MAXLOT))
      aux=MarketInfo(Symbol(),MODE_MAXLOT);

   if(aux<MarketInfo(Symbol(),MODE_MINLOT))
      aux=MarketInfo(Symbol(),MODE_MINLOT);

   return(aux);
  }
// ------------------------------------------------------------------------------------------------
// CALCULATE TICKS by PRICE
// ------------------------------------------------------------------------------------------------
double CalculateTicksByPrice(double volume,double price)
  {
   if(volume==0)
      return(0);
   return(price*ter_tick_size/ter_tick_value/volume);
  }
// ------------------------------------------------------------------------------------------------
// CALCULATE PRICE by TICK DIFFERENCE
// ------------------------------------------------------------------------------------------------
double CalculatePriceByTickDiff(double volume,double diff)
  {
   return(ter_tick_value*volume*diff/ter_tick_size);
  }
// ------------------------------------------------------------------------------------------------
// CALCULATE PIP VALUE
// ------------------------------------------------------------------------------------------------
double CalculatePipValue(double volume)
  {
   double aux_mm_value=0;

   double aux_mm_tick_value=ter_tick_value;
   double aux_mm_tick_size=ter_tick_size;
   int aux_mm_digits=ter_digits;
   double aux_mm_veces_lots;

   if(volume!=0)
     {
      aux_mm_veces_lots=1/volume;

      if(aux_mm_digits==5 || aux_mm_digits==3)
        {
         aux_mm_value=aux_mm_tick_value*10;
        }
      else if(aux_mm_digits==4 || aux_mm_digits==2)
        {
         aux_mm_value=aux_mm_tick_value;
        }

      aux_mm_value=aux_mm_value/aux_mm_veces_lots;
     }

   return(aux_mm_value);
  }
// ------------------------------------------------------------------------------------------------
// CALCULATE TAKE PROFIT
// ------------------------------------------------------------------------------------------------
double CalculateTP(double volume)
  {
// #009: fix math round bug for stop loss and take profit, because of wrong var type int instead of double
   double aux_take_profit;

   aux_take_profit=take_profit*CalculatePipValue(volume);

   return(aux_take_profit);
  }
// ------------------------------------------------------------------------------------------------
// CALCULATE STOP LOSS
// ------------------------------------------------------------------------------------------------
double CalculateSL(double volume,int positions)
// volume = volume of last position only
  {
// #009: fix math round bug for stop loss and take profit, because of wrong var type int instead of double
   double aux_stop_loss;

// #008: use progression for grid size as well as volume
   double myVal=CalculateVolume(positions)/min_lots;  // myVal = # of actual progression
                                                      //debugCommentDyn+="\nCalculateSL with factor: "+DoubleToString(myVal,5)+" and CalcPipVal: "+DoubleToString(CalculatePipValue(volume),5);

   aux_stop_loss=-(myVal*grid_size*CalculatePipValue(volume));
//aux_stop_loss=-1*grid_size*CalculatePipValue(volume);

// the stop loss line is calculated in ShowLines and the value to clear a position does also not use this value
   return(aux_stop_loss);
  }
// ------------------------------------------------------------------------------------------------
// ROBOT
// ------------------------------------------------------------------------------------------------
void Robot()
  {
   int ticket=-1;
   bool closed=FALSE;

// *************************
// ACCOUNT RISK CONTROL
// *************************
   if(((100-(100*account_risk))/100)*AccountBalance()>AccountEquity())
     {
      // #012: make account risk save: all positions will be cleared and trading will be paused by stop&close button
      stopAll=1;
      // Closing buy orders
      //for(i=0; i<=buys-1; i++)
      //  {
      //   closed=OrderCloseReliable(buy_tickets[i],buy_lots[i],MarketInfo(Symbol(),MODE_BID),slippage,Blue);
      //  }
      //// Closing sell orders
      //for(i=0; i<=sells-1; i++)
      //  {
      //   closed=OrderCloseReliable(sell_tickets[i],sell_lots[i],MarketInfo(Symbol(),MODE_ASK),slippage,Red);
      //  }
      //BuyResetAfterClose();
      //SellResetAfterClose();
     }

// **************************************************
// BUYS==0
// **************************************************
   if(buys==0)
     {
      // #019: new button: Stop Next Cyle, which trades normally, until cycle is closed
      if(!stopNextCycle && !restAndRealize)
        {
         if(unbalance_control==0)
            ticket=OrderSendReliable(Symbol(),OP_BUY,CalculateStartingVolume(),MarketInfo(Symbol(),MODE_ASK),slippage,0,0,key,magic,0,Blue);
         else
           {
            if(sells<4)
               ticket=OrderSendReliable(Symbol(),OP_BUY,CalculateStartingVolume(),MarketInfo(Symbol(),MODE_ASK),slippage,0,0,key,magic,0,Blue);
            else
               ticket=OrderSendReliable(Symbol(),OP_BUY,sell_lots[sells-3],MarketInfo(Symbol(),MODE_ASK),slippage,0,0,key,magic,0,Blue);
           }
        }
     }

// **************************************************
// BUYS==1
// **************************************************
   if(buys==1)
     {
      if(!stopNextCycle && !restAndRealize && max_positions>1)
        {
         // CASE 1 >>> We reach Stop Loss (grid size)    
         if(buy_profit[buys-1]<=CalculateSL(buy_lots[buys-1],1))
           {
            // We are going to open a new order. Volume depends on chosen progression.
            NewIkarusOrder(OP_BUY,false);
           }
        }

      // CASE 2.1 >>> We reach Take Profit so we activate profit lock
      if(buy_max_profit==0 && total_buy_profit>CalculateTP(buy_lots[0]))
        {
         buy_max_profit=total_buy_profit;
         buy_close_profit=profit_lock*buy_max_profit;
        }

      // CASE 2.2 >>> Profit locked is updated in real time
      if(buy_max_profit>0)
        {
         if(total_buy_profit>buy_max_profit)
           {
            buy_max_profit=total_buy_profit;
            buy_close_profit=profit_lock*total_buy_profit;
           }
        }

      // CASE 2.3 >>> If profit falls below profit locked we close all orders
      if(buy_max_profit>0 && buy_close_profit>0 && buy_max_profit>buy_close_profit && total_buy_profit<buy_close_profit)
        {
         CloseAllBuys();
         // At this point all order are closed. Global vars will be updated thanks to UpdateVars() on next start() execution
        }
     } // if (buys==1)

// **************************************************
// BUYS>1
// **************************************************  
   if(buys>1)
     {
      // CASE 1 >>> We reach Stop Loss (grid size)      
      if(buy_profit[buys-1]<=CalculateSL(buy_lots[buys-1],buys))
        {
         // We are going to open a new order if we have less than 50 orders opened. Volume depends on chosen progression.
         if(buys<max_open_positions && buys<max_positions) // #007: be able to deal with variable number of open positions
           {
            NewIkarusOrder(OP_BUY,false);
           }
        }

      // CASE 2.1 >>> We reach Take Profit so we activate profit lock
      if(buy_max_profit==0 && progression==0 && total_buy_profit>CalculateTP(buy_lots[0]))
        {
         buy_max_profit=total_buy_profit;
         buy_close_profit=profit_lock*buy_max_profit;
        }
      if(buy_max_profit==0 && progression==1 && total_buy_profit>buys*CalculateTP(buy_lots[0]))
        {
         buy_max_profit=total_buy_profit;
         buy_close_profit=profit_lock*buy_max_profit;
        }
      if(buy_max_profit==0 && progression==2 && total_buy_profit>CalculateTP(buy_lots[buys-1]))
        {
         buy_max_profit=total_buy_profit;
         buy_close_profit=profit_lock*buy_max_profit;
        }
      if(buy_max_profit==0 && progression==3 && total_buy_profit>CalculateTP(buy_lots[buys-1]))
        {
         buy_max_profit=total_buy_profit;
         buy_close_profit=profit_lock*buy_max_profit;
        }

      // CASE 2.2 >>> Profit locked is updated in real time
      if(buy_max_profit>0)
        {
         if(total_buy_profit>buy_max_profit)
           {
            buy_max_profit=total_buy_profit;
            buy_close_profit=profit_lock*total_buy_profit;
           }
        }

      // CASE 2.3 >>> If profit falls below profit locked we close all orders
      if(buy_max_profit>0 && buy_close_profit>0 && buy_max_profit>buy_close_profit && total_buy_profit<buy_close_profit)
        {
         // At this point all order are closed. Global vars will be updated thanks to UpdateVars() on next start() execution
         CloseAllBuys();
        }
     } // if (buys>1)
   debugCommentCloseBuys
   ="\nbuys will be closed if:\n"+
    "    - buy max profit: "+DoubleToString(buy_max_profit,2)+" > buy close profit: "+DoubleToString(buy_close_profit,2)+"     AND \n"+
    "    - total buy profit: "+DoubleToString(total_buy_profit,2)+" < buy close profit: "+DoubleToString(buy_close_profit,2)+"\n";

// **************************************************
// SELLS==0
// **************************************************
   if(sells==0)
     {
      // #019: new button: Stop Next Cyle, which trades normally, until cycle is closed
      if(!stopNextCycle && !restAndRealize)
        {
         if(unbalance_control==0)
            ticket=OrderSendReliable(Symbol(),OP_SELL,CalculateStartingVolume(),MarketInfo(Symbol(),MODE_BID),slippage,0,0,key,magic,0,Red);
         else
           {
            if(buys<4)
               ticket=OrderSendReliable(Symbol(),OP_SELL,CalculateStartingVolume(),MarketInfo(Symbol(),MODE_BID),slippage,0,0,key,magic,0,Red);
            else
               ticket=OrderSendReliable(Symbol(),OP_SELL,buy_lots[buys-3],MarketInfo(Symbol(),MODE_BID),slippage,0,0,key,magic,0,Red);
           }
        }
     }

// **************************************************
// SELLS==1
// **************************************************
   if(sells==1)
     {
      // CASE 1 >>> We reach Stop Loss (grid size)      
      if(!stopNextCycle && !restAndRealize && max_positions>1)
        {
         if(sell_profit[sells-1]<=CalculateSL(sell_lots[sells-1],1))
           {
            // We are going to open a new order. Volume depends on chosen progression.
            NewIkarusOrder(OP_SELL,false);
           }
        }

      // CASE 2.1 >>> We reach Take Profit so we activate profit lock
      if(sell_max_profit==0 && total_sell_profit>CalculateTP(sell_lots[0]))
        {
         sell_max_profit=total_sell_profit;
         sell_close_profit=profit_lock*sell_max_profit;
        }

      // CASE 2.2 >>> Profit locked is updated in real time
      if(sell_max_profit>0)
        {
         if(total_sell_profit>sell_max_profit)
           {
            sell_max_profit=total_sell_profit;
            sell_close_profit=profit_lock*total_sell_profit;
           }
        }

      // CASE 2.3 >>> If profit falls below profit locked we close all orders
      if(sell_max_profit>0 && sell_close_profit>0 && sell_max_profit>sell_close_profit && total_sell_profit<sell_close_profit)
        {
         // At this point all order are closed. Global vars will be updated thanks to UpdateVars() on next start() execution
         CloseAllSells();
        }
     } // if (sells==1)

// **************************************************
// SELLS>1
// **************************************************  
   if(sells>1)
     {
      // CASE 1 >>> We reach Stop Loss (grid size)   
      if(sell_profit[sells-1]<=CalculateSL(sell_lots[sells-1],sells))
        {
         // We are going to open a new order if we have less than 50 orders opened. Volume depends on chosen progression.
         if(sells<max_open_positions && sells<max_positions) // #007: be able to deal with variable number of open positions
           {
            NewIkarusOrder(OP_SELL,false);
           }
        }

      // CASE 2.1 >>> We reach Take Profit so we activate profit lock
      if(sell_max_profit==0 && progression==0 && total_sell_profit>CalculateTP(sell_lots[0]))
        {
         sell_max_profit=total_sell_profit;
         sell_close_profit=profit_lock*sell_max_profit;
        }
      if(sell_max_profit==0 && progression==1 && total_sell_profit>sells*CalculateTP(sell_lots[0]))
        {
         sell_max_profit=total_sell_profit;
         sell_close_profit=profit_lock*sell_max_profit;
        }
      if(sell_max_profit==0 && progression==2 && total_sell_profit>CalculateTP(sell_lots[sells-1]))
        {
         sell_max_profit=total_sell_profit;
         sell_close_profit=profit_lock*sell_max_profit;
        }
      if(sell_max_profit==0 && progression==3 && total_sell_profit>CalculateTP(sell_lots[sells-1]))
        {
         sell_max_profit=total_sell_profit;
         sell_close_profit=profit_lock*sell_max_profit;
        }

      // CASE 2.2 >>> Profit locked is updated in real time
      if(sell_max_profit>0)
        {
         if(total_sell_profit>sell_max_profit)
           {
            sell_max_profit=total_sell_profit;
            sell_close_profit=profit_lock*sell_max_profit;
           }
        }

      // CASE 2.3 >>> If profit falls below profit locked we close all orders
      if(sell_max_profit>0 && sell_close_profit>0 && sell_max_profit>sell_close_profit && total_sell_profit<sell_close_profit)
        {
         // At this point all order are closed. Global vars will be updated thanks to UpdateVars() on next start() execution
         CloseAllSells();
        }
     } // if (sells>1)  
   debugCommentCloseSells="\nsells will be closed if:\n"+
                          "    - sell max profit: "+DoubleToString(sell_max_profit,2)+" > sell close profit: "+DoubleToString(sell_close_profit,2)+" AND \n"+
                          "    - total sell profit: "+DoubleToString(total_sell_profit,2)+" < sell close profit: "+DoubleToString(sell_close_profit,2);

// #017: deal with global vars to save and restore data, while chart is closed or must be restarted by other reason
   WriteIniData();
  }
//+------------------------------------------------------------------+
//
// #005: add some functions, to make program more modular
//
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|  CalulateFibonacci                                                                |
//+------------------------------------------------------------------+
int CalculateFibonacci(int index)
  {
   int val1=0;
   int val2 = 1;
   int val3 = 0;
   for(int i=1;i<index;i++) // use this for: 1, 1, 2, 3, 5, 8, 13, 21, ...
     {
      val3=val2;
      val2= val1+val2;
      val1=val3;
     }
   return val2;
  }
//+------------------------------------------------------------------+
// CloseAllSells
//+------------------------------------------------------------------+
void CloseAllSells()
  {
   sell_max_profit=0;
   sell_close_profit=0;
   if(sells>0)
     {
      for(int i=0; i<=sells-1; i++)
        {
         bool retVal=OrderCloseReliable(sell_tickets[i],sell_lots[i],MarketInfo(Symbol(),MODE_ASK),slippage,Red);
        }
      ObjectDelete("TakeProfit_sell");
      ObjectDelete("ProfitLock_sell");
      ObjectDelete("Next_sell");
      ObjectDelete("NewTakeProfit_sell");
      line_sell=0;line_sell_tmp=0;line_sell_next=0;line_sell_ts=0;
     }
  }
//+------------------------------------------------------------------+
// CloseAllBuys
//+------------------------------------------------------------------+
void CloseAllBuys()
  {
   buy_max_profit=0;
   buy_close_profit=0;
   if(buys>0)
     {
      for(int i=0; i<=buys-1; i++)
        {
         bool retVal=OrderCloseReliable(buy_tickets[i],buy_lots[i],MarketInfo(Symbol(),MODE_BID),slippage,Blue);
        }
      ObjectDelete("TakeProfit_buy");
      ObjectDelete("ProfitLock_buy");
      ObjectDelete("Next_buy");
      ObjectDelete("NewTakeProfit_buy");
      line_buy=0;line_buy_tmp=0;line_buy_next=0;line_buy_ts=0;
     }
  }
//+------------------------------------------------------------------+
//| NewIkarusOrder
//+------------------------------------------------------------------+
void  NewIkarusOrder(int orderType,bool isManually)
  {
   int ticket;

// #018: rename button: stop next cyle to rest and realize; does not open new positions until cycle is closed
// #019: Button: Stop On Next Cycle is still at Robot()
   if(restAndRealize && !isManually)
      return;

   if(orderType==OP_BUY)
     {
      // new buy:
      if(progression==0) ticket = OrderSendReliable(Symbol(),OP_BUY,buy_lots[0],MarketInfo(Symbol(),MODE_ASK),slippage,0,0,key,magic,0,Blue);
      if(progression==1) ticket = OrderSendReliable(Symbol(),OP_BUY,buy_lots[buys-1]+buy_lots[0],MarketInfo(Symbol(),MODE_ASK),slippage,0,0,key,magic,0,Blue);
      if(progression==2) ticket = OrderSendReliable(Symbol(),OP_BUY,2*buy_lots[buys-1],MarketInfo(Symbol(),MODE_ASK),slippage,0,0,key,magic,0,Blue);
      if(progression==3) ticket = OrderSendReliable(Symbol(),OP_BUY,CalculateFibonacci(buys+1)*buy_lots[0],MarketInfo(Symbol(),MODE_ASK),slippage,0,0,key,magic,0,Blue);
     }
   else
     {
      // new sell:
      if(progression==0) ticket = OrderSendReliable(Symbol(),OP_SELL,sell_lots[0],MarketInfo(Symbol(),MODE_BID),slippage,0,0,key,magic,0,Red);
      if(progression==1) ticket = OrderSendReliable(Symbol(),OP_SELL,sell_lots[sells-1]+sell_lots[0],MarketInfo(Symbol(),MODE_BID),slippage,0,0,key,magic,0,Red);
      if(progression==2) ticket = OrderSendReliable(Symbol(),OP_SELL,2*sell_lots[sells-1],MarketInfo(Symbol(),MODE_BID),slippage,0,0,key,magic,0,Red);
      if(progression==3) ticket = OrderSendReliable(Symbol(),OP_SELL,CalculateFibonacci(sells+1)*sell_lots[0],MarketInfo(Symbol(),MODE_BID),slippage,0,0,key,magic,0,Red);
     }
  }
//+------------------------------------------------------------------+
//
// #013: end
//
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//
// #006: add buttons to chart
//
// common button functionality from RdzGridTraps                     |
// ON INIT
//                                                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
// #047: add panel right upper corner
   ObjectDelete("panel_1_01");
   ObjectDelete("panel_1_02");
   ObjectDelete("panel_1_03");
   ObjectDelete("panel_1_04");
   ObjectDelete("panel_1_05");
   ObjectDelete("panel_1_06");
   ObjectDelete("panel_1_07");
   ObjectDelete("panel_1_08");
   ObjectDelete("panel_1_09");
   ObjectDelete("panel_1_10");
   ObjectDelete("panel_1_11");

// #006 #010 #011 #018 #026: implement buttons
   DrawButton("btnManualBuy","Buy",btnLeftAxis,btnTopAxis,btnWidth,btnHeight,false,colNeutral,clrBlack);
   DrawButton("btnManualSell","Sell",btnLeftAxis+btnNextLeft,btnTopAxis,btnWidth,btnHeight,false,colNeutral,clrBlack);
   DrawButton("btnCloseLastBuy","Cl. Last B",btnLeftAxis,btnTopAxis+btnNextTop,btnWidth,btnHeight,false,colNeutral,clrBlack);
   DrawButton("btnCloseLastSell","Cl. Last S",btnLeftAxis+btnNextLeft,btnTopAxis+btnNextTop,btnWidth,btnHeight,false,colNeutral,clrBlack);
   DrawButton("btnCloseAllBuys","Cl. All Bs",btnLeftAxis,btnTopAxis+2*btnNextTop,btnWidth,btnHeight,false,colNeutral,clrBlack);
   DrawButton("btnCloseAllSells","Cl. All Ss",btnLeftAxis+btnNextLeft,btnTopAxis+2*btnNextTop,btnWidth,btnHeight,false,colNeutral,clrBlack);
   DrawButton("btnShowComment","Show/Hide Comment",5,btnTopAxis,btnWidth*2,btnHeight,false,colNeutral,colCodeYellow);

   DrawButton("btnstopNextCycle","Stop Next Cycle",btnLeftAxis+2*btnNextLeft,btnTopAxis,MathRound(btnWidth*1.5),btnHeight,false,colNeutral,clrBlack);
   DrawButton("btnrestAndRealize","Rest & Realize",btnLeftAxis+2*btnNextLeft,btnTopAxis+btnNextTop,btnWidth*1.5,btnHeight,false,colNeutral,clrBlack);
   DrawButton("btnStopAll","Stop & Close",btnLeftAxis+2*btnNextLeft,btnTopAxis+2*btnNextTop,btnWidth*1.5,btnHeight,false,colNeutral,clrBlack);
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   DeleteButton("btnStopAll");
   DeleteButton("btnrestAndRealize");
   DeleteButton("btnstopNextCycle");

   DeleteButton("btnManualBuy");
   DeleteButton("btnManualSell");
   DeleteButton("btnCloseLastBuy");
   DeleteButton("btnCloseLastSell");
   DeleteButton("btnCloseAllBuys");
   DeleteButton("btnCloseAllSells");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum enObjectOperation
  {
   LODraw=0,
   LODelete=1
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteButton(string ctlName)
  {
   ObjectButton(ctlName,LODelete);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetButtonText(string ctlName,string Text)
  {
   if((ObjectFind(ChartID(),ctlName)>-1))
     {
      ObjectSetString(ChartID(),ctlName,OBJPROP_TEXT,Text);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetButtonColor(string ctlName,color buttonColor=clrNONE,color textColor=clrNONE)
  {
   if((ObjectFind(ChartID(),ctlName)>-1))
     {
      if(buttonColor!=clrNONE)
         ObjectSetInteger(ChartID(),ctlName,OBJPROP_BGCOLOR,buttonColor);
      if(textColor!=clrNONE)
         ObjectSetInteger(ChartID(),ctlName,OBJPROP_COLOR,textColor);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PressButton(string ctlName)
  {
   bool selected=ObjectGetInteger(ChartID(),ctlName,OBJPROP_STATE);
   if(selected)
     {
      ObjectSetInteger(ChartID(),ctlName,OBJPROP_STATE,false);
     }
   else
     {
      ObjectSetInteger(ChartID(),ctlName,OBJPROP_STATE,true);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawButton(string ctlName,string Text="",int X=-1,int Y=-1,int Width=-1,int Height=-1,bool Selected=false,color BgColor=clrNONE,color TextColor=clrNONE)
  {
   ObjectButton(ctlName,LODraw,Text,X,Y,Width,Height,Selected,BgColor,TextColor);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectButton(string ctlName,enObjectOperation Operation,string Text="",int X=-1,int Y=-1,int Width=-1,int Height=-1,bool Selected=false,color BgColor=clrNONE,color TextColor=clrNONE)
  {
   int DefaultX = btnLeftAxis;
   int DefaultY = btnTopAxis;
   int DefaultWidth=90;
   int DefaultHeight=20;
   if((ObjectFind(ChartID(),ctlName)>-1))
     {
      if(Operation==LODraw)
        {
         if(TextColor==clrNONE) TextColor=clrWhite;
         if(BgColor==clrNONE) BgColor=clrBlueViolet;
         if(X == -1) X = DefaultX;
         if(Y == -1) Y = DefaultY;
         if(Width==-1) Width=DefaultWidth;
         if(Height==-1) Height=DefaultHeight;

         ObjectSetInteger(ChartID(),ctlName,OBJPROP_COLOR,TextColor);
         ObjectSetInteger(ChartID(),ctlName,OBJPROP_BGCOLOR,BgColor);
         ObjectSetInteger(ChartID(),ctlName,OBJPROP_XDISTANCE,X);
         ObjectSetInteger(ChartID(),ctlName,OBJPROP_YDISTANCE,Y);
         ObjectSetInteger(ChartID(),ctlName,OBJPROP_XSIZE,Width);
         ObjectSetInteger(ChartID(),ctlName,OBJPROP_YSIZE,Height);
         ObjectSetInteger(ChartID(),ctlName,OBJPROP_STATE,Selected);
         ObjectSetString(ChartID(),ctlName,OBJPROP_FONT,"Arial");
         ObjectSetString(ChartID(),ctlName,OBJPROP_TEXT,Text);
         ObjectSetInteger(ChartID(),ctlName,OBJPROP_FONTSIZE,9);
         ObjectSetInteger(ChartID(),ctlName,OBJPROP_SELECTABLE,0);

        }
      else if(Operation==LODelete)
        {
         ObjectDelete(ChartID(),ctlName);
        }
     }
   else if(Operation==LODraw)
     {
      if(TextColor==clrNONE) TextColor=clrWhite;
      if(BgColor==clrNONE) BgColor=clrBlueViolet;
      if(X == -1) X = DefaultX;
      if(Y == -1) Y = DefaultY;
      if(Width==-1) Width=DefaultWidth;
      if(Height==-1) Height=DefaultHeight;

      ObjectCreate(ChartID(),ctlName,OBJ_BUTTON,0,0,0);
      ObjectSetInteger(ChartID(),ctlName,OBJPROP_COLOR,TextColor);
      ObjectSetInteger(ChartID(),ctlName,OBJPROP_BGCOLOR,BgColor);
      ObjectSetInteger(ChartID(),ctlName,OBJPROP_XDISTANCE,X);
      ObjectSetInteger(ChartID(),ctlName,OBJPROP_YDISTANCE,Y);
      ObjectSetInteger(ChartID(),ctlName,OBJPROP_XSIZE,Width);
      ObjectSetInteger(ChartID(),ctlName,OBJPROP_YSIZE,Height);
      ObjectSetInteger(ChartID(),ctlName,OBJPROP_STATE,Selected);
      ObjectSetString(ChartID(),ctlName,OBJPROP_FONT,"Arial");
      ObjectSetString(ChartID(),ctlName,OBJPROP_TEXT,Text);
      ObjectSetInteger(ChartID(),ctlName,OBJPROP_FONTSIZE,9);
      ObjectSetInteger(ChartID(),ctlName,OBJPROP_SELECTABLE,0);
     }
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   int retVal=0;
//if(id==CHARTEVENT_KEYDOWN)
//  {
//   if(id==CHARTEVENT_KEYDOWN) // does not work in tester
//     {
//      if(lparam==KEY_PAUSE)
//        {
//         pauseIsOn=false;
//         pauseCount=0;
//         pausePrice=0;
//        }
//     }
//  }
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      string clickedObject=sparam;

      // #019: implement button: Stop On Next Cycle
      if(clickedObject=="btnstopNextCycle") //stop on Next Cycle
        {
         if(stopNextCycle)
            stopNextCycle=0;
         else
           {
            retVal=MessageBox("Trading as normal, until a cycle is successfully closed?","   S T O P  N E X T  C Y C L E :",MB_YESNO);
            if(retVal==IDYES)
               stopNextCycle=1;
           }
        }
      // #011 #018: implement button: Stop On Next Cycle
      if(clickedObject=="btnrestAndRealize") //stop on Next Cycle
        {
         if(restAndRealize)
            restAndRealize=0;
         else
           {
            retVal=MessageBox("Do not open any new position. Close cycle successfully, if possible.","   R E S T  &  R E A L I Z E :",MB_YESNO);
            if(retVal==IDYES)
               restAndRealize=1;
           }
        }
      // #010: implement button: Stop & Close All
      if(clickedObject=="btnStopAll") //stop trading and close all positions
        {
         if(stopAll)
            stopAll=0;
         else
           {
            retVal=MessageBox("Close all positons and stop trading?","   S T O P  &  C L O S E :",MB_YESNO);
            if(retVal==IDYES)
               stopAll=1;
           }
        }
      // #044: Add button to show or hide comment
      if(clickedObject=="btnShowComment") //stop on Next Cycle
        {
         if(showComment)
            showComment=0;
         else
            showComment=1;
        }
      // #026: implement manual trades, if account state is not green
      if(clickedObject=="btnManualBuy")
        {
         if(accountState==as_yellow || accountState==as_red) // execute this button only, if account state is not green
           {
            retVal=MessageBox("Buy "+CalculateNextVolume(OP_BUY)+"Lot of "+Symbol()+" ?","   M A N U A L   O R D E R :",MB_YESNO);
            if(retVal==IDYES)
               NewIkarusOrder(OP_BUY,true);
           }
        }
      if(clickedObject=="btnManualSell")
        {
         if(accountState==as_yellow || accountState==as_red) // execute this button only, if account state is not green
           {
            retVal=MessageBox("Sell "+CalculateNextVolume(OP_SELL)+"Lot of "+Symbol()+" ?","   M A N U A L   O R D E R :",MB_YESNO);
            if(retVal==IDYES)
               NewIkarusOrder(OP_SELL,true);
           }
        }
      // #034: implement manual closing trades, if account state is not green
      if(clickedObject=="btnCloseLastBuy")
        {
         if(total_buy_lots>0)
           {
            if(accountState==as_yellow || accountState==as_red) // execute this button only, if account state is not green
              {
               retVal=MessageBox("Close last buy "+buy_lots[buys-1]+"Lot of "+Symbol()+" ?","   M A N U A L   O R D E R :",MB_YESNO);
               if(retVal==IDYES)
                 {
                  retVal=OrderCloseReliable(buy_tickets[buys-1],buy_lots[buys-1],MarketInfo(Symbol(),MODE_BID),slippage,Blue);
                  restAndRealize=1; // set status, that not a new position will be opened directly after closing all
                 }
              }
           }
        }
      if(clickedObject=="btnCloseLastSell")
        {
         if(total_sell_lots>0)
           {
            if(accountState==as_yellow || accountState==as_red) // execute this button only, if account state is not green
              {
               retVal=MessageBox("Close last sell "+sell_lots[sells-1]+"Lot of "+Symbol()+" ?","   M A N U A L   O R D E R :",MB_YESNO);
               if(retVal==IDYES)
                 {
                  retVal=OrderCloseReliable(sell_tickets[sells-1],sell_lots[sells-1],MarketInfo(Symbol(),MODE_ASK),slippage,Blue);
                  restAndRealize=1; // set status, that not a new position will be opened directly after closing all
                 }
              }
           }
        }
      // #035: implement manual closing trades, if account state is not green
      if(clickedObject=="btnCloseAllBuys")
        {
         if(total_buy_lots>0)
           {
            if(accountState==as_yellow || accountState==as_red) // execute this button only, if account state is not green
              {
               retVal=MessageBox("Close all "+total_buy_lots+"buy Lot of "+Symbol()+" ?","   M A N U A L   O R D E R :",MB_YESNO);
               if(retVal==IDYES)
                 {
                  CloseAllBuys();
                  // set status, that not a new position will be opened directly after alosing all
                  if(restAndRealize==0) // if not already choosen by use, set the other pause option
                     stopNextCycle=1;
                 }
              }
           }
        }
      if(clickedObject=="btnCloseAllSells")
        {
         if(total_sell_lots>0)
           {
            if(accountState==as_yellow || accountState==as_red) // execute this button only, if account state is not green
              {
               retVal=MessageBox("Close all "+total_sell_lots+"sell Lot of "+Symbol()+" ?","   M A N U A L   O R D E R :",MB_YESNO);
               if(retVal==IDYES)
                 {
                  CloseAllSells();
                  // set status, that not a new position will be opened directly after alosing all
                  if(restAndRealize==0) // if not already choosen by use, set the other pause option
                     stopNextCycle=1;
                 }
              }
           }
        }
      WriteIniData();
     }
  }
//+------------------------------------------------------------------+
//
// #006: end
// #005: end
//
//+------------------------------------------------------------------+

//=============================================================================
//							 OrderSendReliable()
//
//	This is intended to be a drop-in replacement for OrderSend() which, 
//	one hopes, is more resistant to various forms of errors prevalent 
//	with MetaTrader.
//			  
//	RETURN VALUE: 
//
//	Ticket number or -1 under some error conditions.  Check
// final error returned by Metatrader with OrderReliableLastErr().
// This will reset the value from GetLastError(), so in that sense it cannot
// be a total drop-in replacement due to Metatrader flaw. 
//
//	FEATURES:
//
//		 * Re-trying under some error conditions, sleeping a random 
//		   time defined by an exponential probability distribution.
//
//		 * Automatic normalization of Digits
//
//		 * Automatically makes sure that stop levels are more than
//		   the minimum stop distance, as given by the server. If they
//		   are too close, they are adjusted.
//
//		 * Automatically converts stop orders to market orders 
//		   when the stop orders are rejected by the server for 
//		   being to close to market.  NOTE: This intentionally
//       applies only to OP_BUYSTOP and OP_SELLSTOP, 
//       OP_BUYLIMIT and OP_SELLLIMIT are not converted to market
//       orders and so for prices which are too close to current
//       this function is likely to loop a few times and return
//       with the "invalid stops" error message. 
//       Note, the commentary in previous versions erroneously said
//       that limit orders would be converted.  Note also
//       that entering a BUYSTOP or SELLSTOP new order is distinct
//       from setting a stoploss on an outstanding order; use
//       OrderModifyReliable() for that. 
//
//		 * Displays various error messages on the log for debugging.
//
//
//	Matt Kennel, 2006-05-28 and following
//
//=============================================================================
// #001: eliminate all warnings: 
//    change internal declaration of slippage to mySlippage in all OrderSendReliable stuff
//    change internal declaration of magic to myMagic
int OrderSendReliable(string symbol,int cmd,double volume,double price,
                      int mySlippage,double stoploss,double takeprofit,
                      string comment,int myMagic,datetime expiration=0,
                      color arrow_color=CLR_NONE)
  {

// ------------------------------------------------
// Check basic conditions see if trade is possible. 
// ------------------------------------------------
   OrderReliable_Fname="OrderSendReliable";
   OrderReliablePrint(" attempted "+OrderReliable_CommandString(cmd)+" "+volume+
                      " lots @"+price+" sl:"+stoploss+" tp:"+takeprofit);

//if (!IsConnected()) 
//{
//	OrderReliablePrint("error: IsConnected() == false");
//	_OR_err = ERR_NO_CONNECTION; 
//	return(-1);
//}

   if(IsStopped())
     {
      OrderReliablePrint("error: IsStopped() == true");
      _OR_err=ERR_COMMON_ERROR;
      return(-1);
     }

   int cnt=0;
   while(!IsTradeAllowed() && cnt<retry_attempts)
     {
      OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
      cnt++;
     }

   if(!IsTradeAllowed())
     {
      OrderReliablePrint("error: no operation possible because IsTradeAllowed()==false, even after retries.");
      _OR_err=ERR_TRADE_CONTEXT_BUSY;

      return(-1);
     }

//#004 new setting: max_spread; trades only, if spread <= max spread:
   int spread=0;
   cnt=0;
// wait a bit if spread is too high
   while(cnt<retry_attempts)
     {
      spread=MarketInfo(symbol,MODE_SPREAD);
      if(spread>max_spread)
         OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
      else
         cnt=retry_attempts;   // spread is ok; go on trading
      cnt++;
     }
   if(spread>max_spread)
     {
      OrderReliablePrint(" no operation because spread: "+spread+" > max_spread: "+max_spread);
      return(-1);
     }
//#004 end

// Normalize all price / stoploss / takeprofit to the proper # of digits.
   int digits=MarketInfo(symbol,MODE_DIGITS);
   if(digits>0)
     {
      price=DoubleToString(price,digits);
      stoploss=DoubleToString(stoploss,digits);
      takeprofit=DoubleToString(takeprofit,digits);
     }

   if(stoploss!=0)
      OrderReliable_EnsureValidStop(symbol,price,stoploss);

   int err=GetLastError(); // clear the global variable.  
   err=0;
   _OR_err=0;
   bool exit_loop=false;
   bool limit_to_market=false;

// limit/stop order. 
   int ticket=-1;

   if((cmd==OP_BUYSTOP) || (cmd==OP_SELLSTOP) || (cmd==OP_BUYLIMIT) || (cmd==OP_SELLLIMIT))
     {
      cnt=0;
      while(!exit_loop)
        {
         if(IsTradeAllowed())
           {
            ticket=OrderSend(symbol,cmd,volume,price,mySlippage,stoploss,
                             takeprofit,comment,myMagic,expiration,arrow_color);
            err=GetLastError();
            _OR_err=err;
           }
         else
           {
            cnt++;
           }

         switch(err)
           {
            case ERR_NO_ERROR:
               exit_loop=true;
               break;

               // retryable errors
            case ERR_SERVER_BUSY:
            case ERR_NO_CONNECTION:
            case ERR_INVALID_PRICE:
            case ERR_OFF_QUOTES:
            case ERR_BROKER_BUSY:
            case ERR_TRADE_CONTEXT_BUSY:
               cnt++;
               break;

            case ERR_PRICE_CHANGED:
            case ERR_REQUOTE:
               RefreshRates();
               continue;   // we can apparently retry immediately according to MT docs.

            case ERR_INVALID_STOPS:
               double servers_min_stop=MarketInfo(symbol,MODE_STOPLEVEL)*MarketInfo(symbol,MODE_POINT);
               if(cmd==OP_BUYSTOP)
                 {
                  // If we are too close to put in a limit/stop order so go to market.
                  if(MathAbs(MarketInfo(symbol,MODE_ASK)-price)<=servers_min_stop)
                     limit_to_market=true;

                 }
               else if(cmd==OP_SELLSTOP)
                 {
                  // If we are too close to put in a limit/stop order so go to market.
                  if(MathAbs(MarketInfo(symbol,MODE_BID)-price)<=servers_min_stop)
                     limit_to_market=true;
                 }
               exit_loop=true;
               break;

            default:
               // an apparently serious error.
               exit_loop=true;
               break;

           }  // end switch 

         if(cnt>retry_attempts)
            exit_loop=true;

         if(exit_loop)
           {
            if(err!=ERR_NO_ERROR)
              {
               OrderReliablePrint("non-retryable error: "+OrderReliableErrTxt(err));
              }
            if(cnt>retry_attempts)
              {
               OrderReliablePrint("retry attempts maxed at "+retry_attempts);
              }
           }

         if(!exit_loop)
           {
            OrderReliablePrint("retryable error ("+cnt+"/"+retry_attempts+
                               "): "+OrderReliableErrTxt(err));
            OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
            RefreshRates();
           }
        }

      // We have now exited from loop. 
      if(err==ERR_NO_ERROR)
        {
         OrderReliablePrint("apparently successful OP_BUYSTOP or OP_SELLSTOP order placed, details follow.");
         // #001: eliminate all warnings:
         bool retVal=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
         OrderPrint();
         return(ticket); // SUCCESS! 
        }
      if(!limit_to_market)
        {
         OrderReliablePrint("failed to execute stop or limit order after "+cnt+" retries");
         OrderReliablePrint("failed trade: "+OrderReliable_CommandString(cmd)+" "+symbol+
                            "@"+price+" tp@"+takeprofit+" sl@"+stoploss);
         OrderReliablePrint("last error: "+OrderReliableErrTxt(err));
         return(-1);
        }
     }  // end	  

   if(limit_to_market)
     {
      OrderReliablePrint("going from limit order to market order because market is too close.");
      if((cmd==OP_BUYSTOP) || (cmd==OP_BUYLIMIT))
        {
         cmd=OP_BUY;
         price=MarketInfo(symbol,MODE_ASK);
        }
      else if((cmd==OP_SELLSTOP) || (cmd==OP_SELLLIMIT))
        {
         cmd=OP_SELL;
         price=MarketInfo(symbol,MODE_BID);
        }
     }

// we now have a market order.
   err=GetLastError(); // so we clear the global variable.  
   err= 0;
   _OR_err= 0;
   ticket = -1;

   if((cmd==OP_BUY) || (cmd==OP_SELL))
     {
      cnt=0;
      while(!exit_loop)
        {
         if(IsTradeAllowed())
           {
            ticket=OrderSend(symbol,cmd,volume,price,mySlippage,
                             stoploss,takeprofit,comment,myMagic,
                             expiration,arrow_color);
            err=GetLastError();
            _OR_err=err;
           }
         else
           {
            cnt++;
           }
         switch(err)
           {
            case ERR_NO_ERROR:
               exit_loop=true;
               break;

            case ERR_SERVER_BUSY:
            case ERR_NO_CONNECTION:
            case ERR_INVALID_PRICE:
            case ERR_OFF_QUOTES:
            case ERR_BROKER_BUSY:
            case ERR_TRADE_CONTEXT_BUSY:
               cnt++; // a retryable error
               break;

            case ERR_PRICE_CHANGED:
            case ERR_REQUOTE:
               RefreshRates();
               continue; // we can apparently retry immediately according to MT docs.

            default:
               // an apparently serious, unretryable error.
               exit_loop=true;
               break;

           }  // end switch 

         if(cnt>retry_attempts)
            exit_loop=true;

         if(!exit_loop)
           {
            OrderReliablePrint("retryable error ("+cnt+"/"+
                               retry_attempts+"): "+OrderReliableErrTxt(err));
            OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
            RefreshRates();
           }

         if(exit_loop)
           {
            if(err!=ERR_NO_ERROR)
              {
               OrderReliablePrint("non-retryable error: "+OrderReliableErrTxt(err));
              }
            if(cnt>retry_attempts)
              {
               OrderReliablePrint("retry attempts maxed at "+retry_attempts);
              }
           }
        }

      // we have now exited from loop. 
      if(err==ERR_NO_ERROR)
        {
         //#004 new setting: max_spread; add spread info for this position
         OrderReliablePrint("apparently successful OP_BUY or OP_SELL order placed(spread: "+spread+"), details follow.");
         // #001: eliminate all warnings:
         retVal=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
         OrderPrint();
         return(ticket); // SUCCESS! 
        }
      OrderReliablePrint("failed to execute OP_BUY/OP_SELL, after "+cnt+" retries");
      OrderReliablePrint("failed trade: "+OrderReliable_CommandString(cmd)+" "+symbol+
                         "@"+price+" tp@"+takeprofit+" sl@"+stoploss);
      OrderReliablePrint("last error: "+OrderReliableErrTxt(err));
      return(-1);
     }
// #001: eliminate all warnings:
   return(-1);
  }
//=============================================================================
//							 OrderSendReliableMKT()
//
//	This is intended to be an alternative for OrderSendReliable() which
// will update market-orders in the retry loop with the current Bid or Ask.
// Hence with market orders there is a greater likelihood that the trade will
// be executed versus OrderSendReliable(), and a greater likelihood it will
// be executed at a price worse than the entry price due to price movement. 
//			  
//	RETURN VALUE: 
//
//	Ticket number or -1 under some error conditions.  Check
// final error returned by Metatrader with OrderReliableLastErr().
// This will reset the value from GetLastError(), so in that sense it cannot
// be a total drop-in replacement due to Metatrader flaw. 
//
//	FEATURES:
//
//     * Most features of OrderSendReliable() but for market orders only. 
//       Command must be OP_BUY or OP_SELL, and specify Bid or Ask at
//       the time of the call.
//
//     * If price moves in an unfavorable direction during the loop,
//       e.g. from requotes, then the slippage variable it uses in 
//       the real attempt to the server will be decremented from the passed
//       value by that amount, down to a minimum of zero.   If the current
//       price is too far from the entry value minus slippage then it
//       will not attempt an order, and it will signal, manually,
//       an ERR_INVALID_PRICE (displayed to log as usual) and will continue
//       to loop the usual number of times. 
//
//		 * Displays various error messages on the log for debugging.
//
//
//	Matt Kennel, 2006-08-16
//
//=============================================================================
int OrderSendReliableMKT(string symbol,int cmd,double volume,double price,
                         int mySlippage,double stoploss,double takeprofit,
                         string comment,int myMagic,datetime expiration=0,
                         color arrow_color=CLR_NONE)
  {

// ------------------------------------------------
// Check basic conditions see if trade is possible. 
// ------------------------------------------------
   OrderReliable_Fname="OrderSendReliableMKT";
   OrderReliablePrint(" attempted "+OrderReliable_CommandString(cmd)+" "+volume+
                      " lots @"+price+" sl:"+stoploss+" tp:"+takeprofit);

   if((cmd!=OP_BUY) && (cmd!=OP_SELL))
     {
      OrderReliablePrint("Improper non market-order command passed.  Nothing done.");
      _OR_err=ERR_MALFUNCTIONAL_TRADE;
      return(-1);
     }

//if (!IsConnected()) 
//{
//	OrderReliablePrint("error: IsConnected() == false");
//	_OR_err = ERR_NO_CONNECTION; 
//	return(-1);
//}

   if(IsStopped())
     {
      OrderReliablePrint("error: IsStopped() == true");
      _OR_err=ERR_COMMON_ERROR;
      return(-1);
     }

   int cnt=0;
   while(!IsTradeAllowed() && cnt<retry_attempts)
     {
      OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
      cnt++;
     }

   if(!IsTradeAllowed())
     {
      OrderReliablePrint("error: no operation possible because IsTradeAllowed()==false, even after retries.");
      _OR_err=ERR_TRADE_CONTEXT_BUSY;

      return(-1);
     }

// Normalize all price / stoploss / takeprofit to the proper # of digits.
   int digits=MarketInfo(symbol,MODE_DIGITS);
   if(digits>0)
     {
      price=DoubleToString(price,digits);
      stoploss=DoubleToString(stoploss,digits);
      takeprofit=DoubleToString(takeprofit,digits);
     }

   if(stoploss!=0)
      OrderReliable_EnsureValidStop(symbol,price,stoploss);

   int err=GetLastError(); // clear the global variable.  
   err=0;
   _OR_err=0;
   bool exit_loop=false;

// limit/stop order. 
   int ticket=-1;

// we now have a market order.
   err=GetLastError(); // so we clear the global variable.  
   err= 0;
   _OR_err= 0;
   ticket = -1;

   if((cmd==OP_BUY) || (cmd==OP_SELL))
     {
      cnt=0;
      while(!exit_loop)
        {
         if(IsTradeAllowed())
           {
            double pnow=price;
            int slippagenow=mySlippage;
            if(cmd==OP_BUY)
              {
               // modification by Paul Hampton-Smith to replace RefreshRates()
               pnow=DoubleToString(MarketInfo(symbol,MODE_ASK),MarketInfo(symbol,MODE_DIGITS)); // we are buying at Ask
               if(pnow>price)
                 {
                  slippagenow=mySlippage -(pnow-price)/MarketInfo(symbol,MODE_POINT);
                 }
                 } else if(cmd==OP_SELL) {
               // modification by Paul Hampton-Smith to replace RefreshRates()
               pnow=DoubleToString(MarketInfo(symbol,MODE_BID),MarketInfo(symbol,MODE_DIGITS)); // we are buying at Ask
               if(pnow<price)
                 {
                  // moved in an unfavorable direction
                  slippagenow=mySlippage -(price-pnow)/MarketInfo(symbol,MODE_POINT);
                 }
              }
            if(slippagenow>mySlippage) slippagenow=mySlippage;
            if(slippagenow>=0)
              {

               ticket=OrderSend(symbol,cmd,volume,pnow,slippagenow,
                                stoploss,takeprofit,comment,myMagic,
                                expiration,arrow_color);
               err=GetLastError();
               _OR_err=err;
                 } else {
               // too far away, manually signal ERR_INVALID_PRICE, which
               // will result in a sleep and a retry. 
               err=ERR_INVALID_PRICE;
               _OR_err=err;
              }
           }
         else
           {
            cnt++;
           }
         switch(err)
           {
            case ERR_NO_ERROR:
               exit_loop=true;
               break;

            case ERR_SERVER_BUSY:
            case ERR_NO_CONNECTION:
            case ERR_INVALID_PRICE:
            case ERR_OFF_QUOTES:
            case ERR_BROKER_BUSY:
            case ERR_TRADE_CONTEXT_BUSY:
               cnt++; // a retryable error
               break;

            case ERR_PRICE_CHANGED:
            case ERR_REQUOTE:
               // Paul Hampton-Smith removed RefreshRates() here and used MarketInfo() above instead
               continue; // we can apparently retry immediately according to MT docs.

            default:
               // an apparently serious, unretryable error.
               exit_loop=true;
               break;

           }  // end switch 

         if(cnt>retry_attempts)
            exit_loop=true;

         if(!exit_loop)
           {
            OrderReliablePrint("retryable error ("+cnt+"/"+
                               retry_attempts+"): "+OrderReliableErrTxt(err));
            OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
           }

         if(exit_loop)
           {
            if(err!=ERR_NO_ERROR)
              {
               OrderReliablePrint("non-retryable error: "+OrderReliableErrTxt(err));
              }
            if(cnt>retry_attempts)
              {
               OrderReliablePrint("retry attempts maxed at "+retry_attempts);
              }
           }
        }

      // we have now exited from loop. 
      if(err==ERR_NO_ERROR)
        {
         OrderReliablePrint("apparently successful OP_BUY or OP_SELL order placed, details follow.");
         // #001: eliminate all warnings:
         bool retVal=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
         OrderPrint();
         return(ticket); // SUCCESS! 
        }
      OrderReliablePrint("failed to execute OP_BUY/OP_SELL, after "+cnt+" retries");
      OrderReliablePrint("failed trade: "+OrderReliable_CommandString(cmd)+" "+symbol+
                         "@"+price+" tp@"+takeprofit+" sl@"+stoploss);
      OrderReliablePrint("last error: "+OrderReliableErrTxt(err));
      return(-1);
     }
// #001: eliminate all warnings:
   return(-1);
  }
//=============================================================================
//							 OrderModifyReliable()
//
//	This is intended to be a drop-in replacement for OrderModify() which, 
//	one hopes, is more resistant to various forms of errors prevalent 
//	with MetaTrader.
//			  
//	RETURN VALUE: 
//
//		TRUE if successful, FALSE otherwise
//
//
//	FEATURES:
//
//		 * Re-trying under some error conditions, sleeping a random 
//		   time defined by an exponential probability distribution.
//
//		 * Displays various error messages on the log for debugging.
//
//
//	Matt Kennel, 	2006-05-28
//
//=============================================================================
bool OrderModifyReliable(int ticket,double price,double stoploss,
                         double takeprofit,datetime expiration,
                         color arrow_color=CLR_NONE)
  {
   OrderReliable_Fname="OrderModifyReliable";

   OrderReliablePrint(" attempted modify of #"+ticket+" price:"+price+
                      " sl:"+stoploss+" tp:"+takeprofit);

//if (!IsConnected()) 
//{
//	OrderReliablePrint("error: IsConnected() == false");
//	_OR_err = ERR_NO_CONNECTION; 
//	return(false);
//}

   if(IsStopped())
     {
      OrderReliablePrint("error: IsStopped() == true");
      return(false);
     }

   int cnt=0;
   while(!IsTradeAllowed() && cnt<retry_attempts)
     {
      OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
      cnt++;
     }
   if(!IsTradeAllowed())
     {
      OrderReliablePrint("error: no operation possible because IsTradeAllowed()==false, even after retries.");
      _OR_err=ERR_TRADE_CONTEXT_BUSY;
      return(false);
     }

   if(false)
     {
      // This section is 'nulled out', because
      // it would have to involve an 'OrderSelect()' to obtain
      // the symbol string, and that would change the global context of the
      // existing OrderSelect, and hence would not be a drop-in replacement
      // for OrderModify().
      //
      // See OrderModifyReliableSymbol() where the user passes in the Symbol 
      // manually.

      // #001: eliminate all warnings:
      bool retVal=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
      string symbol=OrderSymbol();
      int digits=MarketInfo(symbol,MODE_DIGITS);
      if(digits>0)
        {
         price=DoubleToString(price,digits);
         stoploss=DoubleToString(stoploss,digits);
         takeprofit=DoubleToString(takeprofit,digits);
        }
      if(stoploss!=0) OrderReliable_EnsureValidStop(symbol,price,stoploss);
     }

   int err=GetLastError(); // so we clear the global variable.  
   err=0;
   _OR_err=0;
   bool exit_loop=false;
   cnt=0;
   bool result=false;

   while(!exit_loop)
     {
      if(IsTradeAllowed())
        {
         result=OrderModify(ticket,price,stoploss,
                            takeprofit,expiration,arrow_color);
         err=GetLastError();
         _OR_err=err;
        }
      else
         cnt++;

      if(result==true)
         exit_loop=true;

      switch(err)
        {
         case ERR_NO_ERROR:
            exit_loop=true;
            break;

         case ERR_NO_RESULT:
            // modification without changing a parameter. 
            // if you get this then you may want to change the code.
            exit_loop=true;
            break;

         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TRADE_CONTEXT_BUSY:
         case ERR_TRADE_TIMEOUT:      // for modify this is a retryable error, I hope. 
            cnt++;    // a retryable error
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            RefreshRates();
            continue;    // we can apparently retry immediately according to MT docs.

         default:
            // an apparently serious, unretryable error.
            exit_loop=true;
            break;

        }  // end switch 

      if(cnt>retry_attempts)
         exit_loop=true;

      if(!exit_loop)
        {
         OrderReliablePrint("retryable error ("+cnt+"/"+retry_attempts+
                            "): "+OrderReliableErrTxt(err));
         OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
         RefreshRates();
        }

      if(exit_loop)
        {
         if((err!=ERR_NO_ERROR) && (err!=ERR_NO_RESULT))
            OrderReliablePrint("non-retryable error: "+OrderReliableErrTxt(err));

         if(cnt>retry_attempts)
            OrderReliablePrint("retry attempts maxed at "+retry_attempts);
        }
     }

// we have now exited from loop. 
   if((result==true) || (err==ERR_NO_ERROR))
     {
      OrderReliablePrint("apparently successful modification order, updated trade details follow.");
      // #001: eliminate all warnings:
      retVal=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
      OrderPrint();
      return(true); // SUCCESS! 
     }

   if(err==ERR_NO_RESULT)
     {
      OrderReliablePrint("Server reported modify order did not actually change parameters.");
      OrderReliablePrint("redundant modification: "+ticket+" "+symbol+
                         "@"+price+" tp@"+takeprofit+" sl@"+stoploss);
      OrderReliablePrint("Suggest modifying code logic to avoid.");
      return(true);
     }

   OrderReliablePrint("failed to execute modify after "+cnt+" retries");
   OrderReliablePrint("failed modification: "+ticket+" "+symbol+
                      "@"+price+" tp@"+takeprofit+" sl@"+stoploss);
   OrderReliablePrint("last error: "+OrderReliableErrTxt(err));

   return(false);
  }
//=============================================================================
//
//						OrderModifyReliableSymbol()
//
//	This has the same calling sequence as OrderModify() except that the 
//	user must provide the symbol.
//
//	This function will then be able to ensure proper normalization and 
//	stop levels.
//
//=============================================================================
bool OrderModifyReliableSymbol(string symbol,int ticket,double price,
                               double stoploss,double takeprofit,
                               datetime expiration,color arrow_color=CLR_NONE)
  {
   int digits=MarketInfo(symbol,MODE_DIGITS);

   if(digits>0)
     {
      price=DoubleToString(price,digits);
      stoploss=DoubleToString(stoploss,digits);
      takeprofit=DoubleToString(takeprofit,digits);
     }

   if(stoploss!=0)
      OrderReliable_EnsureValidStop(symbol,price,stoploss);

   return(OrderModifyReliable(ticket, price, stoploss,
          takeprofit,expiration,arrow_color));

  }
//=============================================================================
//							 OrderCloseReliable()
//
//	This is intended to be a drop-in replacement for OrderClose() which, 
//	one hopes, is more resistant to various forms of errors prevalent 
//	with MetaTrader.
//			  
//	RETURN VALUE: 
//
//		TRUE if successful, FALSE otherwise
//
//
//	FEATURES:
//
//		 * Re-trying under some error conditions, sleeping a random 
//		   time defined by an exponential probability distribution.
//
//		 * Displays various error messages on the log for debugging.
//
//
//	Derk Wehler, ashwoods155@yahoo.com  	2006-07-19
//
//=============================================================================
bool OrderCloseReliable(int ticket,double lots,double price,
                        int mySlippage,color arrow_color=CLR_NONE)
  {
   int nOrderType;
   string strSymbol;
   OrderReliable_Fname="OrderCloseReliable";

   OrderReliablePrint(" attempted close of #"+ticket+" price:"+price+
                      " lots:"+lots+" slippage:"+mySlippage);

// collect details of order so that we can use GetMarketInfo later if needed
   if(!OrderSelect(ticket,SELECT_BY_TICKET))
     {
      _OR_err=GetLastError();
      OrderReliablePrint("error: "+ErrorDescription(_OR_err));
      return(false);
     }
   else
     {
      nOrderType= OrderType();
      strSymbol = OrderSymbol();
     }

   if(nOrderType!=OP_BUY && nOrderType!=OP_SELL)
     {
      _OR_err=ERR_INVALID_TICKET;
      OrderReliablePrint("error: trying to close ticket #"+ticket+", which is "+OrderReliable_CommandString(nOrderType)+", not OP_BUY or OP_SELL");
      return(false);
     }

//if (!IsConnected()) 
//{
//	OrderReliablePrint("error: IsConnected() == false");
//	_OR_err = ERR_NO_CONNECTION; 
//	return(false);
//}

   if(IsStopped())
     {
      OrderReliablePrint("error: IsStopped() == true");
      return(false);
     }

   int cnt=0;
/*	
	Commented out by Paul Hampton-Smith due to a bug in MT4 that sometimes incorrectly returns IsTradeAllowed() = false
	while(!IsTradeAllowed() && cnt < retry_attempts) 
	{
		OrderReliable_SleepRandomTime(sleep_time,sleep_maximum); 
		cnt++;
	}
	if (!IsTradeAllowed()) 
	{
		OrderReliablePrint("error: no operation possible because IsTradeAllowed()==false, even after retries.");
		_OR_err = ERR_TRADE_CONTEXT_BUSY; 
		return(false);  
	}
*/

   int err=GetLastError(); // so we clear the global variable.  
   err=0;
   _OR_err=0;
   bool exit_loop=false;
   cnt=0;
   bool result=false;

   while(!exit_loop)
     {
      if(IsTradeAllowed())
        {
         result=OrderClose(ticket,lots,price,mySlippage,arrow_color);
         err=GetLastError();
         _OR_err=err;
        }
      else
         cnt++;

      if(result==true)
         exit_loop=true;

      switch(err)
        {
         case ERR_NO_ERROR:
            exit_loop=true;
            break;

         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TRADE_CONTEXT_BUSY:
         case ERR_TRADE_TIMEOUT:      // for modify this is a retryable error, I hope. 
            cnt++;    // a retryable error
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            continue;    // we can apparently retry immediately according to MT docs.

         default:
            // an apparently serious, unretryable error.
            exit_loop=true;
            break;

        }  // end switch 

      if(cnt>retry_attempts)
         exit_loop=true;

      if(!exit_loop)
        {
         OrderReliablePrint("retryable error ("+cnt+"/"+retry_attempts+
                            "): "+OrderReliableErrTxt(err));
         OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
         // Added by Paul Hampton-Smith to ensure that price is updated for each retry
         if(nOrderType == OP_BUY)  price = DoubleToString(MarketInfo(strSymbol,MODE_BID),MarketInfo(strSymbol,MODE_DIGITS));
         if(nOrderType == OP_SELL) price = DoubleToString(MarketInfo(strSymbol,MODE_ASK),MarketInfo(strSymbol,MODE_DIGITS));
        }

      if(exit_loop)
        {
         if((err!=ERR_NO_ERROR) && (err!=ERR_NO_RESULT))
            OrderReliablePrint("non-retryable error: "+OrderReliableErrTxt(err));

         if(cnt>retry_attempts)
            OrderReliablePrint("retry attempts maxed at "+retry_attempts);
        }
     }

// we have now exited from loop. 
   if((result==true) || (err==ERR_NO_ERROR))
     {
      OrderReliablePrint("apparently successful close order, updated trade details follow.");
      // #001: eliminate all warnings:
      bool retVal=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
      OrderPrint();
      return(true); // SUCCESS! 
     }

   OrderReliablePrint("failed to execute close after "+cnt+" retries");
   OrderReliablePrint("failed close: Ticket #"+ticket+", Price: "+
                      price+", Slippage: "+mySlippage);
   OrderReliablePrint("last error: "+OrderReliableErrTxt(err));

   return(false);
  }
//=============================================================================
//=============================================================================
//								Utility Functions
//=============================================================================
//=============================================================================



int OrderReliableLastErr()
  {
   return (_OR_err);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string OrderReliableErrTxt(int err)
  {
   return ("" + err + ":" + ErrorDescription(err));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderReliablePrint(string s)
  {
// Print to log prepended with stuff;
   if(!(IsTesting() || IsOptimization())) Print(OrderReliable_Fname+" "+OrderReliableVersion+":"+s);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string OrderReliable_CommandString(int cmd)
  {
   if(cmd==OP_BUY)
      return("OP_BUY");

   if(cmd==OP_SELL)
      return("OP_SELL");

   if(cmd==OP_BUYSTOP)
      return("OP_BUYSTOP");

   if(cmd==OP_SELLSTOP)
      return("OP_SELLSTOP");

   if(cmd==OP_BUYLIMIT)
      return("OP_BUYLIMIT");

   if(cmd==OP_SELLLIMIT)
      return("OP_SELLLIMIT");

   return("(CMD==" + cmd + ")");
  }
//=============================================================================
//
//						 OrderReliable_EnsureValidStop()
//
// 	Adjust stop loss so that it is legal.
//
//	Matt Kennel 
//
//=============================================================================
void OrderReliable_EnsureValidStop(string symbol,double price,double &sl)
  {
// Return if no S/L
   if(sl==0)
      return;

   double servers_min_stop=MarketInfo(symbol,MODE_STOPLEVEL)*MarketInfo(symbol,MODE_POINT);

   if(MathAbs(price-sl)<=servers_min_stop)
     {
      // we have to adjust the stop.
      if(price>sl)
         sl=price-servers_min_stop;   // we are long

      else if(price<sl)
         sl=price+servers_min_stop;   // we are short

      else
         OrderReliablePrint("EnsureValidStop: error, passed in price == sl, cannot adjust");

      sl=DoubleToString(sl,MarketInfo(symbol,MODE_DIGITS));
     }
  }
//=============================================================================
//
//						 OrderReliable_SleepRandomTime()
//
//	This sleeps a random amount of time defined by an exponential 
//	probability distribution. The mean time, in Seconds is given 
//	in 'mean_time'.
//
//	This is the back-off strategy used by Ethernet.  This will 
//	quantize in tenths of seconds, so don't call this with a too 
//	small a number.  This returns immediately if we are backtesting
//	and does not sleep.
//
//	Matt Kennel mbkennelfx@gmail.com.
//
//=============================================================================
void OrderReliable_SleepRandomTime(double mean_time,double max_time)
  {
   if(IsTesting())
      return;    // return immediately if backtesting.

   double tenths=MathCeil(mean_time/0.1);
   if(tenths<=0)
      return;

   int maxtenths=MathRound(max_time/0.1);
   double p=1.0-1.0/tenths;

   Sleep(100);    // one tenth of a second PREVIOUS VERSIONS WERE STUPID HERE. 

   for(int i=0; i<maxtenths; i++)
     {
      if(MathRand()>p*32768)
         break;

      // MathRand() returns in 0..32767
      Sleep(100);
     }
  }
//+------------------------------------------------------------------+

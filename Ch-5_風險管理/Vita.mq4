//+------------------------------------------------------------------+
//|                                                         Vita.mq4 |
//+------------------------------------------------------------------+

//---- input parameters
extern double    Lots=0.1;
extern int       Slip=5;
extern string    StopSettings="Set stops below";
extern double    TakeProfit=120;
extern double    StopLoss=800;
extern string    PSARsettings="Parabolic sar settings follow";
extern double    Step    =0.001;   //Parabolic setting
extern double    Maximum =0.2;     //Parabolic setting
extern bool      CloseOnOpposite=true;
extern string    TimeSettings="Set the hour range the EA should trade";
extern int       StartHour=0;
extern int       EndHour=23;
 
int MagicNumber1=220101,MagicNumber2=220102;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----

//----
   return(0);
  }
  
int deinit()
  {
    double   AB=AccountBalance(); 
    int     tickets[],      nTickets = GetHistoryOrderByCloseTime(tickets);
  
    double  balances[];     ArrayResize(balances,  nTickets+1);
    double  prevBal = AB;
    
    // is counting from end balance down to start balance , hence taking off wins and adding losses
    for(int iTicket = 0; iTicket < nTickets; iTicket++)               
    {
     if ( OrderSelect(tickets[iTicket], SELECT_BY_TICKET))                  
     {
        double  profit  = OrderProfit() + OrderSwap() + OrderCommission();
        if((profit<0)==1){ prevBal += MathAbs(profit); }
        else if((profit>0)==1){ prevBal -= MathAbs(profit); }  
        balances[iTicket]   = prevBal;  
        //Print("nTickets ", nTickets ,"iTicket ", iTicket ," profit ", profit," prevBal ", prevBal, "great ",profit > 0, "less  ",profit < 0);
     }
    // balances[nTickets]  = prevBal;
   } 

   double AHPR = 0 ;
   double res1 = GetSharpFromArray(AHPR, balances,0,true);
    Alert(" res1 ", res1 ," AHPR  ", AHPR ); 
  }
    
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
int digits=MarketInfo(Symbol(),MODE_DIGITS);
int StopMultd=10;
int Slippage=Slip*StopMultd;

int  i,closesell=0,closebuy=0;

double   TP=NormalizeDouble(TakeProfit*StopMultd,Digits);
double   SL=NormalizeDouble(StopLoss*StopMultd,Digits);
double   slb=NormalizeDouble(Ask-SL*Point,Digits);
double   sls=NormalizeDouble(Bid+SL*Point,Digits);
double   tpb=NormalizeDouble(Ask+TP*Point,Digits);
double   tps=NormalizeDouble(Bid-TP*Point,Digits);

//-------------------------------------------------------------------+
//Check open orders
//-------------------------------------------------------------------+
if(OrdersTotal()>0){
  for(i=1; i<=OrdersTotal(); i++)               // Cycle searching in orders
     {
      if (OrderSelect(i-1,SELECT_BY_POS)==true) // If the next is available
        {
          if(OrderMagicNumber()==MagicNumber1) {int halt1=1;}
          if(OrderMagicNumber()==MagicNumber2) {int halt2=1;}
        }
     }
}


//-------------------------------------------------------------------+
// time check
//-------------------------------------------------------------------
if((Hour()>=StartHour)&&(Hour()<=EndHour))
{
   int TradeTimeOk=1;
}
else
{ TradeTimeOk=0; }

//-----------------------------------------------------------------------------------------------------
// Opening criteria
//-----------------------------------------------------------------------------------------------------
// Open buy
 if((iSAR(NULL, 0,Step,Maximum, 0)<iClose(NULL,0,0))&&(iSAR(NULL, 0,Step,Maximum, 1)>iClose(NULL,0,1))&&(TradeTimeOk==1)&&(halt1!=1))
 {
    int openbuy=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,"PSAR trader buy order",MagicNumber1,0,Blue);
    if(CloseOnOpposite==true)closesell=1;
 }

// Open sell
 if((iSAR(NULL, 0,Step,Maximum, 0)>iClose(NULL,0,0))&&(iSAR(NULL, 0,Step,Maximum, 1)<iClose(NULL,0,1))&&(TradeTimeOk==1)&&(halt2!=1))
 {
    int opensell=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,"PSAR trader sell order",MagicNumber2,0,Green);
    if(CloseOnOpposite==true)closebuy=1;
 }


//-------------------------------------------------------------------------------------------------
// Closing criteria
//-------------------------------------------------------------------------------------------------
if(closesell==1||closebuy==1||openbuy<1||opensell<1)
{
   if(OrdersTotal()>0)
   {
     for(i=1; i<=OrdersTotal(); i++)
     {          
      if (OrderSelect(i-1,SELECT_BY_POS)==true)
      {
        
          if(OrderMagicNumber()==MagicNumber1&&closebuy==1) { OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,CLR_NONE); }
          if(OrderMagicNumber()==MagicNumber2&&closesell==1) { OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,CLR_NONE); }
          
          if((OrderMagicNumber()==MagicNumber1)&&(OrderTakeProfit()==0)&&(OrderSymbol()==Symbol())){ OrderModify(OrderTicket(),0,OrderStopLoss(),tpb,0,CLR_NONE); }
          if((OrderMagicNumber()==MagicNumber2)&&(OrderTakeProfit()==0)&&(OrderSymbol()==Symbol())){ OrderModify(OrderTicket(),0,OrderStopLoss(),tps,0,CLR_NONE); }
          if((OrderMagicNumber()==MagicNumber1)&&(OrderStopLoss()==0)&&(OrderSymbol()==Symbol())){ OrderModify(OrderTicket(),0,slb,OrderTakeProfit(),0,CLR_NONE); }
          if((OrderMagicNumber()==MagicNumber2)&&(OrderStopLoss()==0)&&(OrderSymbol()==Symbol())){ OrderModify(OrderTicket(),0,sls,OrderTakeProfit(),0,CLR_NONE); }
       }
      }
   }
}

int Error=GetLastError();
  if(Error==130){Alert("Wrong stops. Retrying."); RefreshRates();}
  if(Error==133){Alert("Trading prohibited.");}
  if(Error==2){Alert("Common error.");}
  if(Error==146){Alert("Trading subsystem is busy. Retrying."); Sleep(500); RefreshRates();}

//-------------------------------------------------------------------
   return(0);
  }
//+------------------------------------------------------------------+

// RiskFreeRate 絕對值，
//如果無風險利率是1.2%，那要轉為0.012
//如果無風險利率是2.0%，那要轉為0.02

double GetSharpFromArray(double & AHPR, double BalanceArray[],double RiskFreeRate=0,bool direct=true)
   {
   double res,Std;

   int i,limit=ArraySize(BalanceArray);
   if (limit<2) 
      {
      Print("沒有足夠數據 !");
      return(0);
      }

   double HPR[];
   int N=limit-1;

   ArrayResize(HPR,limit-1);   
   if (direct)
      {
      for (i=1;i<limit;i++)
         {
         if (BalanceArray[i-1]!=0) 
            {
            HPR[i-1]=BalanceArray[i]/BalanceArray[i-1];
            AHPR+=HPR[i-1];
            //Print("i=",i-1,"  Balance[",i,"]=",BalanceArray[i-1],"   HPR[",i,"]=",HPR[i-1]);
            }
         }
      }
   else
      {
      for (i=limit-2;i>=0;i--)
         {
         if (BalanceArray[i+1]!=0) 
            {
            HPR[i]=BalanceArray[i]/BalanceArray[i+1];
            AHPR+=HPR[i];
            //Print("i=",i,"  Balance[",i,"]=",BalanceArray[i],"   HPR[",i,"]=",HPR[i]);
            }
         }
      }
   AHPR=AHPR/(N);
   
   for (i=0;i<N-1;i++)
      {
      Std+=(AHPR-HPR[i])*(AHPR-HPR[i]);
      }
   Std=MathPow(Std/(N-1),0.5);
   res=(AHPR-(1.0+RiskFreeRate))/Std;
//----
   return(res);
   }
 
 int GetHistoryOrderByCloseTime(int& tickets[], int dsc=1){  #define ASCENDING -1
    /* https://forum.mql4.com/46182 zzuegg says history ordering "is not reliable
     * (as said in the doc)" [not in doc] dabbler says "the order of entries is
     * mysterious (by actual test)" */
    int nOrders = 0;    datetime OCTs[];
    for(int iPos=OrdersHistoryTotal()-1; iPos >= 0; iPos--) if (
        OrderSelect(iPos, SELECT_BY_POS, MODE_HISTORY)  // Only orders w/
    && ( OrderMagicNumber()  == MagicNumber1  ||  OrderMagicNumber()  == MagicNumber2 )           // my magic number
    &&  OrderSymbol()       == Symbol()             // and my pair.
    &&  OrderType()         <= OP_SELL//Avoid cr/bal forum.mql4.com/32363#325360
    ){
        int nextTkt = OrderTicket();        datetime nextOCT = OrderCloseTime();
        nOrders++; ArrayResize(tickets,nOrders); ArrayResize(OCTs,nOrders);
        for (int iOrders=nOrders - 1; iOrders > 0; iOrders--){  // Insertn sort.
            datetime    prevOCT     = OCTs[iOrders-1];
            if ((prevOCT - nextOCT) * dsc >= 0)     break;
            int         prevTkt = tickets[iOrders-1];
            tickets[iOrders] = prevTkt;    OCTs[iOrders] = prevOCT;
        }
        tickets[iOrders] = nextTkt;    OCTs[iOrders] = nextOCT; // Insert.
    }
    return(nOrders);
}
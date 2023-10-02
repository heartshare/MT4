#define ExpertName   "Reverse Victory"
#define Copyright    "Findex ©2020"
#property copyright  Copyright
#define EAID   "RV_UBDS"  //EA orders identifier
#define Version      "1.0" 
#property version    Version
#define MAGIC  69
string   Comm;          

extern double  RV_Multiplier = 1.45;   //逆轉乘數
extern int     RV_TriggerPoints = 10000; //對沖啟動距離
extern double  Lots = 0.1;             //起始手數,0:預設餘額0.1%
extern double  PackageTakeProfit = 10; //獲利平倉目標(dollar),0:預設餘額10%
extern int     RiskPercent = 75;       //風險上限%，鎖倉,0:預設餘額10%
extern int     Slippage = 50;          //滑價
extern int     Time_Frame=15;          //時框

//extern bool    AutoTrade = TRUE;          //自動
//extern double  UpperHedgeBound = 1.14500; //手動價，上框
//extern double  LowerHedgeBound = 1.14000; //手動價，下框

//Internal Variables
int PendingBuy, PendingSell, Buys, Sells, i, Spread;
double BuyLots, SellLots, PendingBuyLots, PendingSellLots;
double CheckPoint, Profit, Risk, UpExit, DwExit;

//+------------------------------------------------------------------+
//| Init function                                                    |
//+------------------------------------------------------------------+
void init()
  {
   //Comm=StringConcatenate( EAID,"-",_Symbol, MAGIC );
   Comm=StringConcatenate( EAID,"-", MAGIC );
   Spread=MarketInfo(Symbol(),MODE_SPREAD);
  }
//+------------------------------------------------------------------+
//| Start function                                                   |
//+------------------------------------------------------------------+
void start()
  {
   
   if(Lots==0){Lots = MathRound(AccountBalance()/1000)/100;}         //Default 0.1% 
   if(PackageTakeProfit==0){PackageTakeProfit=AccountBalance()/1000;}//Default 10%
   
   Count();
   //---core Procedure
   if(BuyLots+SellLots != 0 && CheckPoint==0 )//Need to retrievel last checkponint for restart session
   {
      for(int i=(OrdersHistoryTotal()-1); i>=0;i--)
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         {
            if(OrderSymbol()==_Symbol && OrderMagicNumber()==MAGIC)
              {
               if(OrderType()==ORDER_TYPE_BUY)
               {
                  CheckPoint=OrderOpenPrice()-RV_TriggerPoints*Point;
                  break;
               }
               if(OrderType()==ORDER_TYPE_SELL)
               {
                  CheckPoint=OrderOpenPrice()+RV_TriggerPoints*Point;
                  break;
               }
              }   
          }        
    }
          
   CheckForRV();
   if (Buys==0 && Sells==0) {CheckForOpen();}
   else{CheckForClose();}
   
   Comment("Profit Goal= $ ",PackageTakeProfit,";\n;\n","Floating Gain= $ ",Profit,";\n;\n",
          "Buy=",Buys,"; BuyLots=",BuyLots,";\n;\n","Sell=", Sells,"; SellLots=",SellLots,";\n;\n",
          "UpExit=",UpExit," DwExit=",DwExit);
   //---End of MAIN Procedure
           
  }

//---------------------------------------------------------------------------         
int CheckForOpen()
{
  Count();
  //if(AutoTrade)
  //  {
     //double SAR=iSAR(NULL,0,0.02,0.2,0);
     double UBB =iBands(NULL,Time_Frame,20,2,0,PRICE_TYPICAL,MODE_UPPER,0);
     double LBB =iBands(NULL,Time_Frame,20,2,0,PRICE_TYPICAL,MODE_LOWER,0);
     if(Ask>=UBB){
                  OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,Comm,MAGIC,0,clrRed); CheckPoint=Bid+RV_TriggerPoints*Point;
                 }
     if(Bid<=LBB){
                  OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,Comm,MAGIC,0,clrBlue); CheckPoint=Ask-RV_TriggerPoints*Point;
                 }
  //  }
  /*
  else
    {
     if(PendingBuyLots==0)
       {
       if(Ask+Spread*Point<UpperHedgeBound){OrderSend(Symbol(),OP_BUYSTOP,Lots,UpperHedgeBound,Slippage,0,0,Comm,MAGIC,0,clrBlue);}
       if(Bid-Spread*Point>UpperHedgeBound){OrderSend(Symbol(),OP_BUYLIMIT,Lots,UpperHedgeBound,Slippage,0,0,Comm,MAGIC,0,clrBlue);} 
       }
     if(PendingSellLots==0)
       {
       if(Ask+Spread*Point<LowerHedgeBound){OrderSend(Symbol(),OP_SELLLIMIT,Lots,LowerHedgeBound,Slippage,0,0,Comm,MAGIC,0,clrRed);}
       if(Bid-Spread*Point>LowerHedgeBound){OrderSend(Symbol(),OP_SELLSTOP,Lots,LowerHedgeBound,Slippage,0,0,Comm,MAGIC,0,clrRed);} 
       }  
    }
    */
} 

//---------------------------------------------------------------------------         
int CheckForClose()
{
  if(Profit>=PackageTakeProfit){CloseAll();Print(Profit,"/",PackageTakeProfit);}

  Count();
  if(Profit<-AccountBalance()*RiskPercent/100)//EMERGENCY LOCKING
    {
     if(SellLots>BuyLots+PendingBuyLots)
       {OrderSend(Symbol(),OP_BUY,(SellLots-(BuyLots+PendingBuyLots)),Ask,Slippage,0,0,Comm,MAGIC,0,clrAqua);}
     if(BuyLots>SellLots+PendingSellLots)
       {OrderSend(Symbol(),OP_SELL,(BuyLots-(SellLots+PendingSellLots)),Bid,Slippage,0,0,Comm,MAGIC,0,clrMagenta);}
    }
                  
}  

//---------------------------------------------------------------------------         
int CheckForRV()
{
  //setting High Low hedge boundary
  
  //if(AutoTrade){
   UpExit=CheckPoint+RV_TriggerPoints*Point;
   DwExit=CheckPoint-RV_TriggerPoints*Point;
  /*
   }
  else{
  UpExit=NormalizeDouble(UpperHedgeBound,5);DwExit=NormalizeDouble(UpperHedgeBound,5);   
   }*/

  Count();
  
  //SYSTEM CORE IDEA()   
  if(SellLots>BuyLots+PendingBuyLots)
    {OrderSend(Symbol(),OP_BUYSTOP,(SellLots*RV_Multiplier)-BuyLots,UpExit,Slippage,0,0,Comm,MAGIC,0,clrBlueViolet);}
  if(BuyLots>SellLots+PendingSellLots)
    {OrderSend(Symbol(),OP_SELLSTOP,(BuyLots*RV_Multiplier)-SellLots,DwExit,Slippage,0,0,Comm,MAGIC,0,clrOrangeRed);}
}  

//---------------------------------------------------------------------------         


//---------------------------------------------------------------------------         
//---------------------------------------------------------------------------         
void CloseAll()
{
   bool   Result;
   int    i,Pos,Error;
   int    Total=OrdersTotal();
   
   if(Total>0)
   {for(i=Total-1; i>=0; i--) 
     {if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == TRUE) 
       {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC)
         {
          Pos=OrderType();
           if(Pos==OP_BUY){Result=OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, clrGreen);}
           if(Pos==OP_SELL){Result=OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, clrGreen);}
           if((Pos==OP_BUYSTOP)||(Pos==OP_SELLSTOP)||(Pos==OP_BUYLIMIT)||(Pos==OP_SELLLIMIT))
           {Result=OrderDelete(OrderTicket(), CLR_NONE);}
           //-----------------------
           if(Result!=true){Error=GetLastError();Print("LastError = ",Error);}
        else Error=0;
        //-----------------------
          }
       }
     }
   }
   return(0);
}

//---------------------------------------------------------------------------         
//---------------------------------------------------------------------------         
//---------------------------------------------------------------------------
void Count()
{  
  Buys=0; Sells=0; PendingBuy=0; PendingSell=0; BuyLots=0; SellLots=0; PendingBuyLots=0; PendingSellLots=0; Profit=0;
  for(i=OrdersTotal(); i>=0; i--)
    {OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
     if(OrderMagicNumber()==MAGIC && OrderSymbol()==Symbol())
       {
        Profit = Profit + OrderProfit() + OrderSwap();
        if(OrderType()==OP_SELL){SellLots=SellLots+OrderLots();Sells++;}
        if(OrderType()==OP_BUY){BuyLots=BuyLots+OrderLots();Buys++;}
        if(OrderType()==OP_SELLSTOP || OrderType()==OP_SELLLIMIT){PendingSellLots=PendingSellLots+OrderLots();}
        if(OrderType()==OP_BUYSTOP || OrderType()==OP_BUYLIMIT){PendingBuyLots=PendingBuyLots+OrderLots();}
       }
    }
}
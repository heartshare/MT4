#define Copyright    "Findex ©2020"
#property copyright  Copyright
#define EAID   "RV_UBDS"  
#define Version      "1.0" 
#property version    Version

#define ExpertName   "Swing Reversal"
#define MAGIC  69
extern double  RV_Multiplier = 1.45;   //逆轉乘數
extern int     SR_TriggerPoints = 100; //搖擺(對沖)啟動距離
extern double  Lots = 0.1;             //起始手數,0:預設餘額0.1%
extern double  PackageTakeProfit = 10; //獲利平倉目標(dollar),0:預設餘額10%
extern int     RiskPercent = 75;       //風險上限%，鎖倉,0:預設餘額10%
extern int     Slippage = 50;          //滑價
extern int     Time_Frame=60;          //時框

//Internal Variables
int      PendingBuy, PendingSell, Buys, Sells, i, Spread;
double   BuyLots, SellLots, PendingBuyLots, PendingSellLots;
double   checkSwingPoint, Profit, Risk, UpExit, DwExit;
string   comt;          

//+------------------------------------------------------------------+
//| Init function                                                    |
//+------------------------------------------------------------------+
void init()
  {
   comt=StringConcatenate( EAID,"-", MAGIC );
   Spread=MarketInfo(Symbol(),MODE_SPREAD);
  }
//+------------------------------------------------------------------+
//| Start function                                                   |
//+------------------------------------------------------------------+
void start()
  {
   
   if(Lots==0){Lots = MathRound(AccountBalance()/1000)/100;}          
   if(PackageTakeProfit==0){PackageTakeProfit=AccountBalance()/1000;}
   
   OrderCount();
   //---MAIN Procedure
   if(BuyLots+SellLots != 0 && checkSwingPoint==0 )
   {
      for(int i=(OrdersHistoryTotal()-1); i>=0;i--)
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         {
            if(OrderSymbol()==_Symbol && OrderMagicNumber()==MAGIC)
              {
               if(OrderType()==ORDER_TYPE_BUY)
               {
                  checkSwingPoint=OrderOpenPrice()-SR_TriggerPoints*Point;
                  break;
               }
               if(OrderType()==ORDER_TYPE_SELL)
               {
                  checkSwingPoint=OrderOpenPrice()+SR_TriggerPoints*Point;
                  break;
               }
              }   
          }        
    }
          
   CheckForSwingReversal();
   if(Buys==0 && Sells==0) {CheckForOpen();}
   else{CheckForClose();}
           
  }

// --- 下單 ---         
int CheckForOpen()
{
  OrderCount();
     double UBB =iBands(NULL,Time_Frame,20,2,0,PRICE_TYPICAL,MODE_UPPER,0);
     double LBB =iBands(NULL,Time_Frame,20,2,0,PRICE_TYPICAL,MODE_LOWER,0);
     if(Ask>=UBB){
         OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,comt,MAGIC,0,clrBlue); checkSwingPoint=Ask-SR_TriggerPoints*Point;
     }
     if(Bid<=LBB){
         OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,comt,MAGIC,0,clrRed); checkSwingPoint=Bid+SR_TriggerPoints*Point;
     }
} 

// --- 出場 ---         
int CheckForClose()
{
  if(Profit>=PackageTakeProfit){CloseAll();Print(Profit,"/",PackageTakeProfit);}

  OrderCount();
  if(Profit<-AccountBalance()*RiskPercent/100)  // ---緊急鎖倉條件
    {
     if(SellLots>BuyLots+PendingBuyLots)
       {OrderSend(Symbol(),OP_BUY,(SellLots-(BuyLots+PendingBuyLots)),Ask,Slippage,0,0,comt,MAGIC,0,clrAqua);}
     if(BuyLots>SellLots+PendingSellLots)
       {OrderSend(Symbol(),OP_SELL,(BuyLots-(SellLots+PendingSellLots)),Bid,Slippage,0,0,comt,MAGIC,0,clrMagenta);}
    }
                  
}  

// --- 檢查是否符合補單條件 ---         
int CheckForSwingReversal()
{
  // --- 設定出場的價格上下界 ---
  UpExit=checkSwingPoint+SR_TriggerPoints*Point;
  DwExit=checkSwingPoint-SR_TriggerPoints*Point;
  OrderCount();
  
  // --- 核心模組 ---  
  if(SellLots>BuyLots+PendingBuyLots)
    {OrderSend(Symbol(),OP_BUYSTOP,(SellLots*RV_Multiplier)-BuyLots,UpExit,Slippage,0,0,comt,MAGIC,0,clrBlueViolet);}
  if(BuyLots>SellLots+PendingSellLots)
    {OrderSend(Symbol(),OP_SELLSTOP,(BuyLots*RV_Multiplier)-SellLots,DwExit,Slippage,0,0,comt,MAGIC,0,clrOrangeRed);}
}  

// --- 刪除委託單 ---         
void CloseAll()
{
   bool   Result;
   int    i,op_type,Error;
   int    Total=OrdersTotal();
   
   if(Total>0)
   {for(i=Total-1; i>=0; i--) 
     {if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == TRUE) 
       {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC)
         {
          op_type=OrderType();
           if(op_type==OP_BUY){Result=OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, clrGreen);}
           if(op_type==OP_SELL){Result=OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, clrGreen);}
           if((op_type==OP_BUYSTOP)||(op_type==OP_SELLSTOP)||(op_type==OP_BUYLIMIT)||(op_type==OP_SELLLIMIT))
           {Result=OrderDelete(OrderTicket(), CLR_NONE);}

           if(Result!=true){Error=GetLastError();Print("LastError = ",Error);}
           else Error=0;
          }
       }
     }
   }
   return(0);
}

// --- 統計委託單數目 ---
void OrderCount()
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
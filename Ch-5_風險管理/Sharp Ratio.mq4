//+-------------------------------------------+
//| 根據帳號餘額計算       Sharp Ratio        |
//| 這只是一個函數                            |
//+-------------------------------------------+
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

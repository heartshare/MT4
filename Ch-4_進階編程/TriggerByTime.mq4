//+----------------------------------------------+ 
//| 腳本程式啟動函數                             | 
//+----------------------------------------------+

#property strict
#property show_inputs

// 小時的定義，用來做下拉選單的項目做為輸入選項
enum ENUM_HOUR
{
   h00 = 00, // 00:00
   h01 = 01, // 01:00
   h02 = 02, // 02:00
   h03 = 03, // 03:00
   h04 = 04, // 04:00
   h05 = 05, // 05:00
   h06 = 06, // 06:00
   h07 = 07, // 07:00
   h08 = 08, // 08:00
   h09 = 09, // 09:00
   h10 = 10, // 10:00
   h11 = 11, // 11:00
   h12 = 12, // 12:00
   h13 = 13, // 13:00
   h14 = 14, // 14:00
   h15 = 15, // 15:00
   h16 = 16, // 16:00
   h17 = 17, // 17:00
   h18 = 18, // 18:00
   h19 = 19, // 19:00
   h20 = 20, // 20:00
   h21 = 21, // 21:00
   h22 = 22, // 22:00
   h23 = 23, // 23:00
};

input ENUM_HOUR StartHour = h07; // 開始交易操作的時間
input ENUM_HOUR LastHour = h17;  // 停止交易操作的時間

bool CheckActiveHours()
{
   // Set operations disabled by default.
   bool OperationsAllowed = false;
   // 檢查目前是否在允許的交易時間內。如果是：則返回 true。
   if ((StartHour == LastHour) && (Hour() == StartHour))
      OperationsAllowed = true;
   if ((StartHour < LastHour) && (Hour() >= StartHour) && (Hour() <= LastHour))
      OperationsAllowed = true;
   if ((StartHour > LastHour) && (((Hour() >= LastHour) && (Hour() <= 23)) || ((Hour() <= StartHour) && (Hour() > 0))))
      OperationsAllowed = true;
   return OperationsAllowed;
}

void OnStart()
{
   if (CheckActiveHours()) Print(“交易已啟動”);
}

void  OnStart ( ) 
{ 
   if  ( CheckActiveHours ( ) )  Print ( "交易已啟用" ) ; 
} 
//+---------------------------------------------------------------- ---------- --------------------+
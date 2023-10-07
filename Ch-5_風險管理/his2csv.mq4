//Script 擷取歷史數據到csv檔
//對每個貨幣對和時框重複以下程式碼行，然後按 F5 to recompile (or restart MT4)
//參數1：輸出的貨幣兌，如：GBPUSD
//參數2：時框，如：1, 5, 15, 30, 60 , 240, 1440, 10080, 43200
int start()
 {
	export_histData(“GBPUSD”,1440);
	   return(0);
	  }
	int export_histData(string symb, int tf)
{
	  string fname = symb + “,” + tf + “.csv”;
	  int handle = FileOpen(fname, FILE_CSV|FILE_WRITE, “,”);
	  if(handle>0)
{
	     FileWrite(handle,”Date,Time,Open,Low,High,Close,Volume”);
for(int i=0; i<iBars(symb,tf); i++)
{
	       string date1 = TimeToStr(iTime(symb,tf,i),TIME_DATE);
	       date1 = StringSubstr(date1,5,2) + “-” + StringSubstr(date1,8,2) + “-” + StringSubstr(date1,0,4);
	
	string time1 = TimeToStr(iTime(symb,tf,i),TIME_MINUTES);       
	FileWrite(handle, date1, time1, iOpen(symb,tf,i), iLow(symb,tf,i), iHigh(symb,tf,i), iClose(symb,tf,i), iVolume(symb,tf,i));
	      }
	 FileClose(handle);
	 Comment(“History output complete”);
	}
	
	   return(0);
	}

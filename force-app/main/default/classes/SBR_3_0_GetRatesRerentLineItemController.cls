public class SBR_3_0_GetRatesRerentLineItemController {

    @AuraEnabled(cacheable=true)
    public static String getPOData(String RerentLineItemId) {
        system.debug('RerentLineItemId:'+RerentLineItemId);
        List<PO_Rerent_Line_Item__c> RerentLineItemList;
        RerentLineItemList= [SELECT Id,Purchase_Order__r.Location__c,Purchase_Order__r.Ship_To_Account_Number__c,Category__c,Class__c,Purchase_Order__r.Company_Code__c FROM PO_Rerent_Line_Item__c WHERE PO_Line_Item__c=:RerentLineItemId]; 
        system.debug('poLineItemList'+RerentLineItemList);
        String accountNumber;
        String productId;
        String pc;
        String product;
        String companyId=RerentLineItemList[0].Purchase_Order__r.Company_Code__c;
        String shipToAcc=RerentLineItemList[0].Purchase_Order__r.Ship_To_Account_Number__c;
        system.debug('shipToAcc==='+shipToAcc);
        String catClass = RerentLineItemList[0].Category__c + RerentLineItemList[0].Class__c;
        system.debug('productId==='+catClass);
        String location=RerentLineItemList[0].Purchase_Order__r.Location__c;
        system.debug('PC==='+location);
        List<String> jsonStrings = new List<String>();
        
       	RatesRequestJson reqJson = new RatesRequestJson();
        reqJson.accountNumber = RerentLineItemList[0].Purchase_Order__r.Ship_To_Account_Number__c;

        Products prod=new Products();
        prod.pc=RerentLineItemList[0].Purchase_Order__r.Location__c;
        prod.productId=RerentLineItemList[0].Category__c + RerentLineItemList[0].Class__c;
    
        reqJson.products=new List<Products>{prod};
        String ratesRequestJson=JSON.serialize(reqJson);
        system.debug('reqjson'+reqJson); 
        system.debug(SBR_3_0_API_Rates.getRates(ratesRequestJson, companyId));

        return SBR_3_0_API_Rates.getRates(ratesRequestJson, companyId);
    }

    @AuraEnabled(cacheable=true)
    public static List<PO_Rerent_Line_Item__c> getRerentItems(String RerentLineItemId) {
        system.debug('RerentLineItemId:'+RerentLineItemId);
        List<PO_Rerent_Line_Item__c> poLineItemList;
        poLineItemList=[SELECT Equipment_Num__c,Serial_Number__c,Current_Mi_Hr_2__c,Current_Mi_Hr__c,Day_Rate__c,Make__c,Min_Rate__c,Model__c,Month_Rate__c,Week_Rate__c FROM PO_Rerent_Line_Item__c WHERE PO_Line_Item__c=:RerentLineItemId]; 
        system.debug('poLineItemList'+poLineItemList);
        return poLineItemList;
    }

	@AuraEnabled
    public static void updateRerent(Id recordId,Decimal Min,Decimal Day,Decimal Week,Decimal fourWeek,String Equipment,String Make,String Model, String Serial, Decimal Meter1, Decimal Meter2) {
        List<PO_Rerent_Line_Item__c>RerentLineItemList= [SELECT Id FROM PO_Rerent_Line_Item__c WHERE PO_Line_Item__c=:recordId]; 
        System.debug('Min,'+Min);
        System.debug('Day,'+Day);
        System.debug('Week,'+Week);
        System.debug('fourWeek,'+fourWeek);
        System.debug('Equipment,'+Equipment);
        System.debug('Make,'+Make);
        System.debug('Model,'+Model);
        System.debug('Serial,'+Serial);
        System.debug('Meter1,'+Meter1);
        System.debug('Meter2,'+Meter2);
        String returnVal = '';
        try { 
            PO_Rerent_Line_Item__c poRec = new PO_Rerent_Line_Item__c();
            poRec.Id = RerentLineItemList[0].Id;
            poRec.Min_Rate__c =Min;
            poRec.Day_Rate__c = Day;
            poRec.Week_Rate__c = Week;
            poRec.Month_Rate__c = fourWeek;
            poRec.Equipment_Num__c = Equipment;
            poRec.Make__c =Make;
            poRec.Model__c = Model;
            poRec.Serial_Number__c = Serial;
            poRec.Current_Mi_Hr__c = Meter1;
            poRec.Current_Mi_Hr_2__c = Meter2;
            System.debug('POrecvalues' +poRec);
            update poRec;
        } catch(Exception ex) {
            SBR_3_0_LogException.LogIt(ex) ;
            System.debug('An Exception: '+ex);
        }
    }


    public class RatesRequestJson {
        public String accountNumber;
        public List<Products> products;
    }
 
    public class Products {
        public String pc;
        public String productId;
	}

    public class ReturnJson {
		public Data data;
	}
    
    public class SuggestedRates {
		public String minimum;
		public String daily;
		public String weekly;
		public String monthly;
	}
    
    public class Rates {
		public SuggestedRates suggestedRates;
		public SuggestedRates bookRates;
	}

    public class Data {
		public String company;
		public String accountNumber;
		public String jobsiteName;
		public List<Items> items;
	}
    
    public class Items {
		public String productId;
		public String pc;
		public String rateFlag;
		public String notToExceed;
		public String rppPercentage;
		public String rateFlagDescription;
		public String needPassword;
		public String showAllRates;
		public String suggestMinimalHours;
		public String isConsumerCatClass;
		public String isSerialized;
		public String notToExceedDescription;
		public String customerDiscountPercentageDaily;
		public String customerDiscountPercentageWeekly;
		public String customerDiscountPercentageMonthly;
		public Rates rates;
	}
}
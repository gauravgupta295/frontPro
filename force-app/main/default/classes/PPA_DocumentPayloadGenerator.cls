public with sharing class PPA_DocumentPayloadGenerator {

    public class customException extends Exception {}
    
    public static Map<String,Object> generatePayload(String priceListId, Boolean onlyRatesLoaded, Boolean draftTemplate) {
        List<PPA_Price_List__c> priceList = new List<PPA_Price_List__c>();
        String outputStr;
        Map<String, Object> outputMap = new Map<String, Object>();

        try {
            priceList = [SELECT Id, Name, RecordType.DeveloperName, PPA_Rate_Load_Scope__c, PPA_Rate_Load_Type__c, PPA_Customer_No__c,
                                PPA_CompanyId__c, PPA_Customer_Name__c, PPA_Rate_Type__c, PPA_Start_Date__c, PPA_End_Date__c, PPA_Regions__c
                           FROM PPA_Price_List__c
                          WHERE Id = :priceListId];

            if(priceList.size() > 0) {
                outputMap.put('Transportation', getTransporationData(priceListId, priceList[0].RecordType.DeveloperName));
                outputMap.put('RentalCatClass', getRentalCatClassData(priceListId, onlyRatesLoaded, priceList[0].RecordType.DeveloperName));
                outputMap.put('Draft', draftTemplate);

                if(priceList[0].PPA_Rate_Load_Scope__c == 'Regional') {
                    outputMap.put('RatesLoadedScope', 'Region(s) ' + priceList[0].PPA_Regions__c);
                }
                else {
                    outputMap.put('RatesLoadedScope', priceList[0].PPA_Rate_Load_Scope__c);
                }

                outputMap.put('RateLoadType', priceList[0].PPA_Rate_Load_Type__c);
                outputMap.put('EndDate', priceList[0].PPA_End_Date__c != null ? priceList[0].PPA_End_Date__c.format() : null);
                outputMap.put('StartDate', priceList[0].PPA_Start_Date__c != null ? priceList[0].PPA_Start_Date__c.format() : null);
                outputMap.put('RateType', priceList[0].PPA_Rate_Type__c != null ? priceList[0].PPA_Rate_Type__c.toUpperCase() : null);
                outputMap.put('CustomerName', priceList[0].PPA_Customer_Name__c);
                outputMap.put('CustomerNo', priceList[0].PPA_Customer_No__c);
                outputMap.put('Company', priceList[0].PPA_CompanyId__c);
                outputMap.put('Name', priceList[0].Name);            
            }
            else {
                throw new customException('Price List Id not found');
            }
        }
        catch(Exception e) {            
            Map<String,String> exceptionParams = new Map<String,String>();
            exceptionParams.put('ClassName', 'PPA_DocumentPayloadGenerator');
            exceptionParams.put('MethodName', 'generatePayload');
            exceptionParams.put('Type', e.getTypeName());
            exceptionParams.put('LineNumber', String.valueOf(e.getLineNumber()));
            exceptionParams.put('StackTrace', e.getStackTraceString());
            exceptionParams.put('Message', e.getMessage());
            PPA_ExceptionLogHandler.createExceptionLog(exceptionParams);
        }
        
        return outputMap;
    }
    
    public static List<Map<String, Object>> getRentalCatClassData(String priceListId, Boolean onlyRatesLoaded, String recordType) {
        Map<String, List<PPA_Rental_CatClass__c>> superCats = new Map<String, List<PPA_Rental_CatClass__c>>();
        List<PPA_Rental_CatClass__c> catClasses = new List<PPA_Rental_CatClass__c>();
        List<Map<String, Object>> outputMap = new List<Map<String, Object>>();
        Map<String, Object> catClassObj = new Map<String, Object>();
        Map<String, Object> superCatObj = new Map<String, Object>();
        List<Object> outputRecs = new List<Object>();
        String superCatStr;
        
		for(PPA_Rental_CatClass__c catClass : [SELECT Id, Name, PPA_Super_Cat__c, PPA_Product_Category__c, PPA_Product_Name__c, PPA_Category__c, PPA_Class__c,
                                                      PPA_Old_Day__c, PPA_Old_Week__c, PPA_Old_Month__c,
                                                      PPA_New_Day__c, PPA_New_Week__c, PPA_New_Month__c
                                                 FROM PPA_Rental_CatClass__c
                                                WHERE PPA_Price_List__c = :priceListId
                                                  AND PPA_Like_CatClass__c = false
                                                  AND (PPA_Rates_Loaded__c = true
                                                   OR PPA_Rates_Loaded__c = :onlyRatesLoaded)
                                                ORDER BY PPA_Super_Cat__c, PPA_MasterSort__c])
        {
            if(!String.isEmpty(catClass.PPA_Super_Cat__c)) {
                superCatStr = catClass.PPA_Super_Cat__c;
            }
            else {
                superCatStr = 'UNKNOWN';
            }
            
            if(superCats.containsKey(superCatStr)) {
                catClasses = superCats.get(superCatStr);
                catClasses.add(catClass);
            }
            else {
                catClasses = new List<PPA_Rental_CatClass__c>();
                catClasses.add(catClass);
                superCats.put(superCatStr, catClasses);
            }
        }
        
        for(String key : superCats.keySet()) {
            superCatObj = new Map<String, Object>();
            outputRecs = new List<Object>();
      
            catClasses = superCats.get(key);
            
            for(PPA_Rental_CatClass__c catClass : catClasses) {
                catClassObj = new Map<String, Object>();

                if(recordType == 'PPA_Renewal') {
                    catClassObj.put('Month', formatCurrencyFields(String.valueOf(catClass.PPA_New_Month__c)));
                    catClassObj.put('Week', formatCurrencyFields(String.valueOf(catClass.PPA_New_Week__c)));
                    catClassObj.put('Day', formatCurrencyFields(String.valueOf(catClass.PPA_New_Day__c)));    
                }
                else {
                    catClassObj.put('Month', formatCurrencyFields(String.valueOf(catClass.PPA_Old_Month__c)));
                    catClassObj.put('Week', formatCurrencyFields(String.valueOf(catClass.PPA_Old_Week__c)));
                    catClassObj.put('Day', formatCurrencyFields(String.valueOf(catClass.PPA_Old_Day__c)));    
                }

                catClassObj.put('ProductName', catClass.PPA_Product_Name__c);
                catClassObj.put('Class', catClass.PPA_Class__c);
                catClassObj.put('Cat', catClass.PPA_Category__c);
                catClassObj.put('ProdCat', catClass.PPA_Product_Category__c);
                
				outputRecs.add(catClassObj);                
            }
            
            superCatObj.put('records', outputRecs);
            superCatObj.put('superCat', key);
            
        	outputMap.add(superCatObj);    
        }
        
        return outputMap;
    }
    
    public static Map<String, Object> getTransporationData(String priceListId, String recordType) {
        Map<String, List<PPA_Transportation__c>> transTypes = new Map<String, List<PPA_Transportation__c>>();
        List<PPA_Transportation__c> transRecs = new List<PPA_Transportation__c>();
		Map<String, Object> outputMap = new Map<String, Object>();
		List<Object> transTypeObj = new List<Object>();
        Boolean transDataExists = false;
        
        for(PPA_Transportation__c transRec : [SELECT Id, Name, PPA_Transportation_Type__c, PPA_Truck_Type__c, PPA_Rates_Loaded__c,
                                                     PPA_Old_Band1__c,  PPA_Old_Band2__c, PPA_Old_Band3__c, PPA_Old_Band4__c,  PPA_Old_Excess__c,
                                                     PPA_New_Band1__c,  PPA_New_Band2__c, PPA_New_Band3__c, PPA_New_Band4__c,  PPA_New_Excess__c
                                                FROM PPA_Transportation__c
                                               WHERE PPA_Price_List__c = :priceListId])
        {
            if(transRec.PPA_Rates_Loaded__c) {
                transDataExists = true;
            }

            if(transTypes.containsKey(transRec.PPA_Transportation_Type__c)) {
                transTypes.get(transRec.PPA_Transportation_Type__c).add(transRec);
            }
            else {
                transRecs = new List<PPA_Transportation__c>();
                transRecs.add(transRec);
                transTypes.put(transRec.PPA_Transportation_Type__c, transRecs);
            }            
        }
        
        if(transTypes.size() > 0) {
            transTypeObj.add(processTransportationType('NonUnion', transTypes, recordType));
            transTypeObj.add(processTransportationType('Union', transTypes, recordType));
            
			outputMap.put('transTypes', transTypeObj);            
        }
		
        outputMap.put('dataExists', transDataExists);            
        
        return outputMap;
    }

    public static Map<String, Object> processTransportationType(String type, Map<String, List<PPA_Transportation__c>> transTypes, String recordType) {
    	List<PPA_Transportation__c> transRecs = new List<PPA_Transportation__c>();
		Map<String, Object> transTypeObj = new Map<String, Object>();
		Map<String, Object> truckTypeObj = new Map<String, Object>();
        List<Object> outputRecs = new List<Object>();
        Boolean transDataExists = false;
        
        if(transTypes.containsKey(type)) {
    		transRecs = transTypes.get(type);

            if(transRecs.size() > 0) {
                for(PPA_Transportation__c truckType : transRecs) {    
                    truckTypeObj = new Map<String, Object>();

                    if(recordType == 'PPA_Renewal') {
                        if(truckType.PPA_Rates_Loaded__c) {
                            truckTypeObj.put('Excess', formatCurrencyFields(String.valueOf(truckType.PPA_New_Excess__c)));
                            truckTypeObj.put('MBand4', formatCurrencyFields(String.valueOf(truckType.PPA_New_Band4__c)));
                            truckTypeObj.put('MBand3', formatCurrencyFields(String.valueOf(truckType.PPA_New_Band3__c)));
                            truckTypeObj.put('MBand2', formatCurrencyFields(String.valueOf(truckType.PPA_New_Band2__c)));
                            truckTypeObj.put('MBand1', formatCurrencyFields(String.valueOf(truckType.PPA_New_Band1__c)));
							transDataExists = true;                           
                        }
                        else {
                            truckTypeObj.put('Excess', '');
                            truckTypeObj.put('MBand4', '');
                            truckTypeObj.put('MBand3', 'Will Be Quoted');                            
                            truckTypeObj.put('MBand2', '');
                            truckTypeObj.put('MBand1', '');                            
                        }
                    }
                    else {
                        if(truckType.PPA_Rates_Loaded__c) {
                            truckTypeObj.put('Excess', formatCurrencyFields(String.valueOf(truckType.PPA_Old_Excess__c)));
                            truckTypeObj.put('MBand4', formatCurrencyFields(String.valueOf(truckType.PPA_Old_Band4__c)));
                            truckTypeObj.put('MBand3', formatCurrencyFields(String.valueOf(truckType.PPA_Old_Band3__c)));
                            truckTypeObj.put('MBand2', formatCurrencyFields(String.valueOf(truckType.PPA_Old_Band2__c)));
                            truckTypeObj.put('MBand1', formatCurrencyFields(String.valueOf(truckType.PPA_Old_Band1__c)));                            
							transDataExists = true;                           
                        }
                        else {
                            truckTypeObj.put('Excess', '');
                            truckTypeObj.put('MBand4', '');
                            truckTypeObj.put('MBand3', 'Will Be Quoted');                            
                            truckTypeObj.put('MBand2', '');
                            truckTypeObj.put('MBand1', '');                            
                        }
                    }

                    truckTypeObj.put('TruckType', truckType.PPA_Truck_Type__c);    
                    outputRecs.add(truckTypeObj);
                }
                
                transTypeObj.put('records', outputRecs);
            }

            transTypeObj.put('dataExists', transDataExists);
            transTypeObj.put('TransType', type);                
        }

        return transTypeObj;        
    }

    public static String formatCurrencyFields(String unformattedValue) {
        String formattedValue;
        Integer decimalPlaces;
        String decimalSep = 0.23.format().substring(1, 2);

        if(unformattedValue != null) {
        	formattedValue = Decimal.valueof(unformattedValue).setScale(2).format();
            
            if(formattedValue.contains(decimalSep)) {
                decimalPlaces = formattedValue.split('\\' + decimalSep)[1].length();
            } else {
                formattedValue += decimalSep;
                decimalPlaces = 0;
            }
        
            //Add trailing zeros
            while(decimalPlaces < 2) {
                formattedValue += '0';
                decimalPlaces ++;
            }            
        }
    
        return '$'+formattedValue;
    }    
}
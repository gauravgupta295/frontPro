public with sharing class PPA_ExportPriceListsToCSVBatch implements Database.Batchable<sObject>, Database.Stateful {

    public Map<String,List<String>> rentalFileBodyMap = new Map<String,List<String>>();
    public Map<String,List<String>> transFileBodyMap = new Map<String,List<String>>();
    public Map<String,String> truckTypeMap = new Map<String,String>();
    public List<PPA_Export_CSV_Key__c> rentalRegionList = new List<PPA_Export_CSV_Key__c>();
    public List<PPA_Export_CSV_Key__c> transRegionList = new List<PPA_Export_CSV_Key__c>();
    public Map<String,String> transLoaded = new Map<String,String>();
    public Map<String, PPA_Price_List__c> priceListMap = new Map<String, PPA_Price_List__c>();
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = '';
        query = query + 'SELECT Id, RecordType.DeveloperName, CurrencyIsoCode, PPA_Customer_No__c, PPA_Rate_Type__c, PPA_CompanyId__c,';
        query = query + '       PPA_Start_Date__c, PPA_End_Date__c, PPA_Export_Status__c, PPA_Rate_Load_Scope__c, PPA_Regions__c,';
        query = query + '       PPA_Customer_Name__c, PPA_Rep_EmployeeNumber__c, PPA_Mgr_EmployeeNumber__c, PPA_RA_Improvement__c';
        query = query + '  FROM PPA_Price_List__c';
        query = query + ' WHERE RecordType.DeveloperName IN (\'PPA_Renewal\',\'PPA_Extension\')';
        query = query + '   AND PPA_Export_Status__c = \'Scheduled\'';
        
        rentalRegionList = [SELECT Id, PPA_CompanyId__c, PPA_Region__c, PPA_Export_Region__c, PPA_Export_District__c, PPA_Exclude_National__c
                            FROM PPA_Export_CSV_Key__c
                            WHERE RecordType.DeveloperName = 'PPA_Rental'
                            AND PPA_Active__c = true];
        
        transRegionList = [SELECT Id, PPA_CompanyId__c, PPA_Transportation_Type__c, PPA_Region__c, PPA_Export_Region__c, PPA_Export_District__c, PPA_Exclude_National__c
                           FROM PPA_Export_CSV_Key__c
                           WHERE RecordType.DeveloperName = 'PPA_Transportation'
                           AND PPA_Active__c = true];
        
        for(PPA_Export_CSV_Key__c mapTruck : [SELECT Id, PPA_Truck_Type__c, PPA_Export_Class__c
                                              FROM PPA_Export_CSV_Key__c
                                              WHERE RecordType.DeveloperName = 'PPA_TruckType'
                                              AND PPA_Active__c = true])
        {
            truckTypeMap.put(mapTruck.PPA_Truck_Type__c,mapTruck.PPA_Export_Class__c);
        }            
        
 		return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<PPA_Price_List__c> priceLists) {
        //Setting RentalCat,Transportations List
    	List<PPA_Rental_CatClass__c> rentalList = new List<PPA_Rental_CatClass__c>();
        List<PPA_Transportation__c> transList = new List<PPA_Transportation__c>();
        PPA_Price_List__c onePriceList;        
        Set<String> priceListIds = new Set<String>();
        String strStartDatekey;
        String strCompanyKey;
        String strFileNameKey;
        
        //Adding price list records into priceListMap
        for(PPA_Price_List__c priceList : priceLists){
            priceListMap.put(priceList.Id,priceList);
            priceListIds.add(priceList.Id);
        }
        
        rentalList = [SELECT Id, PPA_Price_List__c, PPA_Apply_Rate_Type__c, PPA_Min_Rate__c, PPA_CatClass__c, PPA_Category__c, PPA_Class__c,
                             PPA_Old_Day__c, PPA_Old_Week__c, PPA_Old_Month__c,
                             PPA_New_Day__c, PPA_New_Week__c, PPA_New_Month__c
                        FROM PPA_Rental_CatClass__c
                       WHERE PPA_Price_List__c IN :priceListIds
                         AND PPA_Like_CatClass__c = false];
        
        transList = [SELECT Id, PPA_Price_List__c, PPA_Transportation_Type__c, PPA_Truck_Type__c,
                            PPA_Old_Band1__c, PPA_Old_Band2__c, PPA_Old_Band3__c, PPA_Old_Band4__c, PPA_Old_Excess__c,
                            PPA_New_Band1__c, PPA_New_Band2__c, PPA_New_Band3__c, PPA_New_Band4__c, PPA_New_Excess__c
                       FROM PPA_Transportation__c
                      WHERE PPA_Price_List__c IN :priceListIds
                        AND PPA_Rates_Loaded__c = true]; 
        
        //Setting a Forloop for Each Record IN Rental CatClass Collection     
        for(PPA_Rental_CatClass__c rental : rentalList) {
            onePriceList = priceListMap.get(rental.PPA_Price_List__c);
            strStartDatekey = onePriceList.PPA_Start_Date__c <= system.today()+1 ? System.today().format().replaceAll('/','-') : onePriceList.PPA_Start_Date__c.format().replaceAll('/','-');
            strCompanyKey = onePriceList.PPA_CompanyId__c == '01' ? 'US' : 'CA';
            strFileNameKey = strCompanyKey + '_RENTAL_' + strStartDatekey;

            if(rentalFileBodyMap.containsKey(strFileNameKey)) {
                List<String> currentBody = rentalFileBodyMap.get(strFileNameKey);
                currentBody.add(generateRentalOutput(rental));
            }
            else {
				List<String> currentBody = new List<String>();
				currentBody.add(generateRentalOutput(rental));                
                rentalFileBodyMap.put(strFileNameKey, currentBody);
            }            
        }
        
        //Setting a Forloop for Each Record IN Transportaion  
        for(PPA_Transportation__c trans : transList) {
            if(!transLoaded.containsKey(trans.PPA_Price_List__c)) {
                transLoaded.put(trans.PPA_Price_List__c, trans.PPA_Transportation_Type__c);
            }
            else {
                String transType = transLoaded.get(trans.PPA_Price_List__c);
                if(!transType.contains(trans.PPA_Transportation_Type__c)) {
                    transLoaded.put(trans.PPA_Price_List__c, transType + ';' + trans.PPA_Transportation_Type__c);
                }
            }
            
            onePriceList = priceListMap.get(trans.PPA_Price_List__c);
            strStartDatekey = onePriceList.PPA_Start_Date__c <= system.today()+1 ? System.today().format().replaceAll('/','-') : onePriceList.PPA_Start_Date__c.format().replaceAll('/','-');
            strCompanyKey = onePriceList.PPA_CompanyId__c == '01' ? 'US' : 'CA';
            strFileNameKey = strCompanyKey + '_TRANSPORTATION_' + strStartDatekey;

            if(transFileBodyMap.containsKey(strFileNameKey)) {
                List<String> currentBody = transFileBodyMap.get(strFileNameKey);
                currentBody.add(generateTransportationOutput(trans));
            }
            else {
				List<String> currentBody = new List<String>();
				currentBody.add(generateTransportationOutput(trans));                
                transFileBodyMap.put(strFileNameKey, currentBody);
            }            
        }
    }

    public void finish(Database.BatchableContext BC) {
        List<Messaging.EmailFileAttachment> allFiles = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment auditFile = new Messaging.EmailFileAttachment();
        Messaging.EmailFileAttachment outputFile = new Messaging.EmailFileAttachment();
        String exportedDateStr = 'Exported on ' + System.now().format('M/d/yyyy h:mm:ss a');
        String auditFileName = 'EXPORT_SUMMARY_' + System.today().format().replaceAll('/','-') + '.csv';
        String auditBody = 'Customer#,CustomerName,StartDate,EndDate,Rep,Manager,RateType,Scope,Regions,Exported,RateExtension,RA_Improvement,TransLoaded,TransType\n';
        String fileBody;

        //Building Audit Report Attachment
        for(String priceListKey : priceListMap.keySet()) {
            PPA_Price_List__c auditPL = priceListMap.get(priceListKey);
            
            auditBody = auditBody + auditPL.PPA_Customer_No__c + ',';                                                   //Customer#
            auditBody = auditBody + '"' + auditPL.PPA_Customer_Name__c + '",';                                          //CustomerName
            auditBody = auditBody + auditPL.PPA_Start_Date__c.format() + ',';                                           //StartDate
            auditBody = auditBody + auditPL.PPA_End_Date__c.format() + ',';                                             //EndDate
            auditBody = auditBody + auditPL.PPA_Rep_EmployeeNumber__c + ',';                                            //Rep
            auditBody = auditBody + auditPL.PPA_Mgr_EmployeeNumber__c + ',';                                      		//Manager
            auditBody = auditBody + auditPL.PPA_Rate_Type__c + ',';                                                     //RateType
            auditBody = auditBody + auditPL.PPA_Rate_Load_Scope__c + ',';                                               //Scope
            /*PPA Phase 2: DP-1025
            Added double quotes around Regions*/
            auditBody = auditBody + (!String.isBlank(auditPL.PPA_Regions__c) ? '="' + auditPL.PPA_Regions__c + '"' : '') + ',';      //Regions
            auditBody = auditBody + exportedDateStr + ',';                                                              //Exported
            auditBody = auditBody + (auditPL.RecordType.DeveloperName == 'PPA_Extension' ? 'TRUE,' : 'FALSE,');         //RateExtension
            auditBody = auditBody + String.valueOf(auditPL.PPA_RA_Improvement__c) + ',';                                //RA_Improvement
            auditBody = auditBody + (transLoaded.containsKey(auditPL.Id) ? 'TRUE,' : 'FALSE,');                         //TransLoaded
            auditBody = auditBody + (transLoaded.containsKey(auditPL.Id) ? transLoaded.get(auditPL.Id) : '') + '\n';    //TransType
        }
        
        auditFile.body = Blob.valueOf(auditBody);
        auditFile.FileName = auditFileName;
        allFiles.add(auditFile);

        // Process the Rental File Body Map
        for(String oneFile : rentalFileBodyMap.keySet()) {
            fileBody = 'EDCMP,EDLOC,EDCUS,EDCATG,EDCLAS,EDJOB,EDSTDT,EDENDT,EDMCHG,EDHRRT,EDMNRT,EDDYRT,EDWKRT,EDMORT,EDSALE,EDDWP,EDDWD,EDDWW,';
            fileBody = fileBody + 'EDDWM,EDDSCP,EDSTTS,EDCNT,EDCURC,EDDCHG,EDPCHG,EDHMAX,EDNMAX,EDDMAX,EDWMAX,EDMMAX,EDDMHU,EDWMHU,EDMMHU,EDCXCB,EDCXRT,EDIRGN,EDARGN,EDDNE,EDDISTRICT\n';
			
            for(String oneBody : rentalFileBodyMap.get(oneFile)) {
                fileBody = fileBody + oneBody;
            }
            
            outputFile = new Messaging.EmailFileAttachment();
            outputFile.filename = oneFile + '.csv';
            outputFile.body = Blob.valueOf(fileBody);
            allFiles.add(outputFile);
        }

        // Process the Transporation File Body Map
        for(String oneFile : transFileBodyMap.keySet()) {
        	fileBody = 'RTCMP,RTCUS,RTLOC,RTRTYP,RTLVL1,RTLVL2,RTLVL3,RTLVL4,RTLVL5,RTEFFD,RTEFTD,RTRGN,RTDIST\n';
			
            for(String oneBody : transFileBodyMap.get(oneFile)) {
                fileBody = fileBody + oneBody;
            }
            
            outputFile = new Messaging.EmailFileAttachment();
            outputFile.filename = oneFile + '.csv';
            outputFile.body = Blob.valueOf(fileBody);
            allFiles.add(outputFile);
        }

        //Call the Class/method to send the email
        PPA_ExportDeliverCSVs.sendCSVsViaEmail(priceListMap.values().size(), allFiles);
        
        //Update the Price List in the PriceList collection to set the Export Status = Exported on mm/dd/yyyy
        for(PPA_Price_List__c onePriceList : priceListMap.values()) {
            onePriceList.PPA_Export_Status__c = exportedDateStr;
            onePriceList.PPA_Exported_Date__c = System.today();
        }
        
        update priceListMap.values();        
    }
    
    //Method to generate the output files for Rental CatClasses 
    public String generateRentalOutput(PPA_Rental_CatClass__c rentalCat){
        List<PPA_Export_CSV_Key__c> outputRegion = new List<PPA_Export_CSV_Key__c>();
        String fileBody = '';
        String dayRate = '';
        String weekRate = '';
        String monthRate = '';
        String minRate = '';
        String rateType = '';
        String strStartDate;
        String strEndDate;
        String exportRegion;
        String exportDistrict;
        String[] listOfRegions;

        PPA_Price_List__c onePriceList = priceListMap.get(rentalCat.PPA_Price_List__c);
        strStartDate = String.valueOf(onePriceList.PPA_Start_Date__c).replaceAll('-','');
        strEndDate = String.valueOf(onePriceList.PPA_End_Date__c).replaceAll('-','');
        
        if(rentalCat.PPA_Apply_Rate_Type__c) {
            switch on onePriceList.PPA_Rate_Type__c {
                when 'Firm Fixed' {
                    rateType = 'S';
                }
                when 'Not To Exceed' {
                    rateType = 'X';
                }
            }
        }
        else {
            rateType = '';
        }
        
        if(onePriceList.RecordType.DeveloperName == 'PPA_Renewal'){
            dayRate = String.valueOf(rentalCat.PPA_New_Day__c);
            weekRate = String.valueOf(rentalCat.PPA_New_Week__c);
            monthRate = String.valueOf(rentalCat.PPA_New_Month__c);
        }
        else {
            dayRate = String.valueOf(rentalCat.PPA_Old_Day__c);
            weekRate = String.valueOf(rentalCat.PPA_Old_Week__c);
            monthRate = String.valueOf(rentalCat.PPA_Old_Month__c);
        }
        
        switch on rentalCat.PPA_Min_Rate__c {
            when 'Day' {
                minRate = dayRate;
            }
            when 'Week' {
                minRate = weekRate;
            }
            when 'Month' {
                minRate = monthRate;
            }
        }
        
        outputRegion = new List<PPA_Export_CSV_Key__c>();
        
        if(onePriceList.PPA_Rate_Load_Scope__c == 'National') {
            for(PPA_Export_CSV_Key__c rentalRegion : rentalRegionList) {
                if(rentalRegion.PPA_CompanyId__c == onePriceList.PPA_CompanyId__c && rentalRegion.PPA_Exclude_National__c == false) {
                    outputRegion.add(rentalRegion);
                }
            }
        }
        else {
            if(!String.isEmpty(onePriceList.PPA_Regions__c)) {
                listOfRegions = onePriceList.PPA_Regions__c.split(';');
                
                for(PPA_Export_CSV_Key__c rentalRegion : rentalRegionList) {
                    if(rentalRegion.PPA_CompanyId__c == onePriceList.PPA_CompanyId__c && listOfRegions.contains(rentalRegion.PPA_Region__c)) {                        
                        outputRegion.add(rentalRegion);
                    }
                }                
            }
        }
        
        // Process all Regions found in the Export CSV Key table and output 1 record per region
        for(PPA_Export_CSV_Key__c oneRegion : outputRegion) {
            exportRegion = oneRegion.PPA_Export_Region__c != null ? oneRegion.PPA_Export_Region__c : '0';
            exportDistrict = oneRegion.PPA_Export_District__c != null? oneRegion.PPA_Export_District__c : '';    

            fileBody = fileBody + onePriceList.PPA_CompanyId__c + ',';            	//EDCMP
            fileBody = fileBody + ',';                                            	//EDLOC - Not Used <Empty String>
            fileBody = fileBody + onePriceList.PPA_Customer_No__c + ',';          	//ECCUS
            fileBody = fileBody + rentalCat.PPA_Category__c + ',';                	//EDCATG
            fileBody = fileBody + rentalCat.PPA_Class__c + ',';                   	//EDCLAS
            fileBody = fileBody + ',';                                            	//EDJOB - Not Used <Empty String>
            fileBody = fileBody + strStartDate + ',';                             	//EDSTDT
            fileBody = fileBody + strEndDate + ',';                               	//EDENDT
            fileBody = fileBody + '0,';                                           	//EDMCHG - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDHRRT - Not Used 0
            fileBody = fileBody + minRate + ',';									//EDMNRT
            fileBody = fileBody + dayRate + ',';                               		//EDDYRT
            fileBody = fileBody + weekRate + ',';                               	//EDWKRT
            fileBody = fileBody + monthRate + ',';                               	//EDMORT
            fileBody = fileBody + '0,';                                           	//EDSALE - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDDWP - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDDWD - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDDWW - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDDWM - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDDSCP - Not Used 0
            fileBody = fileBody + 'A,';                                           	//EDSTTS - Not Used A
            fileBody = fileBody + '0,';                                           	//EDCNT - Not Used 0
            fileBody = fileBody + onePriceList.CurrencyIsoCode + ',';            	//EDCURC
            fileBody = fileBody + '0,';                                           	//EDDCHG - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDPCHG - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDHMAX - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDNMAX - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDDMAX - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDWMAX - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDMMAX - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDDMHU - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDWMHU - Not Used 0
            fileBody = fileBody + '0,';                                           	//EDMMHU - Not Used 0
            fileBody = fileBody + ',';                                            	//EDCXCB - Not Used <Empty String>
            fileBody = fileBody + ',';                                            	//EDCXRT - Not Used <Empty String>
            fileBody = fileBody + exportRegion + ',';            	                //EDIRGN
            fileBody = fileBody + '0,';                                           	//EDARGN - Not Used 0
            fileBody = fileBody + rateType + ',';									//EDDNE
            fileBody = fileBody + exportDistrict + ',';         	                //EDDISTRICT
            fileBody = fileBody + '\n';            
        }
                
        return fileBody;
    }

    //Method to generate the output files of Transportaion
    public String generateTransportationOutput(PPA_Transportation__c Trans){ 
        List<PPA_Export_CSV_Key__c> outputRegion = new List<PPA_Export_CSV_Key__c>();        
        String fileBody = '';        
        String mBand1;
        String mBand2;
        String mBand3;
        String mBand4;
        String mExcess;
        String exportRegion;
        String exportDistrict;
        String[] listOfRegions;
        
        PPA_Price_List__c onePriceList = priceListMap.get(Trans.PPA_Price_List__c);
        outputRegion = new List<PPA_Export_CSV_Key__c>();
        String strStartDate = String.valueOf(onePriceList.PPA_Start_Date__c).replaceAll('-','');
        String strEndDate = String.valueOf(onePriceList.PPA_End_Date__c).replaceAll('-',''); 
        
        if(onePriceList.RecordType.DeveloperName == 'PPA_Renewal'){
            mBand1 = String.valueOf(Trans.PPA_New_Band1__c);
            mBand2 = String.valueOf(Trans.PPA_New_Band2__c);
            mBand3 = String.valueOf(Trans.PPA_New_Band3__c);
            mBand4 = String.valueOf(Trans.PPA_New_Band4__c);
            mExcess = String.valueOf(Trans.PPA_New_Excess__c);
        }
        else{
            mBand1 = String.valueOf(Trans.PPA_Old_Band1__c);
            mBand2 = String.valueOf(Trans.PPA_Old_Band2__c);
            mBand3 = String.valueOf(Trans.PPA_Old_Band3__c);
            mBand4 = String.valueOf(Trans.PPA_Old_Band4__c);
            mExcess = String.valueOf(Trans.PPA_Old_Excess__c);
        }
        
        if(onePriceList.PPA_Rate_Load_Scope__c == 'National'){
            for(PPA_Export_CSV_Key__c Key : transRegionList){
                if(Key.PPA_CompanyId__c == onePriceList.PPA_CompanyId__c && Key.PPA_Transportation_Type__c == trans.PPA_Transportation_Type__c && Key.PPA_Exclude_National__c == false){
                    outputRegion.add(Key);
                }                           
            }
        }
        else{
            if(!String.isEmpty(onePriceList.PPA_Regions__c)) {
                listOfRegions = onePriceList.PPA_Regions__c.split(';');
                
                for(PPA_Export_CSV_Key__c Key : transRegionList){
                    if(Key.PPA_CompanyId__c == onePriceList.PPA_CompanyId__c && Key.PPA_Transportation_Type__c == trans.PPA_Transportation_Type__c && listOfRegions.contains(Key.PPA_Region__c)){
                        outputRegion.add(Key);
                    } 
                }
            }
        }
        
        for(PPA_Export_CSV_Key__c oneRegion: outputRegion) {
            String[] exportClass = truckTypeMap.get(Trans.PPA_Truck_Type__c).split(';');
            exportRegion = oneRegion.PPA_Export_Region__c != null ? oneRegion.PPA_Export_Region__c : '';
            exportDistrict = oneRegion.PPA_Export_District__c != null? oneRegion.PPA_Export_District__c : '';              
            
            //Create output record per region for ExportCSVKey
            for(String oneClass : exportClass){
                fileBody = fileBody + onePriceList.PPA_CompanyId__c + ',';    	//RTCMP 
                fileBody = fileBody + onePriceList.PPA_Customer_No__c + ',';  	//RTCUS
                fileBody = fileBody + ',';                                   	//RTLOC - Not Used <Empty String>
                fileBody = fileBody + oneClass + ',';     						//RTRTYP
                fileBody = fileBody + mBand1 + ',';              				//RTLVL1
                fileBody = fileBody + mBand2 + ',';              				//RTLVL2
                fileBody = fileBody + mBand3 + ',';              				//RTLVL3
                fileBody = fileBody + mBand4 + ',';              				//RTLVL4
                fileBody = fileBody + mExcess + ',';             				//RTLVL5
                fileBody = fileBody + strStartDate + ',';        				//RTEFFD 
                fileBody = fileBody + strEndDate + ',';          				//RTEFTD                  
                fileBody = fileBody + exportRegion + ',';        				//RTRGN
                fileBody = fileBody + exportDistrict + ',';      				//RTDIST                  
                fileBody = fileBody + '\n';
            }
        }   
        
        return fileBody;
    }
}
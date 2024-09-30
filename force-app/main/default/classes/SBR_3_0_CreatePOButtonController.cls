public with sharing class SBR_3_0_CreatePOButtonController {
    @AuraEnabled(cacheable=false)
    public static Integer checkRecordCount(String recordId) {
        List<AggregateResult> poLineItems = [SELECT COUNT(Id) LineItemsCount FROM PO_Line_Item__c WHERE Purchase_Order__c =:recordId];
        System.debug('poLineItems: ' + poLineItems);
        if(poLineItems.size() > 0) {
            Object lineItemCnt = poLineItems[0].get('LineItemsCount');
            System.debug('lineItemCnt: ' + lineItemCnt);
            return (Integer)lineItemCnt;
        }
        else {
            return poLineItems.size();
        }
    }
    @AuraEnabled(cacheable=false)
    public static boolean checkOldPOLI(String recordId) {
        List<PO_Line_Item__c> poLineItems = [SELECT id,oldPOItem__c FROM PO_Line_Item__c WHERE Purchase_Order__c =:recordId];
        System.debug('poLineItems: ' + poLineItems);
        list<PO_Line_Item__c> poliList=new list<PO_Line_Item__c>();
        Boolean isValid;
            for(PO_Line_Item__c polI: poLineItems){
                system.debug('inside for');
                if(polI.oldPOItem__c==false){
                    system.debug('polI.oldPOItem__c Before---'+polI.oldPOItem__c);
                    polI.oldPOItem__c=true;
                    system.debug('polI.oldPOItem__c after---'+polI.oldPOItem__c);
                    poliList.add(polI);
                }
            }
        update poliList;
        if(poliList.size()>0){
            isValid=true;
        }
        return isValid;
    }
    @AuraEnabled(cacheable=false)
    public static boolean checkRequiredFields(String recordId) {
        Boolean isValid = true;
        List<PO_Line_Item__c> poLineItems = [SELECT Id, Quantity__c, Unit_Cost__c, Item_Number__c, Freight_Type__c, Freight_Reason__c, Units__c,RecordTypeName__c,
                                                    Contract_Num__c, AcctNumber__c,oldPOItem__c, Transfer_Num__c, Equipment_Num__c,
                                                    (SELECT Id, Min_Rate__c, Day_Rate__c, Week_Rate__c, Month_Rate__c FROM PO_Rerent_Line_Items__r)
                                               FROM PO_Line_Item__c
                                              WHERE Purchase_Order__c =:recordId LIMIT 49999];

        for (PO_Line_Item__c poLI : poLineItems) {
            if((poLI.Quantity__c == 0 ) || (poLI.Unit_Cost__c == 0 ) || String.isBlank(poLI.Units__c) || String.isBlank(poLI.Item_Number__c))
            {
                isValid = false;
            }                
            
            if(poLI.RecordTypeName__c == 'Rerent') {
                //Check some additional fields
                if(poLI.PO_Rerent_Line_Items__r.size() > 0) {
                    for(PO_Rerent_Line_Item__c poRerentLI : poLI.PO_Rerent_Line_Items__r) {
                        if((poRerentLI.Min_Rate__c == null) ||
                            (poRerentLI.Day_Rate__c == null) ||
                            (poRerentLI.Week_Rate__c == null) ||
                            (poRerentLI.Month_Rate__c == null)) {
                            isValid = false;
                        }
                    }                    
                }
                else {
                    isValid = false;
                }
            }
            
            if(poli.RecordTypeName__c == 'Third_Party_Hauler') {
                //Check some additional fields
                if(String.isBlank(poLI.Freight_Type__c) || String.isBlank(poLI.Freight_Reason__c)) {
                    isValid = false;
                }
                if(poLI.Freight_Type__c == 'D' || poLI.Freight_Type__c == 'P') {
                    if(poLI.Contract_Num__c == null) {
                        isValid = false;
                    }                    
                }
                if(poLI.Freight_Type__c == 'T') {
                    if(poLI.Transfer_Num__c == null) {
                        isValid = false;
                    }
                }
                if(poLI.Freight_Type__c == 'S') {
                    if(poLI.AcctNumber__c == null || (poLI.Contract_Num__c == null && poLi.Transfer_Num__c == null)) {
                        isValid = false;
                    }
                }
                if(poli.oldPOItem__c==true){
                    isValid = true;
                }
            }
             
        }
        System.debug('isValid: ' + isValid);
        return isValid;
    }
    @AuraEnabled(cacheable=false)
    public static string updateStatus(String recordId){
        System.debug('updateStatus >> ' +recordId);
        string returnVal = 'Success';
        // Temporary placeholder until RM integration has been setup
        // this will generate a value to put into the Receive Number field
        String dtString = String.valueOf(system.now()).replaceAll('-','').replaceAll(' ','').replaceAll(':','').substring(6);
        Integer receiverNum = Integer.valueOf(dtString);
        
        Integer receiverSeq = 1; // Just for testing purpose --- Sachin Khambe. #FRONT-11940
        //Integer receiverNum = 000100; // Just for testing purpose --- Sachin Khambe. #FRONT-11940
        try {
            system.debug('inside try');
            Purchase_Order__c upStat = [SELECT Id, Name, Status__c, Draft_PO_Number__c, Type__c, Location__c 
                                        FROM Purchase_Order__c 
                                        WHERE Id =: recordId 
                                        LIMIT 1];
            List<PO_Line_Item__c> polList = [SELECT Id, Status__c, Messages__c, Quantity__c,  Unit_Cost__c, Units__c   FROM PO_Line_Item__c WHERE Purchase_Order__c =: upStat.Id];
            List<PO_Receipt__c> receiptList = new List<PO_Receipt__c>();
			system.debug('inside try 2');
            Id currentUserId = UserInfo.getUserId();
            system.debug('inside try 3'+currentUserId);
            User_Location__c currentUserLocation = [SELECT Id, Name, ProfileBranche__r.Branch_Location_Number__c  
                                                    FROM User_Location__c 
                                                    WHERE User__c =: currentUserId
                                                    LIMIT 1];
                System.debug('ProfileBranche__r.Branch_Location_Number__c'+ currentUserLocation);
			
           // Modified this method as per One Step PO requirements. --- Sachin Khambe. #FRONT-11940
        if(upStat.Status__c == 'Draft'){   
			if(upStat.Type__c == 'Standard Purchase Order - One Step'){
				upStat.Status__c ='Received';
				upStat.Name = upStat.Draft_PO_Number__c.substring(6);
                update upStat;

                System.debug('inside for of updatestatus'+currentUserLocation.ProfileBranche__r.Branch_Location_Number__c );

                for(PO_Line_Item__c pol : polList){
                    System.debug('inside for of updatestatus');
                    pol.Status__c = 'Received';
                    
                    /*--------------------------
                        Creating PO_Receipt__c records just for testing purpose. this code will not be usefull 
                            after integration with Rental Man.
                        User Story : FRONT-11940 
                        Author : Sachin Khambe 
                        ------------------------------------ */

                    PO_Receipt__c poR = new PO_Receipt__c();
                    poR.Purchase_Order__c = upStat.Id;
                    poR.PO_Line_Item__c = pol.Id;
                    poR.Messages__c = pol.Messages__c;
                    poR.Quantity_Received__c = pol.Quantity__c;
                    poR.Receiver_Seq__c = receiverSeq;
                    poR.Receiver_Number__c =  receiverNum; // receiverNum++;
                    poR.Unit_Cost__c = pol.Unit_Cost__c;
                    poR.Date_Received__c = Date.today();
                    poR.Time_Received__c = Decimal.valueOf(datetime.now().format('HHmmss'));
                    poR.Units__c  = pol.Units__c;
                    poR.Location__c = upStat.Location__c;
                    poR.Received_Location__c = currentUserLocation.ProfileBranche__r.Branch_Location_Number__c;
                    poR.Status__c = 'RC';
                    poR.Source__c = 'SF';

                    receiptList.add(poR);
                    //System.debug('poR.Received_Location__c >> '+poR.Received_Location__c);
                    
                    }
                    Update polList;
                    insert receiptList;
                
			}else{
                upStat.Status__c ='Open';
                upStat.Name = upStat.Draft_PO_Number__c.substring(6);
                update upStat;
				}
            }
        else if(upStat.Status__c == 'Open') {
                returnVal = 'Open';
            }
        } catch (Exception err) {
            returnVal = 'Failure';
            SBR_3_0_LogException.LogIt(err);
        }
        return returnVal;
    }
    @AuraEnabled(cacheable=false)
    public static string getVendorStatus(String recordId) {
        Purchase_Order__c pOrder = [SELECT Id, Name, Status__c, Vendor__r.Vendor_Status__c FROM Purchase_Order__c WHERE Id =: recordId];
        string venStatus = pOrder.Vendor__r.Vendor_Status__c;
        return venStatus;
    }
    @AuraEnabled(cacheable=false)
    public static Map<String, string> getVendorStatusPicklist(String objectName, String fieldName) {
        Map<String, string> returnMap = new Map<String, string>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectName) ;
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            //System.debug(pickListVal.getLabel() +' '+pickListVal.getValue());
            returnMap.put(pickListVal.getValue(), pickListVal.getLabel());
        }
        return returnMap;
    }
}
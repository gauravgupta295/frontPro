/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-05-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class SBR_3_0_Estimates_API_Service {

    public static SBR_3_0_WrapEstimates estimatesWrapper;
    public static WorkOrder wo;
    private static String companyId;
    private static final String APINAME = 'API_Estimates_Service';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    public static string returnPayload;
    // @AuraEnabled
    // public static string dummyRespTobeRemoved(String woId, String existingPayload)
    // {
    //     string body;
    //     String payload=existingPayload;
    //     system.debug(payload);
    //     map<string,Object> finalPayload= new map<string,Object>();
    //     Map<String, Object> m =   (Map<String, Object>) JSON.deserializeUntyped(payload);
    //    System.debug(JSON.serializePretty(m.get('parts')));
    //     list<Object> parts=(list< Object>)JSON.deserializeUntyped( JSON.serialize(m.get('parts')));
        
    //     List<map<string,Object>> estimates= new list<Map<string,Object>>();
    //     string orgPayload ='{"taxInformation":[{"taxOnSales":151.04,"totalInvoiceAmount":1852.79,"stateTaxAmount":68.07,"countyTaxAmount":0}]}';
    //    Map<String, Object> parsed =   (Map<String, Object>) JSON.deserializeUntyped(orgPayload);
    //     Integer i=0;		
    //     for(Object p:parts)
    //     { Map<String, Object>part =(Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(p));
            
    //         map<string,Object> estimate= new map<string,Object>();
    //         estimate.put('itemNumber',part.get('itemNumber')+'');
    //             estimate.put('quantity',part.get('quantity')+'');
    //             estimate.put('stockClass','test '+i);
    //             estimate.put('discountPercent',(i+1)*2);
    //             estimate.put('sourceReferenceLineNumber',part.get('sourceReferenceLineNumber')+'');
    //             estimates.add(estimate);
    //         i++;
    //     }
    //     finalpayload.put('estimatesItems',estimates);
    //     finalpayload.put('taxInformation',parsed.get('taxInformation'));
    //     body= JSON.serializePretty(finalpayload);
    //     system.debug(body);
    //     return body;
    //    //return '{"sourceWorkOrderNumber":"12345","workOrderNumber":lq8sz0d71k2ms8j16,"estimatesItems":[{"itemNumber":"ALT001","stockClass":"ELEAL","quantity":1,"unitOfMeasure":"EA","sellingPrice":500,"listPrice":0,"discountPercent":1,"sku":0,"sourceReferenceLine 
    // }

    @AuraEnabled(cacheable=true)
    public static string parseWorkOrder(String woId, String existingPayload) {
        System.debug('@@WorkOrderId' + woId);
        Set<String> woIds = new Set<String>{woId};
        estimatesWrapper = new SBR_3_0_WrapEstimates();
        List<WorkOrder> woList = SBR_3_0_WorkOrderDA.getWorkOrders(woIds);
        wo = woList[0];
        system.debug('WorkOrder ' + wo);
        // Append 'workOrder' key at the beginning
        String prefixedPayload = '{ "workOrder": [ ' + existingPayload;
        // Append '}' at the end
        String finalPayload = prefixedPayload + ']}';
        system.debug('final payload '+finalPayload);
                //String jsonString = '{ "workOrder": [ { "insideLabor": [ { "insideLaborHours": -9999.99, "insideLaborRate": 9999999.99, "laborCode": 0, "mechanicId": "string", "sourceReferenceLineNumber": "string" } ], "outsideLabor": [ { "laborCode": 0, "outsideLaborCost": -99999999.99, "outsideLaborPrice": 99999999.99, "outsideLaborPoNumber": 0, "sourceReferenceLineNumber": "string" } ], "mileage": { "laborCode": 0, "mileageMiles": -9999.99, "mileageRate": 9999.999, "sourceReferenceLineNumber": "string" }, "parts": [ { "cost": 999999999.999, "discountPercent": 999.99, "itemNumber": "string", "laborCode": 0, "orderQuantity": -99999.99, "sellingPrice": 999999999.999, "sourceReferenceLineNumber": "string", "stockClass": "strin", "unitOfMeasure": "st" } ] } ] }';
        

        estimatesWrapper = (SBR_3_0_WrapEstimates)JSON.deserialize(finalPayload, SBR_3_0_WrapEstimates.class);



        populateWoDetails();
        makeTheCallout();
        return returnPayload;
        //return '{"sourceWorkOrderNumber":"12345","workOrderNumber":lq8sz0d71k2ms8j16,"estimatesItems":[{"itemNumber":"ALT001","stockClass":"ELEAL","quantity":1,"unitOfMeasure":"EA","sellingPrice":500,"listPrice":0,"discountPercent":1,"sku":0,"sourceReferenceLineNumber":"35242a41-3a7d-459e-bce4-f687eb640ece"},{"itemNumber":"AA-BATTERY","stockClass":"BATTE","quantity":1,"unitOfMeasure":"EA","sellingPrice":2.252,"listPrice":0,"discountPercent":4,"sku":0,"sourceReferenceLineNumber":"0137d827-5243-475f-b71a-06e23e1a10c1"}],"taxInformation":[{"taxOnSales":151.04,"totalInvoiceAmount":1852.79,"stateTaxAmount":68.07,"countyTaxAmount":0}]}';
    }


    public static void populateWoDetails(){
        //Populate Account Number
        if(wo.Account.RM_Account_Number__c != null){
            String accountNumber = wo.Account.RM_Account_Number__c;
            if(accountNumber.contains('-')) {
                accountNumber = accountNumber.subStringAfter('-');
            }
            estimatesWrapper.workOrder[0].accountNumber = Integer.Valueof(accountNumber);
        }
        else{
            estimatesWrapper.workOrder[0].accountNumber=0;
        }

        estimatesWrapper.workOrder[0].majorRepair = String.valueOf(wo.SF_PS_Major_Repair__c);
        estimatesWrapper.workOrder[0].workOrderDescription = wo.SF_PS_Work_Order_Des__c;
        estimatesWrapper.workOrder[0].laborCode = Integer.valueOf(wo.SF_PS_LaborCode__c);
        estimatesWrapper.workOrder[0].billTo = wo.SF_PS_BillCustOrLoc__c;
        estimatesWrapper.workOrder[0].currencyCode = wo.CurrencyIsoCode;
        estimatesWrapper.workOrder[0].expenseToLocation = wo.SF_PS_Expense_To_Location__r.Branch_Location_Number__c;
        estimatesWrapper.workOrder[0].expenseCode = wo.SF_PS_ExpenseCode__c;
        estimatesWrapper.workOrder[0].jobLocation = wo.SF_PS_Job_Location__c;
        estimatesWrapper.workOrder[0].mechanicId = wo.SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c;
        estimatesWrapper.workOrder[0].driverLicenseState = wo.SF_PS_License_State__c;
        estimatesWrapper.workOrder[0].driverLicenseNumber = wo.SF_PS_Drivers_License_Number__c;
        estimatesWrapper.workOrder[0].jobNumber = wo.SF_PS_Job_Site__r.Job_Number__c;
        estimatesWrapper.workOrder[0].pONumber = wo.SF_PS_PONumber__c;
        
        system.debug('Test '+JSON.serialize(estimatesWrapper));
    }

    public static void makeTheCallout() {
        String payload = generateJSONPayload();

        system.debug('payload+ '+ payload);
        system.debug('Test Hello');
        system.debug('Owner'+wo);
        String rentalManUserName=[SELECT Wynne_User_Name__c FROM User WHERE id=:wo.OwnerId].Wynne_User_Name__c;
        system.debug('rentalManUserName'+rentalManUserName);
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
                 
        HttpRequest req = httpCallout.getRequest();
        system.debug('request@@' +req);
        req.setHeader('thresholdWaitTime', '1');
        system.debug('X-Correlation-ID'+ X_CORRELATION_ID);
        req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
        system.debug('requestTimestamp'+ String.valueOf(wo.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));
        req.setHeader('Content-Type', 'application/json');  
        req.setHeader('requestTimestamp', String.valueOf(wo.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));
        // system.debug('lastmodified is ' + String.valueOf(workOrder.LastModifiedDate));
        system.debug('sourceSystemUserId'+ wo.CreatedBy.alias);
        req.setHeader('sourceSystemUserId', wo.CreatedBy.alias);
        req.setHeader('sourceSystemName', 'Salesforce');
        system.debug('rentalmanUserId'+ rentalManUserName);
        req.setHeader('rentalmanUserId', rentalManUserName);
        system.debug('requestTimeZone'+ wo.ServiceTerritory.OperatingHours.TimeZone);
        req.setHeader('requestTimeZone', wo.ServiceTerritory.OperatingHours.TimeZone);
        system.debug('sourceWorkOrderNumber'+wo.WorkOrderNumber );
        req.setHeader('sourceWorkOrderNumber',wo.WorkOrderNumber );
        system.debug('pc'+ wo.ServiceTerritory.Branch_Location_Number__c);
        req.setHeader('pc', wo.ServiceTerritory.Branch_Location_Number__c);
        system.debug('companyId'+ wo.SF_PS_Company_Code__c);
        req.setHeader('companyId', wo.SF_PS_Company_Code__c);  
        req.setBody(payload);
        req.setTimeout(20000);
        
        Http http = new Http();
        
        HTTPResponse res = http.send(req);
        returnPayload = res.getBody();
        system.debug('Response'+returnPayload);
    }

    public static String generateJSONPayload() {
        if (estimatesWrapper.workOrder != null && !estimatesWrapper.workOrder.isEmpty()) {
            SBR_3_0_WrapEstimates.WorkOrder order = estimatesWrapper.workOrder[0];
            if (estimatesWrapper.workOrder[0].mileage != null &&
            (estimatesWrapper.workOrder[0].mileage.laborCode == null || estimatesWrapper.workOrder[0].mileage.laborCode == 0) &&
            (estimatesWrapper.workOrder[0].mileage.mileageMiles == null || estimatesWrapper.workOrder[0].mileage.mileageMiles == 0) &&
            (estimatesWrapper.workOrder[0].mileage.mileageRate == null || estimatesWrapper.workOrder[0].mileage.mileageRate == 0)) {
            estimatesWrapper.workOrder[0].mileage = null;
        }

        }
    
        String currentWrapper = JSON.serialize(estimatesWrapper).replace('null', '""');
        Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(currentWrapper);

        // Check if "mileage" key exists and is empty
        if (jsonMap.containsKey('workOrder')) {
            List<Object> workOrders = (List<Object>)jsonMap.get('workOrder');
            if (!workOrders.isEmpty()) {
                Map<String, Object> workOrder = (Map<String, Object>)workOrders[0];
                
                if (workOrder.containsKey('mileage')) {
                    if((String)(workOrder.get('mileage')+'' )=='' ){
                    	String mil = (String)workOrder.get('mileage');
                        // Check if the "mileage" key is empty
                        if (mil == null || mil == '' ) {
                            // Remove the "mileage" key
                            workOrder.remove('mileage');
                        }
                    }
                }
                list<Object> finalParts= new List<Object>();
                if(workOrder.containsKey('parts'))
                {
                   list<Object> parts=(list< Object>)JSON.deserializeUntyped( JSON.serialize(workOrder.get('parts')));
                    for(Object part:parts)
                    {
                        system.debug(part);
                        Map<String, Object>partMap =(Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(part));
                        system.debug('partmap '+partMap);
                        system.debug('discount '+ partMap.get('discountPercent'));
                        if(partMap.containsKey('discountPercent') && partMap.get('discountPercent')+''=='' )
                        {
                            system.debug('discountPercent removed');
                            partMap.remove('discountPercent');
                        }
                        finalParts.add(partMap);
                    }
                    workOrder.put('parts',finalParts);
                }
            }
        }
        
        // Serialize the Map back to JSON
        currentWrapper = JSON.serialize(jsonMap);
        System.debug('updatedJsonString' + currentWrapper);
        return currentWrapper;
    }
}


// String jsonString = '{"insideLabor":[{"insideLaborHours":-9999.99,"insideLaborRate":9999999.99,"laborCode":0,"mechanicId":"string","sourceReferenceLineNumber":"string"}],"outsideLabor":[{"laborCode":0,"outsideLaborCost":-99999999.99,"outsideLaborPrice":99999999.99,"outsideLaborPoNumber":0,"sourceReferenceLineNumber":"string"}],"mileage":{"laborCode":"","mileageMiles":."","mileageRate":,"sourceReferenceLineNumber":"string"},"parts":[{"cost":999999999.999,"discountPercent":999.99,"itemNumber":"string","laborCode":0,"orderQuantity":-99999.99,"sellingPrice":999999999.999,"sourceReferenceLineNumber":"string","stockClass":"strin","unitOfMeasure":"st"},{"unitOfMeasure":"st","stockClass":"strin","sourceReferenceLineNumber":"string","sellingPrice":999999999.999,"orderQuantity":-99999.99,"laborCode":0,"itemNumber":"string","discountPercent":999.99,"cost":999999999.999}]}';
// WorkOrder wo = [Select Id from Workorder where Id='0WO760000018c8kGAA' Limit 1];
// // //SBR_3_0_Estimates_API_Service es = new SBR_3_0_Estimates_API_Service();
// SBR_3_0_Estimates_API_Service.parseWorkOrder(wo.Id,jsonString);
// SBR_3_0_WrapEstimates jsonclass = (SBR_3_0_WrapEstimates)JSON.deserialize(jsonString, SBR_3_0_WrapEstimates.class);
// system.debug('Test'+jsonclass.workOrder.);
// if (workOrderParser != null && workOrderParser.workOrder != null) {
//     for (SBR_3_0_Estimates_API_Service.WorkOrder order : workOrderParser.workOrder) {
//         System.debug('Major Repair: ' + order.majorRepair);
//     }
// }
    
//         // Accessing other fields in the WorkOrder class...
    
//         // Accessing insideLabor details
//         if (order.insideLabor != null && !order.insideLabor.isEmpty()) {
//             for (SBR_3_0_Estimates_API_Service.InsideLabor insideLabor : order.insideLabor) {
//                 System.debug('Inside Labor Hours: ' + insideLabor.insideLaborHours);
//                 System.debug('Inside Labor Rate: ' + insideLabor.insideLaborRate);
    
//                 // Accessing other fields in the InsideLabor class...
//             }
//         }
    
//         // Accessing outsideLabor details
//         if (order.outsideLabor != null && !order.outsideLabor.isEmpty()) {
//             for (SBR_3_0_Estimates_API_Service.OutsideLabor outsideLabor : order.outsideLabor) {
//                 System.debug('Outside Labor Cost: ' + outsideLabor.outsideLaborCost);
//                 System.debug('Outside Labor Price: ' + outsideLabor.outsideLaborPrice);
    
//                 // Accessing other fields in the OutsideLabor class...
//             }
//         }
    
//         // Accessing mileage details
//         if (order.mileage != null) {
//             System.debug('Mileage Miles: ' + order.mileage.mileageMiles);
//             System.debug('Mileage Rate: ' + order.mileage.mileageRate);
    
//             // Accessing other fields in the Mileage class...
//         }
    
//         // Accessing parts details
//         if (order.parts != null && !order.parts.isEmpty()) {
//             for (SBR_3_0_Estimates_API_Service.Parts part : order.parts) {
//                 System.debug('Part Cost: ' + part.cost);
//                 System.debug('Part Item Number: ' + part.itemNumber);
    
//                 // Accessing other fields in the Parts class...
//             }
//         }
//     }

// }
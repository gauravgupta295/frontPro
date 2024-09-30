/*********************************************************************************************************************
* Apex Class: SBR_3_0_UpsertPORerent
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - This class is being called from custom API - SBR_3_0_API_Web_PurchaseOrderRerent
* - Create/Update Purchase Order Rerent Line Items in Salesforce from incoming JSON payload from RM
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME            DATE                   DETAIL FEATURES
1.0             Abhishek Sharma           2024-04-10             Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_UpsertPORerent {
   
    private static String poNumber = null;
    private static String companyCode = null;
       
    // Method to handle the creation of Purchase Order and its related Line Items
    public static void saveRerentLineItems(String reqPayload) {
        Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(reqPayload);
        system.debug('DeSerialized JSON ----->' +jsonData);
        system.debug('Mapped JSON ----->' + jsonData.get('rerentdetails'));
        List<Object> poRerentLineItemDetailsList = (List<Object>) jsonData.get('rerentdetails');
        List<PO_Rerent_Line_Item__c> rerentLineItemsToUpsert = new List<PO_Rerent_Line_Item__c>();
        Map<String, PO_Rerent_Line_Item__c> rerentLineItemsMap = new Map<String, PO_Rerent_Line_Item__c>();
        List<PO_Line_Item__c> poLineItems;
        List<String> poLineItemExternalIds = new List<String>();
        Set<String> poLIExternalIds = new Set<String>();
        Purchase_Order__c poObj;
        
        if (poRerentLineItemDetailsList == null) {
            System.debug('No PO Rerent details found in the request payload.');
            throw new NullPointerException();
        }

        for (Object detailRerentLineItem : poRerentLineItemDetailsList) {
            Map<String, Object> rerentLineItemData = (Map<String, Object>) detailRerentLineItem;
            PO_Rerent_Line_Item__c rerentLineItem =createRerentLineItems(rerentLineItemData);
            if(!rerentLineItemsMap.containsKey(rerentLineItem.ExternalId__c)){
                rerentLineItemsMap.put(rerentLineItem.ExternalId__c, rerentLineItem);
                poLineItemExternalIds.add(rerentLineItem.ExternalId__c);
            }
            if(poNumber == null) poNumber = rerentLineItem.PO_Number__c;
            if(companyCode == null) companyCode = rerentLineItem.Company_Code__c;
        }

        if(poLineItemExternalIds.size() > 0){
             try {            
            		poObj = [SELECT Id 
                             FROM 
                             	Purchase_Order__c 
                             WHERE 
                             	Name = :poNumber 
                             AND 
                             	Company_Code__c = :companyCode LIMIT 1];
                 system.debug('po obj-=--> ' +poObj);
             } catch (QueryException e) {
                System.debug('An error occurred while querying Purchase Order for given PO Number and Company Code: ' + e.getMessage());
                throw new System.QueryException('Invalid value. No Purchase order found for the given PO Number: ' + poNumber + ' and Company Code: ' + companyCode);
        	}
            
            try { 
            	poLineItems = [SELECT Id, ExternalId__c 
                                                      FROM 
                                                      	PO_Line_Item__c 
                                                      WHERE 
                                                      	Purchase_Order__c = :poObj.Id
                               						  AND
                               						  	RecordType.DeveloperName = 'Rerent'
                                                      AND 
                                                      	ExternalId__c IN :poLineItemExternalIds LIMIT 9999];
                system.debug('poLineItems obj-=--> ' +poLineItems);
                if(poLineItems.isEmpty() || poLineItems.size() < poLineItemExternalIds.size()){
                    throw new System.QueryException('Record count mismatch.');
                }
            }catch (QueryException e) {
                System.debug('An error occurred while querying PO Line Items for PO Number ' + e.getMessage());
                throw new System.QueryException('Invalid value - Rerent PO Line Items not found for the given PO Number: ' +poNumber+ ' and External Ids: ' +poLineItemExternalIds );
        	}
            
            for(PO_Line_Item__c poLineItem : poLineItems){
                if(!poLIExternalIds.contains(poLineItem.ExternalId__c) && rerentLineItemsMap.get(poLineItem.ExternalId__c) != null){
                    poLIExternalIds.add(poLineItem.ExternalId__c);
                    PO_Rerent_Line_Item__c poRerentItem = rerentLineItemsMap.get(poLineItem.ExternalId__c);
                    poRerentItem.Purchase_Order__c = poObj.Id;
                    poRerentItem.PO_Line_Item__c = poLineItem.Id;
                    rerentLineItemsToUpsert.add(poRerentItem);
                }
            }
        }

        if (rerentLineItemsToUpsert.size() > 0) {
            upsert rerentLineItemsToUpsert ExternalId__c;
        }
    }
    

    private static PO_Rerent_Line_Item__c createRerentLineItems(Map<String, Object> rerentLineItemData){
        return new PO_Rerent_Line_Item__c(
                ExternalId__c = (String) rerentLineItemData.get('ExternalId'),
                Company_Code__c = (String) rerentLineItemData.get('Company_Code__c'),
                PO_Number__c = String.valueOf(rerentLineItemData.get('PO_Number__c')),
                PO_Sequence__c = (Integer) rerentLineItemData.get('PO_Sequence__c'),
                Category__c =  String.valueOf(rerentLineItemData.get('Category__c')),
                Class__c =  String.valueOf(rerentLineItemData.get('Class__c')),
                Status__c = (String) rerentLineItemData.get('Status__c'),
                Vendor_Number__c =  String.valueOf(rerentLineItemData.get('Vendor_Number__c')),
                Item_Number__c = (String) rerentLineItemData.get('Item_Number__c'),
                Stock_Class__c = (String) rerentLineItemData.get('Stock_Class__c'),
                Equipment_Num__c = (String) rerentLineItemData.get('Equipment_Num__c'),
                Make__c = (String) rerentLineItemData.get('Make__c'),
                Model__c = (String) rerentLineItemData.get('Model__c'),
                Serial_Number__c = (String) rerentLineItemData.get('Serial_Number__c'),
                Min_Rate__c = (Decimal) rerentLineItemData.get('Min_Rate__c'),
                Day_Rate__c = (Decimal) rerentLineItemData.get('Day_Rate__c'),
                Week_Rate__c = (Decimal) rerentLineItemData.get('Week_Rate__c'),
                Month_Rate__c = (Decimal) rerentLineItemData.get('Month_Rate__c'),
                Current_Mi_Hr__c = (Decimal) rerentLineItemData.get('Current_Mi_Hr__c'),
                Total_AP_Cost__c = (Decimal) rerentLineItemData.get('Total_AP_Cost__c'),
                System_Date__c = parseDate(String.valueOf(rerentLineItemData.get('System_Date__c'))),
                System_Time__c = (Decimal) rerentLineItemData.get('System_Time__c'),
                CreatedBy__c = (String) rerentLineItemData.get('CreatedBy__c'),
                Last_Maint_Date__c = parseDate(String.valueOf(rerentLineItemData.get('Last_Maint_Date__c'))),
                Last_Maint_Time__c = (Decimal) rerentLineItemData.get('Last_Maint_Time__c'),
                Last_Maint_By__c = (String) rerentLineItemData.get('Last_Maint_By__c'),
                Location__c = (String) rerentLineItemData.get('Location__c'),
                Region_Work_Field__c = (Integer) rerentLineItemData.get('Region_Work_Field__c'),
                Currency_Code__c = (String) rerentLineItemData.get('Currency_Code__c'),
                Current_Mi_Hr_2__c = (Decimal) rerentLineItemData.get('Current_Mi_Hr_2__c')
        );
    }

    private static Date parseDate(String dateString) {
        if (String.isBlank(dateString)) {
            return null;
        }
        
        try {
            Integer year = Integer.valueOf(dateString.substring(0, 4));
            Integer month = Integer.valueOf(dateString.substring(4, 6));
            Integer day = Integer.valueOf(dateString.substring(6, 8));
            return Date.newInstance(year, month, day);

        } catch (Exception e) {
            System.debug('Error parsing date: ' + e.getMessage());
            return null;
        }
    }

}
/*********************************************************************************************************************
* Apex Class: SBR_3_0_UpsertPOReceipts
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - This class is being called from custom API - SBR_3_0_API_Web_PurchaseOrderReceipts
* - Create/Update PO Receipt Line Items in Salesforce from incoming JSON payload from RM
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME            DATE                   DETAIL FEATURES
1.0             Abhishek Sharma           2024-04-14             Initial version
*********************************************************************************************************************/
public with sharing class SBR_3_0_UpsertPOReceipts {
   
    private static String poNumber = null;
    private static String companyCode = null;
       
    // Method to handle the creation of Purchase Order and its related Line Items
    public static void savePOReceipts(String reqPayload) {
        Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(reqPayload);
        system.debug('DeSerialized JSON ----->' +jsonData);
        system.debug('Mapped JSON ----->' + jsonData.get('poreceipts'));
        List<Object> poReceiptsList = (List<Object>) jsonData.get('poreceipts');
        List<PO_Receipt__c> receiptsToUpsert = new List<PO_Receipt__c>();
        Map<String, PO_Receipt__c> receiptsMap = new Map<String, PO_Receipt__c>();
        List<PO_Line_Item__c> poLineItems;
        Set<decimal> lineItemNumbers = new Set<decimal>();
        Set<String> poLineItemExternalIds = new Set<String>();
        Set<String> poLIExternalIds = new Set<String>();
        Purchase_Order__c poObj;
        
        if (poReceiptsList == null) {
            System.debug('No PO Rerent details found in the request payload.');
            throw new NullPointerException();
        }

        for (Object receipt : poReceiptsList) {
            Map<String, Object> receiptObj = (Map<String, Object>) receipt;
            PO_Receipt__c poReceiptObj =createPOReceipts(receiptObj);
            String poLineItemUniqueKey = String.ValueOf(poReceiptObj.Company_Code__c) + '-' +
                						 String.ValueOf(poReceiptObj.PO_Number__c) +  '-' +
                						 String.ValueOf(poReceiptObj.Line_Item__c);
            System.debug('poLineItemUniqueKey--->' +poLineItemUniqueKey);
            if(!receiptsMap.containsKey(poLineItemUniqueKey)){
                receiptsMap.put(poLineItemUniqueKey, poReceiptObj);
                poLineItemExternalIds.add(poLineItemUniqueKey);
                lineItemNumbers.add(poReceiptObj.Line_Item__c);                
            }
            if(poNumber == null) poNumber = String.ValueOf(poReceiptObj.PO_Number__c);
            if(companyCode == null) companyCode = poReceiptObj.Company_Code__c;
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
            	poLineItems = [SELECT Id, Purchase_Order__c, PO_Number__c, Company_Code__c, Line_Item_Num__c, ExternalId__c 
                               FROM 
                               	PO_Line_Item__c 
                               WHERE 
                               	Purchase_Order__c = :poObj.Id
                               AND 
                               	PO_Number__c = :decimal.valueOf(poNumber)
                               AND 
                               	Company_Code__c = :companyCode
                               AND
                               	Line_Item_Num__c IN :lineItemNumbers LIMIT 9999];
                system.debug('poLineItems obj-=--> ' +poLineItems);
                if(poLineItems.isEmpty() || poLineItems.size() < poLineItemExternalIds.size()){
                    throw new System.QueryException('Record count mismatch.');
                }
            }catch (QueryException e) {
                System.debug('An error occurred while querying PO Line Items for PO Number ' + e.getMessage());
                throw new System.QueryException('Invalid value - PO Line Items not found for the given PO Number: ' +poNumber+ ' and company code ' +companyCode + ' and Line Item Numbers: ' +lineItemNumbers );
        	}
            
            for(PO_Line_Item__c poLineItem : poLineItems){
                String poLiUniqueKey = String.ValueOf(poLineItem.Company_Code__c) + '-' +
                					   String.ValueOf(poLineItem.PO_Number__c) +  '-' +
                					   String.ValueOf(poLineItem.Line_Item_Num__c);
                if(!poLIExternalIds.contains(poLiUniqueKey)){
                    poLIExternalIds.add(poLiUniqueKey);
                    PO_Receipt__c poReceipt = receiptsMap.get(poLiUniqueKey);
                    poReceipt.Purchase_Order__c = poObj.Id;
                    poReceipt.PO_Line_Item__c = poLineItem.Id;
                    receiptsToUpsert.add(poReceipt);
                }
            }
        }

        if (receiptsToUpsert.size() > 0) {
            try{
                System.debug('Rerent records to upsert--->' +receiptsToUpsert);
            	upsert receiptsToUpsert ExternalId__c;
                //insert receiptsToUpsert;
            }
            catch(Exception ex){
                System.debug('Exception occured--->' +ex.getMessage());
            }
        }else{
            System.debug('No Records found to create or update.');
        }
    }
    

    private static PO_Receipt__c createPOReceipts(Map<String, Object> receiptObj){
        return new PO_Receipt__c(
                ExternalId__c = (String) receiptObj.get('ExternalId__c'),
                Company_Code__c = (String) receiptObj.get('Company_Code__c'),
                PO_Number__c = (Integer)receiptObj.get('PO_Number__c'),
            	Status__c = (String) receiptObj.get('Status__c'),
            
            	Adj_Receiver_Seq__c = (Integer) receiptObj.get('Adj_Receiver_Seq__c'),
            	AP_Check_Date__c = 	parseDate(String.valueOf(receiptObj.get('AP_Check_Date__c'))),
            	AP_Check_Number__c = (Integer) receiptObj.get('AP_Check_Number__c'),
            	AP_Invoice_Num__c = (String) receiptObj.get('AP_Invoice_Num__c'),
            	AP_Invoice_Seq__c = (Integer) receiptObj.get('AP_Invoice_Seq__c'),            
            
                Average_Cost__c = (Decimal) receiptObj.get('Average_Cost__c'),
            	Bin_1__c = (String) receiptObj.get('Bin_1__c'),
            	Bin_2__c = (String) receiptObj.get('Bin_2__c'),
            	Check_Amount__c = (Decimal) receiptObj.get('Check_Amount__c'),
            	
            	Contract_Inv_Seq__c = (Integer) receiptObj.get('Contract_Inv_Seq__c'),
            	Contract_Number__c = (Decimal) receiptObj.get('Contract_Number__c'),
            	Created_From__c = (String) receiptObj.get('Created_From__c'),
                Currency_Code__c = (String) receiptObj.get('Currency_Code__c'),
            	Curr_Exchange_Rate__c = (Decimal) receiptObj.get('Curr_Exchange_Rate__c'),
            
            	Delivery_Note_Number__c = (String) receiptObj.get('Delivery_Note_Number__c'),
            	Equipment__c = (String) receiptObj.get('Equipment__c'),
            	Equipment_Type__c = (String) receiptObj.get('Equipment_Type__c'),
            	Inventory_Loss_Amt__c = (Decimal) receiptObj.get('Inventory_Loss_Amt__c'),
            	Item_History_Id__c = String.valueOf(receiptObj.get('Item_History_Id__c')),
                Item_Type__c = (String) receiptObj.get('Item_Type__c'),
                Last_Cost__c = (Decimal) receiptObj.get('Last_Cost__c'),
                Last_Maint_Date__c = parseDate(String.valueOf(receiptObj.get('Last_Maint_Date__c'))),
                Last_Maint_Time__c = (Decimal) receiptObj.get('Last_Maint_Time__c'),
                Last_Maint_By__c = (String) receiptObj.get('Last_Maint_By__c'),
            
            	Line_Item__c = (Integer) receiptObj.get('Line_Item__c'),
            	Location__c = (String) receiptObj.get('Location__c'),
            	Overage__c = (String) receiptObj.get('Overage__c'),
            	Pgm_Defined_Flag__c = (String) receiptObj.get('Pgm_Defined_Flag__c'),
            	New_Average_Cost__c = (Decimal) receiptObj.get('New_Average_Cost__c'),
            
            	Qty_On_Hand__c = (Decimal) receiptObj.get('Qty_On_Hand__c'),
            	Quantity_Received__c = (Decimal) receiptObj.get('Quantity_Received__c'),
            	Reason_Code__c = (String) receiptObj.get('Reason_Code__c'),
            	Received_By__c = (String) receiptObj.get('Received_By__c'),
            
            	Received_Location__c = (String) receiptObj.get('Received_Location__c'),
            	Messages__c = (String) receiptObj.get('Messages__c'),
            
                Receiver_Number__c = (Integer) receiptObj.get('Receiver_Number__c'),
            	Receiver_Seq__c = (Integer) receiptObj.get('Receiver_Seq__c'),
            	Requisition_Num__c = (Integer) receiptObj.get('Requisition_Num__c'),
            	RM_System_Date__c = parseDate(String.valueOf(receiptObj.get('RM_System_Date__c'))),
            	RM_System_Time__c = (Decimal) receiptObj.get('RM_System_Time__c'),
            
            	Sequence_Num__c = (Integer) receiptObj.get('Sequence_Num__c'),
                Serial_Number__c = (String) receiptObj.get('Serial_Number__c'),
            	Source__c = (String) receiptObj.get('Source__c'),
                Stock_Class__c = (String) receiptObj.get('Stock_Class__c'),
            	Tax_Amount__c = (Decimal) receiptObj.get('Tax_Amount__c'),
            	Tax_Code__c = (String) receiptObj.get('Tax_Code__c'),
            	Transaction_Cost__c = (Decimal) receiptObj.get('Transaction_Cost__c'),
                
                Units__c = (String) receiptObj.get('Units__c'),
            	Unit_Cost__c = (Decimal) receiptObj.get('Unit_Cost__c'),    
                Vendor_Number__c =  String.valueOf(receiptObj.get('Vendor_Number__c')),            
                
                Date_Received__c = parseDate(String.valueOf(receiptObj.get('Date_Received__c'))),
            	Time_Received__c = (Decimal) receiptObj.get('Time_Received__c'),
                CreatedById = (String) receiptObj.get('CreatedBy__c')
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
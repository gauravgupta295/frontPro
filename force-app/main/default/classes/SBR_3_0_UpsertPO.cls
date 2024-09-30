/*********************************************************************************************************************
* Apex Class: SBR_3_0_UpsertPO
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - This class is being called from custom API - SBR_3_0_API_Web_PurchaseOrder
* - Create/Update Purchase Order and Purchase Order Line item in Salesforce from incoming JSON payload from RM
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME            DATE                   DETAIL FEATURES
1.0             Shubham Biddua            2024-03-14             Initial version
1.1             Yashwee Nemmani           2024-03-28             Updated version
*********************************************************************************************************************/

public with sharing class SBR_3_0_UpsertPO {
    // Define mapping between material codes and corresponding record type values
    private static Map<String, String> materialRecordTypeMapping = new Map<String, String>{
        'RR' => 'Rerent',
        'RF' => '3rd Party Hauler',
        'SP' => 'Standard Purchase Order'
    };

    private static String poRecordTypeId = null;
    private static String lineItemRecordTypeId = null;
    private static Account vendorAccountObj;
    private static Schema.Location branchLocObj;
    private static User orderedByUserObj;
    private static Schema.Location shipToLocObj;
    private static AssociatedLocation jobNumberObj;
       
    // Method to handle the creation of Purchase Order and its related Line Items
    public static void handlePO(String reqPayload) {
        Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(reqPayload);
        Map<String, Object> poBodyData = (Map<String, Object>) jsonData.get('pobody');
        
        if (poBodyData == null) {
            System.debug('No PO body data found in the request payload.');
            throw new NullPointerException();
        }
        upsertPO(jsonData);
    }
    
    public static void upsertPO( Map<String, Object> jsonData) {
        // Process lookup fields to upsert PO and POlineItem
        List<Purchase_Order__c> purchaseOrdersToUpsert = new List<Purchase_Order__c>();
        List<PO_Line_Item__c> lineItemsToUpsert = new List<PO_Line_Item__c>();
        
        // Extract Purchase Order & Line Item details from the payload
        Map<String, Object> poBodyDetailsMap = jsonData.containsKey('pobody') ? (Map<String, Object>) jsonData.get('pobody') : new Map<String, Object>();
        List<Object> poLineItemDetailsList = jsonData.containsKey('podetails') ? (List<Object>) jsonData.get('podetails') : new List<Object>();
        
        // Extract necessary fields for lookup
        String vendorNumber = (String) poBodyDetailsMap.get('Vendor_Number__c');   // Required
        String locationCode = (String) poBodyDetailsMap.get('Location__c');        // Required
        String orderedBy = (String) poBodyDetailsMap.get('OrderedBy_Text__c');     // Required
        String shipTo = (String) poBodyDetailsMap.get('ShipTo__c');                // Optional 
        String jobNum = (String) poBodyDetailsMap.get('Job_Num__c');               // Optional 

        // the following extracted from json-details
        String freightType;
        String itemNumber;
        String externalId;
        String stockClass;
        
        Set<String> companyCodes = new Set<String>();
        companyCodes.add((String) poBodyDetailsMap.get('Company_Code__c'));
         
        // Perform SOQL queries for lookups
        try {
            vendorAccountObj = [SELECT Id FROM Account WHERE Vendor_Account_Number__c = :vendorNumber LIMIT 1];
        } catch (QueryException e) {
            System.debug('An error occurred while querying Vendor Account: ' + e.getMessage());
            throw new System.QueryException('Invalid value for Vendor Account Number: ' + vendorNumber);
        }
        
        try {
            branchLocObj = [SELECT Id FROM Location WHERE Branch_Location_Number__c = :locationCode AND Company_Code__c = :companyCodes LIMIT 1];
        } catch (QueryException e) {
            System.debug('An error occurred while querying Branch Location: ' + e.getMessage());
            throw new System.QueryException('Invalid value for Location Code: ' + locationCode);
        }
        
        try {
            orderedByUserObj = [SELECT Id FROM User WHERE Wynne_User_Name__c = :orderedBy LIMIT 1];
        } catch (QueryException e) {
            System.debug('An error occurred while querying Ordered By User: ' + e.getMessage());
            throw new System.QueryException('Invalid value for Ordered By Wynne User Name: ' + orderedBy);
        }

        shipToLocObj = [SELECT Id FROM Location WHERE Branch_Location_Number__c = :shipTo AND Company_Code__c = :companyCodes LIMIT 1] ?? null;
        jobNumberObj = [SELECT Id FROM AssociatedLocation WHERE Job_Number__c = :jobNum LIMIT 1] ?? null;

        // Extract RecordType for PO
        String materialCode = (String) poBodyDetailsMap.get('Material_Code__c');
        String recordTypeValue;
        String itemNumberVal;
        
        materialCode = String.isBlank(materialCode) ? 'SP' : materialCode;
        recordTypeValue = getPORecordTypeValue(materialCode);
     	
        // Use the obtained record type value to get the corresponding RecordTypeId
        Map<String, Schema.RecordTypeInfo> purchaseOrderRecordTypes = Schema.SObjectType.Purchase_Order__c.getRecordTypeInfosByName();
        poRecordTypeId = purchaseOrderRecordTypes.containsKey(recordTypeValue) ? purchaseOrderRecordTypes.get(recordTypeValue).getRecordTypeId() : null;
        
        // Check if records were found for lookups
        if (vendorAccountObj != null && branchLocObj != null) {
            // Upsert Purchase Order
            Purchase_Order__c purchaseOrder = createPurchaseOrder(poBodyDetailsMap);
            purchaseOrder.RecordTypeId = poRecordTypeId;
            purchaseOrdersToUpsert.add(purchaseOrder);
            
            // Upsert Purchase Orders
            if (!purchaseOrdersToUpsert.isEmpty()) {
                upsert purchaseOrdersToUpsert ExternalId__c;
                system.debug('PO-purchaseOrder Id...........'+purchaseOrder.Id);
            }

            Map<String, Schema.RecordTypeInfo> poLineItemRecordTypes = Schema.SObjectType.PO_Line_Item__c.getRecordTypeInfosByName();
            Map<String, String> itemNumbersValByExternalId = new Map<String, String>();
            Map<String, String> stocksByExternalId = new Map<String, String>();
            Map<String, String> recordTypeByExternalId = new Map<String, String>();
            
            for (Object detailLineItem : poLineItemDetailsList) {
                Map<String, Object> lineItemData = (Map<String, Object>) detailLineItem;
                freightType = (String) lineItemData.get('Freight_Type__c');     // Freight type value assignment
                itemNumber = (String) lineItemData.get('Item_Number__c');       // ItemNumber value assignment
                externalId = (String) lineItemData.get('ExternalId');	        // External Id value assignment
                stockClass = (String) lineItemData.get('Stock_Class__c');       // Stock class value assignment
                
                // Recordtype selection with respect to the values of Freight type and ItemNumber
                if (String.isBlank(freightType)) {
                    if (itemNumber.startsWith('*RR')) {
                        recordTypeValue = 'Rerent';
                        itemNumberVal = itemNumber.substring(3);
                    } else {
                        recordTypeValue = 'Standard Purchase Order';
                        itemNumberVal = itemNumber;
                    }
                } else {
                    recordTypeValue = '3rd Party Hauler';
                    itemNumberVal = itemNumber;
                }
                
                recordTypeByExternalId.put(externalId, recordTypeValue);
                itemNumbersValByExternalId.put(externalId, itemNumberVal);
                stocksByExternalId.put(externalId, stockClass);
            }
            
            List<Product2> productsList = new List<Product2>();
            Set<String> itemNumberVals = new Set<String>(itemNumbersValByExternalId.values());
            Set<String> stockVals = new Set<String>(stocksByExternalId.values());
            Map<String, Product2> productByProductSKU = new Map<String, Product2>();
            String productQuery = '';
            productByProductSKU = getProductByProductSKUMap(itemNumberVals, stockVals, companyCodes);
            
            // Processing line item details
            for (Object detailLineItem : poLineItemDetailsList) {
                Map<String, Object> lineItemData = (Map<String, Object>) detailLineItem;
                externalId = (String) lineItemData.get('ExternalId');	        // External Id value assignment
                
                recordTypeValue = recordTypeByExternalId.get(externalId);
                itemNumberVal = itemNumbersValByExternalId.get(externalId);
                lineItemRecordTypeId = poLineItemRecordTypes.containsKey(recordTypeValue) ? poLineItemRecordTypes.get(recordTypeValue).getRecordTypeId() : null;
                
                PO_Line_Item__c lineItem = new PO_Line_Item__c();

                lineItem = createPurchaseOrderLineItem(lineItemData, poBodyDetailsMap, recordTypeValue, itemNumberVal, purchaseOrder, productByProductSKU);
                system.debug('Out create PO LI> lineItem.ExternalId__c..'+lineItem.ExternalId__c);
                if (lineItem != null && lineItem.ExternalId__c != null) {
                    lineItemsToUpsert.add(lineItem);
                }
                system.debug('Out create PO LI> lineItemsToUpsert..'+lineItemsToUpsert);
            }
        }
        
        // upsert line Items
        if (!lineItemsToUpsert.isEmpty()) {
            upsert lineItemsToUpsert ExternalId__c;
        }
    }
    
    private static Purchase_Order__c createPurchaseOrder(Map<String, Object> poBodyDetailsMap){
        Purchase_Order__c poObj = new Purchase_Order__c(
            Name = (String) poBodyDetailsMap.get('Name'),
            RecordTypeId = poRecordTypeId,
            ExternalId__c = (String) poBodyDetailsMap.get('ExternalId__c'),
            Vendor__c = vendorAccountObj.Id,
            Vendor_Number__c = (String) poBodyDetailsMap.get('Vendor_Number__c'),
            Company_Code__c = (String) poBodyDetailsMap.get('Company_Code__c'),
            Location__c = (String) poBodyDetailsMap.get('Location__c'),
            Branch_Location__c = branchLocObj.Id,
            ShipTo_Location__c = (shipToLocObj != null) ? shipToLocObj.Id : null,
            ShipTo_Name__c = (String) poBodyDetailsMap.get('ShipTo_Name__c'),
            ShipTo_Addr1__c = (String) poBodyDetailsMap.get('ShipTo_Addr1__c'),
            ShipTo_Addr2__c = (String) poBodyDetailsMap.get('ShipTo_Addr2__c'),
            ShipTo_City__c = (String) poBodyDetailsMap.get('ShipTo_City__c'),
            ShipTo_State__c = (String) poBodyDetailsMap.get('ShipTo_State__c'),
            ShipTo_Zip__c = (String) poBodyDetailsMap.get('ShipTo_Zip__c'),
            ShipTo_Phone__c = (String) poBodyDetailsMap.get('ShipTo_Phone__c'),
            Status__c = (String) poBodyDetailsMap.get('Status__c'),
            Issue_Date__c = parseDate((String) poBodyDetailsMap.get('Issue_Date__c')),
            Promised_Date__c = parseDate((String) poBodyDetailsMap.get('Promised_Date__c')),
            Requested_Date__c = parseDate((String) poBodyDetailsMap.get('Requested_Date__c')),
            Closed_Date__c = parseDate((String) poBodyDetailsMap.get('Closed_Date__c')),
            Ordered_From__c = (String) poBodyDetailsMap.get('Ordered_From__c'),
            Ordered_For__c = (String) poBodyDetailsMap.get('Ordered_For__c'),
            PO_Total__c = (Decimal) poBodyDetailsMap.get('PO_Total__c'),
            PO_Tax__c = (Decimal) poBodyDetailsMap.get('PO_Tax__c'),
            Material_Code__c = (String) poBodyDetailsMap.get('Material_Code__c'),
            Employee__c = (String) poBodyDetailsMap.get('Employee__c'),
            Tax_Pct__c = (Decimal) poBodyDetailsMap.get('Tax_Pct__c'),
            Ship_Method__c = (String) poBodyDetailsMap.get('Ship_Method__c'),
            Terms__c = (String) poBodyDetailsMap.get('Terms__c'),
            FOB__c = (String) poBodyDetailsMap.get('FOB__c'),
            ShipTo__c = (String) poBodyDetailsMap.get('ShipTo__c'),
            Customer_or_Contract_Number__c = (Integer) poBodyDetailsMap.get('Customer_or_Contract_Number__c'),
            Alternate_AddrNum__c = (String) poBodyDetailsMap.get('Alternate_AddrNum__c'),
            Reference_Num__c = (String) poBodyDetailsMap.get('Reference_Num__c'),
            CurrencyISOCode = (String) poBodyDetailsMap.get('CurrencyISOCode'),
            CurrencyExchangeRate__c = (Integer) poBodyDetailsMap.get('CurrencyExchangeRate__c'),
            Order_Time__c = (Integer) poBodyDetailsMap.get('Order_Time__c'),
            Driv_Lic_State__c = (String) poBodyDetailsMap.get('Driv_Lic_State__c'),
            Misc_Group3__c = (Integer) poBodyDetailsMap.get('Misc_Group3__c'),
            Third_Party_RefNum__c = (String) poBodyDetailsMap.get('Third_Party_RefNum__c'),
            RM_User__c = (String) poBodyDetailsMap.get('RM_User__c'),
            RM_Last_Modified_Date__c = parseDate((String) poBodyDetailsMap.get('RM_Last_Modified_Date__c')),
            RM_Last_Modified_Time__c = (String) poBodyDetailsMap.get('RM_Last_Modified_Time__c'),
            Term_Days__c = (Integer) poBodyDetailsMap.get('Term_Days__c'),
            Disc_Pct__c = (Decimal) poBodyDetailsMap.get('Disc_Pct__c'),
            Disc_Days__c = (Integer) poBodyDetailsMap.get('Disc_Days__c'),
            Reason_Code__c = (String) poBodyDetailsMap.get('Reason_Code__c'),
            Invoice_Due_Date_Code__c = (String) poBodyDetailsMap.get('Invoice_Due_Date_Code__c'),
            Job_Site__c = (jobNumberObj != null) ? jobNumberObj.Id : null,
            Job_Num__c = (String) poBodyDetailsMap.get('Job_Num__c'),
            Account_Num__c = (Integer) poBodyDetailsMap.get('Account_Num__c'),
            PhoneNumberType__c = (String) poBodyDetailsMap.get('PhoneNumberType__c'),
            InternationPhoneNumber__c = (String) poBodyDetailsMap.get('InternationPhoneNumber__c'),
            Project_Num__c = (Integer) poBodyDetailsMap.get('Project_Num__c'),
            Phase_Num__c = (Integer) poBodyDetailsMap.get('Phase_Num__c'),
            Terms_Code_Override__c = (String) poBodyDetailsMap.get('Terms_Code_Override__c'),
            Pay_By_Date__c = parseDate((String) poBodyDetailsMap.get('Pay_By_Date__c')),
            PO_Comments__c = (String) poBodyDetailsMap.get('PO_Comments__c'),
            OrderedBy__c = orderedByUserObj.Id
        );
        
        return poObj;
    }
    
    private static PO_Line_Item__c createPurchaseOrderLineItem(Map<String, Object> lineItemjsonData, Map<String, Object> poBodyDetailsMap, String recordTypeValue, String itemNumberVal, Purchase_Order__c purchaseOrder, Map<String, Product2> productByProductSKU){
        String externalId = (String) lineItemjsonData.get('ExternalId');
        String itemDescsId = recordTypeValue != '3rd Party Hauler' ? productByProductSKU.get(itemNumberVal)?.Id : null; 
            
        PO_Line_Item__c lineItem = new PO_Line_Item__c(
            ExternalId__c = externalId,
            RecordTypeId = lineItemRecordTypeId,
            Company_Code__c = (String) lineItemjsonData.get('Company_Code__c'),
            Item_Desc__c = String.isEmpty(itemDescsId) ? null : itemDescsId,
            Purchase_Order__c = purchaseOrder.Id,
            PO_Number__c = (Integer) lineItemjsonData.get('PO_Number__c'),
            Line_Item_Num__c = (Integer) lineItemjsonData.get('Line_Item_Num__c'),
            Item_Number__c = (String) lineItemjsonData.get('Item_Number__c'),
            Stock_Class__c = (String) lineItemjsonData.get('Stock_Class__c'),
            Vendor_Item_Num__c = (String) lineItemjsonData.get('Vendor_Item_Num__c'),
            Unit_Cost__c = (Decimal) lineItemjsonData.get('Unit_Cost__c'),
            Open_Order_Qty__c = (Decimal) lineItemjsonData.get('Open_Order_Qty__c'),
            Quantity_Rcvd__c = (Decimal) lineItemjsonData.get('Quantity_Rcvd__c'),
            Quantity__c = (Decimal) lineItemjsonData.get('Quantity__c'),
            Units__c = (String) lineItemjsonData.get('Units__c'),
            Total_Cost__c = (Decimal) lineItemjsonData.get('Total_Cost__c'), 
            Total_Disc_Pct__c = (Decimal) lineItemjsonData.get('Total_Disc_Pct__c'), 
            Discount_Pct1__c = (Decimal) lineItemjsonData.get('Discount_Pct1__c'),
            Discount_Pct2__c = (Decimal) lineItemjsonData.get('Discount_Pct2__c'),
            Discount_Pct3__c = (Decimal) lineItemjsonData.get('Discount_Pct3__c'),
            Status__c = (String) lineItemjsonData.get('Status__c'),
            PO_Date__c = parseDate((String) lineItemjsonData.get('PO_Date__c')),
            Request_Date__c = parseDate((String) lineItemjsonData.get('Request_Date__c')),
            Due_Date__c = parseDate((String) lineItemjsonData.get('Due_Date__c')),
            Date_Rcvd__c = parseDate((String) lineItemjsonData.get('Date_Rcvd__c')),
            Warehouse__c = (String) lineItemjsonData.get('Warehouse__c'),
            GL_Account__c = (Decimal) lineItemjsonData.get('GL_Account__c'),
            Item_Type__c = (String) lineItemjsonData.get('Item_Type__c'),
            Drop_Shipment__c = (String) lineItemjsonData.get('Drop_Shipment__c'),
            AcctNumber__c = (Integer) lineItemjsonData.get('AcctNumber__c'),
            Driver_Lic_State__c = (String) lineItemjsonData.get('Driver_Lic_State__c'),
            Driver_Lic_Num__c = (String) lineItemjsonData.get('Driver_Lic_Num__c'),
            ContractOrWONumberOrCustNumber__c = (Integer) lineItemjsonData.get('ContractOrWONumberOrCustNumber__c'),
            Equipment_Num__c = (String) lineItemjsonData.get('Equipment_Num__c'),
            RM_SystemDate__c = parseDate((String) lineItemjsonData.get('RM_SystemDate__c')),
            RM_SystemTime__c = (String) poBodyDetailsMap.get('RM_Last_Modified_Time__c'),
            Config_Num__c = (Integer) lineItemjsonData.get('Config_Num__c'),
            Tax_Code__c = (String) lineItemjsonData.get('Tax_Code__c'),
            Job_Num__c = (String) lineItemjsonData.get('Job_Num__c'),
            Equipment_Type__c = (String) lineItemjsonData.get('Equipment_Type__c'),
            Work_Code__c = (String) lineItemjsonData.get('Work_Code__c'),
            Analysis_Code1__c = (Integer) lineItemjsonData.get('Analysis_Code1__c'),
            Analysis_Code2__c = (Integer) lineItemjsonData.get('Analysis_Code2__c'),
            Analysis_Code3__c = (Integer) lineItemjsonData.get('Analysis_Code3__c'),
            Analysis_Code4__c = (Integer) lineItemjsonData.get('Analysis_Code4__c'),
            Analysis_Code5__c = (Integer) lineItemjsonData.get('Analysis_Code5__c'),
            Analysis_Code6__c = (Integer) lineItemjsonData.get('Analysis_Code6__c'),
            Transaction_Cost__c = (Decimal) lineItemjsonData.get('Transaction_Cost__c'),
            Purchase_Reason__c = (String) lineItemjsonData.get('Purchase_Reason__c'),
            Third_Party_DtlNum__c = (String) lineItemjsonData.get('Third_Party_DtlNum__c'),
            Freight_Type__c = (String) lineItemjsonData.get('Freight_Type__c'),
            Freight_Reason__c = (String) lineItemjsonData.get('Freight_Reason__c'),
            Order_Comments_Line_Level__c = (String) lineItemjsonData.get('Order_Comments_Line_Level__c'),
            ProductSkuNumber__c = (Integer) lineItemjsonData.get('ProductSkuNumber__c'),
            RM_Item_Type__c = (String) lineItemjsonData.get('RM_Item_Type__c')
        );
        
        return lineItem;
    }
    
    private static Map<String, Product2> getProductByProductSKUMap(Set<String> itemNumberVals, Set<String> stockVals, Set<String> companyCodes){
        Map<String, Product2> productByProductSKU = new Map<String, Product2>();
        
        String productQuery = 'SELECT Id, Product_SKU__c, Stock_class__c, Item_Number__c, Status__c, Company_Code__c, Product_Type__c '
            + 'FROM Product2 '
            + 'WHERE ((Product_SKU__c IN :itemNumberVals AND Status__c = \'A\' AND Product_Type__c = \'Cat-Class\') '
            + 'OR (Stock_class__c IN :stockVals AND Item_Number__c IN :itemNumberVals AND Status__c = \'A\')) '
            + 'AND Company_Code__c IN :companyCodes';
        
        for(Product2 proObj : Database.query(productQuery)) {
            String productLinkNumber;
            if (proObj.Product_SKU__c != null && itemNumberVals.contains(proObj.Product_SKU__c)) {
                productLinkNumber = proObj.Product_SKU__c;
            } else if (proObj.Item_Number__c != null && itemNumberVals.contains(proObj.Item_Number__c)) {
                productLinkNumber = proObj.Item_Number__c;
            } else {
                productLinkNumber = null;
            }
            productByProductSKU.put(productLinkNumber, proObj);
        }
        
        return productByProductSKU;
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
    
    private static String getPORecordTypeValue(String materialCode) {
        return materialRecordTypeMapping.get(materialCode);
    }
}
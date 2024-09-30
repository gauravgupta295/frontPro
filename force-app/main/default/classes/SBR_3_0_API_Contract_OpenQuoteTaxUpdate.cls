public without sharing class SBR_3_0_API_Contract_OpenQuoteTaxUpdate {

    private static final String APINAME = 'Contracts';
    private static final String COMPANY_ID = '01';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
  
    private static WrapQuoteResponse wrapQuoteResp = new WrapQuoteResponse();

    @AuraEnabled
    public static QuoteWrapper updateQuoteTaxes(String recordId){

        QuoteWrapper quoteWrapped = new QuoteWrapper();
        quoteWrapped.isValidQuoteRecord = 'N';

        List<SBQQ__Quote__c>  quotes = [SELECT Id,Name, Total_Misc__c,Total_Rental_Amount__c, 
            RPP_Amount__c,Total_Sales_Amount__c,Total_Sales_Taxes__c,Total_Quoted_Amount__c,SBQQ__Status__c,
            RecordTypeId,RM_Account_Number__c,Company_Code__c,Rentalman_Quote_Id__c,
                (SELECT id, Line_Composite_Key__c,Misc_Charges_Item_Tax_Rate__c, Misc_Charges_Tax__c,
                    Rental_Tax__c,Sales_Tax__c,Global_Line_Number__c, Total_Price__c
                FROM SBQQ__LineItems__r) 
            FROM SBQQ__Quote__c WHERE Id =:recordId LIMIT 1];
    
        if(quotes == null || quotes.isEmpty()){
            return  quoteWrapped;
        }

        SBQQ__Quote__c quoteRecd = quotes[0];
        List<SBQQ__QuoteLine__c> quoteItems = quoteRecd.SBQQ__LineItems__r;

        quoteWrapped.quoteNumber = quoteRecd.Name;
        quoteWrapped.seqNum = '0';
       if(quoteRecd.Rentalman_Quote_Id__c != null){
            String quoteRMID = quoteRecd.Rentalman_Quote_Id__c;
            quoteWrapped.rmId = quoteRMID.substring(3);
            quoteWrapped.isValidQuoteRecord = 'Y';
        }else{
            quoteWrapped.isValidQuoteRecord = 'N';
        }
    
        quoteWrapped.companyId = quoteRecd.Company_Code__c;

        // Invoke Contract API
        if(quoteWrapped.isValidQuoteRecord == 'Y'){
            WrappedResponse response = buildRequest(quoteWrapped.rmId, quoteWrapped.companyId, quoteWrapped.seqNum);
        
            // parse the resonse and update taxes
            parseResponseAndUpdateTaxes(quoteWrapped.rmId, quoteItems, response.body,quoteRecd);   
        }

        return quoteWrapped;
    }

    @AuraEnabled(cacheable=false)
    public static WrappedResponse buildRequest(String rentanlManId, String companyCode, String seqNum){
        try {
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            if(String.isEmpty(companyCode)){
                companyCode = COMPANY_ID;
            }
            WrappedResponse response = new WrappedResponse();
                     
            HttpRequest req = httpCallout.getRequest();
            req.setMethod('GET');
            req.setEndpoint(req.getEndpoint()+'/'+rentanlManId+'/'+seqNum);
            req.setHeader('companyId', companyCode);
            //req.setHeader('thresholdWaitTime', '1');
            req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
            req.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);  
            req.setTimeout(120000);
			
            Http http = new Http();
            
            HTTPResponse res = http.send(req);
            System.debug('Error::'+res);
            response.headers = res.getHeaderKeys();
            response.body = res.getBody();
            
            System.debug('Response from API: ' +response.body);

            if((res.getStatusCode() == 200 || res.getStatus()== 'OK')){
                response.status = 'Complete';
            }else {
                response.status = 'InComplete';
            }
            return response;      
        } catch (Exception e) {
            system.debug('**** '+ e.getMessage() +' ' + e.getLineNumber()+' '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class QuoteWrapper{
        
        @AuraEnabled
        public String quoteNumber{get;set;}
        @AuraEnabled
        public String rmId{get;set;}
        @AuraEnabled
        public String isValidQuoteRecord{get;set;}
        @AuraEnabled
        public String companyId{get;set;}
        @AuraEnabled
        public String seqNum{get;set;}
        public QuoteWrapper(){
        }
    }
    public class WrappedResponse{
        @AuraEnabled
        public String body{get;set;}
        @AuraEnabled
        public String status{get;set;} 
        @AuraEnabled
        public list<String> headers{get;set;}
    }

   public static void parseResponseAndUpdateTaxes(String contractNumber, List<SBQQ__QuoteLine__c> quoteItems, String body, SBQQ__Quote__c quoteRecord){
        
       system.debug(body);
       wrapQuoteResp = (WrapQuoteResponse) JSON.deserialize(body, WrapQuoteResponse.class);
        System.debug('WrapQuoteResp->'+JSON.serialize(wrapQuoteResp));

        Boolean hasQuoteTotalChanged = false;

        Map<String, WrapProductQuoteLineItem> quoteLineNumToRentalTaxMap = new  Map<String, WrapProductQuoteLineItem>();
        Map<String, WrapSalesQuoteLineItem> quoteLineNumToSalesTaxMap = new  Map<String, WrapSalesQuoteLineItem>();
        Map<String, WrapMiscQuoteLineItem> quoteLineNumToMiscTaxMap = new  Map<String, WrapMiscQuoteLineItem>();

        Map<String, String> respTotalValuesMap = new  Map<String, String>();

        String lineItemCompKey = quoteRecord.Company_Code__c+'-'+contractNumber + '-';

        WrapTotals totals = wrapQuoteResp.totals;
       
        Decimal fuel = totals.fuel != null ? Decimal.valueOf(totals.fuel) : 0.0 ;
        Decimal environmental = totals.environmental != null ? Decimal.valueOf(totals.environmental) : 0.0 ;
        Decimal deliveryAndPickup = totals.deliveryAndPickup != null ? Decimal.valueOf(totals.deliveryAndPickup) : 0.0 ;
        Decimal miscValue = totals.misc != null ? Decimal.valueOf(totals.misc) : 0.0 ;

        Decimal respTotalMisc =  miscValue + fuel + environmental + deliveryAndPickup;
        if(quoteRecord.Total_Misc__c == null || (quoteRecord.Total_Misc__c !=null &&  quoteRecord.Total_Misc__c != respTotalMisc)){
            quoteRecord.Total_Misc__c = respTotalMisc;
            hasQuoteTotalChanged = true;
        }
       
        Decimal respTotalRentalAmount = totals.rentals != null ? Decimal.valueOf(totals.rentals) : 0.0 ;
        if(quoteRecord.Total_Rental_Amount__c == null || (quoteRecord.Total_Rental_Amount__c !=null &&  quoteRecord.Total_Rental_Amount__c != respTotalRentalAmount)){
            quoteRecord.Total_Rental_Amount__c = respTotalRentalAmount;
            hasQuoteTotalChanged = true;
        }
       
        Decimal respTotalSalesAmount = totals.salesAmount != null ? Decimal.valueOf(totals.salesAmount) : 0.0 ;
        
        if(quoteRecord.Total_Sales_Amount__c == null || (quoteRecord.Total_Sales_Amount__c !=null &&  quoteRecord.Total_Sales_Amount__c != respTotalSalesAmount)){
            quoteRecord.Total_Sales_Amount__c = respTotalSalesAmount;
            hasQuoteTotalChanged = true;
        }
       
        Decimal respRPPAmount = totals.rpp != null ? Decimal.valueOf(totals.rpp) : 0.0 ;
        if(quoteRecord.RPP_Amount__c == null || (quoteRecord.RPP_Amount__c !=null &&  quoteRecord.RPP_Amount__c != respRPPAmount)){
            quoteRecord.RPP_Amount__c = respRPPAmount;
            hasQuoteTotalChanged = true;
        }
       
        Decimal respTotalSalesTax =   totals.tax != null ? Decimal.valueOf(totals.tax) : 0.0 ;
        if(quoteRecord.Total_Sales_Taxes__c == null || (quoteRecord.Total_Sales_Taxes__c !=null &&  quoteRecord.Total_Sales_Taxes__c != respTotalSalesTax)){
            quoteRecord.Total_Sales_Taxes__c = respTotalSalesTax;
            hasQuoteTotalChanged = true;
        }

        Decimal respTotalOrderedAmount = respTotalMisc + respTotalRentalAmount + respTotalSalesAmount + respRPPAmount + respTotalSalesTax;
        if(quoteRecord.Total_Quoted_Amount__c == null || (quoteRecord.Total_Quoted_Amount__c !=null &&  quoteRecord.Total_Quoted_Amount__c != respTotalOrderedAmount)){
            quoteRecord.Total_Quoted_Amount__c = respTotalOrderedAmount;
            hasQuoteTotalChanged = true;
        }

        // (SF-6318) SF-6347 - Start
        quoteRecord.Total_Delivery_Pickup__c = deliveryAndPickup;
        quoteRecord.Total_Ancillary__c = miscValue + environmental + fuel;
        quoteRecord.Total_Estimated_Revenue__c = !String.isBlank(totals.finalTotal) ? Decimal.valueOf(totals.finalTotal) : 00;
        // (SF-6318) SF-6347 - End

        System.debug('quoteRecord->'+JSON.serialize(quoteRecord));

        if(wrapQuoteResp.products != null ){
            for(WrapProductQuoteLineItem prodLineData : wrapQuoteResp.products){
                quoteLineNumToRentalTaxMap.put(lineItemCompKey+prodLineData.lineNumber, prodLineData);
            }
            System.debug('quoteLineNumToRentalTaxMap->'+JSON.serialize(quoteLineNumToRentalTaxMap));
        }
        
        if(wrapQuoteResp.salesItems != null ){
            for(WrapSalesQuoteLineItem salesLineData : wrapQuoteResp.salesItems){
                quoteLineNumToSalesTaxMap.put(lineItemCompKey+salesLineData.lineNumber,salesLineData);
            }
            System.debug('quoteLineNumToSalesTaxMap->'+JSON.serialize(quoteLineNumToSalesTaxMap));
        }
        
        if(wrapQuoteResp.miscItems != null){
            for(WrapMiscQuoteLineItem misLineData : wrapQuoteResp.miscItems){
                quoteLineNumToMiscTaxMap.put(lineItemCompKey+misLineData.lineNumber,misLineData);
            }
            System.debug('quoteLineNumToMiscTaxMap->'+JSON.serialize(quoteLineNumToMiscTaxMap));
        }
        
        List<SBQQ__QuoteLine__c> quoteItemsToUpdate = new List<SBQQ__QuoteLine__c>();

        for(SBQQ__QuoteLine__c quoteLineItemObj : quoteItems){

            Boolean isTaxChanged = false;
           
            //SF-6347
            String lineItemCompKeyStr;
            if(quoteLineItemObj.Line_Composite_Key__c != null &&  (quoteLineItemObj.Line_Composite_Key__c.startsWith('01-') || quoteLineItemObj.Line_Composite_Key__c.startsWith('02-'))){
                lineItemCompKeyStr = quoteLineItemObj.Line_Composite_Key__c;
            }
            else if(quoteLineItemObj.Line_Composite_Key__c !=null){
                lineItemCompKeyStr =    COMPANY_ID + '-'+ String.valueOf(quoteLineItemObj.Line_Composite_Key__c);
            }
            else{
                lineItemCompKeyStr = '';   
            }
            System.debug('lineItemCompKeyStr->'+lineItemCompKeyStr);

            SBQQ__QuoteLine__c quoteLineItem = new SBQQ__QuoteLine__c();
            quoteLineItem.Id = quoteLineItemObj.Id;

            Decimal rentalTax ;
            Decimal salesTax ;
            Decimal miscTax ;

            if(String.isNotBlank(lineItemCompKeyStr) && !quoteLineNumToRentalTaxMap.isEmpty() && quoteLineNumToRentalTaxMap.containsKey(lineItemCompKeyStr)){
                WrapProductQuoteLineItem prodLineData = quoteLineNumToRentalTaxMap.get(lineItemCompKeyStr);
                rentalTax = Decimal.valueOf(prodLineData.rentalTax);
                quoteLineItem.Total_Price__c = (prodLineData.rentalCost !=null && (quoteLineItemObj.Total_Price__c == null || Decimal.valueOf(prodLineData.rentalCost)!= quoteLineItemObj.Total_Price__c) ) ? Decimal.valueOf(prodLineData.rentalCost):quoteLineItemObj.Total_Price__c;
            }
            if(String.isNotBlank(lineItemCompKeyStr) && !quoteLineNumToSalesTaxMap.isEmpty() && quoteLineNumToSalesTaxMap.containsKey(lineItemCompKeyStr)){
                WrapSalesQuoteLineItem salesLineData = quoteLineNumToSalesTaxMap.get(lineItemCompKeyStr);
                salesTax = Decimal.valueOf(salesLineData.salesTax);
                quoteLineItem.Total_Price__c = (salesLineData.cost !=null && (quoteLineItemObj.Total_Price__c == null || Decimal.valueOf(salesLineData.cost) != quoteLineItemObj.Total_Price__c) ) ? Decimal.valueOf(salesLineData.cost):quoteLineItemObj.Total_Price__c;
            }
            if(String.isNotBlank(lineItemCompKeyStr) && !quoteLineNumToMiscTaxMap.isEmpty() && quoteLineNumToMiscTaxMap.containsKey(lineItemCompKeyStr)){
                WrapMiscQuoteLineItem misLineData =  quoteLineNumToMiscTaxMap.get(lineItemCompKeyStr);
                miscTax = Decimal.valueOf(misLineData.tax);
                quoteLineItem.Total_Price__c = (misLineData.cost != null && (quoteLineItemObj.Total_Price__c == null || Decimal.valueOf(misLineData.cost) != quoteLineItemObj.Total_Price__c) ) ? Decimal.valueOf(misLineData.cost) : quoteLineItemObj.Total_Price__c;
            }

            if(rentalTax != null && ((quoteLineItemObj.Rental_Tax__c != null && quoteLineItemObj.Rental_Tax__c != rentalTax) || quoteLineItemObj.Rental_Tax__c == null )){
                quoteLineItem.Rental_Tax__c = rentalTax;
                isTaxChanged = true;
            }
            if(salesTax != null && ((quoteLineItemObj.Sales_Tax__c != null && quoteLineItemObj.Sales_Tax__c != salesTax) || quoteLineItemObj.Sales_Tax__c == null)){
                quoteLineItem.Sales_Tax__c = salesTax;
                isTaxChanged = true;
            }
            if(miscTax != null && ((quoteLineItemObj.Misc_Charges_Tax__c != null && quoteLineItemObj.Misc_Charges_Tax__c != miscTax) || quoteLineItemObj.Misc_Charges_Tax__c == null)){
                quoteLineItem.Misc_Charges_Tax__c = miscTax;
                isTaxChanged = true;
            }
            //if(isTaxChanged){
                quoteItemsToUpdate.add(quoteLineItem);
            //}
        }
        // update the tax fields on quoteItems
        if(!quoteItemsToUpdate.isEmpty()){
            System.debug('quoteItemsToUpdate->'+JSON.serialize(quoteItemsToUpdate));
            update quoteItemsToUpdate;
        }
        if(hasQuoteTotalChanged){
            update quoteRecord; 
        }
    }

    public class WrapQuoteResponse{
        public String companyId = '';
        public String contractNumber = '';
        public String sequenceNumber ='';
        public String type ='';
        public String channel ='';
        public String contractStartDateTime ='';
        public String contractReturnDateTime ='';
        public String numberOfRentalDays ='';
        public String numberOfRentalHours ='';
        public String isDeliveryAndPickupCharge = ''; 
        public String isRPPCharge = ''; 
        public String assignedToEmployeeID = ''; 
        public String assignedToEmployeeName = ''; 
        public String fulfillmentStatus = ''; 
        public String stagingStatus = ''; 
        public String customerOnSite = '';  
        public List<WrapProductQuoteLineItem> products = new List <WrapProductQuoteLineItem>();
        public List<WrapSalesQuoteLineItem> salesItems = new List <WrapSalesQuoteLineItem>();
        public List<WrapMiscQuoteLineItem> miscItems = new List <WrapMiscQuoteLineItem>();
        public WrapTotals totals = new WrapTotals();
    }

    public class WrapProductQuoteLineItem {
        public String  description = ''; 
        public String  productId = ''; 
        public String  make = ''; 
        public String  model = ''; 
        public String  serialNumber = ''; 
        public String  minimumRate = ''; 
        public String  dayRate = ''; 
        public String  weekRate = ''; 
        public String  monthlyRate = ''; 
        public String  quantity = ''; 
        public String  unitCost = ''; 
        public String  rentalCost = ''; 
        public String  rmLineNumber = ''; 
        public String  lineNumber = ''; 
        public String  rentalTax = ''; 
        public String  miscellaneousOptions = ''; 
    }
    public class WrapMiscQuoteLineItem {
        public String  item = ''; 
        public String  stockClass = ''; 
        public String  quantity = ''; 
        public String  unitCost = ''; 
        public String  cost = ''; 
        public String  tax = ''; 
        public String  rmLineNumber = ''; 
        public String  lineNumber = ''; 
        public String  SKU = ''; 
    }
    public class WrapSalesQuoteLineItem {
        public String  itemNumber = ''; 
        public String  description = ''; 
        public String  stockClass = ''; 
        public String  quantity = ''; 
        public String  unitCost = ''; 
        public String  cost = ''; 
        public String  salesTax = ''; 
        public String  rmLineNumber = ''; 
        public String  lineNumber = ''; 
        public String  SKU = ''; 
    }
    public class WrapTotals {
        public String  rentals = ''; 
        public String  salesAmount = ''; 
        public String  rpp = ''; 
        public String  fuel = ''; 
        public String  environmental = ''; 
        public String  deliveryAndPickup = ''; 
        public String  misc = ''; 
        public String  tax = ''; 
        public String  finalTotal = ''; 
    }
    
}
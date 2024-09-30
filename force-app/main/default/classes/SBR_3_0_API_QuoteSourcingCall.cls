/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_QuoteSourcingCall
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Victor Mitra          2023-01-28             Initial version    
*********************************************************************************************************************/
public class SBR_3_0_API_QuoteSourcingCall {
    private static final String APINAME = 'OptimalSourcingBranch_API';
    private static final String DATA = 'data';
    private static final String PC = 'pc';
    private static final String DELIVERY = 'Delivery';
    private static final String ERROR = 'error';
    private static final String CAT_CLASS = 'H';
    private static final String PARTS = 'P';
    private static final String MERCHANDISE = 'M';
    private static final String DEL = 'DEL';
    
    public static SBR_3_0_WrapOrderSource quoteWrapper;
    public static SBQQ__Quote__c quote;
    String companyId;
    public static Object response;
    public static Map<String,Object> m;
    public static List<SBQQ__QuoteLine__c> listQuoteItem;
    
    public static Map<String,Integer> catClassQtyMap = new Map<String,Integer>();//SAL-25690
    
    @AuraEnabled
    public static void callSource(Id quoteId) {
        try {
            Set<Id> quoteIds = new Set<Id>{quoteId};
                listQuoteItem = new List<SBQQ__QuoteLine__c>();
            Map<Id,SBQQ__Quote__c> quotes;
            quoteWrapper = new SBR_3_0_WrapOrderSource();
            quotes = new Map<Id,SBQQ__Quote__c>(SBR_3_0_QuoteDA.getQuotes(quoteIds));
            for (Id key: quotes.keySet()) {
                quote = quotes.get(key);           
                for (SBQQ__QuoteLine__c quoteItem : quote.SBQQ__LineItems__r)
                {
                    listQuoteItem.add(quoteItem);
                }   
            }
            if(listQuoteItem.size() < 1) {
                throw new QuoteSourcingCallException('You must have at least one Line Item added on the record to retrieve Totals.');
            } else {
                if(quote.OMS_Sourcing_Enabled__c && quote.SBQQ__DeliveryMethod__c == DELIVERY) {
                    validateData();
                    generateWrapper();
                    callAPI();
                    //handleQuoteResponse();
                }else{
                    Boolean isTotalsUpdated =  SBR_3_0_UpdateTotals.updateTotals(quote.Id,null);//23506
                }
            }
        }
        catch(Exception ex){
            throw new QuoteSourcingCallException(ex.getMessage());
        }        
        // return new List<String>{'success'};
    }
    
    private static void callAPI(){
        try {
            String returnPayload = '';
            System.debug('@@@wr'+JSON.serialize(quoteWrapper, true));
            returnPayload = SBR_3_0_Generic_Callout.callEndpoint(JSON.serialize(quoteWrapper, true), APINAME, '');
            response = System.JSON.deserializeUntyped(returnPayload);
            System.debug('reponse==> '+response);
            handleQuoteResponse();
        } catch (Exception ex) {
            throw new QuoteSourcingCallException(ex.getMessage());
        }
    }
    
    private static void validateData() {
        if(quote.SBQQ__DeliveryMethod__c == null) {
            throw new QuoteSourcingCallException('quote.SBQQ__DeliveryMethod__c is required');
        }
        if(quote.Selling_Channel__c == null) {
            throw new QuoteSourcingCallException('quote.Selling_Channel__c is required');
        }
        if(quote.Jobsite__r == null){
            throw new QuoteSourcingCallException('Jobsite is required');
        } else {
            if(quote.Jobsite__r.Latitude_Longitude__Latitude__s == null) {
                throw new QuoteSourcingCallException('Latitude is required on Jobsite');
            } 
            if(quote.Jobsite__r.Latitude_Longitude__Longitude__s == null) {
                throw new QuoteSourcingCallException('Longitude is required on Jobsite');
            } 
            if (quote.Jobsite__r.Location == null) {
                throw new QuoteSourcingCallException('Jobsite Address is required');
            } else {
                if(quote.Jobsite__r.Location.Country__c == null) {
                    throw new QuoteSourcingCallException('quote.Jobsite__r.Location.Country__c is required');
                }
                if (quote.Jobsite__r.Location.City__c == null) {
                    throw new QuoteSourcingCallException('quote.Jobsite__r.Location.City__c is required');
                }
                if (quote.Jobsite__r.Location.State__c == null) {
                    throw new QuoteSourcingCallException('quote.Jobsite__r.Location.State__c is required');
                }
                if (quote.Jobsite__r.Location.Zip_Code__c == null) {
                    throw new QuoteSourcingCallException('quote.Jobsite__r.Location.Zip_Code__c is required');
                }
            }
        }
        for(SBQQ__QuoteLine__c ql: quote.SBQQ__LineItems__r) {
            if(ql.SBQQ__Product__r.Product_Type__c == 'Cat-Class') {
                validateProduct(ql);
            } else if(ql.SBQQ__Product__r.Product_Type__c == 'Parts' || ql.SBQQ__Product__r.Product_Type__c == 'Merchandise') {
                validateSaleItem(ql);
            }
        }
    }
    
    private static void validateProduct(SBQQ__QuoteLine__c quoteItem) {
        if (quoteItem.Misc_Charges_Type__c == null) {
            if (quoteItem.SBQQ__Product__r.Category__c == null) {
                throw new QuoteSourcingCallException('quoteItem.Product2.Category__c is required for Product');
            } 
            if (quoteItem.SBQQ__Product__r.Class__c == null) {
                throw new QuoteSourcingCallException('quoteItem.Product2.Class__c is required for Product');
            } 
            if (quoteItem.SBQQ__Quantity__c == null) {
                throw new QuoteSourcingCallException('quoteItem.Quantity is required for Product');
            } 
            if (quoteItem.SBQQ__Product__r.Product_Type__c == null) {
                throw new QuoteSourcingCallException('quoteItem.Product2.Product_Type__c is required for Product');
            }
        }
    }
    
    private static void validateSaleItem(SBQQ__QuoteLine__c quoteItem) {
        if (quoteItem.SBQQ__Product__r.Item_Number__c == null) {
            throw new QuoteSourcingCallException('quoteItem.Product2.Item_Number__c is required for SaleItem');
        }
        if (quoteItem.SBQQ__Product__r.Stock_Class__c == null) {
            throw new QuoteSourcingCallException('quoteItem.Product2.Stock_Class__c is required for SaleItem');
        }
        if (quoteItem.SBQQ__Quantity__c == null) {
            throw new QuoteSourcingCallException('quoteItem.Quantity is required for SaleItem');
        }
        //SAL-24055
        if (quoteItem.Selling_Price__c == null) {
            throw new QuoteSourcingCallException('quoteItem.Selling_Price__c is required for SaleItem');
        }
    }
    
    private static void handleQuoteResponse() {
        String errorMsg  = '';
        try {
            if(response != null && response instanceof Map<String, Object>) {
                Map<String, Object> resultMap = (Map<String, Object>)response;
                if(resultMap.containsKey(DATA) && resultMap.get(DATA) instanceof Map<String, Object>){
                    Map<String, Object> data = (Map<String, Object>)resultMap.get(DATA);
                    System.debug('@@@data'+data);
                    List<Schema.Location> locationData = new List<Schema.Location>();
                    if(data.containsKey(PC) && data.get(PC) != ''){
                        String branch = String.valueOf(data.get(PC));
                        System.debug('@@@branch'+branch);
                        locationData = SBR_3_0_LocationDA.getLocation(branch);
                        if(!locationData.isEmpty()) {
                            quote.Sourcing_Branch__c = locationData[0].Id;
                            System.debug('locationData[0].Id 153'+locationData[0].Id);
                            System.debug(' quote.Sourcing_Branch__c'+quote.Sourcing_Branch__c);
                            System.debug(' quote.Id'+quote.Id);
                            if(Test.isRunningTest()){
                                return;
                            }
                            Boolean isTotalsUpdated =  SBR_3_0_UpdateTotals.updateTotals(quote.Id,locationData[0]);//23506
                            //update quote;
                        }
                    }else{//SAL-25930
                        locationData = SBR_3_0_LocationDA.getLocation(quote.Branch__r.Branch_Location_Number__c);
                        Boolean isTotalsUpdated =  SBR_3_0_UpdateTotals.updateTotals(quote.Id,locationData[0]);
                    }
                } else if(resultMap.containsKey(ERROR) && resultMap.get(ERROR) instanceof Map<String, Object>) {
                    Map<String, Object> error = (Map<String, Object>)resultMap.get(ERROR);
                    errorMsg = Label.Reservation_API_Error+'\n \n'+' message: '+error.get('message') + ' errorKey: ' + error.get('errorKey') +' errorCode: ' +error.get('errorCode');
                    throw new QuoteSourcingCallException(errorMsg);
                }
            }
        }
        catch(Exception e) {
            throw new QuoteSourcingCallException(e.getMessage());
        }
    }
    
    private static void generateWrapper() {
        String rmQuoteIdSansCompanyCode ='';
        quoteWrapper.companyId = quote.Company_Code__c;
        quoteWrapper.cartId = quote.Name;//quote.Cart__c !=null || quote.Cart__c !='null'?quote.Cart__c:'';
        quoteWrapper.cartType = quote.Selling_Channel__c;
        //quoteWrapper.customerType = 'DEFAULT';
        quoteWrapper.sellingChannel = quote.Selling_Channel__c;
        quoteWrapper.fulfillmentService = SBR_3_0_Constants.FULFILLMENT_SERVICE_URGENT;
        quoteWrapper.fulfillmentType = DEL;
        //quoteWrapper.overrideDistance = true;
        quoteWrapper.sourceSystem = SBR_3_0_Constants.SALESFORCE;
        setJobsite();
        setPC();
        groupQuoteLines(listQuoteItem);     
    }
    
    private static void setPC() {
        quoteWrapper.pc = new SBR_3_0_WrapOrderSource.PC();
        quoteWrapper.pc.id = quote.Company_Code__c+'-'+quote.Branch__r.Branch_Location_Number__c;
        System.debug('quoteWrapper'+ quoteWrapper.pc.id);              
    }
    
    private static void setJobsite() {
        quoteWrapper.jobsite = new SBR_3_0_WrapOrderSource.Jobsite();
        quoteWrapper.jobsite.address = new SBR_3_0_WrapOrderSource.Address();
        quoteWrapper.jobsite.latitude = quote.Jobsite__r.Latitude_Longitude__Latitude__s; 
        quoteWrapper.jobsite.longitude = quote.Jobsite__r.Latitude_Longitude__Longitude__s;
        quoteWrapper.jobsite.timezoneId = quote.Jobsite__r.Time_Zone_Id__c!=NULL?quote.Jobsite__r.Time_Zone_Id__c:quote.Branch__r.Time_Zone_Id__c;        
        quoteWrapper.jobsite.address.line1 = quote.Jobsite__r.Location.Street_Address__c;
        quoteWrapper.jobsite.address.line2 = quote.Jobsite__r.Location.Street_Address_2__c != null?quote.Jobsite__r.Location.Street_Address_2__c:'';
        quoteWrapper.jobsite.address.city = quote.Jobsite__r.Location.City__c;
        quoteWrapper.jobsite.address.state = quote.Jobsite__r.Location.State__c;
        quoteWrapper.jobsite.address.country = quote.Jobsite__r.Location.Country__c;
        quoteWrapper.jobsite.address.zip = quote.Jobsite__r.Location.Zip_Code__c;
        
    }
    
    private static void setProduct(SBQQ__QuoteLine__c quoteItem) {
        SBR_3_0_WrapOrderSource.Products product = new SBR_3_0_WrapOrderSource.Products();
        product.requestedDeliveryDate = quote.Delivery_Date__c != null ? quote.Delivery_Date__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT) : DateTime.now().formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT);
        product.lineId = String.valueOf(quoteItem.ID);
        product.uom = quoteItem.Unit_of_Measure__c;
        product.quantity = quoteItem.SBQQ__Quantity__c.intValue();
        if(quoteItem.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.CAT_CLASS) {
            product.productType = CAT_CLASS;
            if(!catClassQtyMap.isEmpty() && catClassQtyMap.containsKey(quoteItem.SBQQ__Product__r.Product_SKU__c)){
                product.quantity = catClassQtyMap.get(quoteItem.SBQQ__Product__r.Product_SKU__c);
            }
        }
        else if(quoteItem.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.PARTS) {
            product.productType = PARTS;
        }
        else if(quoteItem.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.MERCHANDISE) {
            product.productType = MERCHANDISE;
        }
        product.productId = quoteItem.SBQQ__Product__r.Product_SKU__c;
        product.catId = quoteItem.SBQQ__Product__r.Category__c; 
        product.classId = quoteItem.SBQQ__Product__r.Class__c;
        quoteWrapper.products.add(product);
    }
    
    private static void setSalesItem(SBQQ__QuoteLine__c quoteItem) {
        SBR_3_0_WrapOrderSource.SalesItems salesItems = new SBR_3_0_WrapOrderSource.SalesItems();
        salesItems.itemNumber = quoteItem.SBQQ__Product__r.Item_Number__c;
        salesItems.stockClass = quoteItem.SBQQ__Product__r.Stock_Class__c;
        salesItems.quantity = quoteItem.SBQQ__Quantity__c.intValue(); 
        salesItems.unitPrice = quoteItem?.Selling_Price__c;//SAL-24055
        quoteWrapper.salesItems.add(salesItems);
    }
    
    private static void groupQuoteLines(List<SBQQ__QuoteLine__c> quoteItems) {
        quoteWrapper.products = new List<SBR_3_0_WrapOrderSource.Products>();
        quoteWrapper.salesItems = new List<SBR_3_0_WrapOrderSource.SalesItems>();
        //SAL-25690
        Integer currentQuantity = 0;
        for(SBQQ__QuoteLine__c ql : quoteItems) {
            if(ql.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.CAT_CLASS) {
                currentQuantity = ql.SBQQ__Quantity__c.intValue();
                if(!catClassQtyMap.isEmpty() && catClassQtyMap.containsKey(ql.SBQQ__Product__r.Product_SKU__c)){
                    Integer existingQty = catClassQtyMap.get(ql.SBQQ__Product__r.Product_SKU__c);
                    catClassQtyMap.put(ql.SBQQ__Product__r.Product_SKU__c, currentQuantity+existingQty);
                }else{
                    catClassQtyMap.put(ql.SBQQ__Product__r.Product_SKU__c, currentQuantity);
                }
            }
        }
        for(SBQQ__QuoteLine__c ql: quoteItems) {
            if(ql.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.CAT_CLASS) {
                setProduct(ql);
            } else if(ql.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.PARTS || ql.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.MERCHANDISE) {
                setSalesItem(ql);
            }}
        if(quoteWrapper.salesItems.size() < 1) quoteWrapper.salesItems = null;
    }      
    
    //Added this method as part of FRONT-21763
    @AuraEnabled
    public static void callSourceFrontline(SBQQ__Quote__c quoteObj, Id quoteId) {
        try {
            quoteObj.Id = quoteId;
            update quoteObj;           
        }
        catch(Exception ex){
            System.debug(LoggingLevel.DEBUG, ex.getLineNumber() + '==ex==' + ex.getMessage());
            throw new QuoteSourcingCallException(ex.getMessage());
        }
    }
    
    public class QuoteSourcingCallException extends Exception {}
}
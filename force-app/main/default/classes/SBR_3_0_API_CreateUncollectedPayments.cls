/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateUncollectedPayments
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - @description Send Payments to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Vivek Sharma          2024-03-18            Initial version    
*********************************************************************************************************************/
@SuppressWarnings('PMD.ExcessiveParameterList,PMD.CyclomaticComplexity')
public class SBR_3_0_API_CreateUncollectedPayments {

    private static final String API_UNCOLLECTED_PAYMENT = 'Create_UCP_API';
    private Id orderId;
    private String companyId;
    private SBR_3_0_WrapPayment.UCPDeposits ucpWrapper;
    private Order order;
    @TestVisible
    private static Object response;
    @TestVisible
    public static String makeADepositDetails = '';
    /**
    * @description BadRequestException.
    */
    public class BadRequestException extends Exception{}
    
    /**
    * @description AuraEnabled method to create payments.
    * @param orderRecordId ID of the order record.
    * @param paymentDepositData Payment deposit data as a string.
    * @param transactionId Transaction ID associated with the payment.
    * @param wynneUserName Username for authentication.
    * @return Object representing the response from the API call.
    * @throws BadRequestException If the API returns an error, it throws a BadRequestException with details.
    */
    @AuraEnabled
    public static object createUncollectedPayment(Id orderRecordId , String paymentDepositData,Id transactionId,String wynneUserName) {
        SBR_3_0_Log.setRelatedRecordId(orderRecordId);
        SBR_3_0_Generic_Callout.sourceTransactionId = transactionId;  
        SBR_3_0_Generic_Callout.sourceSystemUserId =wynneUserName ;    
        makeADepositDetails = paymentDepositData;
        new SBR_3_0_API_CreateUncollectedPayments(orderRecordId);
        Map<String, Object> responseMap = (Map<String, Object>) response;
        if(responseMap != null) {
            if(responseMap.containsKey('error')){
                String jsonExceptionString = JSON.serialize(responseMap);
                SBR_3_0_Log.logInfo(jsonExceptionString);
                throw new BadRequestException(jsonExceptionString);
            }      
        }
        return response;
    }
    
    /**
    * @description Constructor for initializing payment creation process.
    * @param orderRecordId ID of the order record for which payments are to be created.
    */
    public SBR_3_0_API_CreateUncollectedPayments(Id orderRecordId) {
        try{
            List<Order> orders =new List<Order>(SBR_3_0_OrderDA.getPaymentOrder(orderRecordId));
            ucpWrapper = new SBR_3_0_WrapPayment.UCPDeposits();
            this.orderId = orderRecordId;
            for (Order order : orders) {
                this.companyId = order.Company_Code__c;
                ucpWrapper.currencyIsoCode= order.CurrencyIsoCode;
                ucpWrapper.pc = order.Sourcing_Branch__r.Branch_Location_Number__c;
                ucpWrapper.invSeqNumber = order.Invoice_Sequence_Number__c;
                SBR_3_0_HttpCallout.contractId = order.Reservation_Order_Number__c;
            }
            setUncollectedPaymentDetails();
            createUncollectedPayment();
        }catch(Exception ex){
            SBR_3_0_Log.logException(ex);
        }finally {
            SBR_3_0_Log.saveLog();       
        }          
    }
    
    /**
     * @description Private method to initiate payment creation via external API call.
    */
    private void createUncollectedPayment(){
        try{
            String returnPayload = '';
            returnPayload = SBR_3_0_Generic_Callout.callEndpoint(JSON.serialize(this.ucpWrapper, true), API_UNCOLLECTED_PAYMENT, this.companyId);    
            response = JSON.deserializeUntyped(returnPayload);
        }catch(Exception Ex){
            SBR_3_0_Log.logException(ex);
        }   
    }
    
    /**
     * @description Private method to set payment details based on input data.
    */
    @TestVisible
    private void setUncollectedPaymentDetails(){
        try{
            Map<String,String> mapOfPaymentMenthodAnnotation = new map<String,String>{'Visa' =>'V','Amex' => 'A','Cash Currency' => 'C', 'Discover' => 'D', 'Interac Debit' => 'G' , 'Check' => 'K' , 'Mastercard' => 'M','No Refund Given' => 'N', 'Pay On Return'=> 'P','Refund Request (Corporate)' => 'R','Uncollected' => 'U','Diners Club'=> 'X' };        
            Map<String, Object> paymentDetailsObject = (Map<String, Object>)JSON.deserializeUntyped(makeADepositDetails);
            String pmSelected = (String)paymentDetailsObject.get('paymentMethod');
            SBR_3_0_Generic_Callout.PaymentMethod = (String)paymentDetailsObject.get('paymentMethod');
            ucpWrapper.depositType =mapOfPaymentMenthodAnnotation.get(pmSelected);
            ucpWrapper.depositAmount= (Decimal)paymentDetailsObject.get('amountCollected');
            if (mapOfPaymentMenthodAnnotation.get(pmSelected) == 'K' ){
                ucpWrapper.checkNumber =String.valueOf(paymentDetailsObject.get('checkNumber'));
            }
            Boolean isPreviousCardUsed = (boolean)paymentDetailsObject.get('usePreviousCard') == true;
            if ((mapOfPaymentMenthodAnnotation.get(pmSelected) == 'A' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'V' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'D' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'M' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'X' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'G') && !isPreviousCardUsed) {
                ucpWrapper.lane=(String.valueOf(paymentDetailsObject.get('terminal'))==null || String.valueOf(paymentDetailsObject.get('terminal'))=='') ? '': String.valueOf(paymentDetailsObject.get('terminal')).split('ID: ')[1];
            }
        }catch(Exception Ex){
            SBR_3_0_Log.logException(ex);
        }        
    }
}
/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreatePayments
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - @description Send Payments to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Vivek Sharma          2024-03-18            Initial version    
*********************************************************************************************************************/
@SuppressWarnings('PMD.ExcessiveParameterList,PMD.CyclomaticComplexity')
public with sharing class SBR_3_0_API_CreatePayments {
    private static final String APINAMEPAYMENTS = 'Create_Payments_API';
    private Id orderId;
    private String companyId;
    private SBR_3_0_WrapPayment.AdditionalDeposits paymentWrapper;
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
    public static object createPayments(Id orderRecordId , String paymentDepositData,Id transactionId ,String wynneUserName) {
        SBR_3_0_Log.setRelatedRecordId(orderRecordId);
        SBR_3_0_Generic_Callout.sourceTransactionId = transactionId;  
        SBR_3_0_Generic_Callout.sourceSystemUserId =wynneUserName ;
        makeADepositDetails = paymentDepositData;
        new SBR_3_0_API_CreatePayments(orderRecordId);
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
    public SBR_3_0_API_CreatePayments(Id orderRecordId) {
        try{
            List<Order> orders =new List<Order>(SBR_3_0_OrderDA.getPaymentOrder(orderRecordId));
            paymentWrapper = new SBR_3_0_WrapPayment.AdditionalDeposits();
            this.orderId = orderRecordId;

            for (Order order : orders) {
                this.companyId = order.Company_Code__c;
                paymentWrapper.currencyIsoCode= order.CurrencyIsoCode;
                paymentWrapper.pc = order.Sourcing_Branch__r.Branch_Location_Number__c;
                SBR_3_0_HttpCallout.contractId = !String.isEmpty(order.Reservation_Order_Number__c) ? order.Reservation_Order_Number__c : order.Contract_Order_Number__c;
            }
            setPaymentDetails();
            createPayment();
        }catch(Exception ex){
            SBR_3_0_Log.logException(ex);
        }finally {
            SBR_3_0_Log.saveLog();
        } 
    }

    /**
     * @description Private method to initiate payment creation via external API call.
    */
    private void createPayment(){
        try{
            String returnPayload = '';
            returnPayload = SBR_3_0_Generic_Callout.callEndpoint(JSON.serialize(this.paymentWrapper, true), APINAMEPAYMENTS, this.companyId);    
            response = JSON.deserializeUntyped(returnPayload);
        }catch(Exception Ex){
            SBR_3_0_Log.logException(ex);
        }    
    }
   
    /**
     * @description Private method to set payment details based on input data.
    */
    @TestVisible
    private void setPaymentDetails(){
        try{
            Map<String,String> mapOfPaymentMenthodAnnotation = new map<String,String>{'Visa' =>'V','Amex' => 'A','Cash Currency' => 'C', 'Discover' => 'D', 'Interac Debit' => 'G' , 'Check' => 'K' , 'Mastercard' => 'M','No Refund Given' => 'N', 'Pay On Return'=> 'P','Refund Request (Corporate)' => 'R','Uncollected' => 'U','Diners Club'=> 'X' };        
            Map<String, Object> paymentDetailsObject = (Map<String, Object>)JSON.deserializeUntyped(makeADepositDetails); 
            String pmSelected = (String)paymentDetailsObject.get('paymentMethod');
            SBR_3_0_Generic_Callout.PaymentMethod = (String)paymentDetailsObject.get('paymentMethod');
            paymentWrapper.depositType =mapOfPaymentMenthodAnnotation.get(pmSelected);
            paymentWrapper.depositAmount= (Decimal)paymentDetailsObject.get('amountCollected');
            if (mapOfPaymentMenthodAnnotation.get(pmSelected) == 'K' ){
                paymentWrapper.checkNumber =String.valueOf(paymentDetailsObject.get('checkNumber'));
            }
            Boolean isPreviousCardUsed = (boolean)paymentDetailsObject.get('usePreviousCard') == true;
            if ((mapOfPaymentMenthodAnnotation.get(pmSelected) == 'A' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'V' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'D' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'M' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'X' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'G') && !isPreviousCardUsed) {//Make sure CreditCardlane is passed only if card is selected.
                paymentWrapper.lane=(String.valueOf(paymentDetailsObject.get('terminal'))==null || String.valueOf(paymentDetailsObject.get('terminal'))=='') ? '': String.valueOf(paymentDetailsObject.get('terminal')).split('ID: ')[1];
            }
            if ((mapOfPaymentMenthodAnnotation.get(pmSelected) == 'A' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'V' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'D' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'M' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'X' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'G') && isPreviousCardUsed) {//Make sure CreditCardlane is passed only if card is selected.
                paymentWrapper.usePreviousCard = (boolean)paymentDetailsObject.get('usePreviousCard');
            }
        }catch(Exception Ex){
            SBR_3_0_Log.logException(ex);
        }        
    }
}
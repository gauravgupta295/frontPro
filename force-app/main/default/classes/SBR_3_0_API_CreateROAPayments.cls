/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateROAPayments
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - @description Send Payments to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Vivek Sharma          2024-03-18            Initial version    
*********************************************************************************************************************/
@SuppressWarnings('PMD.ExcessiveParameterList,PMD.CyclomaticComplexity')
public class SBR_3_0_API_CreateROAPayments {
    private static final String API_ROA_PAYMENT = 'Create_ROA_API';
    private Id accountId;
    private String companyId;
    private SBR_3_0_WrapPayment.ROADeposits roaDeposits;
    private SBR_3_0_WrapPayment.Payment payments;
    private Account account;
    @TestVisible
    private static Object response;
    @TestVisible
    public static String makeADepositDetails = '';
    /**
    * @description BadRequestException.
    */
    public class BadRequestException extends Exception{}
    
    /**
     * @description Private method to save PaymentRecord.
    */
    public class PaymentRecord {
        public Decimal paymentAmount;
        public String comment;
        public String sfReferenceNumber;
    }

    /**
    * @description Creates a ROA (Remote Online Authorization) payment record for an account.
    * This method initiates the creation of ROA payments based on the provided parameters.
    *
    * @param accountRecordId The Salesforce ID of the account record.
    * @param paymentDepositData JSON string containing deposit/payment data.
    * @param transactionId The transaction ID associated with the payment.
    * @param paymentRecords JSON string representing payment records.
    * @param wynneUserName The username for the Wynne system integration.
    * @return Returns a response object containing the result of the payment creation.
    * @throws BadRequestException Throws a BadRequestException if an error is encountered during the operation.
    */
    @AuraEnabled
    public static object createRoaPayment(Id accountRecordId , String paymentDepositData,Id transactionId, String paymentRecords,String wynneUserName) {   
        SBR_3_0_Log.setRelatedRecordId(accountRecordId);
        SBR_3_0_Generic_Callout.sourceTransactionId = transactionId;    
        SBR_3_0_Generic_Callout.sourceSystemUserId =wynneUserName ;  
        makeADepositDetails = paymentDepositData;
        new SBR_3_0_API_CreateROAPayments(accountRecordId,paymentRecords);
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
    * @param accountRecordId ID of the account record for which payments are to be created.
    * @param paymentRecords payment records for which payments are to be created.
    */
    public SBR_3_0_API_CreateROAPayments(Id accountRecordId,String paymentRecords) {
        try{
            List<Account> accounts =new List<Account>(SBR_3_0_OrderDA.getPaymentAccount(accountRecordId));
            roaDeposits = new SBR_3_0_WrapPayment.ROADeposits();
            this.accountId = accountRecordId;

            for (Account acct : accounts) {
                this.companyId = acct.Company_Code__c;
                roaDeposits.pc = acct.Branch_Location_Number__c;          
                SBR_3_0_HttpCallout.contractId = acct.Salesforce_Account_Number__c;
            }
            setRoaPaymentDetails(paymentRecords);
            createRoaPayment();
        }catch(Exception ex){
            SBR_3_0_Log.logException(ex);
        }finally {
            SBR_3_0_Log.saveLog();
        } 
    }
    
    /**
     * @description Private method to initiate payment creation via external API call.
    */
    private void createRoaPayment(){
        try{
            String returnPayload = '';
            returnPayload = SBR_3_0_Generic_Callout.callEndpoint(JSON.serialize(this.roaDeposits, true), API_ROA_PAYMENT, this.companyId);    
            response = JSON.deserializeUntyped(returnPayload);
        }catch(Exception Ex){
            SBR_3_0_Log.logException(ex);
        }    
    }
    
    /**
     * @description Private method to set payment details based on input data.
     * @param paymentRecords JSON string representing payment records.
    */
    @TestVisible
    private void setRoaPaymentDetails(String paymentRecords){
        try{
            Map<String,String> mapOfPaymentMenthodAnnotation = new map<String,String>{'Visa' =>'V','Amex' => 'A','Cash Currency' => 'C', 'Discover' => 'D', 'Interac Debit' => 'G' , 'Check' => 'K' , 'Mastercard' => 'M','No Refund Given' => 'N', 'Pay On Return'=> 'P','Refund Request (Corporate)' => 'R','Uncollected' => 'U','Diners Club'=> 'X' };        
            Map<String, Object> paymentDetailsObject = (Map<String, Object>)JSON.deserializeUntyped(makeADepositDetails);
            String pmSelected = (String)paymentDetailsObject.get('paymentMethod');
            SBR_3_0_Generic_Callout.PaymentMethod = (String)paymentDetailsObject.get('paymentMethod');
            roaDeposits.paymentType =mapOfPaymentMenthodAnnotation.get(pmSelected);
            roaDeposits.paymentAmount= (Decimal)paymentDetailsObject.get('amountCollected');
            if (mapOfPaymentMenthodAnnotation.get(pmSelected) == 'K' ){
                roaDeposits.checkNumber =String.valueOf(paymentDetailsObject.get('checkNumber'));// need to check regarding this.
            }
            Boolean isPreviousCardUsed = (boolean)paymentDetailsObject.get('usePreviousCard') == true;
            if ((mapOfPaymentMenthodAnnotation.get(pmSelected) == 'A' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'V' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'D' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'M' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'X' || mapOfPaymentMenthodAnnotation.get(pmSelected) == 'G') && !isPreviousCardUsed) {
                roaDeposits.laneNumber=(String.valueOf(paymentDetailsObject.get('terminal'))==null || String.valueOf(paymentDetailsObject.get('terminal'))=='') ? '': String.valueOf(paymentDetailsObject.get('terminal')).split('ID: ')[1];
            }
            List<SBR_3_0_WrapPayment.Payment> paymentsList = new List<SBR_3_0_WrapPayment.Payment>();
            List<PaymentRecord> paymentRecordList = (List<PaymentRecord>)JSON.deserialize(paymentRecords, List<PaymentRecord>.class);
            for (PaymentRecord roaRec : paymentRecordList) {
                SBR_3_0_WrapPayment.Payment payment = new SBR_3_0_WrapPayment.Payment();
                payment.paymentAmount = roaRec.paymentAmount;
                payment.comment = roaRec.comment;
                payment.sfReferenceNumber = roaRec.sfReferenceNumber;
                paymentsList.add(payment);
            }
            roaDeposits.payments = paymentsList; 
        }catch(Exception Ex){
            SBR_3_0_Log.logException(ex);
        }        
    }
}
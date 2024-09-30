/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_ContractResponse
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Wrapper class for Create Contract API Response
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Nilesh Jaiswal          2024-05-27          Initial version   
*********************************************************************************************************************/
public without sharing class SBR_3_0_API_ContractResponse {
  public Data data;

  public class Data {
    public String rmContractId;
    public String sfOrderId;
    public String detailSeqNumber;
    //public String validation;
    //public List<ValidationFailures> validationFailures;
    public List<Lines> lines;
  }

  public class Lines {
    public Integer lineNumber;
    public String sfLineNumber;
    public Integer rmLineNumber;
    public String rmLineType;
    public String rmItemNumber;
    public String rmStockClass;
    public Integer rmProductSku;
  }

  /*public class ValidationFailures {
    public String sfLineNumber;
    public String validationInfo;
  }*/

  public static SBR_3_0_API_ContractResponse parse(String json) {
    return (SBR_3_0_API_ContractResponse) System.JSON.deserialize(
      json,
      SBR_3_0_API_ContractResponse.class
    );
  }
}
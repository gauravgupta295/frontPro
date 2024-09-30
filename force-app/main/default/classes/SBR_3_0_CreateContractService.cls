/*********************************************************************************************************************
* Apex Class: SBR_3_0_CreateContractService
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to send the payload to Create Contract End Point
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Nilesh Jaiswal          2024-05-27          Initial version   
*********************************************************************************************************************/
public without sharing class SBR_3_0_CreateContractService {
  private static final String APINAME = 'Create_Contract_API';
  private Id orderId;
  private String companyId;
  @TestVisible
  private Order order;
  private String response;
  private Map<Integer, OrderItem> mapOrderItem;
  private Integer responseStatusCode;
  private string servicePayload;
  private String currentUserWynneUserName;

  @AuraEnabled
  public static Object submitContract(Id orderId) {
    SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
    return contractInstance.submit(orderId);
  }

  public Object submit(Id orderId) {
    String responseBody;
    Set<Id> orderIds;
    Map<Id, Order> orders;
    this.orderId = orderId;
    orderIds = new Set<Id>();
    mapOrderItem = new Map<Integer, OrderItem>();
    orderIds.add(orderId);
    orders = new Map<Id, Order>(SBR_3_0_OrderDA.getOrders(orderIds));
    order = orders.get(orderId);

    this.companyId = String.isNotBlank(order.Company_Code__c)
      ? order.Company_Code__c
      : '01';
    validateData();
    servicePayload = SBR_3_0_ContractServicePayloadGenerator.generatePayload(
      order
    );
    if (order.Contract_Order_Number__c == null) {
      responseBody = createContract();
    }
    handleOrderResponse();
    return responseBody;
  }

  private string createContract() {
    HTTPResponse returnPayload;
    Map<String, String> headers = new Map<String, String>();
    headers.put('x-correlation-id', SBR_3_0_Generic.generateRandomString(10));
    headers.put('companyId', this.companyId);
    SBR_3_0_Generic_Callout.setHeaders(headers);
    returnPayload = SBR_3_0_Generic_Callout.callEndpoint(
      servicePayload,
      APINAME
    );
    responseStatusCode = returnPayload.getStatusCode();
    System.debug('\n @@ HTTPresponse =' + returnPayload);
    response = returnPayload.getBody();
    System.debug('\n @@ response =' + response);
    return returnPayload.getBody();
  }

  private void handleOrderResponse() {
    if (response != null) {
      SBR_3_0_API_ContractResponse responseWrapper = SBR_3_0_API_ContractResponse.parse(
        response
      );
      Map<String, OrderItem> orderItemMap = new Map<String, OrderItem>();
      List<OrderItem> orderItemList = new List<OrderItem>();
      for (OrderItem orderItem : order.OrderItems) {
        orderItemMap.put(orderItem.OrderItemNumber, orderItem);
      }
      if (responseWrapper.data != null) {
        if (responseWrapper.data.lines != null) {
          for (
            SBR_3_0_API_ContractResponse.Lines lineItem : responseWrapper.data.lines
          ) {
            if (orderItemMap.containsKey(lineItem.sfLineNumber)) {
              OrderItem tempItem = orderItemMap.get(lineItem.sfLineNumber);
              tempItem.Global_Line_Number__c = lineItem.lineNumber;
              tempItem.Contract_Line_Number__c = lineItem.rmLineNumber;
              tempItem.Line_Item_Type__c = lineItem.rmLineType;
              orderItemList.add(tempItem);
            }
          }
          update orderItemList;
        }
        if (responseWrapper.data.rmContractId != null) {
          order.Contract_Order_Number__c = responseWrapper.data.rmContractId;
          update order;
        }
      }
    }
  }

  @TestVisible
  private void validateData() {
    if (order.Order_By__r.FirstName == null) {
      throw new CreateContractException(
        Label.SBR_3_0_OrderAPI_OrdrByFrstName_ErrMsg
      );
    }
    if (order.Order_By__r.Email == null) {
      throw new CreateContractException(
        Label.SBR_3_0_OrderAPI_OrderByEmail_ErrMsg
      );
    }
    if (order.Order_By__r.Phone == null) {
      throw new CreateContractException(
        Label.SBR_3_0_OrderAPI_OrderByPhone_ErrMsg
      );
    }
    if (
      order.Order_By__r.Phone != null &&
      order.Order_By__r.Phone.length() < 10
    ) {
      throw new CreateContractException(
        Label.SBR_3_0_OrderAPI_OrderByPhoneNotValid_ErrMsg
      );
    }
    if (order.Sales_Rep__r.RepID__c == null) {
      throw new CreateContractException(
        Label.SBR_3_0_OrderAPI_SalesRepId_ErrMsg
      );
    }
    if (order.Return_Date__c == null) {
      throw new CreateContractException(
        Label.SBR_3_0_OrderAPI_ReturnDate_ErrMsg
      );
    }
    if (order.Account.Record_Type_Text__c != 'Non-Credit') {
      if (order.RM_Account_Number__c == null) {
        throw new CreateContractException(
          Label.SBR_3_0_OrderAPI_RMAccNumber_ErrMsg
        );
      }
    }
    if (order.Account.Phone == null) {
      throw new CreateContractException(Label.SBR_3_0_OrderAPI_AccPhone_ErrMsg);
    }
    if (order.Account.Record_Type_Text__c != 'Non-Credit') {
      if (order.Jobsite__r == null) {
        throw new CreateContractException(
          Label.SBR_3_0_OrderAPI_Jobsite_ErrMsg
        );
      } else {
        if (order.Jobsite__r.Branch__r == null) {
          throw new CreateContractException(
            Label.SBR_3_0_OrderAPI_Branch_ErrMsg
          );
        } else {
          if (order.Jobsite__r.Branch__r.Branch_Location_Number__c == null) {
            throw new CreateContractException(
              Label.SBR_3_0_OrderAPI_BrnchLocationNmbr_ErrMsg
            );
          }
          if (order.Jobsite__r.Branch__r.Time_Zone_Id__c == null) {
            throw new CreateContractException(
              Label.SBR_3_0_OrderAPI_LocationTimeZoneId_ErrMsg
            );
          }
        }
        if (order.Jobsite__r.Location == null) {
          throw new CreateContractException(
            Label.SBR_3_0_OrderAPI_JobsiteAddress_ErrMsg
          );
        } else {
          if (order.Jobsite__r.Location.OMS_Sourcing_Enabled__c == null) {
            throw new CreateContractException(
              Label.SBR_3_0_OrderAPI_JobsiteLocationOMSSourcingEnabled_ErrMsg
            );
          }
          if (order.Jobsite__r.LocationId == null) {
            throw new CreateContractException(
              Label.SBR_3_0_OrderAPI_JobsiteLocationId_ErrMsg
            );
          }
          if (order.Jobsite__r.Job_Number__c == null) {
            throw new CreateContractException(
              Label.SBR_3_0_OrderAPI_JobsiteJobNumber_ErrMsg
            );
          }
        }
      }
    }
    for (OrderItem orderItemRec : order.OrderItems) {
      if (orderItemRec.Product2.Product_Type__c == 'Cat-Class') {
        validateProduct(orderItemRec);
      } else if (
        (orderItemRec.Product2.Product_Type__c == SBR_3_0_Constants.PARTS ||
        orderItemRec.Product2.Product_Type__c ==
        SBR_3_0_Constants.MERCHANDISE) ||
        (orderItemRec.Product2.Product_Type__c == 'MISC Charge Items' ||
        orderItemRec.Product2.Product_Type__c == 'Misc-Charge')
      ) {
        validateSaleItem(orderItemRec);
      }
    }
  }

  @TestVisible
  private void validateProduct(OrderItem orderItem) {
    if (orderItem.Misc_Charges_Type__c == null) {
      if (orderItem.Min_Rate__c == null) {
        throw new CreateContractException(
          Label.SBR_3_0_OrderAPI_MinRate_ErrMsg
        );
      }
      if (orderItem.Daily_Rate__c == null) {
        throw new CreateContractException(
          Label.SBR_3_0_OrderAPI_DailyRate_ErrMsg
        );
      }
      if (orderItem.Weekly_Rate__c == null) {
        throw new CreateContractException(
          Label.SBR_3_0_OrderAPI_WeeklyRate_ErrMsg
        );
      }
      if (orderItem.Monthly_Rate__c == null) {
        throw new CreateContractException(
          Label.SBR_3_0_OrderAPI_MonthlyRate_ErrMsg
        );
      }
      if (orderItem.Quantity == null) {
        throw new CreateContractException(
          Label.SBR_3_0_OrderAPI_Quantity_ErrMsg
        );
      }
      if (orderItem.Product2.Category__c == null) {
        throw new CreateContractException(
          Label.SBR_3_0_OrderAPI_ProductCategory_ErrMsg
        );
      }
      if (orderItem.Product2.Class__c == null) {
        throw new CreateContractException(
          Label.SBR_3_0_OrderAPI_ProductClass_ErrMsg
        );
      }
    }
  }

  @TestVisible
  private void validateSaleItem(OrderItem orderItem) {
    if (orderItem.Quantity == null) {
      throw new CreateContractException(
        Label.SBR_3_0_OrderAPI_QuantitySalesItem_ErrMsg
      );
    }
    if (orderItem.Selling_Price__c == null || orderItem.Selling_Price__c == 0) {
      throw new CreateContractException(
        Label.SBR_3_0_OrderAPI_SellingPriceSalesItem_ErrMsg
      );
    }
    if (
      orderItem.Order_Item_Unit_Of_Measure__c == null ||
      orderItem.Order_Item_Unit_Of_Measure__c == ''
    ) {
      throw new CreateContractException(
        Label.SBR_3_0_OrderAPI_OrderItemUntOfMsr_ErrMsg
      );
    }
    if (orderItem.Product2.Item_Number__c == null) {
      throw new CreateContractException(
        Label.SBR_3_0_OrderAPI_ProductOrderItemNumber_ErrMsg
      );
    }
    if (orderItem.Product2.Stock_Class__c == null) {
      throw new CreateContractException(
        Label.SBR_3_0_OrderAPI_ProductStockClass_ErrMsg
      );
    }
    if (orderItem.OrderItemNumber == null) {
      throw new CreateContractException(
        Label.SBR_3_0_OrderAPI_ProductOrderItemNumber_ErrMsg
      );
    }
  }

  public class CreateContractException extends Exception {
  }
}
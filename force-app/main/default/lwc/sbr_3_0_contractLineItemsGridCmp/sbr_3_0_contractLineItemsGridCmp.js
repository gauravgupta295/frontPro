import { LightningElement, api, track, wire } from "lwc";
import { CLI } from "c/sbr_3_0_frontlineConstants";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
import { getRecord } from "lightning/uiRecordApi";
import getLineItemsColumns from "@salesforce/apex/Sbr_3_0_ContractController.getContractLineItemColumns";
const logger = Logger.create(true);
const ORDER_FIELDS = [
  "Order.OwnerId",
  "Order.RPP_Amount__c",
  "Order.Total_Misc__c",
  "Order.Total_Rental_Amount__c",
  "Order.Total_Sales_Amount__c",
  "Order.Total_Sales_Taxes__c",
  "Order.Id",
  "Order.Order_Discount__c",
  //Start FRONT-7977
  "Order.Reservation_Order_Number__c",
  "Order.Contract_Order_Number__c",
  "Order.Record_Type_Name__c",
  //End FRONT-7977
  "Order.Status",
  "Order.Account.RecordType.Name",
  //START: FRONT-8736//
  "Order.Branch__r.Analysis_Region2__r.Allow_Header_Discounts__c",
  "Order.Record_Locked__c",
  "Order.Is_Specific_Pricing_Flag__c",
  "Order.Specific_Pricing_Flag__c",
  //END: FRONT-8736//
  //START: FRONT-9235
  "Order.Is_Edit_In_Progress__c",
  //END: FRONT-9235
  "Order.Is_Edited_By_Current_User__c", //FRONT-20871
  "Order.Start_Date__c" //FRONT-16656
];
const fields = [
  "OrderItem.Id",
  "OrderItem.Product2.Name",
  "OrderItem.Product2.Product_SKU__c",
  "OrderItem.Product2.itemNumberUsedByReservationsRentalOut__c", // FRONT-16652, FRONT-16650
  "OrderItem.Product2.Bulk_Item__c", // FRONT-16652, FRONT-16650
  "OrderItem.SBQQ__Asset__c", // FRONT-16652, FRONT-16650
  "OrderItem.SBQQ__Asset__r.Name", // FRONT-16652, FRONT-16650
  "OrderItem.Meter_Reading_Out__c", // FRONT-16652, FRONT-16650
  "OrderItem.Quantity",
  "OrderItem.Min_Rate__c",
  "OrderItem.Min_Rate2__c",
  "OrderItem.Daily_Rate2__c",
  "OrderItem.Weekly_Rate2__c",
  "OrderItem.Monthly_Rate2__c",
  "OrderItem.Selling_Price__c",
  "OrderItem.UnitPrice",
  "OrderItem.Total_Price__c",
  "OrderItem.groupID__c",
  "OrderItem.Cat_Class__c",
  "OrderItem.Product2Id",
  "OrderItem.Line_Comments__c",
  "OrderItem.Specific_Pricing_Type__c",
  "OrderItem.Suggested_Daily_Rate__c",
  "OrderItem.Suggested_Weekly_Rate__c",
  "OrderItem.Suggested_Monthly_Rate__c",
  "OrderItem.Product2.Product_Type__c",
  "OrderItem.Product2.Type_of_Misc_Charge_Item__c",
  "OrderItem.Misc_Charges_Type__c",
  "OrderItem.Product2.User_Select__c",
  "OrderItem.Product2.Stock_class__c",
  "OrderItem.Product2.Is_Kit__c",
  "OrderItem.is_Line_Item_Hidden__c",
  "OrderItem.Line_Item_Type__c",
  "OrderItem.is_User_Added__c",
  "OrderItem.Status__c", //FRONT-1639
  "Status__c", //FRONT-1639
  "OrderItem.Status_Created_Qty__c", //FRONT-9233, 1950
  "OrderItem.Status_Filled_Qty__c", //FRONT-9233
  "OrderItem.Status_Cancelled_Qty__c", //FRONT-9233
  "OrderItem.Allow_Cancel__c", //FRONT-1950, 1958
  "OrderItem.Discount_Percentage__c" //20309
];

export default class Sbr_3_0_contractLineItemsGridCmp extends LightningElement {
  @api recordId;
  @api objectApiName;
  @api variant;
  @track lineItemsCols;
  lineItems = [];
  relatedListId = "OrderItems";
  fields = fields;

  @api showRemoveScreen; //added for FRONT-31384 - Mobile Change
  @api showRemoveScreenSales; //FRONT-29023
  ORDER_FIELDS = ORDER_FIELDS;
  @track parentRecord;
  @wire(getRelatedListRecords, {
    parentRecordId: "$recordId",
    relatedListId: "$relatedListId",
    fields: "$fields"
  })
  listInfo(result) {
    this.showSpinner = false;
    this.listInfoResults = result;
    let data = result.data,
      error = result.error;
    if (data) {
      this.lineItems = [];
      data.records.forEach((record) => {
        this.lineItems.push(record);
      });
    } else if (error) {
      console.log(error);
    }
  }

  @wire(getLineItemsColumns, { contractContext: "$variant" }) //Added for FRONT-9233
  lineItemsColumns({ error, data }) {
    if (data) {
      this.lineItemsCols = data;
      console.log("Line Item Cols" + JSON.stringify(this.lineItemsCols));
      console.log("Variant is " + this.variant);
      /*   this.rentalLineItemsCols = data.filter(
          (col) => col.Context__c === "Contract Line Item" //Added for FRONT-28988
        );
         this.salesLineItemsCols = data.filter(
          (col) => col.Context__c === "Sales/Misc Contract Line Item" //Added for FRONT-28988
        );*/
    } else if (error) {
      logger.log(error);
    }
  }

  @wire(getRecord, { recordId: "$recordId", fields: "$ORDER_FIELDS" })
  wiredRecord({ error, data }) {
    logger.log("order Data" + JSON.stringify(data));
    logger.log("order Data" + JSON.stringify(error));

    if (data) {
      logger.log("order Data" + JSON.stringify(data));
      this.parentRecord = data;
    } else if (error) {
      logger.log("error in get Order Record" + JSON.stringify(error));
    }
  }

  //Added for FRONT-31386
  @api
  selectAllInRentalsCmp() {
    const rentalsComponent = this.template.querySelector(
      "c-sbr_3_0_contract-line-items-rentals-cmp"
    );
    if (rentalsComponent) {
      rentalsComponent.selectAllCheckbox();
    } else {
      console.error("Rentals component not found");
    }
  }

  //FRONT-29023
  @api
  selectAllInConsumablesCmp() {
    const salesComponent = this.template.querySelector(
      "c-sbr_3_0_contract-line-items-sales-cmp"
    );
    if (salesComponent) {
      salesComponent.selectAllCheckbox();
    } else {
      console.error("Rentals component not found");
    }
  }

  get showRentalDetails() {
    return this.variant === CLI.RENTAL;
  }

  get showConsumableDetails() {
    return this.variant === CLI.CONSUMABLES;
  }

  get showDeliveryDetails() {
    return this.variant === CLI.DELIVERY;
  }

  get showAncillaryDetails() {
    return this.variant === CLI.ANCILLARY;
  }
}
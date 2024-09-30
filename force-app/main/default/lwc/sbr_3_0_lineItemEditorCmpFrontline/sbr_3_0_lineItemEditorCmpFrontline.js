import { LightningElement, api, track, wire } from "lwc";
import prefillLineData from "@salesforce/apex/SBR_3_0_LineItemEditorCmpController.getLineItem";
import saveSObjects from "@salesforce/apex/SBR_3_0_LineItemEditorCmpController.saveSObjects";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecordNotifyChange } from "lightning/uiRecordApi";
import getAppName from "@salesforce/apex/SBR_3_0_CustomLookupController.getAppName";
import { FORM_STORE } from "c/sbr_3_0_dynamicRecordFormRegistry";
let defaultLineItemNote =
  '{"seasonalQuote" : "Seasonal Rates applied. Please see Seasonal Rate Details section for additional details.","singleShift" : "Single Shift Rate applied. Please see Shift Rate Details section for additional details.", "doubleShift" : "Double Shift Rate applied. Please see Shift Rate Details section for additional details.","tripleShift" : "Triple Shift Rate applied. Please see Shift Rate Details section for additional details.", "standByRate" : "Rate based on standby duty, less than 5 hrs/month."}';
const IN_LINE_ERROR_FOR_NEGATIVE_VALUE = "Cannot go below 0 value.";
const ERROR_TOAST_MESSAGE =
  "Review errors and update to confirm changes to this line item.";
export default class Sbr_3_0_lineItemEditorCmpFrontline extends LightningElement {
  @api recordId;
  @api groupId;
  @api lineId = "";
  @api isRentalQuoteSubRecType = false;
  @api row;
  @api isMiscItem = false; //FRONT-14360
  rentalQuoteSubMessage =
    "Line Items cannot be updated after the Quote has been submitted.";
  seasonalMultiplier = 4.0;
  lineItemNotes = "";
  shiftDifferential = "";
  isOverrideDiscount = false;
  applyStandbyRates = false;
  hasSeasonalMultiplier = false;
  hasContingencyPlan = false;
  hasShifting = false;
  hasStandbyRates = false;
  isLoading = false;
  objectType;
  @track lineItem;
  itemGroup;
  itemQuantity;
  @track salesMiscPrice; //FRONT-12303
  disableCC = false;
  startDate = "";
  endDate = "";
  showCustomerPricingAlert = false;
  alertClass = "slds-notify slds-notify_alert slds-alert_warning";
  pricingType = "";
  pricingFlag = false;
  ratesDisabled = false;
  doNotExceedMinRate;
  doNotExceedDailyRate;
  doNotExceedWeeklyRate;
  doNotExceedMonthlyRate;
  suggestedMinRate;
  suggestedDailyRate;
  suggestedWeeklyRate;
  suggestedMonthlyRate;
  discount;
  displayOverrideDiscount = false;
  //Added on FRONT-1906,1670
  appName = "";
  showFrontlineComponents;
  minRateVal = "";
  /*START: FRONT-1950,FRONT-1958 */
  @api totalRequestedQuantity = 0;
  @api filledQuantity = 0;
  @api remainingQuantity = 0;
  isPartiallyFilledOrder = false;
  @api isRental;
  @api isSales;
  isRentalForDesktop = false;
  /*END: FRONT-1950,FRONT-1958 */

  rentalItems;
  fieldErrorSet = new Set([]); //FRONT-25018

  @api populateLineData(lineId, groupId, parentId, row) {
    //START FRONT-1950,1958
    if (row) {
      if (!this.isMobile && row.productType === "Cat-Class") {
        this.isRentalForDesktop = true;
      } else {
        this.isRentalForDesktop = false;
      }
      this.setRowData(row);
    }
    //END FRONT-1950,1958
    prefillLineData({ lineId: lineId, groupId: groupId, parentId: parentId })
      .then((data) => {
        this.salesMiscPrice = 0;
        this.pricingFlag = false;
        this.pricingType = "";
        this.doNotExceedDailyRate = null;
        this.doNotExceedMinRate = null;
        this.doNotExceedMonthlyRate = null;
        this.doNotExceedWeeklyRate = null;
        this.ratesDisabled = false;
        this.objectType = data.objectType;
        let line;
        //             if(this.objectType == 'OrderItem'){
        //                 this.itemGroup = [data.lineItems[0]];
        //                 line = data.lineItems[0];
        //                 this.itemQuantity = data.lineItems.length;
        //                 this.startDate = line.Order.Start_Date__c? line.Order.Start_Date__c: '';
        //                 this.endDate = line.Order.Return_Date__c? line.Order.Return_Date__c: '';
        //             }
        if (this.objectType == "OrderItem") {
          for (let item of data.lineItems) {
            // console.log("Lineitem Id:" + item.Id);
            if (item.Id == lineId) {
              this.itemGroup = [item];
              line = item;
            }
          }
          this.rentalItems =
            line.Product2.Product_Type__c === "Cat-Class" ? true : false;
          this.itemQuantity = line.Quantity;
          this.salesMiscPrice = line.Selling_Price__c; //FRONT-12303
          this.startDate = line.Order.Start_Date__c
            ? line.Order.Start_Date__c
            : "";
          this.endDate = line.Order.Return_Date__c
            ? line.Order.Return_Date__c
            : "";
          this.discount = line.Order.Order_Discount__c
            ? line.Order.Order_Discount__c
            : 0;
          //START FRONT-1950,1958
          if (line.Order.Status === "Partially Filled") {
            this.isPartiallyFilledOrder = true;
          }
          //FRONT-20091,20092 Starts
          console.log("under line item");
          if (
            FORM_STORE.updatedRecords[this.recordId].hasOwnProperty(
              "Contingency_Order__c"
            )
          ) {
            this.hasContingencyPlan =
              FORM_STORE.updatedRecords[this.recordId]["Contingency_Order__c"];
          } else if (data.hasContingencyPlan) {
            this.hasContingencyPlan = true; //query and retrieve contingency plan pricing
          }
          if (
            FORM_STORE.updatedRecords[this.recordId].hasOwnProperty(
              "Apply_Standby_Rates__c"
            )
          ) {
            data.hasStandbyPricing =
              FORM_STORE.updatedRecords[this.recordId][
                "Apply_Standby_Rates__c"
              ];
          }
          if (
            FORM_STORE.updatedRecords[this.recordId].hasOwnProperty(
              "Seasonal_Order__c"
            )
          ) {
            console.log("hasSeasonalRate if");
            data.hasSeasonalRate =
              FORM_STORE.updatedRecords[this.recordId]["Seasonal_Order__c"];
          }

          //FRONT-20091,20092 ends
          //END FRONT-1950,1958
        } else {
          this.rentalItems =
            data.lineItem.SBQQ__Product__r.Product_Type__c === "Cat-Class"
              ? true
              : false;
          line = data.lineItem;
          this.salesMiscPrice = line.Selling_Price__c; //FRONT-12303
          this.itemQuantity = line.SBQQ__Quantity__c;
          this.startDate = line.SBQQ__Quote__r.Start_Date__c
            ? line.SBQQ__Quote__r.Start_Date__c
            : "";
          this.endDate = line.SBQQ__Quote__r.End_Date__c
            ? line.SBQQ__Quote__r.End_Date__c
            : "";
          this.discount = line.SBQQ__Quote__r.Quote_Discount__c
            ? line.SBQQ__Quote__r.Quote_Discount__c
            : 0;
          //FRONT-20093,20094 Starts

          if (
            FORM_STORE.updatedRecords[this.recordId].hasOwnProperty(
              "Contingency_Quote__c"
            )
          ) {
            this.hasContingencyPlan =
              FORM_STORE.updatedRecords[this.recordId]["Contingency_Quote__c"];
          } else if (data.hasContingencyPlan) {
            this.hasContingencyPlan = true; //query and retrieve contingency plan pricing
          }
          if (
            FORM_STORE.updatedRecords[this.recordId].hasOwnProperty(
              "Shift_Rate__c"
            )
          ) {
            data.hasShiftPricing =
              FORM_STORE.updatedRecords[this.recordId]["Shift_Rate__c"];
          }
          if (
            FORM_STORE.updatedRecords[this.recordId].hasOwnProperty(
              "Apply_Standby_Rates__c"
            )
          ) {
            data.hasStandbyPricing =
              FORM_STORE.updatedRecords[this.recordId][
                "Apply_Standby_Rates__c"
              ];
          }
          if (
            FORM_STORE.updatedRecords[this.recordId].hasOwnProperty(
              "Seasonal_Quote__c"
            )
          ) {
            data.hasSeasonalRate =
              FORM_STORE.updatedRecords[this.recordId]["Seasonal_Quote__c"];
          }

          //FRONT-20093,20094 ends
        }
        //Added for FRONT-1906
        if (
          this.objectType == "SBQQ__QuoteLine__c" &&
          (line.Min_Rate__c == "" || line.Min_Rate__c == undefined) &&
          this.appName == "RAE Frontline"
        ) {
          line.Min_Rate__c = line.Daily_Rate__c;
        }

        this.lineItem = {
          Id: line.Id,
          Shift_Differential__c: line.Shift_Differential__c
            ? line.Shift_Differential__c
            : "",
          Contingency_Cost__c: line.Contingency_Cost__c
            ? line.Contingency_Cost__c
            : "",
          Product_SKU__c:
            this.objectType === "OrderItem"
              ? line.Product2.Product_SKU__c
              : line.Product_SKU__c,
          Min_Rate__c: line.Min_Rate__c ? line.Min_Rate__c : "",
          Daily_Rate__c: line.Daily_Rate__c ? line.Daily_Rate__c : "",
          Weekly_Rate__c: line.Weekly_Rate__c ? line.Weekly_Rate__c : "",
          Monthly_Rate__c: line.Monthly_Rate__c ? line.Monthly_Rate__c : "",
          Override_Discount__c: line.Override_Discount__c
            ? line.Override_Discount__c
            : false,
          Apply_Standby_Rates__c: line.Apply_Standby_Rates__c
            ? line.Apply_Standby_Rates__c
            : false,
          Line_Comments__c: line.Line_Comments__c ? line.Line_Comments__c : "", //add Specific_Pricing_Type__c and Specific_Pricing_Flag__c to the OrderItem and QuoteLine Item DA classes that are querying for them
          Discount_Percentage__c: line.Discount_Percentage__c
            ? line.Discount_Percentage__c
            : ""
        };
        this.isOverrideDiscount = this.lineItem.Override_Discount__c;
        this.applyStandbyRates = this.lineItem.Apply_Standby_Rates__c;
        this.lineItemNotes = this.lineItem.Line_Comments__c;
        this.pricingFlag = line.Specific_Pricing_Flag__c;
        this.pricingType = line.Specific_Pricing_Type__c
          ? line.Specific_Pricing_Type__c
          : "";
        this.suggestedMinRate = line.Suggested_Minimum_Rate__c;
        this.suggestedDailyRate = line.Suggested_Daily_Rate__c;
        this.suggestedWeeklyRate = line.Suggested_Weekly_Rate__c;
        this.suggestedMonthlyRate = line.Suggested_Monthly_Rate__c;
        this.displayOverrideDiscount = this.discount > 0 ? true : false;

        console.log("before calling updateShift", data.hasShiftPricing);
        this.updateShift(data.hasShiftPricing);
        this.updateSeasonalMultiplier(data.hasSeasonalRate);
        this.updateStandByRate(data.hasStandbyPricing);
        this.getCustomerPricingAlert();
        this.refreshLineItemData();
      })
      .catch((error) => {
        console.log("error: " + error);
      });
  }
  refreshLineItemData() {
    // this.template.querySelector("lightning-input[data-my-id=item-quantity]").value = this.itemQuantity;
    // this.template.querySelector("lightning-input[data-my-id=daily-rate-id]").value = this.lineItem.Daily_Rate__c;
    // this.template.querySelector("lightning-input[data-my-id=minimum-rate-id]").value = this.lineItem.Min_Rate__c;
    // this.template.querySelector("lightning-input[data-my-id=monthly-rate-id]").value = this.lineItem.Monthly_Rate__c;
    // this.template.querySelector("lightning-input[data-my-id=weekly-rate-id]").value = this.lineItem.Weekly_Rate__c;
    // this.template.querySelector("lightning-input[data-my-id=start-date-id]").value = null;
    // this.template.querySelector("lightning-input[data-my-id=end-date-id]").value = null ;
    // this.template.querySelector("lightning-input[data-my-id=line-item-notes]").value = this.lineItem.Line_Comments__c;
    if (this.lineItem.Product_SKU__c === "1559000") this.disableCC = true;
    else this.disableCC = false;
  }

  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    //Start for FRONT-1906,1670
    getAppName()
      .then((results) => {
        console.log("=======results===", results);
        this.appName = results;
        if (this.appName === "RAE Frontline") {
          this.showFrontlineComponents = true;
        }
      })
      .catch((error) => {
        console.log("error");
      });
    //END for FRONT-1906,1670
  }

  renderedCallback() {
    //alert('inside old editor cmp');
  }

  updateLineItem() {
    let updatedQuoteLine;
    let updatedOrderItems = [];
    let seasonalMultiplierTemp = this.hasSeasonalMultiplier
      ? this.template.querySelector(
          "lightning-input[data-my-id=seasonal-multiplier]"
        ).value
      : null;
    let contigencyPlanTemp = this.hasContingencyPlan
      ? this.template.querySelector(
          "lightning-input[data-my-id=contingency-cost]"
        ).value
      : null;
    if (this.objectType == "OrderItem") {
      for (let i = 0; i < this.itemGroup.length; i++) {
        if (this.appName == "RAE Frontline") {
          //start FRONT-12303
          this.minRateVal =
            this.template.querySelector(
              "lightning-input[data-my-id=minimum-rate-id]"
            ) === null
              ? ""
              : this.template.querySelector(
                  "lightning-input[data-my-id=minimum-rate-id]"
                ).value;
          //end FRONT-12303
          if (this.minRateVal == "" || this.minRateVal == "undefined") {
            //start FRONT-12303
            this.minRateVal =
              this.template.querySelector(
                "lightning-input[data-my-id=daily-rate-id]"
              ) === null
                ? ""
                : this.template.querySelector(
                    "lightning-input[data-my-id=daily-rate-id]"
                  ).value;
            // end FRONT-12303
          }
        }

        let newItem = {
          Id: this.itemGroup[i].Id,
          Quantity: parseInt(
            //start FRONT-12303
            this.template.querySelector(
              "lightning-input[data-my-id=item-quantity]"
            ) === null
              ? ""
              : this.template.querySelector(
                  "lightning-input[data-my-id=item-quantity]"
                ).value
          ), //Quantity: this.itemGroup[i].Quantity,
          Daily_Rate__c:
            this.template.querySelector(
              "lightning-input[data-my-id=daily-rate-id]"
            ) === null
              ? ""
              : this.template.querySelector(
                  "lightning-input[data-my-id=daily-rate-id]"
                ).value,
          Line_Comments__c: this.lineItemNotes,
          Min_Rate__c: "RAE Frontline"
            ? this.minRateVal
              ? this.minRateVal
              : ""
            : "", //Added for FRONT-1906,1670
          Monthly_Rate__c:
            this.template.querySelector(
              "lightning-input[data-my-id=monthly-rate-id]"
            ) === null
              ? ""
              : this.template.querySelector(
                  "lightning-input[data-my-id=monthly-rate-id]"
                ).value,
          Weekly_Rate__c:
            this.template.querySelector(
              "lightning-input[data-my-id=weekly-rate-id]"
            ) === null
              ? ""
              : this.template.querySelector(
                  "lightning-input[data-my-id=weekly-rate-id]"
                ).value,
          //end FRONT-12303
          Seasonal_Multiplier__c: seasonalMultiplierTemp,
          Apply_Standby_Rates__c: this.applyStandbyRates,
          Contingency_Cost__c: contigencyPlanTemp,
          Shift_Differential__c: this.shiftDifferential,
          Override_Discount__c: this.isOverrideDiscount,
          // start FRONT-12339
          Selling_Price__c:
            this.template.querySelector(
              "lightning-input[data-my-id=sales-misc-Price]"
            ) === null
              ? ""
              : this.template.querySelector(
                  "lightning-input[data-my-id=sales-misc-Price]"
                ).value,
          Discount_Percentage__c:
            this.template.querySelector(
              "lightning-input[data-my-id=discount-rate-id]"
            ) === null
              ? ""
              : this.template.querySelector(
                  "lightning-input[data-my-id=discount-rate-id]"
                ).value
          // end FRONT-12339
        };
        updatedOrderItems.push(newItem);
      }
    } else {
      //Added for FRONT-1906
      if (
        this.objectType == "SBQQ__QuoteLine__c" &&
        this.appName == "RAE Frontline"
      ) {
        this.minRateVal =
          // start FRONT-12303
          this.template.querySelector(
            "lightning-input[data-my-id=minimum-rate-id]"
          ) === null
            ? ""
            : this.template.querySelector(
                "lightning-input[data-my-id=minimum-rate-id]"
              ).value;
        if (this.minRateVal == "" || this.minRateVal == "undefined") {
          this.minRateVal =
            this.template.querySelector(
              "lightning-input[data-my-id=daily-rate-id]"
            ) === null
              ? ""
              : this.template.querySelector(
                  "lightning-input[data-my-id=daily-rate-id]"
                ).value;
          // end FRONT-12303
        }
      }

      updatedQuoteLine = {
        Id: this.lineItem.Id,
        SBQQ__Quantity__c: parseInt(
          // start FRONT-12303
          this.template.querySelector(
            "lightning-input[data-my-id=item-quantity]"
          ) === null
            ? ""
            : this.template.querySelector(
                "lightning-input[data-my-id=item-quantity]"
              ).value
        ),
        Daily_Rate__c:
          this.template.querySelector(
            "lightning-input[data-my-id=daily-rate-id]"
          ) === null
            ? ""
            : this.template.querySelector(
                "lightning-input[data-my-id=daily-rate-id]"
              ).value,
        // end FRONT-12303
        Line_Comments__c: this.lineItemNotes,
        Min_Rate__c:
          this.appName == "RAE Frontline"
            ? this.minRateVal
              ? this.minRateVal
              : ""
            : "", //Added for FRONT-1906,1670
        //start FRONT-12303
        Monthly_Rate__c:
          this.template.querySelector(
            "lightning-input[data-my-id=monthly-rate-id]"
          ) === null
            ? ""
            : this.template.querySelector(
                "lightning-input[data-my-id=monthly-rate-id]"
              ).value,
        Weekly_Rate__c:
          this.template.querySelector(
            "lightning-input[data-my-id=weekly-rate-id]"
          ) === null
            ? ""
            : this.template.querySelector(
                "lightning-input[data-my-id=weekly-rate-id]"
              ).value,

        //end FRONT-12303
        Seasonal_Multiplier__c: seasonalMultiplierTemp,
        Apply_Standby_Rates__c: this.applyStandbyRates,
        Contingency_Cost__c: contigencyPlanTemp,
        Shift_Differential__c: this.shiftDifferential,
        Override_Discount__c: this.isOverrideDiscount,
        //start FRONT-12303
        Selling_Price__c:
          this.template.querySelector(
            "lightning-input[data-my-id=sales-misc-Price]"
          ) === null
            ? ""
            : this.template.querySelector(
                "lightning-input[data-my-id=sales-misc-Price]"
              ).value,
        Discount_Percentage__c:
          this.template.querySelector(
            "lightning-input[data-my-id=discount-rate-id]"
          ) === null
            ? ""
            : this.template.querySelector(
                "lightning-input[data-my-id=discount-rate-id]"
              ).value
        // end FRONT-12303
      };
    }
    return [updatedQuoteLine, updatedOrderItems];
  }

  @api async saveData(event) {
    if (this.fieldErrorSet.size > 0) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Submit Error",
          message: ERROR_TOAST_MESSAGE,
          variant: "error"
        })
      );
      return;
    }
    this.isLoading = true;
    try {
      const updateList = this.updateLineItem();

      if (this.pricingFlag) {
        if (
          this.pricingType == "Do Not Exceed" ||
          this.pricingType == "Percent Off Local Book"
        ) {
          if (this.objectType == "OrderItem") {
            let item = updateList[1];
            console.log(item);

            console.log(this.suggestedDailyRate);
            if (
              updateList[1][0].Min_Rate__c > this.suggestedMinRate ||
              updateList[1][0].Monthly_Rate__c > this.suggestedMonthlyRate ||
              updateList[1][0].Daily_Rate__c > this.suggestedDailyRate ||
              updateList[1][0].Weekly_Rate__c > this.suggestedWeeklyRate
            ) {
              throw new Error("Rates cannot exceed Suggested Rate");
            }
          } else {
            if (
              updateList[0].Min_Rate__c > this.suggestedMinRate ||
              updateList[0].Monthly_Rate__c > this.suggestedMonthlyRate ||
              updateList[0].Daily_Rate__c > this.suggestedDailyRate ||
              updateList[0].Weekly_Rate__c > this.suggestedWeeklyRate
            ) {
              throw new Error("Rates cannot exceed Suggested Rate");
            }
          }
        }
      } //add logic here for checking
      const results = await saveSObjects({
        quoteLines: [updateList[0]],
        orderLines: updateList[1],
        objectType: this.objectType
      });

      const message = "Record was successfully saved";
      if (this.objectType == "OrderItem") {
        setTimeout(() => {
          this.dispatchEvent(
            new ShowToastEvent({
              name: "Submit Success",
              message,
              variant: "success",
              mode: "dismissible"
            })
          );
        }, 5000);
      } else {
        setTimeout(() => {
          this.dispatchEvent(
            new ShowToastEvent({
              name: "Submit Success",
              message,
              variant: "success",
              mode: "dismissible"
            })
          );
        }, 5000);
      } //eval("$A.get('e.force:refreshView').fire();"); //getRecordNotifyChange([{recordId: this.recordId}]);
      // SAL-23568

      this.isLoading = false;
      return this.objectType == "OrderItem" ? updateList[1] : updateList[0];
    } catch (e) {
      this.isLoading = false;
      let message = e.body?.message || e.message;
      if (message.indexOf("INSUFFICIENT_ACCESS_OR_READONLY") > 0) {
        message =
          "You do not have the necessary privileges to edit this record. See your administrator for help.";
      }
      this.dispatchEvent(
        new ShowToastEvent({
          name: "Submit Error",
          message,
          variant: "error",
          mode: "sticky"
        })
      );
      return null;
    }
  }

  // how is this changed on the modal? may not be needed. What should happen to LIN if multiplier is 0/empty/undefined
  changeSeasonalMultiplier(event) {
    this.lineItem.Seasonal_Multiplier__c = event.target.value;
    if (this.lineItem.Seasonal_Multiplier__c == 0 || undefined) {
      this.hasSeasonalMultiplier = false;
    }
    this.updateSeasonalMultiplierNotes();
  }

  get shiftOptions() {
    return [
      { label: "Single", value: "S" },
      { label: "Double", value: "D" },
      { label: "Triple", value: "T" }
    ];
  }

  changeShiftDuration(event) {
    this.shiftDifferential = event.target.value;
    this.updateShiftNotes();
  }

  changeApplyStandByRate(event) {
    this.applyStandbyRates = event.target.checked;
  }

  changeOverrideDiscount(event) {
    this.isOverrideDiscount = event.target.checked;
  }

  changeLineItemNotes(event) {
    //FRONT-15689,15690 starts
    this.lineItemNotes = event.target.value;
  }
  changeSalesMiscPrice(event) {
    this.salesMiscPrice = event.target.value;
  } //FRONT-15689,15690 ends
  changeQuantity(event) {
    this.itemQuantity = event.target.value;
  }
  updateSeasonalMultiplier(hasMultiplier) {
    let defaultLineItemNoteJSON = JSON.parse(defaultLineItemNote);
    this.hasSeasonalMultiplier = hasMultiplier;
    if (hasMultiplier) {
      if (this.lineItem.Seasonal_Multiplier__c) {
        this.seasonalMultiplier = this.lineItem.Seasonal_Multiplier__c;
      }
      if (!this.lineItemNotes.includes(defaultLineItemNoteJSON.seasonalQuote)) {
        this.lineItemNotes = this.lineItemNotes.concat(
          "\n" + defaultLineItemNoteJSON.seasonalQuote
        );
      }
    } else {
      this.lineItemNotes = this.lineItemNotes.replace(
        defaultLineItemNoteJSON.seasonalQuote,
        ""
      );
    }
  }

  updateShift(shifting) {
    let defaultLineItemNoteJSON = JSON.parse(defaultLineItemNote);
    this.hasShifting = shifting;
    if (shifting) {
      this.shiftDifferential = this.lineItem.Shift_Differential__c;
      this.removeDefaultShiftNote();
      switch (true) {
        case this.shiftDifferential == "S" &&
          !this.lineItemNotes.includes(defaultLineItemNoteJSON.singleShift):
          this.lineItemNotes = this.lineItemNotes.concat(
            "\n" + defaultLineItemNoteJSON.singleShift
          );
          break;
        case this.shiftDifferential == "D" &&
          !this.lineItemNotes.includes(defaultLineItemNoteJSON.doubleShift):
          this.lineItemNotes = this.lineItemNotes.concat(
            "\n" + defaultLineItemNoteJSON.doubleShift
          );
          break;
        case this.shiftDifferential == "T" &&
          !this.lineItemNotes.includes(defaultLineItemNoteJSON.tripleShift):
          this.lineItemNotes = this.lineItemNotes.concat(
            "\n" + defaultLineItemNoteJSON.tripleShift
          );
          break;
      }
    }
  }

  updateStandByRate(standbyRates) {
    let defaultLineItemNoteJSON = JSON.parse(defaultLineItemNote);
    let standyByRateStr = defaultLineItemNoteJSON.standyByRate;
    if (standyByRateStr == undefined || standyByRateStr == null) {
      standyByRateStr = "Rate based on standby duty, less than 5 hrs/month.";
    }
    if (standbyRates) {
      this.hasStandbyRates = standbyRates;
      if (
        standyByRateStr != undefined &&
        !this.lineItemNotes.includes(standyByRateStr)
      ) {
        this.lineItemNotes = this.lineItemNotes.concat("\n" + standyByRateStr);
      }
    } else {
      this.lineItemNotes = this.lineItemNotes.replace(
        defaultLineItemNoteJSON.standByRate,
        ""
      );
    }
  }

  // updateShiftNotes helper method: clears line item notes of any existing default line item note statements
  removeDefaultShiftNote() {
    let defaultLineItemNoteJSON = JSON.parse(defaultLineItemNote);
    this.lineItemNotes = this.lineItemNotes.replace(
      "\n" + defaultLineItemNoteJSON.singleShift,
      ""
    );
    this.lineItemNotes = this.lineItemNotes.replace(
      defaultLineItemNoteJSON.singleShift,
      ""
    );
    this.lineItemNotes = this.lineItemNotes.replace(
      "\n" + defaultLineItemNoteJSON.doubleShift,
      ""
    );
    this.lineItemNotes = this.lineItemNotes.replace(
      defaultLineItemNoteJSON.doubleShift,
      ""
    );
    this.lineItemNotes = this.lineItemNotes.replace(
      "\n" + defaultLineItemNoteJSON.tripleShift,
      ""
    );
    this.lineItemNotes = this.lineItemNotes.replace(
      defaultLineItemNoteJSON.tripleShift,
      ""
    );
  }

  getCustomerPricingAlert() {
    if (this.pricingFlag) {
      // console.log("pricing flag true");
      if (this.pricingType == "Set Rates") {
        this.customerPricingAlert =
          "Customer has Set Rates. Rates cannot be changed.";
        this.disableCC = true;
        this.ratesDisabled = true;
      }
      if (this.pricingType == "Do Not Exceed") {
        this.customerPricingAlert =
          "Customer has Do Not Exceed Rates. Rates increases not allowed.";
        this.ratesDisabled = false;
        this.doNotExceedDailyRate = this.suggestedDailyRate;
        this.doNotExceedMinRate = this.suggestedMinRate;
        this.doNotExceedMonthlyRate = this.suggestedMonthlyRate;
        this.doNotExceedWeeklyRate = this.suggestedWeeklyRate;
      }
      if (this.pricingType == "Percent Off Local Book") {
        this.customerPricingAlert =
          "Customer has % off Local Book Rates. Rates increases not allowed.";
        this.ratesDisabled = false;
        this.doNotExceedDailyRate = this.suggestedDailyRate;
        this.doNotExceedMinRate = this.suggestedMinRate;
        this.doNotExceedMonthlyRate = this.suggestedMonthlyRate;
        this.doNotExceedWeeklyRate = this.suggestedWeeklyRate;
      }
      if (this.pricingType == "Customer Loaded") {
        this.customerPricingAlert = "Customer has special rates.";
        this.ratesDisabled = false;
      }
      this.showCustomerPricingAlert = true;
    } else {
      this.showCustomerPricingAlert = false;
      this.ratesDisabled = false;
    }
  }

  /*FRONT-1950 start This method sets the Line Item Data */
  setRowData(row) {
    this.row = row;
    if (
      this.row &&
      this.row.StatusCreated != null &&
      this.row.StatusFilled != null &&
      this.row.StatusCancel != null
    ) {
      this.totalRequestedQuantity =
        this.row.StatusCreated + this.row.StatusFilled + this.row.StatusCancel;
      this.filledQuantity = this.row.StatusFilled;
      this.remainingQuantity =
        this.totalRequestedQuantity -
        (this.row.StatusFilled + this.row.StatusCancel);
    }
  }
  /*FRONT-1950 end*/

  //Start FRONT-9131
  roundOffMinRate(event) {
    let minRateValue = event.target.value;
    event.target.value =
      minRateValue.indexOf(".") >= 0
        ? minRateValue.slice(0, minRateValue.indexOf(".") + 3)
        : minRateValue;
  }
  //End FRONT-9131

  //FRONT-25018 added validateNumberField method to restrict negative values for all number fields
  validateNumberField(inputFld) {
    if (inputFld.value < 0) {
      inputFld.setCustomValidity(IN_LINE_ERROR_FOR_NEGATIVE_VALUE);
      if (!this.fieldErrorSet.has(inputFld)) {
        this.fieldErrorSet.add(inputFld);
      }
    } else {
      inputFld.setCustomValidity("");
      if (this.fieldErrorSet.has(inputFld)) {
        this.fieldErrorSet.delete(inputFld);
      }
    }
  }

  //FRONT-25018 added handleValueChange method to handle field specific and common validations
  handleValueChange(event) {
    switch (event.currentTarget.dataset.myId) {
      case "minimum-rate-id":
        this.roundOffMinRate(event);
        break;

      case "item-quantity":
        this.changeQuantity(event);
        break;

      case "sales-misc-Price":
        this.changeSalesMiscPrice(event);
        break;

      case "shift-duration":
        this.changeShiftDuration(event);
        break;
      default: //do nothing
    }
    this.validateNumberField(event.target);
  }
}
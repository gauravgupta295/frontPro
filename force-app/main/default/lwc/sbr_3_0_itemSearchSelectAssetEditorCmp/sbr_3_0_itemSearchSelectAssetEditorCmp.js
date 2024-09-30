import { LightningElement, api, track } from "lwc";
import { Logger, isEmpty } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);
import { isMobile } from "c/sbr_3_0_dynamicRecordFormUtility";
import { loadStyle } from "lightning/platformResourceLoader";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import getAvailableQty from "@salesforce/apex/SBR_3_0_AssetController.getAvailableQty"; // FRONT-31381
//Started for Front-18999
import mobileTemplate from "./sbr_3_0_itemSearchSelectAssetEditorCmpMobile.html";
import desktopTemplate from "./sbr_3_0_itemSearchSelectAssetEditorCmpDesktop.html";
import LABELS from "c/sbr_3_0_customLabelsCmp";
//Ended for Front-18999

export default class Sbr_3_0_itemSearchSelectAssetEditorCmp extends LightningElement {
  _selectedAsset;
  moddedAssetObj;
  isMobile = isMobile;
  @api currentActiveTab;
  @api dateValue;
  @api orderData;
  @api isLoading = false; //16656
  @api ratesInfo;
  labels = LABELS; //19001

  @track assetData = {
    catClass: "",
    catClassDescription: "",
    itemQty: 1,
    hourMeterReading: "",
    minRate: "",
    day: "",
    week: "",
    fourWeek: "",
    rateDiscount: 0,
    requestedCatClass: "",
    dateVar: "",
    timeVar: "",
    lineItemNotes: "",
    days: "",
    hours: "",
    reasonCode: "HolidayFreeDay",
    noCharge: false,
    dateOutVarMobile: "",
    quantityAvailable: "",
    suggestedMinRate: "",
    suggestedHourRate: "",
    suggestedDailyRate: "",
    suggestedWeeklyRate: "",
    suggestedMonthlyRate: "",
    isUserAdded : true
  };

  hourMeterFieldVisibility = false; //FRONT-29160
  @api origin = ""; //Front-16656
  @api
  get selectedAsset() {
    return this._selectedAsset;
  }
  set selectedAsset(value) {
    logger.log(this.currentActiveTab, "🚀 selectedAsset Data :: " + JSON.stringify(value));
    this._selectedAsset = value;
  }

  get isNotBulkItem() {
    return this.isBulkAsset;
  }

  get isNotCatClassDescriptionTab() {
    return this.currentActiveTab !== "Cat Class Description";
  }

  get isCatClassDescriptionTab() {
    return this.currentActiveTab === "Cat Class Description";
  }

  get isCatClassTab() {
    return this.currentActiveTab === "CatClass";
  }

  get reasonCodeOptions() {
    return [
      { label: "N/A", value: "NA" },
      { label: "Holiday Free Day", value: "HolidayFreeDay" }
    ];
  }
  //Started for 19001
  get reqCatClassPlaceholder() {
    //Front-31380
    if (this.isNotBulkItem) {
      return this.labels.CATCLASS_PLACEHOLDER;
    }
    return "";
  }
  //Ended for 19001

  connectedCallback() {
    if (this.origin === "RentalEdit") {
      this.buildAssetDataForEditor();
    } else {
      this.buildAssetData();
    }
  }

  handleFieldChange(event) {
    if (this.origin === "RentalEdit") {
      this.assetData["Id"] = this._selectedAsset.Id;
    }
    let fieldKey = event.currentTarget.dataset.fieldKey;
    this.assetData[fieldKey] = event.target.value;
    if (fieldKey === "itemQty") {
      if (
        parseFloat(event.target.value) >
        parseFloat(event.currentTarget.dataset.availableQuantity)
      ) {
        const oEvent = new CustomEvent("changevalue", {
          detail: true,
          bubbles: true,
          composed: true
        });
        this.dispatchEvent(oEvent);
        event.target.setCustomValidity(
          "Cannot go above available quantity of " +
            event.currentTarget.dataset.availableQuantity
        );
      } else {
        const oEvent = new CustomEvent("changevalue", {
          detail: false,
          bubbles: true,
          composed: true
        });
        this.dispatchEvent(oEvent);
        event.target.setCustomValidity("");
      }
    }
    //FRONT-31374
    if (fieldKey === "noCharge") {
      this.assetData[fieldKey] = event.target.checked;
    }
  }

  handleKeyPress(event) {
    const key = event.key;
    if (key === ".") {
      event.preventDefault();
    }
  }
  isBulkAsset = "";
  async buildAssetData() {
    try {
      this.isLoading = true;
      if (this._selectedAsset) {
        let tempAsset = this.isMobile
          ? this._selectedAsset
          : JSON.parse(JSON.stringify(this._selectedAsset)); //FRONT - 19005
          console.log('Temp Asset '+JSON.stringify(tempAsset));
        let productSKU = "";
        let branchLocationNumber =
          this.orderData?.fields?.Branch_Location_Number__c?.value;
        let dateOutVar = this.orderData?.fields?.Start_Date__c?.value;
        logger.log("this.orderData-->" + JSON.stringify(this.orderData));

        let timeVar;
        let dateVar;
        if (this.origin === "QuickAdd") {
          timeVar = await this.getTimeFromDateTimeUTC(this.dateValue);
          dateVar = await this.getDateFromDateTimeUTC(this.dateValue);
        } else {
          timeVar = await this.getTimeFromDateTimeUTC(dateOutVar);
          dateVar = await this.getDateFromDateTimeUTC(dateOutVar);
        }




        let dateOutVarMobile = !isEmpty(dateOutVar) ? dateOutVar : "";
        let catClass = "";
        let catClassDescription = "";
        let quantityAvailable = "";
        
        let rmAccountNumber =
          this.orderData?.fields?.Account?.value?.fields?.RM_Account_Number__c
            ?.value;
        if (this.isCatClassTab || this.origin === "QuickAdd") {
          productSKU = tempAsset.Product2.Product_SKU__c;
          catClass = tempAsset.Product2.PPA_CatClass__c;
          catClassDescription = tempAsset.Product2?.Name;
        }

        if (this.isCatClassDescriptionTab) {
          productSKU =
            tempAsset?.Product2?.Product_SKU__c ||
            tempAsset["Product2.Product_SKU__c"];
          catClass =
            tempAsset?.Product2?.PPA_CatClass__c ||
            tempAsset["Product2.PPA_CatClass__c"];
          catClassDescription = tempAsset?.ProductName;
          this.isBulkAsset = !(
            tempAsset?.Product2?.Bulk_Item__c ||
            tempAsset["Product2.Bulk_Item__c"]
          );
        } else {
          this.isBulkAsset = !(
            tempAsset.Product2.Bulk_Item__c || tempAsset.isBulkAsset
          );
        }
        // START FRONT-31381, FRONT-31385
        if (!this.isNotBulkItem) {
          if (this.origin === "RentalEdit") {
            quantityAvailable = await getAvailableQty({
              productId: tempAsset.product
            });
          } else if (this.origin === "QuickAdd") {
            quantityAvailable = await getAvailableQty({
              productId: tempAsset.Product2Id
            });
          } else {
            quantityAvailable = tempAsset.SM_PS_Quantity_Available__c;
          }
        }
        // END FRONT-31381, FRONT-31385
        //FRONT-29160
        let miHrReading = tempAsset?.SM_PS_MiHr_Old_meter__c;

        if (
          this.isNotCatClassDescriptionTab &&
          miHrReading &&
          (!isEmpty(tempAsset?.SM_PS_Meter_Code_MIHR__c) ||
            !isEmpty(tempAsset?.SM_PS_Meter_2_Code__c))
        ) {
          this.hourMeterFieldVisibility = true;
        } else {
          this.hourMeterFieldVisibility = false;
        }
        //END : FRONT-29160
        logger.log("assetData-->" + JSON.stringify(this.assetData));
        if (this.origin === "QuickAdd") {
          timeVar = await this.getTimeFromDateTimeUTC(this.dateValue);
          dateVar = await this.getDateFromDateTimeUTC(this.dateValue);
        }
        this.assetData.catClass = catClass;
        this.assetData.catClassDescription = catClassDescription;
        this.assetData.itemQty = 1;

        this.assetData.dateVar = dateVar;

        this.assetData.timeVar = timeVar;

        this.assetData.timeVar = timeVar;
        this.assetData.requestedCatClass = "";
        this.assetData.lineItemNotes = "";
        this.assetData.rateDiscount = 0;
        this.assetData.hourMeterReading = miHrReading; //FRONT-29160
        this.assetData.quantityAvailable = quantityAvailable;
        this.assetData.dateOutVarMobile = dateOutVarMobile;

        if (this.origin !== "RentalEdit") {
          let parsedData = this.ratesInfo;
          if (parsedData) {
            let rates = parsedData.data.items
              ? parsedData.data.items[0]?.rates?.suggestedRates
              : "";

            if (rates) {
              this.assetData.minRate = rates.minimum;
              this.assetData.day = rates.daily;
              this.assetData.week = rates.weekly;
              this.assetData.fourWeek = rates.monthly;
              this.assetData.suggestedDailyRate = rates.daily;
              this.assetData.suggestedHourRate = rates.minimum;
              this.assetData.suggestedMinRate = rates.minimum;
              this.assetData.suggestedMonthlyRate = rates.monthly;
              this.assetData.suggestedWeeklyRate = rates.weekly;
            }
          }
          logger.log("build assetData1-->" + JSON.stringify(this.assetData));
          this.isLoading = false;
        }
      }
    } catch (error) {
      logger.log("---- error In Rates API" + JSON.stringify(error));
      this.isLoading = false;
    }
  }

  getTimeFromDateTimeUTC(dateTimeVar) {
    let timeVar = dateTimeVar?.split("T")[1].split(".")[0];
    return timeVar;
  }

  getDateFromDateTimeUTC(dateTimeVar) {
    let dateVar = dateTimeVar?.split("T")[0];
    return dateVar;
  }

  @api getAssetData() {
    return this.assetData;
  }
  //started for Front-18999
  render() {
    if (this.isMobile) {
      return mobileTemplate;
    }
    return desktopTemplate;
  }
  //ended for Front-18999

  formatDate(dateString) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    const dateParts = dateString.split("-");
    const year = dateParts[0];
    const month = months[parseInt(dateParts[1], 10) - 1];
    const day = dateParts[2];
    return `${day}-${month}-${year}`;
  }

  convertTo12HourFormat(timeString) {
    var parts = timeString.split(":");
    var hours = parseInt(parts[0], 10);
    var minutes = parseInt(parts[1], 10);
    var amPm = hours >= 12 ? "PM" : "AM";

    hours = hours % 12;
    hours = hours ? hours : 12;

    hours = (hours < 10 ? "0" : "") + hours;
    minutes = (minutes < 10 ? "0" : "") + minutes;

    return hours + ":" + minutes + " " + amPm;
  }
  //Start for Front-16656
  async buildAssetDataForEditor() {
    await this.buildAssetData();
    let tempAsset = JSON.parse(JSON.stringify(this._selectedAsset));
    this.assetData.catClass = tempAsset.CatClass;
    this.assetData.rateDiscount = tempAsset.Discount_Percentage;
    this.assetData.catClassDescription = tempAsset.Name;

    if (
      !tempAsset.isBulkAsset &&
      tempAsset.oldMeter &&
      (!isEmpty(tempAsset?.meterCode) || !isEmpty(tempAsset?.mihrMeter))
    ) {
      this.hourMeterFieldVisibility = true;
    } else {
      this.hourMeterFieldVisibility = false;
    }
    if (tempAsset.Current_MiHr) {
      this.assetData.hourMeterReading = tempAsset.Current_MiHr;
    }
    this.assetData.minRate =
      /* String(tempAsset.Min_Rate).charAt(0) === "$" ? tempAsset.Min_Rate.substring(1) : */ tempAsset.Min_Rate;
    this.assetData.day =
      /* String(tempAsset.Daily_Rate).charAt(0) === "$" ? tempAsset.Daily_Rate.substring(1) :*/ tempAsset.Daily_Rate;
    this.assetData.week =
      /*String(tempAsset.Weekly_Rate).charAt(0) === "$" ? tempAsset.Weekly_Rate.substring(1) : */ tempAsset.Weekly_Rate;
    this.assetData.fourWeek =
      /* String(tempAsset.Monthly_Rate).charAt(0) === "$" ? tempAsset.Monthly_Rate.substring(1) : */ tempAsset.Monthly_Rate;
    if (tempAsset.Notes) {
      this.assetData.lineItemNotes = tempAsset.Notes;
    }
    //start FRONT-31374
    this.assetData.itemQty = tempAsset.Quantity;
    this.assetData.noCharge = tempAsset.noCharge;
    this.assetData.dateOutVarMobile = tempAsset.dateOutVarMobile;
    // end FRONT-31374


    this.isLoading = false;
  }
  //End for Front-16656

  renderedCallback() {
    loadStyle(this, FrontLineCSS);
  }
  //Front-30380,30385
  get rateHelpText() {
    let floorRate = "Floor Rate: ";
    return {
      minRate: this.assetData?.minRate
        ? floorRate + this.assetData?.minRate
        : floorRate + "0",
      day: this.assetData?.day
        ? floorRate + this.assetData?.day
        : floorRate + "0",
      week: this.assetData?.week
        ? floorRate + this.assetData?.week
        : floorRate + "0",
      fourWeek: this.assetData?.fourWeek
        ? floorRate + this.assetData?.fourWeek
        : floorRate + "0"
    };
  }
}
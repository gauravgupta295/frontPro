import { LightningElement, api } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import { loadStyle } from "lightning/platformResourceLoader";

import getAllAvailabilityDetails from "@salesforce/apex/SBR_3_0_PartsAndMerchAvailCmpController.getAllAvailabilityDetailsAggregated";
import getSpotlightPanelDetails from "@salesforce/apex/SBR_3_0_PartsAndMerchAvailCmpController.getConsumableSpotlightAvailabilityValues";
import getReservedTabOrderItems from "@salesforce/apex/SBR_3_0_PartsAndMerchAvailCmpController.fetchReservedOrderItems";

import { Logger, isEmpty } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);

const DUMMY_RESERVED_ITEMS = [
  {
    id: "dummy1",
    reservation_number: "",
    account_name: "",
    start_date: "11/15/2023 9:00AM",
    estimated_return: "11/20/2023",
    quantity: 1
  },
  {
    id: "dummy2",
    reservation_number: "",
    account_name: "",
    start_date: "11/15/2023 9:00AM",
    estimated_return: "11/20/2023",
    quantity: 1
  }
];

const AVAILABILITY_COLUMNS = [
  { label: "", fieldName: "label", hasSeparator: false },
  { label: "Avail", fieldName: "available", hasSeparator: true },
  { label: "Rsrv/\nOrder", fieldName: "reserve", hasSeparator: false },
  { label: "Open\nW/O", fieldName: "openwo", hasSeparator: false },
  { label: "Open\nPO", fieldName: "openpo", hasSeparator: false },
  { label: "Tran Out", fieldName: "transout", hasSeparator: false },
  { label: "In Tran", fieldName: "transin", hasSeparator: false }
];

const CONSUMABLE_SPOTLIGHT_AVAILABILITY_COLUMNS = [
  { label: "", fieldName: "label", hasSeparator: false },
  { label: "Avail", fieldName: "available", hasSeparator: true },
  { label: "Rsrv/\nOrder", fieldName: "reserve", hasSeparator: false },
  { label: "Open\nW/O", fieldName: "openwo", hasSeparator: false },
  { label: "Open\nPO", fieldName: "openpo", hasSeparator: false }
];
export default class Sbr_3_0_partsAndMerchandiseAvailabilityCmp extends LightningElement {
  @api callingFrom;
  @api locationInfo;

  @api selectedProductIds;

  isInModal;
  isLoading = false;
  modalHeaderText = "Availability";
  modalCancelButtonLabel = "Back";
  branchLabel = "Branch: PC100";
  activeTabName = "Branch";

  reservedItems = DUMMY_RESERVED_ITEMS;

  showBreadCrumbContainer = false;
  isMobile;
  isAvailabilityScreen;
  mobileProps = {
    footerClasses: "slds-p-around_none",
    fullScreen: true
  };
  availabilityData;
  availabilityDataClone;
  availabilityCols = AVAILABILITY_COLUMNS;
  consumableSpotlightAvailabilityColumns =
    CONSUMABLE_SPOTLIGHT_AVAILABILITY_COLUMNS;

  consumableSpotlightAvailabilityRows;

  districtLabel = "";
  regionLabel = "";
  companyLabel = "";

  districtPlaceholderValues = "Search Districts";
  regionPlaceholderValues = "Search Regions";
  companyPlaceholderValues = "Search Companies";

  connectedCallback() {
    this.isInModal = this.callingFrom === "modal";
    this.isMobile = FORM_FACTOR === "Small";

    this.configureTabProperies(this.locationInfo);
    if (this.locationInfo) {
      this.fetchSpotlightPanelDetails();
    }

    this.fetchAvailabilityData(this.activeTabName);
    this.fetchReservedTabValues();
  }

  renderedCallback() {
    loadStyle(this, FrontLineCSS);
  }

  openAvailabilityModal(event) {
    let actTab = event.detail?.includes("Branch") ? "Branch" : event.detail;
    this.activeTabName = actTab;
    if (!this.isMobile) {
      let availabilityModal = this.template.querySelector(
        "c-sbr_3_0_modal-cmp"
      );
      availabilityModal.toggleModal();

      this.showBreadCrumbContainer = false;
      this.activeItemTab = "Items";
      this.activeReservedTab = "";
    } else {
      this.isAvailabilityScreen = true;
    }
  }

  handleCancelClick = () => {
    let availabilityModal = this.template.querySelector("c-sbr_3_0_modal-cmp");
    availabilityModal.toggleModal();
  };

  toggleSection(event) {
    let buttonid = event.currentTarget.dataset.buttonid;
    let currentsection = this.template.querySelector(
      '[data-id="' + buttonid + '"]'
    );
    if (currentsection.className.search("slds-is-open") === -1) {
      currentsection.className = "slds-section slds-is-open slds-m-bottom_none";
    } else {
      currentsection.className = "slds-section slds-is-close";
    }

    let pricingDetailSection = this.template.querySelector(
      ".availabilityDetails"
    );
    pricingDetailSection.classList.toggle("slds-hide");
  }

  handleTabChange(event) {
    let activeTab = event.target.value;
    if (activeTab === "Items") {
      this.activeTabName = "Branch";
      this.activeItemTab = activeTab;
      this.activeReservedTab = "";
      this.fetchAvailabilityData("Branch");
      this.showBreadCrumbContainer = false;
    } else {
      this.activeReservedTab = activeTab;
      this.activeItemTab = "";
      this.showBreadCrumbContainer = true;
    }
  }

  handleBackClick() {
    this.isAvailabilityScreen = false;
  }

  handleAvailabilityTabChange(event) {
    try {
      let activeTab = event.target.value;
      this.activeAvailabilityTab = activeTab;

      this.fetchAvailabilityData(this.activeAvailabilityTab);
      if (this.activeAvailabilityTab !== "Branch") {
        this.resetSearchBoxes();
      }
    } catch (error) {
      logger.error("👉 error " + error.stack);
    }
  }

  handleSearchParameterEntered(event) {
    let searchQuery = event.detail.searchQuery;
    this.availabilityData =
      this.filterAvailabilityRowsBasedOnSearchTerm(searchQuery);
  }

  filterAvailabilityRowsBasedOnSearchTerm(searchQuery) {
    return !isEmpty(searchQuery)
      ? this.availabilityData?.filter((item) =>
          item.label.toLowerCase().includes(searchQuery.toLowerCase())
        )
      : this.availabilityDataClone;
  }

  resetSearchBoxes() {
    let allTabContainers = this.template.querySelectorAll(
      "c-sbr_3_0_parts-and-merchandise-availability-tab-container-cmp"
    );
    allTabContainers.forEach((element) => {
      element.resetSearchBox();
    });
  }

  configureTabProperies(locationInfoRec) {
    this.branchLabel = locationInfoRec?.Branch_Location_Number__c
      ? "Branch: PC" + locationInfoRec?.Branch_Location_Number__c
      : "Branch";

    this.districtLabel = this.locationInfo?.District__c
      ? this.locationInfo?.District__c
      : "";
    this.regionLabel = this.locationInfo?.Region__c
      ? this.locationInfo?.Region__c
      : "";
    this.companyLabel = this.locationInfo?.Company__c
      ? this.locationInfo?.Company__c
      : "";
  }

  fetchAvailabilityData(tabName) {
    this.availabilityData = [];
    if (!isEmpty(tabName)) {
      this.isLoading = true;
      getAllAvailabilityDetails({
        locationRec: JSON.stringify(this.locationInfo),
        labelType: tabName,
        productIds: this.selectedProductIds,
        isSpotlightPanelAggregated: false
      })
        .then((result) => {
          this.isLoading = false;
          this.availabilityData = this.buildAvailabilityData(result);
          this.availabilityDataClone = JSON.parse(
            JSON.stringify(this.availabilityData)
          );
        })
        .catch((error) => {
          this.isLoading = false;
          logger.error("Error:", error);
          logger.error("Error v2 :", error.stack);
        });
    }
  }

  buildAvailabilityData(res) {
    let itmArr = [];
    res.forEach((itm) => {
      let arrRec = this.dataRowObjForAvailability(itm);
      itmArr.push(arrRec);
    });
    return itmArr;
  }

  dataRowObjForAvailability(branchRec) {
    return {
      label: branchRec?.branch_name ? "PC" + branchRec?.branch_name : "",
      labelDesc: "Schiller Park, IL 60176",
      available: branchRec?.avail ? branchRec?.avail : 0,
      reserve: branchRec?.rsv_ord ? branchRec?.rsv_ord : 0,
      openwo: branchRec?.open_wo ? branchRec?.open_wo : 0,
      openpo: branchRec?.open_po ? branchRec?.open_po : 0,
      transout: branchRec?.trans_out ? branchRec?.trans_out : 0,
      transin: branchRec?.trans_in ? branchRec?.trans_in : 0
    };
  }

  //FRONT-23024 - Reserved Tab will have OrderItem records instead of Equipment_On_Hold__c records
  fetchReservedTabValues() {
    getReservedTabOrderItems({
      locationId: this.locationInfo?.Id,
      productIds: this.selectedProductIds
    })
      .then((result) => {
        this.reservedItems = this.buildReservedData(result);
      })
      .catch((error) => {
        logger.error("Error:", error);
      });
  }

  buildReservedData(res) {
    let itmArr = [];
    res.forEach((itm) => {
      let arrRec = this.dataRowObjForReserved(itm);
      itmArr.push(arrRec);
    });
    return itmArr;
  }

  //FRONT-23024 Changes done as per OrderItem fields rather than Equiment_On_Hold__c fields
  dataRowObjForReserved(oiRec) {
    return {
      Id: !isEmpty(oiRec?.SM_PS_Asset_Id__c) ? oiRec?.SM_PS_Asset_Id__c : "",
      reservation_number: !isEmpty(oiRec?.Order?.Reservation_Order_Number__c)
        ? oiRec?.Order?.Reservation_Order_Number__c
        : "",
      account_name: !isEmpty(oiRec?.Order?.Account?.Name)
        ? oiRec?.Order?.Account?.Name
        : "",
      start_date: !isEmpty(oiRec?.Order?.Start_Date__c)
        ? oiRec?.Order?.Start_Date__c
        : "",
      estimated_return: !isEmpty(oiRec?.Order?.Estimated_Return_Date__c)
        ? oiRec?.Order?.Estimated_Return_Date__c
        : "",
      quantity: !isEmpty(oiRec?.Quantity) ? oiRec?.Quantity : ""
    };
  }

  fetchSpotlightPanelDetails() {
    getSpotlightPanelDetails({
      locationRec: JSON.stringify(this.locationInfo),
      productIds: this.selectedProductIds
    })
      .then((result) => {
        this.consumableSpotlightAvailabilityRows =
          this.buildSpotlightPanelData(result);
      })
      .catch((error) => {
        logger.error("Error:", error);
      });
  }

  buildSpotlightPanelData(res) {
    let itmArr = [];
    res.forEach((itm) => {
      let arrRec = this.dataRowObjForSpotlight(itm);
      itmArr.push(arrRec);
    });
    return itmArr;
  }

  dataRowObjForSpotlight(rec) {
    let label = rec?.label;
    if (label.includes("BRANCH") || label.includes("Branch")) {
      label = this.branchLabel;
    } else {
      label = label.charAt(0).toUpperCase() + label.slice(1).toLowerCase();
    }
    return {
      label: label,
      labelDesc: this.getDefaultLocationAddress(),
      available: rec?.available ? rec?.available : 0,
      reserve: rec?.reserve ? rec?.reserve : 0,
      openwo: rec?.pickUp ? rec?.pickUp : 0,
      openpo: rec?.utilization ? rec?.utilization : 0
    };
  }

  getDefaultLocationAddress() {
    return (
      (this.locationInfo?.City__c ? this.locationInfo?.City__c : "") +
      ", " +
      (this.locationInfo?.State__c ? this.locationInfo?.State__c : "") +
      " " +
      (this.locationInfo?.Zip_Code__c ? this.locationInfo?.Zip_Code__c : "")
    );
  }
}
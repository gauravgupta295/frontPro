import { LightningElement, api, track, wire } from "lwc";
import getProductAvailabilities from "@salesforce/apex/SBR_3_0_AvailabilityCmpController.getProductAvailabilities";
import getChronosStatus from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProfileBranchChronosDetails";
import getBranchDetails from "@salesforce/apex/SBR_3_0_BranchDA.getBranchDetails";
import FORM_FACTOR from "@salesforce/client/formFactor";
import Sbr_3_0_availabilityCmpCss from "@salesforce/resourceUrl/Sbr_3_0_availabilityCmpCss";
import { loadStyle } from "lightning/platformResourceLoader";
import { appName, FL_APP_NAME, SAL_APP_NAME } from "c/sbr_3_0_frontlineUtils";
import FL_TEMPLATE from "./FL/defaultFL.html";
import SAL_TEMPLATE from "./SAL/defaultSAL.html";

export default class Sbr_3_0_availabilityCmp extends LightningElement {
  @api rowData;
  @api rowKey;
  @api isInModal = false;
  @api productCat = [];
  @api atpSelectedData;
  @api atpLabelSelectedData;
  @api branchSelectedData;
  @api rows = [];
  @api id;
  @api label;
  @api type;
  @api locationInfo;
  @api branchNumber;
  @api spotlightBranchNumber;
  @api chronosEnabled;
  @api objectApiName;
  @api recordId;
  @api utilization;
  @api isBranchOpen = false;
  @api tabs = false;
  @api branchName;
  @api title;
  @api isMobileAssets = false;
  @api headerText = "Availability";
  _productCatTest = ["0010001"];
  isMobile = false;
  isDataAvailable = true;
  isDataUnavailable = false;
  refreshDataAvailable = false;
  branchLoaded = false;
  search = "";
  updatedRows;
  isFiltered = false;
  isModalOpen = false;
  activetabContent = "";
  cancelButtonLabel = "Cancel";
  showModalSearch = false;
  oldRecordId;
  branchDisplayFromChild;
  branchNameOMSEnabled;
  @api branchDisplayFromSpotlight;
  rowsComplete = false;

  //hamza
  connectedCallback() {
    this.setAppName();
    //this.isMobile = window.matchMedia('(max-width: 480px)').matches;
    if (FORM_FACTOR === "Small") {
      this.isMobile = true;
    }
    loadStyle(this, Sbr_3_0_availabilityCmpCss); //Added as part of FRONT-8721 to apply dynamic css
    this.showModalSearch = this.isInModal && !this.isMobileAssets;

    getChronosStatus({
      objectId: this.recordId,
      objectApiName: this.objectApiName
    }).then((result) => {
      this.chronosEnabled = result?.isChronosEnabled;
      this.branchNumber = result?.branch?.Branch_Location_Number__c;
      this.spotlightBranchNumber = result?.branch?.Branch_Location_Number__c;
      this.branchDisplayFromChild = this.branchNumber; // setting initial value as profile branch

      this.locationInfo = result?.branch;
      this.getAvailability();
      this.branchLoaded = true;
    });
  }

  renderedCallback() {
    if (this.isMobile && this.oldRecordId != this.recordId) {
      this.oldRecordId = this.recordId;
      getChronosStatus({
        objectId: this.recordId,
        objectApiName: this.objectApiName
      }).then((result) => {
        this.chronosEnabled = result?.isChronosEnabled;
        this.branchNumber = result?.branch?.Branch_Location_Number__c;
        this.spotlightBranchNumber = result?.branch?.Branch_Location_Number__c;
        this.locationInfo = result?.branch;
        this.getAvailability();
        this.branchLoaded = true;
      });
    }
  }

  @track columns = [
    { label: "", fieldName: "label", hasSeparator: false },
    { label: "Avail", fieldName: "available", hasSeparator: true },
    { label: "Rsrv", fieldName: "reserve", hasSeparator: false },
    { label: "Pkup", fieldName: "pickUp", hasSeparator: false },
    { label: "Util", fieldName: "utilization", hasSeparator: false }
  ];

  /* Set the appropriate data available variables depending on if the data loads in the Spotlight Panel */
  @api setAvailabilityError(hasAvailabilityLoaded) {
    this.isDataAvailable = hasAvailabilityLoaded;
    this.isDataUnavailable = !hasAvailabilityLoaded;
  }
  /* Grab dummy data */
  @api setData(availData) {
    this.productCatclass = availData;
  }

  /* update avaiability data */
  @api updateAvailabilityData(availData) {
    this.productCat = availData;
    this.getAvailability();
  }
  @api updateSelectedATPData(atpData) {
    this.atpSelectedData = atpData;
    this.template
      .querySelector("c-sbr_3_0_availability-badge-cmp")
      .updateSelectedATPData(this.atpSelectedData);
  }

  @api updateSelectedATPLabelData(atpLabelData) {
    this.atpLabelSelectedData = atpLabelData;
    this.template
      .querySelector("c-sbr_3_0_availability-badge-cmp")
      .updateSelectedATPLabelData(this.atpLabelSelectedData);
  }

  @api updateLocationData(locData) {
    this.template
      .querySelector("c-sbr_3_0_availability-badge-cmp")
      .updateLocationData(locData);
  }

  @api updateSelectedBranchData(branchData) {
    this.branchSelectedData = branchData;
    this.template
      .querySelector("c-sbr_3_0_availability-badge-cmp")
      .updateSelectedBranchNumberData(this.branchSelectedData);
  }

  /* Method for clicking the Refresh button on the Availability error component. */
  handleRefresh() {
    this.getAvailability();
    if (this.refreshDataAvailable) {
      this.isDataAvailable = true;
      this.isDataUnavailable = false;
      this.getAvailability();
    } else {
      this.isDataAvailable = false;
      this.isDataUnavailable = true;
      return;
    }
  }
  /* Display the error illustration if the data is not available. */
  get illustrationDisplayClass() {
    return this.isDataUnavailable
      ? "illustration-error show"
      : "illustration-error";
  }

  /* Display class for the component.- For Modal window, slds-is-open is needed as it controls slds-section__content class too
   * For other cases, we need slds-is-close class by default  - SAL-26771
   */
  get TopLevelDisplayClass() {
    return this.isInModal
      ? "slds-section slds-is-open slds-m-bottom_none"
      : "slds-section slds-is-close slds-m-bottom_none";
  }

  /* Display data if it is available. */
  get availabilityDisplayClass() {
    return this.isDataAvailable
      ? "availability-grid show"
      : "availability-grid";
  }

  get titleSet() {
    return this.title;
  }
  handleChange(evt) {
    if (evt.target.value == "" || evt.target.value == null) {
      this.isFiltered = false;
    } else {
      this.isFiltered = true;
      this.updatedRows = [];
      this.search = evt.target.value;
      for (var i = 0; i < this.rows.length; i++) {
        var labelValue = this.rows[i].label;
        var lowerCaseValue = labelValue.toLowerCase();
        if (lowerCaseValue.indexOf(this.search.toLowerCase()) >= 0) {
          this.updatedRows.push(this.rows[i]);
        }
      }
    }
    //amy
    this.getLocationDetails(this.updatedRows);
  }
  get header() {
    return this.isInModal ? "header-row2" : "header-row";
  }
  get columnStyle() {
    return this.isInModal ? "columnsModal slds-text-color_weak" : "columns";
  }

  get headerFix() {
    return this.isInModal && this.isMobile ? "fix" : "fixDesktop";
  }
  showModalBox(evt) {
    this.activetabContent = evt.currentTarget.dataset.id;

    if (this.isMobile) {
      if (this.isInModal) {
        let str = this.formatBranch(evt.currentTarget.dataset.id);
        const goBackEvent = new CustomEvent("gotobranch", { detail: str });
        this.dispatchEvent(goBackEvent);
        this.branch = evt.currentTarget.dataset.id;
      } else {
        const toggleprodinqmobilestate = new CustomEvent(
          "toggleprodinqmobilestate",
          {
            bubbles: true,
            composed: true,
            detail: {
              viewState: "availability-asset",
              showTabsPanel: false,
              productCat: this.productCat,
              locationInfo: this.locationInfo,
              activeTab: this.activetabContent
            }
          }
        );
        this.dispatchEvent(toggleprodinqmobilestate);
      }
    } else if (this.isInModal == false) {
      this.isModalOpen = true;
      // SAL-26130 __ Salma

      if (this.chronosEnabled) {
        this.branchNumber = this.branchDisplayFromChild;
        this.branchName = "Branch " + this.branchNumber;
      } else {
        this.branchNumber = this.locationInfo.Branch_Location_Number__c;
        this.branchName = "Branch " + this.branchNumber;
      }
      this.template.querySelector("c-sbr_3_0_modal-cmp").toggleModal();

      if (this.isFrontlineApp) {
        this.showFrontlineModalView();
      } else {
        this.showNowFrontlineModalView();
      }
    } else {
      let str = this.formatBranch(evt.currentTarget.dataset.id);
      const goBackEvent = new CustomEvent("gotobranch", { detail: str });
      this.dispatchEvent(goBackEvent);
      this.branch = evt.currentTarget.dataset.id;
    }
  }

  formatBranch(branch) {
    const branchFormatted = branch.replace("Branch ", "");
    let str = "";
    if (branchFormatted.length === 3) {
      str = "0";
      str += branchFormatted;
    } else if (branchFormatted.length === 2) {
      str = "00";
      branchFormatted = str.concat(branchFormatted);
    } else if (branchFormatted.length === 1) {
      str = "000";
      branchFormatted = str.concat(branchFormatted);
    } else {
      str = branchFormatted;
    }

    return str;
  }

  openBranch(evt) {
    if (evt.detail == null) {
      this.branchNumber = this.locationInfo.Branch_Location_Number__c;
    } else {
      this.branchNumber = evt.detail;
    }

    this.isBranchOpen = true;

    if (this.isFrontlineApp) {
      this.activetabContent = "Branch";
      this.branchName = "Branch " + this.branchNumber;
    } else {
      this.tabs = false;
      this.cancelButtonLabel = "Back";
      this.headerText = "Assets: Branch " + this.branchNumber;
    }
  }

  getAvailability() {
    getProductAvailabilities({
      products: this.productCat,
      type: this.type,
      locationInfo: JSON.stringify(this.locationInfo)
    })
      .then((result) => {
        if (result[0].availabilityInfo.length > 0 && this.isMobile == true) {
          this.refreshDataAvailable = true;
          this.rows = result[0].availabilityInfo;
          this.utilization = result[0].availabilityInfo[0].utilization;
          this.isDataAvailable = true;
          this.isDataUnavailable = false;
          this.sortBranches();
        } else if (
          result[0].availabilityInfo[0] != null &&
          this.isMobile == false
        ) {
          this.refreshDataAvailable = true;
          this.rows = result[0].availabilityInfo;
          this.utilization = result[0].availabilityInfo[0].utilization;
          if (this.branchSelectedData != undefined) {
            this.branchNumber = this.branchSelectedData;
            this.spotlightBranchNumber = this.branchSelectedData;
          }
          this.isDataAvailable = true;
          this.isDataUnavailable = false;
          this.sortBranches();
        } else {
          this.refreshDataAvailable = false;
          this.isDataAvailable = false;
          this.isDataUnavailable = true;
        }
        //amy
        this.getLocationDetails(this.rows);
        const utilEvent = new CustomEvent("utilupdated", {
          detail: { util: this.utilization }
        });
        this.dispatchEvent(utilEvent);
      })
      .catch((error) => {
        console.log(error);
      });
  }

  async getLocationDetails(rows) {
    this.rowsComplete = false;
    //get all branch numbers
    let resultArr;
    let branchNumbers = rows.map((row) =>
      row.label.substr(row.label.length - 4)
    );
    try {
      //query branch details
      resultArr = await getBranchDetails({ branchNumbers: branchNumbers });
      //assign location details to rows
      rows.forEach((row) => {
        let branchNum = row.label.substr(row.label.length - 4);
        row.zipcode = resultArr[branchNum]?.Zip_Code__c;
        row.city = resultArr[branchNum]?.City__c;
        row.state = resultArr[branchNum]?.State__c;
      });
    } catch (err) {
      console.log(err);
    }
    this.rowsComplete = true;
  }

  handleReturnPage() {
    if (this.activetabContent == "Branch") {
      this.activetabContent = "District";
    }
    this.tabs = true;
    this.isBranchOpen = false;
    this.cancelButtonLabel = "Cancel";
  }

  toggleSection(event) {
    let buttonid = event.currentTarget.dataset.buttonid;
    let currentsection = this.template.querySelector(
      '[data-id="' + buttonid + '"]'
    );
    if (currentsection.className.search("slds-is-open") == -1) {
      currentsection.className = "slds-section slds-is-open";
    } else {
      currentsection.className = "slds-section slds-is-close";
    }
  }

  handlePageBack() {
    if (this.isBranchOpen == true) {
      this.template
        .querySelector("c-sbr_3_0_availability-modal-info-cmp")
        .pageBack();
    }
  }

  handleUpdateHeader(event) {
    this.headerText = event.detail;
  }

  tabChangeHandler(event) {
    if (this.isFrontlineApp) {
      this.showFrontlineTabChangeView(event);
    } else {
      this.showNonFrontlineTabChangeView(event);
    }
  }

  //Setting the user's branch as first in the list. The partseInt is to remove a trailing 0. For FRONT-8722 and 8721
  sortBranches() {
    if (
      this.rows &&
      this.rows.length > 0 &&
      this.locationInfo &&
      this.locationInfo.Branch_Location_Number__c &&
      this.type !== "summary"
    ) {
      let branchName = parseInt(
        this.locationInfo.Branch_Location_Number__c,
        10
      ).toString();
      this.rows.unshift(
        this.rows.splice(
          this.rows.findIndex((row) => row.branchNumber === branchName),
          1
        )[0]
      );
    }
  }

  async setAppName() {
    this.appName = await appName;
  }

  render() {
    return this.isFrontlineApp ? FL_TEMPLATE : SAL_TEMPLATE;
  }

  get isFrontlineApp() {
    return this.appName === FL_APP_NAME;
  }

  showFrontlineModalView() {
    if (this.activetabContent == "Branch") {
      //FRONT-8722 & 8721 Branch moved from modal to tabs
      this.isBranchOpen = true;
    } else {
      this.isBranchOpen = false;
    }
    this.tabs = true;
    this.cancelButtonLabel = "Cancel";
    if (this.activetabContent == "District") {
      this.title = this.locationInfo.District__c;
    } else if (this.activetabContent == "Region") {
      this.title = this.locationInfo.Region__c;
    } else if (this.activetabContent == "Territory") {
      this.title = this.locationInfo.Territory__c;
    } else if (this.activetabContent == "Company") {
      this.title = this.locationInfo.Company__c;
    }
  }

  showNowFrontlineModalView() {
    if (this.activetabContent == "Branch") {
      this.tabs = false;
      this.isBranchOpen = true;
      this.cancelButtonLabel = "Back";
    } else {
      this.isBranchOpen = false;
      this.tabs = true;
      this.cancelButtonLabel = "Cancel";
      if (this.activetabContent == "District") {
        this.title = this.locationInfo.District__c;
      } else if (this.activetabContent == "Region") {
        this.title = this.locationInfo.Region__c;
      } else if (this.activetabContent == "Territory") {
        this.title = this.locationInfo.Territory__c;
      } else if (this.activetabContent == "Company") {
        this.title = this.locationInfo.Company__c;
      }
    }
  }

  showFrontlineTabChangeView(event) {
    this.activetabContent = event.target.value;
    if (this.activetabContent == "Branch") {
      //FRONT-8722 & 8721 Branch moved from modal to tabs
      this.isBranchOpen = true;
    } else {
      this.isBranchOpen = false;
      this.headerText = "Availability";
      if (this.activetabContent == "District") {
        this.title = this.locationInfo.District__c;
      } else if (this.activetabContent == "Region") {
        this.title = this.locationInfo.Region__c;
      } else if (this.activetabContent == "Territory") {
        this.title = this.locationInfo.Territory__c;
      } else if (this.activetabContent == "Company") {
        this.title = this.locationInfo.Company__c;
      }
    }
  }

  showNonFrontlineTabChangeView(event) {
    this.activetabContent = event.target.value;

    this.headerText = "Availability";
    if (this.activetabContent == "District") {
      this.title = this.locationInfo.District__c;
    } else if (this.activetabContent == "Region") {
      this.title = this.locationInfo.Region__c;
    } else if (this.activetabContent == "Territory") {
      this.title = this.locationInfo.Territory__c;
    } else if (this.activetabContent == "Company") {
      this.title = this.locationInfo.Company__c;
    }
  }
  handleBranchDisplayUpdate(event) {
    this.branchDisplayFromChild = event.detail.pc;
    let branch = this.branchDisplayFromChild;
    let catClassId = event.detail.productId;
    let branchAvailableWarning = event.detail.branchAvailable;
    this.dispatchEvent(
      new CustomEvent("branchdisplayupdate", {
        detail: {
          pc: branch,
          productId: catClassId,
          branchAvailable: branchAvailableWarning
        }
      })
    );
  }
}
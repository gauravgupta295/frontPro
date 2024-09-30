import { LightningElement, track, api } from "lwc";
import fetchAssetsBasedOnStatus from "@salesforce/apex/SBR_3_0_AvailabilityModalInfoCmpCon.fetchAssets";
import fetchReservedAssets from "@salesforce/apex/SBR_3_0_AvailabilityModalInfoCmpCon.fetchEquipmentOnHold";
//import fetchReservations from '@salesforce/apex/SBR_3_0_AvailabilityModalInfoCmpCon.fetchReservations';
import { NavigationMixin } from "lightning/navigation";

export default class Sbr_3_0_availabilityModalInfoCmp extends NavigationMixin(
  LightningElement
) {
  page1 = true;
  page2 = false;
  isMobile = false;
  activeTabContent = "available";
  @api availableAssets = [];
  @api downLessAssets = [];
  @api downMoreAssets = [];
  @api returnedAssets = [];
  pickupAssets = [];
  @api reservations = [];
  @api productCat;
  @api branchNum;
  @api selectedAssetId;
  showAvailableAssets = false;
  showDownLessAssets = false;
  showDownMoreAssets = false;
  showReturnedAssets = false;
  showPickupAssets = false;

  @track reservedAssets = [];
  @track reservedAssetsExist = {
    isOrderIdAndNumber: false,
    isOrderContract: false,
    isOrderAccount: false,
    isStartDate: false,
    isEstimtedDate: false,
    isQuantity: false
  };

  @track
  myBreadcrumbs = [{ label: "Availability", name: "Availability" }];

  tabClass =
    "tab-button slds-m-horizontal_xx-small slds-button slds-button_neutral";
  selectedTabClass =
    "tab-button slds-m-horizontal_xx-small slds-button slds-button_neutral active-state";
  openClass = "open";
  closedClass = "closed";
  availableTabClass;
  reservedTabClass;
  availableContentClass = "open";
  reservedContentClass = "closed";

  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    this.myBreadcrumbs.push({
      label: "Branch " + this.branchNum,
      name: "Branch " + this.branchNum
    });
    fetchAssetsBasedOnStatus({
      catClass: this.productCat[0],
      branchNumber: this.branchNum
    }).then((result) => {
      console.log('result: '+JSON.stringify(result));
      var Available = [];
      var downLess = [];
      var downMore = [];
      var returned = [];
      var pickupAssets = [];
      for (var i = 0; i < result.length; i++) {
        if (result[i].Status == "AVAILABLE") {
          Available.push(result[i]);
        }
        // Changed As Part Of FRONT-23272 
        else if (result[i].Status == "DOWN - LESS THAN 20 DAYS") {
          downLess.push(result[i]);
        } else if (result[i].Status == "DOWN - MORE THAN 20 DAYS") {
          downMore.push(result[i]);
        } else if (result[i].Status == "RETURNED - NEED CHECK OUT") {
          returned.push(result[i]);
        } else if (result[i].Status == "SCHEDULED FOR PICKUP") {
          pickupAssets.push(result[i]);
        }
      }
      this.availableAssets = Available;
      this.downLessAssets = downLess;
      this.downMoreAssets = downMore;
      this.returnedAssets = returned;
      this.pickupAssets = pickupAssets;

      if (this.availableAssets.length > 0) {
        this.showAvailableAssets = true;
      }
      if (this.downLessAssets.length > 0) {
        this.showDownLessAssets = true;
      }
      if (this.downMoreAssets.length > 0) {
        this.showDownMoreAssets = true;
      }
      if (this.returnedAssets.length > 0) {
        this.showReturnedAssets = true;
      }
      if (this.pickupAssets.length > 0) {
        this.showPickupAssets = true;
      }
    });
    fetchReservedAssets({
      catClass: this.productCat[0],
      branch: this.branchNum
    })
      .then((result) => {
        this.reservedAssets = result;
        this.reservedAssets = this.reservedAssets.map((reservedAsset) => {
          if (reservedAsset?.SM_PS_Line_Number__r?.OrderId !== undefined) {
          reservedAsset.SM_PS_Line_Number__r.OrderId =
            "/" + reservedAsset.SM_PS_Line_Number__r.OrderId;
            //check for Order number
            if (
              reservedAsset?.SM_PS_Line_Number__r?.Order?.OrderNumber !==
              undefined
            )
              reservedAsset.isOrderExist = true;
            // check for Contract_Order_Number__c
            if (
              reservedAsset?.SM_PS_Line_Number__r?.Order
                ?.Contract_Order_Number__c !== undefined
            )
              reservedAsset.isOrderContractExist = true;
            // check for Account Name
            if (
              reservedAsset?.SM_PS_Line_Number__r?.Order?.Account?.Name !==
              undefined
            )
              reservedAsset.isAccountName = true;
            // check for startDate
            if (
              reservedAsset?.SM_PS_Line_Number__r?.Order?.Start_Date__c !==
              undefined
            )
              reservedAsset.isStartDate = true;
            // check for Estimated_Return_Date__c
            if (
              reservedAsset?.SM_PS_Line_Number__r?.Order
                ?.Estimated_Return_Date__c !== undefined
            )
              reservedAsset.isEstimatedDate = true;
            // check for quantity__c
            if (reservedAsset?.SM_PS_Line_Number__r?.Quantity__c !== undefined)
              reservedAsset.isQuantity = true;
            return reservedAsset;
          }
        });
        this.reservedAssets = this.reservedAssets.filter((reservedAsset) => {
          return reservedAsset ? true : false;
        });
      })
      .catch(function (error) {
        console.log("error in fetching reserved assets " + error.message);
      });
    /*fetchReservations({catClass: this.productCat[0],branch: this.branchNum}).then(
            result=>{
                this.reservations = result;
            }
        )*/
    this.setTabClasses("available");
  }

  tabChangeHandler(event) {
    this.activeTabContent = event.target.value;
    this.setTabClasses(this.activeTabContent);
  }

  setTabClasses(activeTab) {
    this.availableTabClass =
      activeTab === "available" ? this.selectedTabClass : this.tabClass;
    this.reservedTabClass =
      activeTab === "reserved" ? this.selectedTabClass : this.tabClass;

    this.availableContentClass =
      activeTab === "available" ? this.openClass : this.closedClass;
    this.reservedContentClass =
      activeTab === "reserved" ? this.openClass : this.closedClass;
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

  changePage(event) {
    this.myBreadcrumbs.push({
      label: "Asset #" + event.target.getAttribute("name"),
      name: "name"
    });
    this.page1 = false;
    this.page2 = true;
    this.selectedAssetId = event.target.getAttribute("name");

    // create event to change header text
    this.dispatchEvent(
      new CustomEvent("newheadertext", {
        detail: "Asset #" + event.target.getAttribute("name")
      })
    );

    //FRONT-1668 and 1937
    // create event to send the asset page is open
    this.dispatchEvent(
      new CustomEvent("changepage", {
        detail: {
          isAssetPageOpen: true
        }
      })
    );
  }

  handlePage(event) {
    const name = event.target.name;
    var point = this.myBreadcrumbs.findIndex((level) => level.name === name);
    var newBreadcrumbs = [];
    for (var i = 0; i <= this.myBreadcrumbs.length; i++) {
      if (i <= point) {
        newBreadcrumbs.push(this.myBreadcrumbs[i]);
      }
    }
    if (point == 0) {
      const goBackEvent = new CustomEvent("returnpage", {});
      this.dispatchEvent(goBackEvent);
    } else if (point == 1) {
      this.page1 = true;
      this.page2 = false;
    } else if (point == 2) {
      this.page1 = false;
      this.page2 = true;
    }
    this.myBreadcrumbs = newBreadcrumbs;
  }

  @api
  pageBack() {
    var point = this.myBreadcrumbs.length - 2;
    var newBreadcrumbs = [];
    for (var i = 0; i <= this.myBreadcrumbs.length; i++) {
      if (i <= point) {
        newBreadcrumbs.push(this.myBreadcrumbs[i]);
      }
    }
    if (point == 0) {
      const goBackEvent = new CustomEvent("returnpage", {});
      this.dispatchEvent(goBackEvent);
    } else if (point == 1) {
      this.page1 = true;
      this.page2 = false;
    } else if (point == 2) {
      this.page1 = false;
      this.page2 = true;
    }
    this.myBreadcrumbs = newBreadcrumbs;
  }

  navigateToRecord(event) {
    event.stopPropagation();

    let recordId = event.target.dataset.id;
    if (recordId) {
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: recordId,
          actionName: "view"
        }
      });
    }
  }
}
import { LightningElement, api } from "lwc";
//15677,15681 start
import borderStyle from "@salesforce/resourceUrl/Sbr_3_0_AddressCss";
import { loadStyle } from "lightning/platformResourceLoader";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import FORM_FACTOR from "@salesforce/client/formFactor";
import DESKTOPTEMPLATE from "./sbr_3_0_itemSearchAssetsTabCmp.html";
import MOBILETEMPLATE from "./sbr_3_0_itemSearchAssetsTabCmpMobile.html";
import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);
//15677,15681 end
export default class Sbr_3_0_itemSearchAssetsTabCmp extends LightningElement {
  //@api locationInfo;
  @api recordId;
  @api objectApiName;
  headerText = "Asset Search";
  cancelButtonLabel = "Cancel";
  isFooterNeeded = false;
  //Front-15677,Front-15681 start
  activeTab = "Cat Class Description";
  placeholder = "";
  catClassVal = "";
  showAssets = false;
  descriptionSelectedLocation = "Current Branch"; // FRONT - 15702
  selectedClass = "slds-button slds-button_neutral active-state";
  unselectedClass = "slds-button slds-button_neutral selected-btn";
  catClasstab = LABELS.CATCLASSTAB;
  catClassDescTab = LABELS.CATCLASSDESCRP;
  isDesktopApp = true;
  defaultButtonClass = "slds-button slds-button_neutral selected-btn";
  viewAssetEventdetail;
  hasCSSLoaded = false;
  //Front-15677,15681 end
  // showInventory = true; //Added as part of FRONT-18174 and 17876
  // handleAddItemClick() {
  //   this.template.querySelector("c-sbr_3_0_modal-cmp").toggleModal();
  // }
  connectedCallback() {
    if (FORM_FACTOR === "Small") {
      this.isDesktopApp = false;
    }
  }
  //15677 start
  tabChangeHandler(e) {
    this.activeTab = e.target.value;
  }

  //Front-15677
  renderedCallback() {
    if (!this.hasCSSLoaded) {
      Promise.all([loadStyle(this, borderStyle), loadStyle(this, FrontLineCSS)])
        .then(() => {
          logger.log("Files loaded");
          this.hasCSSLoaded = true;
        })
        .catch((error) => {
          logger.log("error in" + JSON.stringify(error));
        });
    }
    // If custom event fired from CatClassDescription Tab - View Asset event.
    if (this.viewAssetEventdetail) {
      this.template
        .querySelector('[data-id="CatClassContainer"]')
        .loadCatClassFilter(
          this.viewAssetEventdetail.catClassValue,
          this.viewAssetEventdetail.selectedLocationFilter
        );
      this.viewAssetEventdetail = null;
    }
  }

  render() {
    let renderTemplate = MOBILETEMPLATE;
    if (this.isDesktopApp) {
      renderTemplate = DESKTOPTEMPLATE;
    }
    return renderTemplate;
  }

  //start Front-15702
  handleViewAsset(event) {
    this.activeTab = "CatClass";
   // if (this.isDesktopApp) {
      this.viewAssetEventdetail = event.detail;
      logger.log('viewAsset:'+JSON.stringify(this.viewAssetEventdetail));
      
    /*} else {
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      setTimeout(() => {
        this.refs.catClass.setStaticDataForCatClassMobile(
          event.detail.catClassKey
        );
      }, 1000);
    }*/
  }

  handleSwitchToDescription() {
    this.activeTab = "Cat Class Description";
  }

  handleFilterChange(event) {
    this.descriptionSelectedLocation = event.detail.locationFilter;
  }
  //end Front-15702
}
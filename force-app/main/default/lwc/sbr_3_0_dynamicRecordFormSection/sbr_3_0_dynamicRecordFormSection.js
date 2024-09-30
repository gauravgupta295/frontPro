import { LightningElement, api } from "lwc";
import { isMobile, ACCORDION_VIEW } from "c/sbr_3_0_dynamicRecordFormUtility";
const DEFAULT_LAYOUT_CLASSES_DESKTOP =
  "slds-var-p-horizontal_small slds-var-p-vertical_medium";
const DEFAULT_LAYOUT_ITEM_CLASSES_DESKTOP = "slds-var-p-horizontal_medium";
const FULL_LAYOUT_SIZE = 12;
const HALF_LAYOUT_SIZE = 6;
const DEFAULT_SMALL_DEVICE_SIZE = FULL_LAYOUT_SIZE;
const DEFAULT_MOBILE_ACCORDION_SECTION_CLASSES =
  "drf_mobile dynamic-form-accordion-section";
const DEFAULT_DESKTOP_ACCORDION_SECTION_CLASSES =
  "drf-desktop dynamic-form-accordion-section slds-var-m-vertical_small";

const DEFAULT_LAYOUT_CLASSES_DESKTOP_FULLVIEW = "slds-var-p-horizontal_small";

const DEFAULT_DESKTOP_ACCORDION_SECTION_CLASSES_FULLVIEW =
  "drf-desktop dynamic-form-accordion-section";

export default class Sbr_3_0_dynamicRecordFormSection extends LightningElement {
  static renderMode = "light"; // the default is 'shadow'
  _section;
  @api
  get section() {
    return this._section;
  }

  set section(value) {
    this._section = value;
    this.viewMode = this.section.variant;
  }

  @api
  recordId;
  @api
  objectApiName;
  viewMode;

  isMobile = isMobile;
  //FRONT-16680
  get layoutClasses() {
    return isMobile
      ? ""
      : this.isFullViewMode
        ? DEFAULT_LAYOUT_CLASSES_DESKTOP_FULLVIEW
        : DEFAULT_LAYOUT_CLASSES_DESKTOP;
  }

  get layoutItemClasses() {
    return isMobile ? "" : DEFAULT_LAYOUT_ITEM_CLASSES_DESKTOP;
  }

  get mediumDeviceSize() {
    return this.section.isMultiColLayout ? HALF_LAYOUT_SIZE : FULL_LAYOUT_SIZE;
  }

  get largeDeviceSize() {
    return this.section.isMultiColLayout ? HALF_LAYOUT_SIZE : FULL_LAYOUT_SIZE;
  }

  get smallDeviceSize() {
    return DEFAULT_SMALL_DEVICE_SIZE;
  }

  //FRONT-16680
  get isMobileSingleSectionViewMode() {
    return /*this.isMobile &&*/ this.viewMode !== ACCORDION_VIEW;
  }

  get accordionSectionClasses() {
    return this.isMobile
      ? DEFAULT_MOBILE_ACCORDION_SECTION_CLASSES
      : this.isFullViewMode
        ? DEFAULT_DESKTOP_ACCORDION_SECTION_CLASSES_FULLVIEW
        : DEFAULT_DESKTOP_ACCORDION_SECTION_CLASSES;
  }

  //FRONT-16680
  get isFullViewMode() {
    return this.viewMode !== ACCORDION_VIEW;
  }
}
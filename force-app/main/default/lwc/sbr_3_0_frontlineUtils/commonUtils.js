import getAppName from "@salesforce/apex/SBR_3_0_CustomLookupController.getAppName";

export const isUndefined = (obj) => {
  return obj === undefined;
};

export const isUndefinedOrNull = (obj) => {
  return obj === undefined || obj === null;
};

export const isArray = (obj) => {
  return Array.isArray(obj);
};

export const isObject = (obj) => {
  return typeof obj === "object";
};

export const isEmpty = (obj) => {
  if (isUndefinedOrNull(obj) || obj === "") {
    return true;
  }
  if (isArray(obj)) {
    return obj.length === 0;
  } else if (
    isObject(obj) &&
    Object.prototype.toString.call(obj) === "[object Object]"
  ) {
    return Object.keys(obj).length === 0;
  }
  return false;
};

export const isError = (obj) => {
  return !!obj && this.objToString.apply(obj) === "[object Error]";
};

export const isFunction = (obj) => {
  return !!obj && this.objToString.apply(obj) === "[object Function]";
};

export const isString = (obj) => {
  return typeof obj === "string";
};

export const isNumber = (obj) => {
  return typeof obj === "number";
};

export const isFiniteNumber = (obj) => {
  return this.isNumber(obj) && isFinite(obj);
};

export const isBoolean = (obj) => {
  return typeof obj === "boolean";
};

export const equalsIgnoreCase = (str1, str2) => {
  return isUndefinedOrNull(str1) || isUndefinedOrNull(str2)
    ? isUndefinedOrNull(str1) && isUndefinedOrNull(str2)
    : str1.toLowerCase().trim() === str2.toLowerCase().trim();
};

export function getUrlParameter(name) {
  name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
  let regex = new RegExp("[\\?&]" + name + "=([^&#]*)");
  let results = regex.exec(location.search);
  return isUndefinedOrNull(results)
    ? ""
    : decodeURIComponent(results[1].replace(/\+/g, " "));
}

export const Logger = {
  create: function (isAvailable = false) {
    return {
      isEnabled: isAvailable,
      enable: function () {
        this.isEnabled = true;
      },
      disable: function () {
        this.isEnabled = false;
      },
      log: function (...args) {
        this.run(console.log, console, args);
      },
      warn: function (...args) {
        this.run(console.warn, console, args);
      },
      error: function (...args) {
        console.error.apply(console, args);
      },
      run: function (callbackfn, thisArg, args) {
        try {
          if (this.isEnabled) {
            callbackfn.apply(thisArg, args);
          }
        } catch (ex) {
          console.error(`Unable to run ${callbackfn}`);
        }
      }
    };
  }
};

export const normalizeBoolean = (value) => {
  let returnValue = value;
  if (isString(value)) {
    if (value.toLowerCase() === "false") {
      returnValue = false;
    } else {
      returnValue = true;
    }
  }
  return returnValue;
};

let _app;
export const appName = (async () => {
  if (_app) {
    return Promise.resolve(_app);
  } else {
    _app = await getAppName();
    return _app;
  }
})();

export const FL_APP_NAME = "RAE Frontline";
export const SAL_APP_NAME = "RAE Sales";

export const flattenWiredRecord = (wiredData) => {
  return Object.keys(wiredData.fields).reduce(
    (obj, field) => {
      let fieldVal = wiredData.fields[field]?.value;
      if (typeof fieldVal === "object" && fieldVal !== null) {
        obj[field] = { Id: fieldVal.id };
        Object.assign(obj[field], flattenWiredRecord(fieldVal));
      } else {
        obj[field] = fieldVal;
      }
      return obj;
    },
    { Id: wiredData.id }
  );
};

export const deepFlattenToObject = (obj, prefix = "") => {
  return Object.keys(obj).reduce((acc, k) => {
    const pre = prefix.length ? prefix + "_" : "";
    if (typeof obj[k] === "object" && obj[k] !== null) {
      Object.assign(acc, deepFlattenToObject(obj[k], pre + k));
    } else {
      acc[pre + k] = obj[k];
    }
    return acc;
  }, {});
};
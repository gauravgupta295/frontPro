//Format a Number value with the currency sign
export const formatPrependDollarSign = (fieldValToFormat) => {
    if(this.isEmpty(fieldValToFormat) &&
       String(fieldValToFormat).charAt(0) !== '$') {
       
     return '$' + Number(fieldValToFormat).toFixed(2);
       
    } 
    
    return fieldValToFormat;
}

//Remove the currency sign 
export const formatRemoveDollarSign = (fieldValToFormat) => {
  if(String(fieldValToFormat).charAt(0) === '$') {
    return String(fieldValToFormat).slice(1);
  }

  return fieldValToFormat;
}

/**
     * An element is empty if:
     * 1) it's falsey (undefined, null, empty String) but not 0 (which is falsey, but an acceptable value)
     * 2) It has a length of 0 (empty Arrays, NodeLists, and Strings)
     * 3) It's a String with only whitespace characters
*/
export const isEmpty = (itm) => {
    return (!itm && itm !== 0) ||
    itm.length === 0 ||
    (typeof itm === 'string' && !itm.match(/\S+/g));
};
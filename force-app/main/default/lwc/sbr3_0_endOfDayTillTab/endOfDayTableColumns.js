export const columns = [
    { label: 'Invoice #', fieldName: 'invoice',type: 'text' ,hideDefaultActions: true },
    { label: 'Type', fieldName: 'type', type: 'text' ,hideDefaultActions: true },
    { label: 'Amount', fieldName: 'amount', type: 'currency',hideDefaultActions: true},
    { label: 'User', fieldName: 'user', type: 'text',hideDefaultActions: true  },
    { label: 'SR', fieldName: 'sr', type: 'text',hideDefaultActions: true  },
    { label: 'Drivers License', fieldName: 'driverlicense', type: 'text',hideDefaultActions: true  },
];

export const roaColumns=[
    { label: 'Payment ID', fieldName: 'paymentid',type: 'text' ,hideDefaultActions: true },
    { label: 'Type', fieldName: 'type', type: 'text' ,hideDefaultActions: true },
    { label: 'Location', fieldName: 'location', type: 'text',hideDefaultActions: true  },
    { label: 'Amount', fieldName: 'amount', type: 'currency',hideDefaultActions: true},
    { label: 'User', fieldName: 'user', type: 'text',hideDefaultActions: true  },
    { label: 'Invoice # or Comment', fieldName: 'invoiceorcomment', type: 'text',hideDefaultActions: true  }
];

export const creditColumns=[
    { label: 'Visa', fieldName: 'visa' , type: 'text', hideDefaultActions: true },
    { label: 'Mastercard', fieldName: 'masterCard', type: 'text' ,hideDefaultActions: true },
    { label: 'Amex', fieldName: 'amex', type: 'text',hideDefaultActions: true  },
    { label: 'Diners Club', fieldName: 'dinersClub', type: 'text',hideDefaultActions: true  },
    { label: 'Discover', fieldName: 'discover', type: 'text',hideDefaultActions: true  }
];

export const roaCreditcolumns= [
    { label: 'Visa ROA', fieldName: 'visaroa' , type: 'text', hideDefaultActions: true },
    { label: 'Mastercard ROA', fieldName: 'masterCardroa', type: 'text' ,hideDefaultActions: true },
    { label: 'Amex ROA', fieldName: 'amexroa', type: 'text',hideDefaultActions: true  },
    { label: 'Diners Club ROA', fieldName: 'dinersClubroa', type: 'text',hideDefaultActions: true  },
    { label: 'Discover ROA', fieldName: 'discoverroa', type: 'text',hideDefaultActions: true  }
];

export const cashColumns= [
    { label: 'Invoice #', fieldName: 'invoice' , type: 'text', hideDefaultActions: true },
    { label: 'User', fieldName: 'user', type: 'text' ,hideDefaultActions: true },
    { label: 'Invoice Amount', fieldName: 'invoiceAmount', type: 'currency',hideDefaultActions: true },
    { label: 'Applied Deposit', fieldName: 'appliedDeposit', type: 'currency',hideDefaultActions: true},
    { label: 'Net Cash Received', fieldName: 'netCashReceived', type: 'currency',hideDefaultActions: true},
    { label: 'Other Amount', fieldName: 'otherAmount', type: 'currency',hideDefaultActions: true}
];

export const depositColumns= [
    { label: 'Contract #', fieldName: 'contract' , type: 'text', hideDefaultActions: true },
    { label: 'User', fieldName: 'user', type: 'text' ,hideDefaultActions: true },
    { label: 'Type', fieldName: 'type', type: 'text',hideDefaultActions: true  },
    { label: 'Amount', fieldName: 'amount', type: 'currency',hideDefaultActions: true},
    { label: 'Drivers License', fieldName: 'driversLicense', type: 'text',hideDefaultActions: true  }
];

export const otherLocationColumns= [
    { label: 'Invoice #', fieldName: 'invoice' , type: 'text', hideDefaultActions: true },
    { label: 'Location', fieldName: 'location', type: 'text' ,hideDefaultActions: true },
    { label: 'SR', fieldName: 'SR', type: 'text',hideDefaultActions: true  },
    { label: 'Invoice Amount', fieldName: 'invoiceAmount', type: 'currency',hideDefaultActions: true},
    { label: 'Applied Deposit', fieldName: 'appliedDeposit', type: 'currency',hideDefaultActions: true},
    { label: 'Net Cash Received', fieldName: 'netReceived', type: 'currency',hideDefaultActions: true},
    { label: 'Other Amount', fieldName: 'otherAmount', type: 'currency',hideDefaultActions: true}
];

export const businessColumns= [
    { label: 'Invoice #', fieldName: 'invoice' , type: 'text', hideDefaultActions: true },
    { label: 'Invoice Amount', fieldName: 'invoiceAmount', type: 'currency' ,hideDefaultActions: true},
    { label: 'Sales Tax', fieldName: 'salesTax', type: 'currency',hideDefaultActions: true},
    { label: 'Delivery/Pickup', fieldName: 'deliver', type: 'currency',hideDefaultActions: true},
    { label: 'Subtotal', fieldName: 'subTotal', type: 'currency',hideDefaultActions: true},
    { label: 'Damage Waiver', fieldName: 'damageWaiver', type: 'currency',hideDefaultActions: true}
];

export const amountByCreditCardMap = {
    'A': 'amex',
    'AR': 'amexroa',
    'X': 'dinersClub',
    'XR': 'dinersClubroa',
    'D': 'discover',
    'DR': 'discoverroa',
    'M': 'masterCard',
    'MR': 'masterCardroa',
    'V': 'visa',
    'VR': 'visaroa',
};

export const amountsByCreditCard = {
    visa: 0,
    masterCard: 0,
    amex: 0,
    dinersClub: 0,
    discover: 0,
    visaroa: 0,
    masterCardroa: 0,
    amexroa: 0,
    dinersClubroa: 0,
    discoverroa: 0,
};
public class SubProject {
    // TODO: move to XeroSync class
    public static String XERO_STATUS_SUBMITTED = 'Submitted'; 
    public static String XERO_STATUS_AUTHORISED = 'Authorised';
    public static String XERO_STATUS_PAID = 'Paid'; 
    
    public static Boolean isPaymentContained(Sub_Project__c payment, List<Sub_Project__c> otherPayments) {

        Map<Date, Boolean> includedDates = new Map<Date, Boolean>();
        for (Date tempDate = payment.Start_Date__c;  tempDate <= payment.End_Date__c; tempDate = tempDate.addDays(1)) {
            includedDates.put(tempDate, false);   
        }
        for (Sub_Project__c otherPayment :otherPayments) {
            if (otherPayment.Id == payment.Id) {
                continue;
            }
            if (!(otherPayment.Start_Date__c > payment.End_Date__c || otherPayment.End_Date__c < payment.Start_Date__c)) {
                for (Date tempDate = otherPayment.Start_Date__c; tempDate <= otherPayment.End_Date__c; tempDate = tempDate.addDays(1)) {
                    if (includedDates.containsKey(tempDate)) {
                        includedDates.put(tempDate, true);
                    }
                }
            }
        }

        Boolean isPaymentContained = includedDates.isEmpty() ? false : true;
        for (Boolean isDateIncluded :includedDates.values()) {
            if (!isDateIncluded) {
                isPaymentContained = false;
                break;
            }
        }
        return isPaymentContained;
    }
    
    public class PaymentWrapper {
        public Sub_Project__c payment { get; set; }
        public Boolean deletePayment { get; set; }
        public Boolean inconsistentSpends { get {
            if (inconsistentSpends == null) {
                return true;
            }
            return inconsistentSpends;
        } set; }
        
        public PaymentWrapper(Sub_Project__c payment, Boolean inconsistentSpends) {
            this.payment = payment;
            this.inconsistentSpends = inconsistentSpends;
            deletePayment = false;
        }
    }
}
public class ConSalesRepExpCommissionCalculator {

    public static Boolean SALES_REP_EXPECTED_COMMISSIONS_RECALCULATED = false;
    private static final String COMMISSION_TYPE_DEFAULT = Label.Commission_Type_Default;
    private static final String COMMISSION_TYPE_NO_COMMISSION = Label.Commission_Type_No_Commission;
    private static final String COMMISSION_TYPE_CONSULTANCY = Label.Commission_Type_Consultancy;
    private static final String COMMISSION_TYPE_INSIDE_SALES = Label.Commission_Type_Inside_Sales;
    private static final String COMMISSION_TYPE_SHARED_INSIDE_SALES = Label.Commission_Type_Shared_Inside_Sales;
    private static List<CurrencyType> currencies = [SELECT ISOCode, ConversionRate FROM CurrencyType WHERE IsActive=TRUE];


    public static void calculateExpectedCommission(List<Project__c> contracts) {
        List<Contract_Sales_Rep__c> reps = [SELECT Id, Contract__c From Contract_Sales_Rep__c WHERE Contract__c IN :contracts];
        calculateExpectedCommission(reps);
    }

        
    public static void calculateExpectedCommission(List<Contract_Sales_Rep__c> reps) {
        Set<Id> contractIds = new Set<Id>();
        for (Contract_Sales_Rep__c rep: reps) {
            contractIds.add(rep.Contract__c);
        }
        
        if (System.isFuture() || System.isBatch() || System.isScheduled() || System.isQueueable()) {
            calculateExpectedCommission(contractIds);
        } else {
            calculateExpectedCommissionFuture(contractIds);
        }
    }
    
    @future
    public static void calculateExpectedCommissionFuture(Set<Id> contractIds) {
        calculateExpectedCommission(contractIds);
    }
        
    public static void calculateExpectedCommission(Set<Id> contractIds) {
        if (SALES_REP_EXPECTED_COMMISSIONS_RECALCULATED) return;

        List<Project__c> contracts = [
            SELECT Id,  Client_Spend_Social__c, Client_Spend_YT__c, Actual_Gross_Profit_YT__c, Actual_Gross_Profit_Social__c, CurrencyISOCode, AllInvoicesPaidDate__c,
                    (SELECT Id, ExpectedCommission__c, Commission_Profile_Commission_Type__c, Contract_Gross_Profit_YT__c, Contract_Gross_Profit_Social__c,
                            Contract_Client_Spend_YT__c, Contract_Client_Spend_Social__c, Commission_Profile_FixedCommissionRate__c, CurrencyISOCode,
                            ContractClientSpendSocial__c,ContractClientSpendYT__c, ContractGrossProfitSocial__c, ContractGrossProfitYT__c,
                            Expected_Gross_Profit_per_Rep__c, Contract__r.CurrencyISOCode, All_Invoices_Paid_Date__c
                    FROM Sales_Reps__r
                    ORDER BY Commission_Profile__r.CommissionType__c DESC)
            FROM Project__c
            WHERE Id IN :contractIds
        ];

        List<Contract_Sales_Rep__c> repsToUpdate = prepareRepsToUpdate(contracts);
        SALES_REP_EXPECTED_COMMISSIONS_RECALCULATED = true;
        update repsToUpdate;
    }
    
    @testVisible
    private static List<Contract_Sales_Rep__c> prepareRepsToUpdate(List<Project__c> contracts) {
        if (!Test.isRunningTest()) {
            for (Project__c contract :contracts) {
                for (Contract_Sales_Rep__c rep :contract.Sales_Reps__r)  {
                    rep.Contract_Client_Spend_Social__c = rep.ContractClientSpendSocial__c;
                    rep.Contract_Client_Spend_YT__c = rep.ContractClientSpendYT__c;
                    rep.Contract_Gross_Profit_Social__c = rep.ContractGrossProfitSocial__c;
                    rep.Contract_Gross_Profit_YT__c = rep.ContractGrossProfitYT__c;
                    rep.All_Invoices_Paid_Date__c = contract.AllInvoicesPaidDate__c;
                }
            }
        }
        List<Contract_Sales_Rep__c> repsToUpdate = new List<Contract_Sales_Rep__c>();
        for (Project__c contract :contracts) {
            repsToUpdate.addAll(prepareContractRepsToUpdate(contract.Sales_Reps__r));
        }
        return repsToUpdate;        
    }
    
    @testVisible private static List<Contract_Sales_Rep__c> prepareContractRepsToUpdate(List<Contract_Sales_Rep__c> reps) {
        List<Contract_Sales_Rep__c> repsToUpdate = new List<Contract_Sales_Rep__c>();
        Decimal consultancyCommission;
        Decimal insideCommission;
        Integer normalCommissionCounter = 0;
        Integer consultancyCommissionCounter = 0;
        Integer sharedCommissionCounter = 0;
        Integer insideCommissionCounter = 0;
        for (Contract_Sales_Rep__c rep: reps) {
            if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_SHARED_INSIDE_SALES) {
                sharedCommissionCounter++;
            }
            if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_DEFAULT ||
                rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_NO_COMMISSION) {
                normalCommissionCounter++;
            }
            if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_INSIDE_SALES) {
                insideCommissionCounter++;
            }
            if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_CONSULTANCY) {
                consultancyCommissionCounter++;
            }
        }

        Decimal grossProfitDefaultRatio = 1;
        if (sharedCommissionCounter > 0 || insideCommissionCounter>0) {
            grossProfitDefaultRatio -= 0.2;
        }
        if (consultancyCommissionCounter > 0) {
            grossProfitDefaultRatio -= 0.5;
        }

        for (Contract_Sales_Rep__c rep : reps) {
            if (rep.Contract_Gross_Profit_Social__c == null) {
                rep.Contract_Gross_Profit_Social__c = 0;
            }
            if (rep.Contract_Gross_Profit_YT__c == null) {
                rep.Contract_Gross_Profit_YT__c = 0;
            }
            if (rep.Contract_Client_Spend_Social__c == null) {
                rep.Contract_Client_Spend_Social__c = 0;
            }
            if (rep.Contract_Client_Spend_YT__c == null) {
                rep.Contract_Client_Spend_YT__c = 0;
            }

            Decimal repCommission = (insideCommissionCounter > 0 || sharedCommissionCounter > 0) ?
                                calculateSalesRepBaseCommission(rep, true) :
                                calculateSalesRepBaseCommission(rep, false);
            Decimal repMaxGrossProfit = calculateMaxGrossProfitPerRep(rep);

            if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_NO_COMMISSION) {
                rep.ExpectedCommission__c = 0;
                rep.Expected_Gross_Profit_per_Rep__c = repMaxGrossProfit*grossProfitDefaultRatio/normalCommissionCounter;
                rep.Commission_percentage__c=100.0*grossProfitDefaultRatio/normalCommissionCounter;
            }
            if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_CONSULTANCY) {
                rep.ExpectedCommission__c = repCommission;
                rep.Expected_Gross_Profit_per_Rep__c = repMaxGrossProfit * 0.5;
                rep.Commission_percentage__c=50.0;
                Decimal ratio = 1;
                if (rep.CurrencyISOCode != rep.Contract__r.CurrencyISOCode) {
                    for(CurrencyType curr: currencies) {
                        if(rep.CurrencyISOCode == curr.ISOCode) {
                            ratio = ratio / curr.ConversionRate;
                        } else if(rep.Contract__r.CurrencyISOCode == curr.ISOCode) {
                            ratio = ratio * curr.ConversionRate;
                        }
                    }
                }
                consultancyCommission = repCommission * ratio;
            }
            if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_INSIDE_SALES) {
                rep.ExpectedCommission__c = repCommission;
                rep.Expected_Gross_Profit_per_Rep__c = repMaxGrossProfit * 0.2;
                rep.Commission_percentage__c=20.0;
                insideCommission = repCommission;
            }
            if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_SHARED_INSIDE_SALES) {
                rep.ExpectedCommission__c = repCommission;
                rep.Expected_Gross_Profit_per_Rep__c = repMaxGrossProfit * 0.2 / sharedCommissionCounter;
                rep.Commission_percentage__c = 20.0 / sharedCommissionCounter;
                insideCommission = repCommission;
            }
            if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_DEFAULT) {
                rep.ExpectedCommission__c = repCommission;
                rep.Expected_Gross_Profit_per_Rep__c = repMaxGrossProfit*grossProfitDefaultRatio/normalCommissionCounter;
                rep.Commission_percentage__c=100.0*grossProfitDefaultRatio/normalCommissionCounter;
            }
        }

        for (Contract_Sales_Rep__c rep: reps) {
            if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_DEFAULT) {
                if (consultancyCommission != null) {
                    Decimal ratio = 1;
                    if (rep.CurrencyISOCode != rep.Contract__r.CurrencyISOCode) {
                        for (CurrencyType curr: currencies) {
                            if (rep.CurrencyISOCode == curr.ISOCode) {
                                ratio = ratio / curr.ConversionRate;
                            } else if (rep.Contract__r.CurrencyISOCode == curr.ISOCode) {
                                ratio = ratio * curr.ConversionRate;
                            }
                        }
                    }

                    Decimal difference = rep.ExpectedCommission__c - consultancyCommission/ratio;
                    rep.ExpectedCommission__c = difference > 0 ? difference : 0;
                } else {
                    rep.ExpectedCommission__c = (rep.ExpectedCommission__c) / normalCommissionCounter;
                    if (rep.ExpectedCommission__c < 0) {
                        rep.ExpectedCommission__c = 0;
                    }
                    rep.Expected_Gross_Profit_per_Rep__c = (rep.Expected_Gross_Profit_per_Rep__c) / normalCommissionCounter;
                }
            }
            if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_SHARED_INSIDE_SALES) {
                rep.ExpectedCommission__c = rep.ExpectedCommission__c / sharedCommissionCounter;
            }
            repsToUpdate.add(rep);
        }
        return repsToUpdate;
    }
    
    @testVisible
    private static Decimal calculateSalesRepBaseCommission(Contract_Sales_Rep__c rep) {
        return calculateSalesRepBaseCommission(rep, false);
    }
    
    @testVisible
    private static Decimal calculateSalesRepBaseCommission(Contract_Sales_Rep__c rep, boolean isInsideSalesInContract) {
        Decimal clientSpendYT, clientSpendSocial, actualGrossProfitSocial, actualGrossProfitYT;
        clientSpendYT = rep.Contract_Client_Spend_YT__c;
        clientSpendSocial = rep.Contract_Client_Spend_Social__c;
        actualGrossProfitYT = rep.Contract_Gross_Profit_YT__c;
        actualGrossProfitSocial = rep.Contract_Gross_Profit_Social__c;
        
        if (clientSpendYT == 0 && clientSpendSocial == 0) return 0;
        if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_NO_COMMISSION) return 0;
        if (actualGrossProfitYT < 0 && actualGrossProfitSocial < 0) return 0;

        if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_INSIDE_SALES) {
            return calculateInsideSales(actualGrossProfitSocial, actualGrossProfitYT, clientSpendSocial, clientSpendYT);
        }
        if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_SHARED_INSIDE_SALES) {
            return calculateInsideSales(actualGrossProfitSocial, actualGrossProfitYT, clientSpendSocial, clientSpendYT);
        }        
        if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_CONSULTANCY) {
            Decimal fee = 0;
            if (clientSpendSocial != null && clientSpendSocial !=0 ) {
                Decimal sumSocial = actualGrossProfitSocial/clientSpendSocial;
                if (sumSocial >= 0.05) {
                    Decimal feeSocial= actualGrossProfitSocial * 0.01 * rep.Commission_Profile_FixedCommissionRate__c;
                    if (feeSocial > 0) {
                        fee += feeSocial;
                    }
                }
            }
            if (clientSpendYT != null && clientSpendYT != 0) {
                Decimal sumYT = actualGrossProfitYT/clientSpendYT;
                if (sumYT >= 0.05) {
                    Decimal feeYT = actualGrossProfitYT * 0.01 * rep.Commission_Profile_FixedCommissionRate__c;
                    if (feeYT > 0) {
                        fee += feeYT;
                    }
                }
            }
            return fee;
        }

        if (isInsideSalesInContract==false) {
            if (rep.Commission_Profile_Commission_Type__c == COMMISSION_TYPE_DEFAULT) {
                Decimal commissionYT = 0, commissionSocial = 0;        
                if (rep.Contract_Client_Spend_YT__c != null && rep.Contract_Client_Spend_YT__c != 0) {
                    Decimal finalMargin = actualGrossProfitYT / clientSpendYT;
                    if (finalMargin < 0.05) {
                        commissionYT =  0;
                    } else if (finalMargin < 0.10) {
                        commissionYT = actualGrossProfitYT * 0.01;
                    } else if (finalMargin < 0.15) {
                        commissionYT = actualGrossProfitYT * 0.02;
                    } else if (finalMargin < 0.20) {
                        commissionYT = actualGrossProfitYT * 0.03;
                    } else if (finalMargin < 0.25) {
                        commissionYT = actualGrossProfitYT * 0.04;
                    } else {
                        commissionYT = actualGrossProfitYT * 0.05;
                    }
                    if (commissionYT <= 0) {
                        commissionYT = 0;
                    }
                }
                if (rep.Contract_Client_Spend_Social__c != null && rep.Contract_Client_Spend_Social__c != 0) {
                    Decimal finalMargin = actualGrossProfitSocial / clientSpendSocial;
                    if (finalMargin < 0.05) {
                        commissionSocial = 0;
                    } else if (finalMargin < 0.075) {
                        commissionSocial = actualGrossProfitSocial * 0.01;
                    } else if (finalMargin < 0.10) {
                        commissionSocial =  actualGrossProfitSocial * 0.02;
                    } else if (finalMargin < 0.125) {
                        commissionSocial = actualGrossProfitSocial * 0.03;
                    } else if (finalMargin < 0.15) {
                        commissionSocial =  actualGrossProfitSocial * 0.04;
                    } else {
                        commissionSocial = actualGrossProfitSocial * 0.05;
                    }
                    if (commissionSocial <= 0) {
                        commissionSocial = 0;
                    } 
                }
                return commissionSocial + commissionYT;
            }        
        } else if(isInsideSalesInContract) {
            Decimal commissionYT = 0, commissionSocial = 0;
            if (rep.Contract_Client_Spend_YT__c != null && rep.Contract_Client_Spend_YT__c != 0){
                Decimal finalMargin = actualGrossProfitYT / clientSpendYT;
                if (finalMargin < 0.05) commissionYT =  0;
                else if (finalMargin < 0.10) commissionYT = actualGrossProfitYT * 0.005;
                else if (finalMargin < 0.15) commissionYT = actualGrossProfitYT * 0.01;
                else if (finalMargin < 0.20) commissionYT = actualGrossProfitYT * 0.02;
                else if (finalMargin < 0.25) commissionYT = actualGrossProfitYT * 0.03;
                else commissionYT = actualGrossProfitYT * 0.04;

                if (commissionYT <= 0) {
                    commissionYT = 0;
                }
            }
            if (rep.Contract_Client_Spend_Social__c != null && rep.Contract_Client_Spend_Social__c != 0) {
                Decimal finalMargin = actualGrossProfitSocial / clientSpendSocial;
                if (finalMargin < 0.05) commissionSocial = 0;
                else if (finalMargin < 0.075) commissionSocial = actualGrossProfitSocial * 0.005;
                else if (finalMargin < 0.10) commissionSocial =  actualGrossProfitSocial * 0.01;
                else if (finalMargin < 0.125) commissionSocial = actualGrossProfitSocial * 0.02;
                else if (finalMargin < 0.15) commissionSocial =  actualGrossProfitSocial * 0.03;
                else commissionSocial = actualGrossProfitSocial * 0.04;

                if (commissionSocial <= 0) {
                    commissionSocial=0;
                }
            }
            return commissionSocial + commissionYT;
        }
        return 0;
    }
    
    private static Decimal calculateInsideSales (Decimal actualGrossProfitSocial, Decimal actualGrossProfitYT, Decimal clientSpendSocial, Decimal clientSpendYT) {
        Decimal sum, commissionYT = 0, commissionSocial = 0;
        if (clientSpendYT != null && clientSpendYT != 0) {
            Decimal finalMargin = actualGrossProfitYT / clientSpendYT;
            if (finalMargin < 0.05) commissionYT =  0;
            if (finalMargin < 0.10) commissionYT = actualGrossProfitYT * 0.005;
            else commissionYT = actualGrossProfitYT * 0.01;

            if (commissionYT <= 0) {
                commissionYT = 0;
            }
        }
        if (clientSpendSocial != null && clientSpendSocial != 0) {
            Decimal finalMargin = actualGrossProfitSocial / clientSpendSocial;
            if (finalMargin < 0.05) commissionSocial =  0;
            if (finalMargin < 0.075) commissionSocial = actualGrossProfitSocial * 0.005;
            else commissionSocial = actualGrossProfitSocial * 0.01;

            if (commissionSocial <= 0){
                commissionSocial = 0;
            }
        }
        return (commissionYT + commissionSocial);
    }
    
    private static Decimal calculateMaxGrossProfitPerRep(Contract_Sales_Rep__c rep) {
        Decimal actualGrossProfit;
        if (rep.Contract_Gross_Profit_Social__c == null) {
            rep.Contract_Gross_Profit_Social__c = 0;
        }
        if (rep.Contract_Gross_Profit_YT__c == null) {
            rep.Contract_Gross_Profit_YT__c = 0;
        }
        actualGrossProfit = rep.Contract_Gross_Profit_Social__c + rep.Contract_Gross_Profit_YT__c;
        return actualGrossProfit;
    }

}
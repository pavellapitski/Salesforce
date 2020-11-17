@isTest
public class XeroTestHelper {
    
	public static List<XeroWrappers.XeroCreditNote> xeroCreditNotes = new List<XeroWrappers.XeroCreditNote>();
    public static List<XeroWrappers.XeroInvoice> xeroInvoices = new List<XeroWrappers.XeroInvoice>();    
	
	public static XeroWrappers.XeroContact createXeroContact() {
		XeroWrappers.XeroContact xc = new XeroWrappers.XeroContact();
		xc.ContactID                = '87d5bfb8-359b-4273-8e0b-c08c64da2062';
		xc.ContactNumber            = '1234';
		xc.ContactStatus            = XeroWrappers.XeroContactStatus.ACTIVE;
		xc.Name                     = 'New via API';
		xc.FirstName                = 'Test';
		xc.LastName                 = 'Test';
		xc.EmailAddress             = 'test@test.test';
		xc.SkypeUserName            = '4444';
		xc.BankAccountDetails       = 'asd';
		xc.TaxNumber                = '123';
		xc.XeroNetworkKey 			= '123Test';
		xc.HasAttachments 			= false;

		List<XeroWrappers.XeroAddress> addrs = new List<XeroWrappers.XeroAddress>();
		XeroWrappers.XeroAddress add1        = new XeroWrappers.XeroAddress();
		add1.AddressType                     = XeroWrappers.XeroAddressType.STREET;
		add1.AddressLine1                    = 'test line1';
		add1.City                            = 'Los Angeles';
		add1.Region                          = 'California';
		add1.PostalCode                      = '12345';
		add1.Country                         = 'US';
		add1.AttentionTo                     = 'test';

		XeroWrappers.XeroAddress add2 = new XeroWrappers.XeroAddress();
		add2.AddressType              = XeroWrappers.XeroAddressType.POBOX;
		add2.AddressLine1             = 'test line1';
		add2.City                     = 'Los Angeles';
		add2.Region                   = 'California';
		add2.PostalCode               = '12345';
		add2.Country                  = 'US';
		add2.AttentionTo              = 'test';
		addrs.add(add1);
		addrs.add(add2);
		xc.Addresses                  = addrs;

		XeroWrappers.XeroPhone xp1 = new XeroWrappers.XeroPhone();
		xp1.PhoneType              = XeroWrappers.XeroPhoneType.XDEFAULT;
		xp1.PhoneNumber            = '4444';
		xp1.PhoneAreaCode          = '444';
		xp1.PhoneCountryCode       = '44';

		XeroWrappers.XeroPhone xp2 = new XeroWrappers.XeroPhone();
		xp2.PhoneType              = XeroWrappers.XeroPhoneType.MOBILE;
		xp2.PhoneNumber            = '4444';
		xp2.PhoneAreaCode          = '444';
		xp2.PhoneCountryCode       = '44';
		xc.Phones                  = new List<XeroWrappers.XeroPhone>{xp1, xp2};
       
        //xc.UpdatedDateUTC = '\/Date(1442967113057+1200)\/';
		xc.IsSupplier                  = true;        
		xc.IsCustomer                  = true;
		xc.DefaultCurrency             = 'PLN';
		xc.Discount                    = 1.00;
		xc.Website                     = 'http://123.test';
		xc.PurchasesDefaultAccountCode = '400';
		xc.SalesDefaultAccountCode     = '200';
      	xc.BatchPayments = new XeroWrappers.XeroBatchPayment(new Map<String,Object>{
			'BankAccountNumber' => 'asd',
			'BankAccountName'   => 'asd',
			'Details'           => 'asd'
      	});
      XeroWrappers.XeroTerms xt1 = new XeroWrappers.XeroTerms(new Map<String,Object>{
			'Day'  => 12,
			'Type' => XeroWrappers.XeroPaymentTermType.OFFOLLOWINGMONTH
      });
      XeroWrappers.XeroTerms xt2 = new XeroWrappers.XeroTerms(new Map<String,Object>{
			'Day'  => 23,
			'Type' => XeroWrappers.XeroPaymentTermType.OFFOLLOWINGMONTH
      }); 
		XeroWrappers.XeroPaymentTerms xpt = new XeroWrappers.XeroPaymentTerms();
		xpt.Bills                         = xt1;
		xpt.Sales                         = xt2;
		xc.PaymentTerms                   = xpt;
		return xc;
	}
    
    public static XeroWrappers.XeroCreditNote createXeroCreditNote(CreditNote__c creditNoteObj) {
		XeroWrappers.XeroCreditNote xeroCreditNote  = new XeroWrappers.XeroCreditNote(creditNoteObj);
				
		return xeroCreditNote;
	}

	public static XeroWrappers.XeroInvoice createXeroInvoice() {
		XeroWrappers.XeroInvoice xi  = new XeroWrappers.XeroInvoice();
		xi.Type                      = XeroWrappers.XeroInvoiceType.ACCREC;
		xi.InvoiceID                 = 'c550782f-ce91-4261-a61c-387250909309';
		xi.InvoiceNumber             = 'INV-0029';
		xi.Reference                 = '';
		//"Payments": [],
		//"CreditNotes": [],
		//"Prepayments": [],
		//"Overpayments": [],
		xi.AmountDue                 = 1202.76;
		xi.AmountPaid                =  0.00;
		xi.SentToContact             = false;
		xi.CurrencyRate              = 0.236784;
		xi.HasErrors                 = false;
		//xi.IsDiscounted              = false;
		xi.HasAttachments            = false;
		xi.Contact                   = createXeroContact();
		xi.DateString                = '2015-09-24T00:00:00';
		xi.DueDateString             = '2015-10-23T00:00:00';
		xi.ExpectedPaymentDate 		  = System.today();
		xi.Status                    = XeroWrappers.XeroInvoiceStatus.DRAFT;
		xi.LineAmount           	  = XeroWrappers.XeroLineAmount.Exclusive;
		xi.LineItems                 = new List<XeroWrappers.XeroLineItem>{createXeroLineItem()};
		xi.SubTotal                  = 1202.76;
		xi.TotalTax                  =  0.00;
		xi.Total                     = 1202.76;
		xi.CurrencyCode              = 'USD';
		
		return xi;
	}

	public static XeroWrappers.XeroLineItem createXeroLineItem() {
		XeroWrappers.XeroLineItem xli = new XeroWrappers.XeroLineItem();
		xli.Description               = 'Test description';
		xli.UnitAmount                = 12.00;
		xli.TaxType                   = 'OUTPUT';
		xli.TaxAmount                 = 123.2;
		xli.LineAmount                = 123.12;
		xli.AccountCode               = '200';
		xli.Tracking                  = new List<XeroWrappers.XeroTrackingCategory>();
		xli.Quantity                  = 100.98;
		xli.LineItemID                = 'da4906dc-d0f7-40ea-adab-82063249e32e';
		return xli;
	}

	public static XeroWrappers.XeroAccount createXeroAccount() {
		XeroWrappers.XeroAccount xa = new XeroWrappers.XeroAccount();
		xa.AccountID                = 'f9735ff7-308b-446f-91e9-d14905b6be62';
		xa.Code                     = '412';
		xa.Name                     = 'Consulting & Accounting';
		xa.Status                   = 'ACTIVE';
		xa.AccountType              = 'EXPENSE';
		xa.TaxType                  = 'INPUT';
		xa.Description              = 'Expenses related to paying consultants';
		xa.AccountClass             = 'EXPENSE';
		xa.SystemAccount            = '';
		xa.EnablePaymentsToAccount  = false;
		xa.ShowInExpenseClaims      = true;
		xa.BankAccountType          = '';
		xa.ReportingCode            = '';
		xa.HasAttachments           = false;
		xa.BankAccountNumber        = '1231243234234';
		xa.CurrencyCode             = 'USD';
		xa.ReportingCodeName        = 'ReportingCodeName';
      return xa;
	}
	
}
public with sharing class XMLUtility {
	public XMLUtility() {
		
	}
	
    public static void mapCreditNoteToXML(XeroWrappers.XeroCreditNote obj, Xmlstreamwriter xmlW) {
		xmlW.writeStartElement(null, 'CreditNote', null);

		if (obj.Contact != null && String.isBlank(obj.Contact.ContactID) == false) {
			xmlW.writeStartElement(null,'Contact',null);
				xmlW.writeStartElement(null,'ContactID',null);
					xmlW.writeCharacters(obj.Contact.ContactID);
				xmlW.writeEndElement();
			xmlW.writeEndElement();
		}
        
        if (obj.CreditNoteDate != null) {
			xmlW.writeStartElement(null, 'Date', null);
				xmlW.writeCharacters(String.valueOf(obj.CreditNoteDate));
			xmlW.writeEndElement();
		}
		
		if (obj.CurrencyCode != null) {
			xmlW.writeStartElement(null, 'CurrencyCode', null);
				xmlW.writeCharacters(String.valueOf(obj.CurrencyCode));
			xmlW.writeEndElement();
		}

		if (obj.LineItems != null) {
			xmlW.writeStartElement(null, 'LineItems', null);
				mapLineItemToXml(obj.LineItems, xmlW);
			xmlW.writeEndElement();
		}
        
        if (obj.Status != null) {
			xmlW.writeStartElement(null, 'Status', null);
				xmlW.writeCharacters(obj.Status.name());
			xmlW.writeEndElement();
		}
        
        if (obj.Type != null) {
			xmlW.writeStartElement(null, 'Type', null);
				xmlW.writeCharacters(String.valueOf(obj.Type));
			xmlW.writeEndElement();
		}
        
        if (obj.Reference != null) {
			xmlW.writeStartElement(null, 'Reference', null);
				xmlW.writeCharacters(String.valueOf(obj.Reference));
			xmlW.writeEndElement();
		}

		xmlW.writeEndElement(); 
	}
    
    public static void mapCreditNoteAllocationToXML(XeroWrappers.XeroCreditNoteAllocation obj, Xmlstreamwriter xmlW) {
		xmlW.writeStartElement(null, 'Allocation', null);

        if (obj.AppliedAmount != null) {
			xmlW.writeStartElement(null, 'AppliedAmount', null);
				xmlW.writeCharacters(String.valueOf(obj.AppliedAmount));
			xmlW.writeEndElement();
		}
        
		if (obj.Invoice != null && String.isBlank(obj.Invoice.InvoiceID) == false) {
			xmlW.writeStartElement(null,'Invoice',null);
				xmlW.writeStartElement(null,'InvoiceID',null);
					xmlW.writeCharacters(obj.Invoice.InvoiceID);
				xmlW.writeEndElement();
			xmlW.writeEndElement();
		} 

		xmlW.writeEndElement(); 
	}

	public static void mapInvoiceItemToXML(XeroWrappers.XeroInvoice obj, Xmlstreamwriter xmlW) {		
		
		xmlW.writeStartElement(null, 'Invoice', null);

		if (obj.InvoiceID != null && String.isBlank(obj.InvoiceID) == false) {
			xmlW.writeStartElement(null,'InvoiceID',null);
				xmlW.writeStartElement(null,'InvoiceID',null);
					xmlW.writeCharacters(obj.InvoiceID);
				xmlW.writeEndElement();
			xmlW.writeEndElement();
		}

		if (obj.Contact != null && String.isBlank(obj.Contact.ContactID) == false) {
			xmlW.writeStartElement(null,'Contact',null);
				xmlW.writeStartElement(null,'ContactID',null);
					xmlW.writeCharacters(obj.Contact.ContactID);
				xmlW.writeEndElement();
			xmlW.writeEndElement();
		}
		
		if (obj.Type != null) {
			xmlW.writeStartElement(null, 'Type', null);
				xmlW.writeCharacters(String.valueOf(obj.Type));
			xmlW.writeEndElement();
		}

		if (obj.LineItems != null) {
			xmlW.writeStartElement(null, 'LineItems', null);
				mapLineItemToXml(obj.LineItems, xmlW);
			xmlW.writeEndElement();
		}

		if (obj.InvoiceDate != null) {
			xmlW.writeStartElement(null, 'Date', null);
				xmlW.writeCharacters(String.valueOf(obj.InvoiceDate));
			xmlW.writeEndElement();
		}

		if (obj.DueDate != null) {
			xmlW.writeStartElement(null, 'DueDate', null);
				xmlW.writeCharacters(String.valueOf(obj.DueDate));
			xmlW.writeEndElement();
		}

		if (obj.LineAmount != null) {
			xmlW.writeStartElement(null, 'LineAmount', null);
				xmlW.writeCharacters(obj.LineAmount.name());
			xmlW.writeEndElement();
		}

		if (String.isBlank(obj.InvoiceNumber) == null) {
			xmlW.writeStartElement(null, 'InvoiceNumber', null);
				xmlW.writeCharacters(obj.InvoiceNumber);
			xmlW.writeEndElement();
		}

		if (String.isBlank(obj.Reference) == false) {
			xmlW.writeStartElement(null, 'Reference', null);
				xmlW.writeCharacters(obj.Reference);
			xmlW.writeEndElement();
		}

		if (String.isBlank(obj.BrandingThemeID) == false) {
			xmlW.writeStartElement(null, 'BrandingThemeID', null);
				xmlW.writeCharacters(obj.BrandingThemeID);
			xmlW.writeEndElement();
		}

		if (String.isBlank(obj.Url) == false) {
			xmlW.writeStartElement(null, 'Url', null);
				xmlW.writeCharacters(obj.Url);
			xmlW.writeEndElement();
		}

		if (String.isBlank(obj.CurrencyCode) == false) {
			xmlW.writeStartElement(null, 'CurrencyCode', null);
				xmlW.writeCharacters(obj.CurrencyCode);
			xmlW.writeEndElement();
		}

		if (obj.CurrencyRate != null) {
			xmlW.writeStartElement(null, 'CurrencyRate', null);
				xmlW.writeCharacters(String.valueOf(obj.CurrencyRate));
			xmlW.writeEndElement();
		}

		if (obj.Status != null) {
			xmlW.writeStartElement(null, 'Status', null);
				xmlW.writeCharacters(obj.Status.name());
			xmlW.writeEndElement();
		}

		if (obj.SentToContact != null) {
			xmlW.writeStartElement(null, 'SentToContact', null);
				xmlW.writeCharacters(String.valueOf(obj.SentToContact));
			xmlW.writeEndElement();
		}

		if (obj.ExpectedPaymentDate != null) {
			xmlW.writeStartElement(null, 'ExpectedPaymentDate', null);
				xmlW.writeCharacters(String.valueOf(obj.ExpectedPaymentDate));
			xmlW.writeEndElement();
		}

		if (obj.PlannedPaymentDate != null) {
			xmlW.writeStartElement(null, 'PlannedPaymentDate', null);
				xmlW.writeCharacters(String.valueOf(obj.PlannedPaymentDate));
			xmlW.writeEndElement();
		}

		xmlW.writeEndElement(); //Close 
	}

	public static void mapLineItemToXml(List<XeroWrappers.XeroLineItem> lineItems, XmlStreamWriter xmlW) {

		for (XeroWrappers.XeroLineItem xli : lineItems) {
			xmlW.writeStartElement(null, 'LineItem', null);

			if (String.isBlank(xli.Description) == false) {
				xmlW.writeStartElement(null, 'Description', null);
					xmlW.writeCharacters((xli.Description));
				xmlW.writeEndElement();
			}
			
			if (xli.ItemCode != null) {
				xmlW.writeStartElement(null, 'ItemCode', null);
					xmlW.writeCharacters(String.valueOf(xli.ItemCode));
				xmlW.writeEndElement();
			}

			if (xli.Quantity != null) {
				xmlW.writeStartElement(null, 'Quantity', null);
					xmlW.writeCharacters(String.valueOf(xli.Quantity));
				xmlW.writeEndElement();
			}

			if (xli.UnitAmount != null) {
				xmlW.writeStartElement(null, 'UnitAmount', null);
					xmlW.writeCharacters(String.valueOf(xli.UnitAmount));
				xmlW.writeEndElement();
			}

			if (String.isBlank(xli.AccountCode) == false) {
				xmlW.writeStartElement(null, 'AccountCode', null);
					xmlW.writeCharacters(xli.AccountCode);
				xmlW.writeEndElement();
			}

			if (String.isBlank(xli.LineItemId) == false) {
				xmlW.writeStartElement(null, 'LineItemId', null);
					xmlW.writeCharacters(xli.LineItemId);
				xmlW.writeEndElement();
			}

			if (xli.LineAmount != null) {
				xmlW.writeStartElement(null, 'LineAmount', null);
					xmlW.writeCharacters(String.valueOf(xli.LineAmount));
				xmlW.writeEndElement();
			}
			
			if (xli.TaxType != null) {
				xmlW.writeStartElement(null, 'TaxType', null);
					xmlW.writeCharacters(String.valueOf(xli.TaxType));
				xmlW.writeEndElement();
			}

			xmlW.writeEndElement();	
		}
	}

	// method to create single Contact 
	public static void mapContactItemToXml(XeroWrappers.XeroContact contactObj, XmlStreamWriter xmlW) {
		// create body
		xmlW.writeStartElement(null, 'Contact', null);

		if (String.isBlank(contactObj.Name) == false) {
			xmlW.writeStartElement(null, 'Name', null);
				xmlW.writeCharacters(contactObj.Name);
			xmlW.writeEndElement();
		}

		if (String.isBlank(contactObj.ContactID) == false) {
			xmlW.writeStartElement(null, 'ContactID', null);
				xmlW.writeCharacters(contactObj.ContactID);
			xmlW.writeEndElement();
		}

		if (String.isBlank(contactObj.ContactNumber) == false) {
			xmlW.writeStartElement(null, 'ContactNumber', null);
				xmlW.writeCharacters(contactObj.ContactNumber);
			xmlW.writeEndElement();
		}

		if (String.isBlank(contactObj.AccountNumber) == false) {
			xmlW.writeStartElement(null, 'AccountNumber', null);
				xmlW.writeCharacters(contactObj.AccountNumber);
			xmlW.writeEndElement();
		}

		if (contactObj.ContactStatus != null) {
			xmlW.writeStartElement(null, 'ContactStatus', null);
				xmlW.writeCharacters(contactObj.ContactStatus.name());
			xmlW.writeEndElement();
		}

		if (String.isBlank(contactObj.FirstName) == false) {
			xmlW.writeStartElement(null, 'FirstName', null);
				xmlW.writeCharacters(contactObj.FirstName);
			xmlW.writeEndElement();
		}

		if (String.isBlank(contactObj.LastName) == false) {
			xmlW.writeStartElement(null, 'LastName', null);
				xmlW.writeCharacters(contactObj.LastName);
			xmlW.writeEndElement();
		}

		if (String.isBlank(contactObj.EmailAddress) == false) {
			xmlW.writeStartElement(null, 'EmailAddress', null);
				xmlW.writeCharacters(contactObj.EmailAddress);
			xmlW.writeEndElement();
		}

		if (String.isBlank(contactObj.SkypeUserName) == false) {
			xmlW.writeStartElement(null, 'SkypeUserName', null);
				xmlW.writeCharacters(contactObj.SkypeUserName);
			xmlW.writeEndElement();
		}
		
		if (contactObj.ContactPersons != null && (contactObj.ContactPersons).isEmpty() == false) {
			xmlW.writeStartElement(null, 'ContactPersons', null);
				for (XeroWrappers.XeroContactPerson xcp : contactObj.ContactPersons) {
					XMLUtility.mapContactPersonItemToXml(xmlW, xcp);
				}
			xmlW.writeEndElement();
		}

		if (String.isBlank(contactObj.BankAccountDetails) == false) {
			xmlW.writeStartElement(null, 'BankAccountDetails', null);
				xmlW.writeCharacters(contactObj.BankAccountDetails);
			xmlW.writeEndElement();
		}

		if (String.isBlank(contactObj.TaxNumber) == false) {
			xmlW.writeStartElement(null, 'TaxNumber', null);
				xmlW.writeCharacters(contactObj.TaxNumber);
			xmlW.writeEndElement();
		}

		if (String.isBlank(contactObj.AccountsReceivableTaxType) == false) {
			xmlW.writeStartElement(null, 'AccountsReceivableTaxType', null);
				xmlW.writeCharacters(contactObj.AccountsReceivableTaxType);
			xmlW.writeEndElement();
		}

		if (String.isBlank(contactObj.AccountsPayableTaxType) == false) {
			xmlW.writeStartElement(null, 'AccountsPayableTaxType', null);
				xmlW.writeCharacters(contactObj.AccountsPayableTaxType);
			xmlW.writeEndElement();
		}

		if (contactObj.Addresses != null && (contactObj.Addresses).isEmpty() == false) {
			xmlW.writeStartElement(null, 'Addresses', null);
				for (XeroWrappers.XeroAddress xa : contactObj.Addresses) {
					XMLUtility.mapAddressItemToXml(xmlW, xa);
				}
			xmlW.writeEndElement();
		}

		if (contactObj.Phones != null && (contactObj.Phones).isEmpty() == false) {
			xmlW.writeStartElement(null, 'Phones', null);
				for (XeroWrappers.XeroPhone xp : contactObj.Phones) {
					XMLUtility.mapPhoneItemToXml(xmlW, xp);
				}
			xmlW.writeEndElement();
		}

		if (contactObj.IsSupplier != null) {
			xmlW.writeStartElement(null, 'IsSupplier', null);
				xmlW.writeCharacters(String.valueOf(contactObj.IsSupplier));
			xmlW.writeEndElement();
		}

		if (contactObj.IsCustomer != null) {
			xmlW.writeStartElement(null, 'IsCustomer', null);
				xmlW.writeCharacters(String.valueOf(contactObj.IsCustomer));
			xmlW.writeEndElement();
		}

		if (String.isBlank(contactObj.DefaultCurrency) == false) {
			xmlW.writeStartElement(null, 'DefaultCurrency', null);
				xmlW.writeCharacters(String.valueOf(contactObj.DefaultCurrency));
			xmlW.writeEndElement();
		}

		xmlW.writeEndElement();
	}

	// method to create single Address
	public static void mapAddressItemToXml(XmlStreamWriter xmlW, XeroWrappers.XeroAddress addressObj) {
		System.debug('**** Address ' + addressObj);
		xmlW.writeStartElement(null, 'Address', null);

		if (addressObj.AddressType != null) {
			xmlW.writeStartElement(null, 'AddressType', null);
				xmlW.writeCharacters(addressObj.AddressType.name());
			xmlW.writeEndElement();
		}

		if (String.isBlank(addressObj.AddressLine1) == false) {
			xmlW.writeStartElement(null, 'AddressLine1', null);
				xmlW.writeCharacters(addressObj.AddressLine1);
			xmlW.writeEndElement();
		}

		if (String.isBlank(addressObj.AddressLine2) == false) {
			xmlW.writeStartElement(null, 'AddressLine2', null);
				xmlW.writeCharacters(addressObj.AddressLine2);
			xmlW.writeEndElement();
		}

		if (String.isBlank(addressObj.AddressLine3) == false) {
			xmlW.writeStartElement(null, 'AddressLine3', null);
				xmlW.writeCharacters(addressObj.AddressLine3);
			xmlW.writeEndElement();
		}

		if (String.isBlank(addressObj.AddressLine4) == false) {
			xmlW.writeStartElement(null, 'AddressLine4', null);
				xmlW.writeCharacters(addressObj.AddressLine4);
			xmlW.writeEndElement();
		}

		if (String.isBlank(addressObj.City) == false) {
			xmlW.writeStartElement(null, 'City', null);
				xmlW.writeCharacters(addressObj.City);
			xmlW.writeEndElement();
		}

		if (String.isBlank(addressObj.Region) == false) {
			xmlW.writeStartElement(null, 'Region', null);
				xmlW.writeCharacters(addressObj.Region);
			xmlW.writeEndElement();
		}

		if (String.isBlank(addressObj.PostalCode) == false) {
			xmlW.writeStartElement(null, 'PostalCode', null);
				xmlW.writeCharacters(addressObj.PostalCode);
			xmlW.writeEndElement();
		}

		if (String.isBlank(addressObj.Country) == false) {
			xmlW.writeStartElement(null, 'Country', null);
				xmlW.writeCharacters(addressObj.Country);
			xmlW.writeEndElement();
		}

		if (String.isBlank(addressObj.AttentionTo) == false) {
			xmlW.writeStartElement(null, 'AttentionTo', null);
				xmlW.writeCharacters(addressObj.AttentionTo);
			xmlW.writeEndElement();
		}

		xmlW.writeEndElement();
	}

	// method to create single Phone
	public static void mapPhoneItemToXml(XmlStreamWriter xmlW, XeroWrappers.XeroPhone phoneObj) {
		xmlW.writeStartElement(null, 'Phone', null);

		if (phoneObj.PhoneType != null) {
			xmlW.writeStartElement(null, 'PhoneType', null);
				String tmp = phoneObj.PhoneType.name();
				xmlW.writeCharacters(tmp == 'XDEFAULT' ? 'DEFAULT' : tmp);
			xmlW.writeEndElement();
		}

		if (String.isBlank(phoneObj.PhoneNumber) == false) {
			xmlW.writeStartElement(null, 'PhoneNumber', null);
				xmlW.writeCharacters(phoneObj.PhoneNumber);
			xmlW.writeEndElement();
		}

		if (String.isBlank(phoneObj.PhoneAreaCode) == false) {
			xmlW.writeStartElement(null, 'PhoneAreaCode', null);
				xmlW.writeCharacters(phoneObj.PhoneAreaCode);
			xmlW.writeEndElement();
		}

		if (String.isBlank(phoneObj.PhoneCountryCode) == false) {
			xmlW.writeStartElement(null, 'PhoneCountryCode', null);
				xmlW.writeCharacters(phoneObj.PhoneCountryCode);
			xmlW.writeEndElement();
		}

		xmlW.writeEndElement();
	}
	
	// method to create single ContactPersons
	public static void mapContactPersonItemToXml(XmlStreamWriter xmlW, XeroWrappers.XeroContactPerson cpObj) {
		xmlW.writeStartElement(null, 'ContactPerson', null);

		if (String.isBlank(cpObj.FirstName) == false) {
			xmlW.writeStartElement(null, 'FirstName', null);
				xmlW.writeCharacters(cpObj.FirstName);
			xmlW.writeEndElement();
		}

		if (String.isBlank(cpObj.LastName) == false) {
			xmlW.writeStartElement(null, 'LastName', null);
				xmlW.writeCharacters(cpObj.LastName);
			xmlW.writeEndElement();
		}

		if (String.isBlank(cpObj.EmailAddress) == false) {
			xmlW.writeStartElement(null, 'EmailAddress', null);
				xmlW.writeCharacters(cpObj.EmailAddress);
			xmlW.writeEndElement();
		}

		if (cpObj.IncludeInEmails != null) {
			xmlW.writeStartElement(null, 'IncludeInEmails', null);
				xmlW.writeCharacters(String.valueOf(cpObj.IncludeInEmails));
			xmlW.writeEndElement();
		}

		xmlW.writeEndElement();
	}
}
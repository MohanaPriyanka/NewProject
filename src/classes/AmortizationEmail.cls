global class AmortizationEmail {

	webService static void sendEmail(ID oppID, String email){
		AmortizationEmail amEmail = new AmortizationEmail();
		
		PageReference inlineDoc = Page.AmortizationSchedule;
			inlineDoc.getParameters().put('id', oppID);
			Blob b = inlineDoc.getContent();
		
		amEmail.sendEmail2(email, b);
	}
	
	public void sendEmail2(String email, Blob content){
		List<String> toAddresses = new List<String>();
			toAddresses.add(email.trim());
			
		Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
			fileAttachment.fileName = 'Amortization Schedule.pdf';
    		fileAttachment.setBody(content); 

		List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
    		fileAttachments.add(fileAttachment);
		
		List<EmailTemplate> etemps = [select subject, body, TemplateType, HtmlValue
										from EmailTemplate
									   where DeveloperName = 'Send_schedule_as_PDF'];
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setToAddresses(toAddresses);
			if( etemps.size() > 0 ){
				mail.setSubject(etemps[0].subject);
				mail.setPlainTextBody(etemps[0].body);
				if(etemps[0].templateType != 'text'){
					mail.setHtmlBody(etemps[0].HtmlValue);
				}
			}else{
				mail.setSubject('PDF-copy of Amortization Schedule');
				mail.setPlainTextBody('Hello.\r\n\r\n'
					+'Please see your Amortization Schedule as PDF-file in attachment to this email.\r\n'
					+'Thank you for your interest.');
			}
			mail.setUseSignature(false);
			mail.setSaveAsActivity(false);  
			mail.setFileAttachments(fileAttachments);
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}

}